import Player "../models/Player";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Types "../stadium/Types";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Timer "mo:base/Timer";
import MatchSimulator "MatchSimulator";
import Random "mo:base/Random";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Bool "mo:base/Bool";
import PseudoRandomX "mo:random/PseudoRandomX";
import LeagueTypes "../league/Types";
import IterTools "mo:itertools/Iter";
import MatchAura "../models/MatchAura";
import Team "../models/Team";
import FieldPosition "../models/FieldPosition";
import Season "../models/Season";

actor StadiumActor : Types.StadiumActor {
    type PlayerState = Types.PlayerState;
    type FieldPosition = FieldPosition.FieldPosition;
    type MatchAura = MatchAura.MatchAura;
    type Prng = PseudoRandomX.PseudoRandomGenerator;
    type Team = Team.Team;

    type MatchGroupId = Nat;

    type CompletedMatchResult = {
        match : Season.CompletedMatch;
        matchStats : [Player.PlayerMatchStatsWithId];
    };

    stable var matchGroups = Trie.empty<Nat, Types.MatchGroup>();
    stable var leagueIdOrNull : ?Principal = null;

    system func postupgrade() {
        // Restart the timers for any match groups that were in progress
        for ((matchGroupId, matchGroup) in Trie.iter(matchGroups)) {
            resetTickTimerInternal<system>(matchGroupId);
        };
    };

    public shared ({ caller }) func setLeague(id : Principal) : async Types.SetLeagueResult {
        // TODO how to get the league id vs manual set
        // Set if the league is not set or if the caller is the league
        if (leagueIdOrNull == null or leagueIdOrNull == ?caller) {
            leagueIdOrNull := ?id;
            return #ok;
        };
        #err(#notAuthorized);
    };

    public query func getMatchGroup(id : Nat) : async ?Types.MatchGroupWithId {
        switch (getMatchGroupOrNull(id)) {
            case (null) return null;
            case (?m) {
                ?{
                    m with
                    id = id;
                };
            };
        };
    };

    public query func getMatchGroups() : async [Types.MatchGroupWithId] {
        matchGroups
        |> Trie.iter(_)
        |> Iter.map(
            _,
            func(m : (Nat, Types.MatchGroup)) : Types.MatchGroupWithId = {
                m.1 with
                id = m.0;
            },
        )
        |> Iter.toArray(_);
    };

    public shared ({ caller }) func startMatchGroup(
        request : Types.StartMatchGroupRequest
    ) : async Types.StartMatchGroupResult {
        assertLeague(caller);

        let prng = PseudoRandomX.fromBlob(await Random.blob());
        let tickTimerId = startTickTimer<system>(request.id);

        let tickResults = Buffer.Buffer<Types.TickResult>(request.matches.size());
        label f for ((matchId, match) in IterTools.enumerate(Iter.fromArray(request.matches))) {

            let team1IsOffense = prng.nextCoin();
            let initState = MatchSimulator.initState(
                match.aura,
                match.team1,
                match.team2,
                team1IsOffense,
                prng,
            );
            tickResults.add({
                match = initState;
                status = #inProgress;
            });
        };
        if (tickResults.size() == 0) {
            return #err(#noMatchesSpecified);
        };

        let matchGroup : Types.MatchGroupWithId = {
            id = request.id;
            matches = Buffer.toArray(tickResults);
            tickTimerId = tickTimerId;
            currentSeed = prng.getCurrentSeed();
        };
        addOrUpdateMatchGroup(matchGroup);
        #ok;
    };

    public shared ({ caller }) func cancelMatchGroup(
        request : Types.CancelMatchGroupRequest
    ) : async Types.CancelMatchGroupResult {
        assertLeague(caller);
        let matchGroupKey = buildMatchGroupKey(request.id);
        let (newMatchGroups, matchGroup) = Trie.remove(matchGroups, matchGroupKey, Nat.equal);
        switch (matchGroup) {
            case (null) return #err(#matchGroupNotFound);
            case (?matchGroup) {
                matchGroups := newMatchGroups;
                Timer.cancelTimer(matchGroup.tickTimerId);
                #ok;
            };
        };
    };

    // TODO remove
    public shared func finishMatchGroup(id : Nat) : async () {
        // TODO check BDFN
        let ?matchGroupz = getMatchGroupOrNull(id) else Debug.trap("Match group not found");
        var matchGroup = matchGroupz;
        var prng = PseudoRandomX.LinearCongruentialGenerator(matchGroup.currentSeed);
        label l loop {
            switch (tickMatches(prng, matchGroup.matches)) {
                case (#completed(_)) break l;
                case (#inProgress(newMatches)) {
                    addOrUpdateMatchGroup({
                        matchGroup with
                        id = id;
                        matches = newMatches;
                        currentSeed = prng.getCurrentSeed();
                    });
                    let ?newMG = getMatchGroupOrNull(id) else Debug.trap("Match group not found");
                    matchGroup := newMG;
                    prng := PseudoRandomX.LinearCongruentialGenerator(matchGroup.currentSeed);
                };
            };
        };
    };

    public shared ({ caller }) func tickMatchGroup(id : Nat) : async Types.TickMatchGroupResult {
        if (caller != Principal.fromActor(StadiumActor)) {
            return #err(#notAuthorized);
        };
        let ?leagueId = leagueIdOrNull else Debug.trap("League not set");
        let ?matchGroup = getMatchGroupOrNull(id) else return #err(#matchGroupNotFound);
        let prng = PseudoRandomX.LinearCongruentialGenerator(matchGroup.currentSeed);

        switch (tickMatches(prng, matchGroup.matches)) {
            case (#completed(completedTickResults)) {
                // Cancel tick timer before disposing of match group
                // NOTE: Should be canceled even if the onMatchGroupComplete fails, so it doesnt
                // just keep ticking. Can retrigger manually if needed after fixing the
                // issue

                let completedMatches = completedTickResults
                |> Iter.fromArray(_)
                |> Iter.map(
                    _,
                    func(tickResult : CompletedMatchResult) : Season.CompletedMatch = tickResult.match,
                )
                |> Iter.toArray(_);

                let playerStats = completedTickResults
                |> Iter.fromArray(_)
                |> Iter.map(
                    _,
                    func(tickResult : CompletedMatchResult) : Iter.Iter<Player.PlayerMatchStatsWithId> = Iter.fromArray(tickResult.matchStats),
                )
                |> IterTools.flatten<Player.PlayerMatchStatsWithId>(_)
                |> Iter.toArray(_);

                Timer.cancelTimer(matchGroup.tickTimerId);
                let leagueActor = actor (Principal.toText(leagueId)) : LeagueTypes.LeagueActor;
                let onCompleteRequest : LeagueTypes.OnMatchGroupCompleteRequest = {
                    id = id;
                    matches = completedMatches;
                    playerStats = playerStats;
                };
                let result = try {
                    await leagueActor.onMatchGroupComplete(onCompleteRequest);
                } catch (err) {
                    #err(#onCompleteCallbackError(Error.message(err)));
                };

                let errorMessage = switch (result) {
                    case (#ok) {
                        // Remove match group if successfully passed info to the league
                        let matchGroupKey = buildMatchGroupKey(id);
                        let (newMatchGroups, _) = Trie.remove(matchGroups, matchGroupKey, Nat.equal);
                        matchGroups := newMatchGroups;
                        return #ok(#completed);
                    };
                    case (#err(#notAuthorized)) "Failed: Not authorized to complete match group";
                    case (#err(#matchGroupNotFound)) "Failed: Match group not found - " # Nat.toText(id);
                    case (#err(#seedGenerationError(err))) "Failed: Seed generation error - " # err;
                    case (#err(#seasonNotOpen)) "Failed: Season not open";
                    case (#err(#onCompleteCallbackError(err))) "Failed: On complete callback error - " # err;
                    case (#err(#matchGroupNotInProgress)) "Failed: Match group not in progress";
                };
                Debug.print("On Match Group Complete Result - " # errorMessage);
                // Stuck in a bad state. Can retry by a manual tick call
                #ok(#completed);
            };
            case (#inProgress(newMatches)) {
                addOrUpdateMatchGroup({
                    matchGroup with
                    id = id;
                    matches = newMatches;
                    currentSeed = prng.getCurrentSeed();
                });

                #ok(#inProgress);
            };
        };
    };

    public shared func resetTickTimer(matchGroupId : Nat) : async Types.ResetTickTimerResult {
        resetTickTimerInternal<system>(matchGroupId);
        #ok;
    };

    private func resetTickTimerInternal<system>(matchGroupId : Nat) : () {
        let ?matchGroup = getMatchGroupOrNull(matchGroupId) else return;
        Timer.cancelTimer(matchGroup.tickTimerId);
        let newTickTimerId = startTickTimer<system>(matchGroupId);
        addOrUpdateMatchGroup({
            matchGroup with
            id = matchGroupId;
            tickTimerId = newTickTimerId;
        });
    };

    private func startTickTimer<system>(matchGroupId : Nat) : Timer.TimerId {
        Timer.setTimer<system>(
            #seconds(5),
            func() : async () {
                switch (await tickMatchGroupCallback(matchGroupId)) {
                    case (#err(err)) {
                        Debug.print("Failed to tick match group: " # Nat.toText(matchGroupId) # ", Error: " # err # ". Canceling tick timer. Reset with `resetTickTimer` method");
                    };
                    case (#ok(isComplete)) {
                        if (not isComplete) {
                            resetTickTimerInternal<system>(matchGroupId);
                        } else {
                            Debug.print("Match group complete: " # Nat.toText(matchGroupId));
                        };
                    };
                };
            },
        );
    };

    private func addOrUpdateMatchGroup(newMatchGroup : Types.MatchGroupWithId) : () {
        let matchGroupKey = buildMatchGroupKey(newMatchGroup.id);
        let (newMatchGroups, _) = Trie.replace(matchGroups, matchGroupKey, Nat.equal, ?newMatchGroup);
        matchGroups := newMatchGroups;
    };

    private func tickMatchGroupCallback(matchGroupId : Nat) : async Result.Result<Bool, Text> {
        try {
            switch (await tickMatchGroup(matchGroupId)) {
                case (#ok(#inProgress(_))) #ok(false);
                case (#err(#matchGroupNotFound)) #err("Match Group not found");
                case (#err(#notAuthorized)) #err("Not authorized to tick match group");
                case (#err(#onStartCallbackError(err))) #err("On start callback error: " # debug_show (err));
                case (#ok(#completed(_))) #ok(true);
            };
        } catch (err) {
            #err("Failed to tick match group: " # Error.message(err));
        };
    };

    private func tickMatches(prng : Prng, tickResults : [Types.TickResult]) : {
        #completed : [CompletedMatchResult];
        #inProgress : [Types.TickResult];
    } {
        let completedMatches = Buffer.Buffer<(Types.Match, Types.MatchStatusCompleted)>(tickResults.size());
        let updatedTickResults = Buffer.Buffer<Types.TickResult>(tickResults.size());
        for (tickResult in Iter.fromArray(tickResults)) {
            let updatedTickResult = switch (tickResult.status) {
                // Don't tick if completed
                case (#completed(c)) {
                    completedMatches.add((tickResult.match, c));
                    tickResult;
                };
                // Tick if still in progress
                case (#inProgress) MatchSimulator.tick(tickResult.match, prng);
            };
            updatedTickResults.add(updatedTickResult);
        };
        if (updatedTickResults.size() == completedMatches.size()) {
            // If all matches are complete, then complete the group
            let completedCompiledMatches = completedMatches.vals()
            |> Iter.map(
                _,
                func((match, status) : (Types.Match, Types.MatchStatusCompleted)) : CompletedMatchResult {
                    compileCompletedMatch(match, status);
                },
            )
            |> Iter.toArray(_);
            #completed(completedCompiledMatches);
        } else {
            #inProgress(Buffer.toArray(updatedTickResults));
        };
    };

    private func compileCompletedMatch(match : Types.Match, status : Types.MatchStatusCompleted) : CompletedMatchResult {
        let winner : Team.TeamIdOrTie = switch (status.reason) {
            case (#noMoreRounds) {
                if (match.team1.score > match.team2.score) {
                    #team1;
                } else if (match.team1.score == match.team2.score) {
                    #tie;
                } else {
                    #team2;
                };
            };
            case (#error(e)) #tie;
        };

        let playerStats = buildPlayerStats(match);

        {
            match : Season.CompletedMatch = {
                team1 = match.team1;
                team2 = match.team2;
                aura = match.aura;
                log = match.log;
                winner = winner;
                playerStats = playerStats;
            };
            matchStats = playerStats;
        };
    };

    private func buildPlayerStats(match : Types.Match) : [Player.PlayerMatchStatsWithId] {
        match.players.vals()
        |> Iter.map(
            _,
            func(player : Types.PlayerStateWithId) : Player.PlayerMatchStatsWithId {
                {
                    playerId = player.id;
                    battingStats = {
                        atBats = player.matchStats.battingStats.atBats;
                        hits = player.matchStats.battingStats.hits;
                        runs = player.matchStats.battingStats.runs;
                        strikeouts = player.matchStats.battingStats.strikeouts;
                        homeRuns = player.matchStats.battingStats.homeRuns;
                    };
                    catchingStats = {
                        successfulCatches = player.matchStats.catchingStats.successfulCatches;
                        missedCatches = player.matchStats.catchingStats.missedCatches;
                        throws = player.matchStats.catchingStats.throws;
                        throwOuts = player.matchStats.catchingStats.throwOuts;
                    };
                    pitchingStats = {
                        pitches = player.matchStats.pitchingStats.pitches;
                        strikes = player.matchStats.pitchingStats.strikes;
                        hits = player.matchStats.pitchingStats.hits;
                        runs = player.matchStats.pitchingStats.runs;
                        strikeouts = player.matchStats.pitchingStats.strikeouts;
                        homeRuns = player.matchStats.pitchingStats.homeRuns;
                    };
                    injuries = player.matchStats.injuries;
                };
            },
        )
        |> Iter.toArray(_);
    };

    private func getMatchGroupOrNull(matchGroupId : Nat) : ?Types.MatchGroup {
        let matchGroupKey = buildMatchGroupKey(matchGroupId);
        Trie.get(matchGroups, matchGroupKey, Nat.equal);
    };

    private func buildMatchGroupKey(matchGroupId : Nat) : {
        key : Nat;
        hash : Nat32;
    } {
        {
            hash = Nat32.fromNat(matchGroupId); // TODO better hash? shouldnt need more than 32 bits
            key = matchGroupId;
        };
    };

    private func assertLeague(caller : Principal) {
        let ?leagueId = leagueIdOrNull else Debug.trap("League not set");
        if (caller != leagueId) {
            Debug.trap("Only the league can schedule matches");
        };
    };
};
