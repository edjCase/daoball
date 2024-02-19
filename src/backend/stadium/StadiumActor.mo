import Player "../models/Player";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import StadiumTypes "../stadium/Types";
import Nat "mo:base/Nat";
import Util "./StadiumUtil";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import TrieSet "mo:base/TrieSet";
import PlayersActor "canister:players";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import MatchSimulator "MatchSimulator";
import Random "mo:base/Random";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import RandomX "mo:random/RandomX";
import PseudoRandomX "mo:random/PseudoRandomX";
import CommonUtil "../Util";
import LeagueTypes "../league/Types";
import IterTools "mo:itertools/Iter";
import MatchAura "../models/MatchAura";
import Team "../models/Team";
import FieldPosition "../models/FieldPosition";
import Season "../models/Season";

actor class StadiumActor(leagueId : Principal) : async StadiumTypes.StadiumActor = this {
    type PlayerState = StadiumTypes.PlayerState;
    type FieldPosition = FieldPosition.FieldPosition;
    type MatchAura = MatchAura.MatchAura;
    type Prng = PseudoRandomX.PseudoRandomGenerator;
    type TeamWithId = Team.TeamWithId;

    type MatchGroupId = Nat;

    stable var matchGroups = Trie.empty<Nat, StadiumTypes.MatchGroup>();

    system func postupgrade() {
        // Restart the timers for any match groups that were in progress
        for ((matchGroupId, matchGroup) in Trie.iter(matchGroups)) {
            resetTickTimerInternal(matchGroupId);
        };
    };

    public query func getMatchGroup(id : Nat) : async ?StadiumTypes.MatchGroupWithId {
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

    public query func getMatchGroups() : async [StadiumTypes.MatchGroupWithId] {
        matchGroups
        |> Trie.iter(_)
        |> Iter.map(
            _,
            func(m : (Nat, StadiumTypes.MatchGroup)) : StadiumTypes.MatchGroupWithId = {
                m.1 with
                id = m.0;
            },
        )
        |> Iter.toArray(_);
    };

    public shared ({ caller }) func startMatchGroup(
        request : StadiumTypes.StartMatchGroupRequest
    ) : async StadiumTypes.StartMatchGroupResult {
        assertLeague(caller);

        let prng = PseudoRandomX.fromBlob(await Random.blob());
        let tickTimerId = startTickTimer(request.id);

        let matches = Buffer.Buffer<StadiumTypes.MatchVariant>(request.matches.size());
        label f for ((matchId, match) in IterTools.enumerate(Iter.fromArray(request.matches))) {

            let team1IsOffense = prng.nextCoin();
            let initState = MatchSimulator.initState(
                match.aura,
                match.team1,
                match.team2,
                team1IsOffense,
                prng,
            );
            matches.add(#inProgress(initState));
        };
        if (matches.size() == 0) {
            return #noMatchesSpecified;
        };

        let matchGroup : StadiumTypes.MatchGroupWithId = {
            id = request.id;
            matches = Buffer.toArray(matches);
            tickTimerId = tickTimerId;
            currentSeed = prng.getCurrentSeed();
        };
        addOrUpdateMatchGroup(matchGroup);
        #ok;
    };

    public shared ({ caller }) func tickMatchGroup(matchGroupId : Nat) : async StadiumTypes.TickMatchGroupResult {
        let ?matchGroup = getMatchGroupOrNull(matchGroupId) else return #matchGroupNotFound;
        let prng = PseudoRandomX.LinearCongruentialGenerator(matchGroup.currentSeed);
        switch (tickMatches(prng, matchGroup.matches)) {
            case (#completed(completedMatches)) {
                // Cancel tick timer before disposing of match group
                // NOTE: Should be canceled even if the onMatchGroupComplete fails, so it doesnt
                // just keep ticking. Can retrigger manually if needed after fixing the
                // issue
                Timer.cancelTimer(matchGroup.tickTimerId);
                let leagueActor = actor (Principal.toText(leagueId)) : LeagueTypes.LeagueActor;
                let onCompleteRequest : LeagueTypes.OnMatchGroupCompleteRequest = {
                    id = matchGroupId;
                    matches = completedMatches;
                };
                let result = try {
                    await leagueActor.onMatchGroupComplete(onCompleteRequest);
                } catch (err) {
                    #onCompleteCallbackError(Error.message(err));
                };

                let errorMessage = switch (result) {
                    case (#ok) {
                        // Remove match group if successfully passed info to the league
                        let matchGroupKey = buildMatchGroupKey(matchGroupId);
                        let (newMatchGroups, _) = Trie.remove(matchGroups, matchGroupKey, Nat.equal);
                        matchGroups := newMatchGroups;
                        return #completed;
                    };
                    case (#notAuthorized) "Failed: Not authorized to complete match group";
                    case (#matchGroupNotFound) "Failed: Match group not found - " # Nat.toText(matchGroupId);
                    case (#seedGenerationError(err)) "Failed: Seed generation error - " # err;
                    case (#seasonNotOpen) "Failed: Season not open";
                    case (#onCompleteCallbackError(err)) "Failed: On complete callback error - " # err;
                    case (#matchGroupNotInProgress) "Failed: Match group not in progress";
                };
                Debug.print("On Match Group Complete Result - " # errorMessage);
                // Stuck in a bad state. Can retry by a manual tick call
                #completed;
            };
            case (#inProgress(newMatches)) {
                addOrUpdateMatchGroup({
                    matchGroup with
                    id = matchGroupId;
                    matches = newMatches;
                    currentSeed = prng.getCurrentSeed();
                });

                #inProgress;
            };
        };
    };

    public shared ({ caller }) func resetTickTimer(matchGroupId : Nat) : async StadiumTypes.ResetTickTimerResult {
        resetTickTimerInternal(matchGroupId);
        #ok;
    };

    private func resetTickTimerInternal(matchGroupId : Nat) : () {
        let ?matchGroup = getMatchGroupOrNull(matchGroupId) else return;
        Timer.cancelTimer(matchGroup.tickTimerId);
        let newTickTimerId = startTickTimer(matchGroupId);
        addOrUpdateMatchGroup({
            matchGroup with
            id = matchGroupId;
            tickTimerId = newTickTimerId;
        });
    };

    private func startTickTimer(matchGroupId : Nat) : Timer.TimerId {
        Timer.recurringTimer(
            #seconds(5),
            func() : async () {
                await tickMatchGroupCallback(matchGroupId);
            },
        );
    };

    private func addOrUpdateMatchGroup(newMatchGroup : StadiumTypes.MatchGroupWithId) : () {
        let matchGroupKey = buildMatchGroupKey(newMatchGroup.id);
        let (newMatchGroups, _) = Trie.replace(matchGroups, matchGroupKey, Nat.equal, ?newMatchGroup);
        matchGroups := newMatchGroups;
    };

    private func tickMatchGroupCallback(matchGroupId : Nat) : async () {
        let message = try {
            switch (await tickMatchGroup(matchGroupId)) {
                case (#matchGroupNotFound) "Match Group not found";
                case (#onStartCallbackError(err)) "On start callback error: " # debug_show (err);
                case (#completed(_)) "Match Group completed";
                case (#inProgress(_)) return (); // Dont log normal tick
            };
        } catch (err) {
            "Failed to tick match group: " # Error.message(err);
        };
        Debug.print("Tick Match Group Callback Result - " # message);
    };

    private func tickMatches(prng : Prng, matches : [StadiumTypes.MatchVariant]) : {
        #completed : [Season.CompletedMatch];
        #inProgress : [StadiumTypes.MatchVariant];
    } {
        let completedMatches = Buffer.Buffer<Season.CompletedMatch>(matches.size());
        let allMatches = Buffer.Buffer<StadiumTypes.MatchVariant>(matches.size());
        for (match in Iter.fromArray(matches)) {
            let updatedMatch : StadiumTypes.MatchVariant = switch (match) {
                case (#completed(completedMatch)) {
                    completedMatches.add(completedMatch);
                    #completed(completedMatch);
                };
                case (#inProgress(inProgressState)) {
                    let updatedMatch = switch (MatchSimulator.tick(inProgressState, prng)) {
                        case (#completed(completedMatch)) {
                            completedMatches.add(completedMatch);
                            #completed(completedMatch);
                        };
                        case (#inProgress(updatedMatch)) #inProgress(updatedMatch);
                    };
                };
            };
            allMatches.add(updatedMatch);
        };
        if (allMatches.size() == completedMatches.size()) {
            // If all matches are complete, then complete the group
            #completed(Buffer.toArray(completedMatches));
        } else {
            #inProgress(Buffer.toArray(allMatches));
        };
    };

    private func getMatchGroupOrNull(matchGroupId : Nat) : ?StadiumTypes.MatchGroup {
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
        if (caller != leagueId) {
            Debug.trap("Only the league can schedule matches");
        };
    };
};
