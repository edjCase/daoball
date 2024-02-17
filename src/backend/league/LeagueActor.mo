import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Prelude "mo:base/Prelude";
import Cycles "mo:base/ExperimentalCycles";
import IterTools "mo:itertools/Iter";
import Hash "mo:base/Hash";
import Player "../models/Player";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import StadiumTypes "../stadium/Types";
import Time "mo:base/Time";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import Order "mo:base/Order";
import Timer "mo:base/Timer";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import PseudoRandomX "mo:random/PseudoRandomX";
import Types "../league/Types";
import Util "../Util";
import ScheduleBuilder "ScheduleBuilder";
import PlayersActor "canister:players";
import UsersActor "canister:users";
import Team "../models/Team";
import TeamTypes "../team/Types";
import Season "../models/Season";
import MatchAura "../models/MatchAura";
import TeamFactoryActor "canister:teamFactory";
import StadiumFactoryActor "canister:stadiumFactory";
import PlayerTypes "../players/Types";
import FieldPosition "../models/FieldPosition";
import UserTypes "../users/Types";
import Scenario "../models/Scenario";
import ScenarioUtil "ScenarioUtil";

actor LeagueActor {
    type TeamWithId = Team.TeamWithId;
    type Prng = PseudoRandomX.PseudoRandomGenerator;

    stable var admins : TrieSet.Set<Principal> = TrieSet.empty();
    stable var teams : Trie.Trie<Principal, Team.Team> = Trie.empty();
    stable var scenarioTemplates : Trie.Trie<Text, Scenario.Template> = Trie.empty();
    stable var seasonStatus : Season.SeasonStatus = #notStarted;
    stable var predictionsOrNull : ?[Trie.Trie<Principal, Team.TeamId>] = null;
    stable var historicalSeasons : [Season.CompletedSeason] = [];
    stable var stadiumIdOrNull : ?Principal = null;
    stable var teamFactoryInitialized = false;
    stable var stadiumFactoryInitialized = false;

    public query func getTeams() : async [TeamWithId] {
        getTeamsArray();
    };

    public query func getSeasonStatus() : async Season.SeasonStatus {
        seasonStatus;
    };

    public query func getScenarioTemplates() : async [Scenario.Template] {
        getScenarioTemplateArray();
    };

    public shared ({ caller }) func addScenarioTemplate(request : Types.AddScenarioTemplateRequest) : async Types.AddScenarioTemplateResult {
        if (not isAdminId(caller)) {
            return #notAuthorized;
        };
        let key = {
            key = request.id;
            hash = Text.hash(request.id);
        };
        let (newScenarioTemplates, oldScenarioTemplate) = Trie.put(scenarioTemplates, key, Text.equal, request);
        if (oldScenarioTemplate != null) {
            return #idTaken;
        };
        scenarioTemplates := newScenarioTemplates;
        #ok;
    };

    public shared query ({ caller }) func getAdmins() : async [Principal] {
        TrieSet.toArray(admins);
    };

    public shared ({ caller }) func setUserIsAdmin(id : Principal, isAdmin : Bool) : async Types.SetUserIsAdminResult {
        if (Principal.isAnonymous(id)) {
            Debug.trap("Anonymous user is not a valid user");
        };

        // Check to make sure only admins can update other users
        // BUT if there are no admins, skip the check
        if (Trie.size(admins) > 0) {
            let callerIsAdmin = isAdminId(caller);
            if (not callerIsAdmin) {
                return #notAuthorized;
            };
        };
        let newAdmins = if (isAdmin) {
            TrieSet.put(admins, id, Principal.hash(id), Principal.equal);
        } else {
            TrieSet.delete(admins, id, Principal.hash(id), Principal.equal);
        };
        admins := newAdmins;
        #ok;
    };

    public shared ({ caller }) func startSeason(request : Types.StartSeasonRequest) : async Types.StartSeasonResult {
        if (not isAdminId(caller)) {
            return #notAuthorized;
        };
        switch (seasonStatus) {
            case (#notStarted) {};
            case (#starting) return #alreadyStarted;
            case (#inProgress(_)) return #alreadyStarted;
            case (#completed(completedSeason)) {
                archiveSeason(completedSeason);
            };
        };
        seasonStatus := #starting;

        let seedBlob = try {
            await Random.blob();
        } catch (err) {
            seasonStatus := #notStarted;
            return #seedGenerationError(Error.message(err));
        };
        let prng = PseudoRandomX.fromSeed(Blob.hash(seedBlob));

        let teamIdsBuffer = teams
        |> Trie.iter(_)
        |> Iter.map(_, func(k : (Principal, Team.Team)) : Principal = k.0)
        |> Buffer.fromIter<Principal>(_);

        prng.shuffleBuffer(teamIdsBuffer); // Randomize the team order

        let timeBetweenMatchGroups = #minutes(10);
        // let timeBetweenMatchGroups = #days(1); // TODO revert
        let buildResult = ScheduleBuilder.build(
            request.startTime,
            Buffer.toArray(teamIdsBuffer),
            timeBetweenMatchGroups,
        );

        let schedule : ScheduleBuilder.SeasonSchedule = switch (buildResult) {
            case (#ok(schedule)) schedule;
            case (#noTeams) {
                seasonStatus := #notStarted;
                return #noTeams;
            };
            case (#oddNumberOfTeams) {
                seasonStatus := #notStarted;
                return #oddNumberOfTeams;
            };
        };

        // Save full schedule, then try to start the first match groups
        let regularMatchGroups = schedule.regularSeason
        |> Iter.fromArray(_)
        |> Iter.map(
            _,
            func(mg : ScheduleBuilder.RegularMatchGroup) : Season.InProgressSeasonMatchGroupVariant = #notScheduled({
                time = mg.time;
                matches = mg.matches
                |> Iter.fromArray(_)
                |> Iter.map(
                    _,
                    func(m : ScheduleBuilder.RegularMatch) : Season.NotScheduledMatch = {
                        team1 = #predetermined(getTeamInfo(m.team1Id));
                        team2 = #predetermined(getTeamInfo(m.team2Id));
                    },
                )
                |> Iter.toArray(_);
            }),
        );

        let playoffMatchGroups = schedule.playoffs
        |> Iter.fromArray(_)
        |> Iter.map(
            _,
            func(mg : ScheduleBuilder.PlayoffMatchGroup) : Season.InProgressSeasonMatchGroupVariant = #notScheduled({
                time = mg.time;
                matches = mg.matches
                |> Iter.fromArray(_)
                |> Iter.map(
                    _,
                    func(m : ScheduleBuilder.PlayoffMatch) : Season.NotScheduledMatch = {
                        team1 = m.team1;
                        team2 = m.team2;
                    },
                )
                |> Iter.toArray(_);
            }),
        );

        let inProgressMatchGroups = regularMatchGroups
        |> IterTools.chain(_, playoffMatchGroups)
        |> Iter.toArray(_);

        let inProgressSeason = {
            matchGroups = inProgressMatchGroups;
            teamStandings = null; // No standings yet
        };

        seasonStatus := #inProgress(inProgressSeason);
        // Get first match group to open
        let #notScheduled(firstMatchGroup) = inProgressMatchGroups[0] else Prelude.unreachable();

        let allTeams = getTeamsArray();
        let allPlayers = await PlayersActor.getAllPlayers();

        let allScenarios = getScenarioTemplateArray();
        scheduleMatchGroup(
            0,
            firstMatchGroup,
            inProgressSeason,
            allTeams,
            allPlayers,
            allScenarios,
            prng,
        );

        #ok;
    };

    public shared ({ caller }) func createTeam(request : Types.CreateTeamRequest) : async Types.CreateTeamResult {
        if (not isAdminId(caller)) {
            return #notAuthorized;
        };
        let nameAlreadyTaken = Trie.some(
            teams,
            func(k : Principal, v : Team.Team) : Bool = v.name == request.name,
        );
        if (nameAlreadyTaken) {
            return #nameTaken;
        };
        if (not teamFactoryInitialized) {
            let #ok = await TeamFactoryActor.setLeague(Principal.fromActor(LeagueActor)) else Debug.trap("Failed to set league on team factory");
            teamFactoryInitialized := true;
        };
        let createTeamResult = try {
            await TeamFactoryActor.createTeamActor(request);
        } catch (err) {
            return #teamFactoryCallError(Error.message(err));
        };
        let teamInfo = switch (createTeamResult) {
            case (#ok(teamInfo)) teamInfo;
        };
        let team : Team.Team = {
            name = request.name;
            logoUrl = request.logoUrl;
            motto = request.motto;
            description = request.description;
            entropy = 0; // TODO
            color = request.color;
        };
        let teamKey = buildPrincipalKey(teamInfo.id);
        let (newTeams, _) = Trie.put(teams, teamKey, Principal.equal, team);
        teams := newTeams;

        let populateResult = try {
            await PlayersActor.populateTeamRoster(teamInfo.id);
        } catch (err) {
            return #populateTeamRosterCallError(Error.message(err));
        };
        switch (populateResult) {
            case (#ok(_)) {};
            case (#notAuthorized) {
                Debug.print("Error populating team roster: League is not authorized to populate team roster for team: " # Principal.toText(teamInfo.id));
            };
            case (#noMorePlayers) {
                Debug.print("Error populating team roster: No more players available");
            };
        };
        return #ok(teamInfo.id);
    };

    public shared ({ caller }) func predictMatchOutcome(request : Types.PredictMatchOutcomeRequest) : async Types.PredictMatchOutcomeResult {
        if (Principal.isAnonymous(caller)) {
            return #identityRequired;
        };

        let ?predictions = predictionsOrNull else return #predictionsClosed;
        let predictionsBuffer = Buffer.fromArray<Trie.Trie<Principal, Team.TeamId>>(predictions);

        let ?matchPredictions = predictionsBuffer.getOpt(Nat32.toNat(request.matchId)) else return #matchNotFound;

        let userKey = buildPrincipalKey(caller);
        let newMatchPredictions : Trie.Trie<Principal, Team.TeamId> = switch (request.winner) {
            case (null) {
                let (newMatchPredictions, _) = Trie.remove(matchPredictions, userKey, Principal.equal);
                newMatchPredictions;
            };
            case (?winningTeamId) {
                let (newMatchPredictions, _) = Trie.put(matchPredictions, userKey, Principal.equal, winningTeamId);
                newMatchPredictions;
            };
        };
        predictionsBuffer.put(Nat32.toNat(request.matchId), newMatchPredictions);

        predictionsOrNull := ?Buffer.toArray(predictionsBuffer);
        #ok;
    };

    public shared query ({ caller }) func getUpcomingMatchPredictions() : async Types.UpcomingMatchPredictionsResult {

        let ?predictions = predictionsOrNull else return #noUpcomingMatches;
        let predictionSummaryBuffer = Buffer.Buffer<Types.UpcomingMatchPrediction>(predictions.size());

        for (matchPredictions in Iter.fromArray(predictions)) {
            let matchPredictionSummary = {
                var team1 = 0;
                var team2 = 0;
                var yourVote : ?Team.TeamId = null;
            };
            for ((userId, userPrediction) in Trie.iter(matchPredictions)) {
                switch (userPrediction) {
                    case (#team1) matchPredictionSummary.team1 += 1;
                    case (#team2) matchPredictionSummary.team2 += 1;
                };
                if (userId == caller) {
                    matchPredictionSummary.yourVote := ?userPrediction;
                };
            };
            predictionSummaryBuffer.add({
                team1 = matchPredictionSummary.team1;
                team2 = matchPredictionSummary.team2;
                yourVote = matchPredictionSummary.yourVote;
            });
        };

        #ok(Buffer.toArray(predictionSummaryBuffer));
    };

    public shared ({ caller }) func updateLeagueCanisters() : async Types.UpdateLeagueCanistersResult {
        if (not isAdminId(caller)) {
            return #notAuthorized;
        };
        await TeamFactoryActor.updateCanisters();
        await StadiumFactoryActor.updateCanisters();
        #ok;
    };

    public shared ({ caller }) func processEffectOutcomes(effectOutcomes : [Scenario.EffectOutcome]) : async Types.ProcessEffectOutcomesResult {
        if (not isAdminId(caller)) {
            return #notAuthorized;
        };
        let #inProgress(season) = seasonStatus else return #seasonNotInProgress;
        var updatedSeason = season;

        let playerOutcomes = Buffer.Buffer<Scenario.PlayerEffectOutcome>(effectOutcomes.size());
        for (effectOutcome in Iter.fromArray(effectOutcomes)) {
            switch (effectOutcome) {
                case (#trait(traitEffect)) playerOutcomes.add(#trait(traitEffect));
                case (#removeTrait(removeTraitEffect)) playerOutcomes.add(#removeTrait(removeTraitEffect));
                case (#injury(injuryEffect)) playerOutcomes.add(#injury(injuryEffect));
                case (#entropy(entropyEffect)) {
                    updateTeamEntropy(entropyEffect.teamId, entropyEffect.delta);
                };
            };
        };
        // TODO handle failure
        if (playerOutcomes.size() > 0) {
            let result = try {
                await PlayersActor.applyEffects(Buffer.toArray(playerOutcomes));
            } catch (err) {
                return Debug.trap("Failed to apply traits: " # Error.message(err));
            };
            switch (result) {
                case (#ok) ();
            };
        };
        #ok;
    };

    public shared ({ caller }) func startMatchGroup(matchGroupId : Nat) : async Types.StartMatchGroupResult {
        if (not isAdminId(caller)) {
            return #notAuthorized;
        };
        let #inProgress(season) = seasonStatus else return #matchGroupNotFound;
        let stadiumId = switch (await* getOrCreateStadium()) {
            case (#ok(id)) id;
            case (#stadiumCreationError(error)) return Debug.trap("Failed to create stadium: " # error);
        };

        // Get current match group
        let ?matchGroupVariant = Util.arrayGetSafe(
            season.matchGroups,
            matchGroupId,
        ) else return #matchGroupNotFound;

        let scheduledMatchGroup : Season.ScheduledMatchGroup = switch (matchGroupVariant) {
            case (#notScheduled(_)) return #notScheduledYet;
            case (#inProgress(_)) return #alreadyStarted;
            case (#completed(_)) return #alreadyStarted;
            case (#scheduled(d)) d;
        };

        let allPlayers = await PlayersActor.getAllPlayers();
        let matchStartRequestBuffer = Buffer.Buffer<StadiumTypes.StartMatchRequest>(scheduledMatchGroup.matches.size());

        let prng = PseudoRandomX.fromBlob(await Random.blob());
        let effectOutcomes = Buffer.Buffer<Scenario.EffectOutcome>(scheduledMatchGroup.matches.size() * 2);
        for (match in Iter.fromArray(scheduledMatchGroup.matches)) {
            let team1Data = await* buildTeamInitData(matchGroupId, match.team1, allPlayers, prng);
            let team2Data = await* buildTeamInitData(matchGroupId, match.team2, allPlayers, prng);
            matchStartRequestBuffer.add({
                team1 = team1Data;
                team2 = team2Data;
                aura = match.aura.aura;
            });
            effectOutcomes.append(Buffer.fromArray(team1Data.scenario.effectOutcomes));
            effectOutcomes.append(Buffer.fromArray(team2Data.scenario.effectOutcomes));
        };

        // TODO handle failure
        try {
            let result = await processEffectOutcomes(Buffer.toArray(effectOutcomes));
            switch (result) {
                case (#ok) ();
                case (#notAuthorized) Debug.trap("League is not authorized to process effect outcomes");
                case (#seasonNotInProgress) Debug.trap("Season is not in progress");
            };
        } catch (err) {
            Debug.print("Failed to process effect outcomes: " # Error.message(err));
        };

        let startMatchGroupRequest : StadiumTypes.StartMatchGroupRequest = {
            id = matchGroupId;
            matches = Buffer.toArray(matchStartRequestBuffer);
        };
        let stadiumActor = actor (Principal.toText(stadiumId)) : StadiumTypes.StadiumActor;
        let startResult = await stadiumActor.startMatchGroup(startMatchGroupRequest);

        switch (startResult) {
            case (#noMatchesSpecified) Debug.trap("No matches specified for match group " # Nat.toText(matchGroupId));
            case (#ok) {
                // TODO this should better handled in case of failure to start the match
                let inProgressMatches = scheduledMatchGroup.matches
                |> Iter.fromArray(_)
                |> IterTools.zip(_, Iter.fromArray(startMatchGroupRequest.matches))
                |> IterTools.mapEntries(
                    _,
                    func(matchId : Nat, match : (Season.ScheduledMatch, StadiumTypes.StartMatchRequest)) : Season.InProgressMatch {
                        let mapTeam = func(
                            team : Season.TeamInfo,
                            teamData : StadiumTypes.StartMatchTeam,
                        ) : Season.InProgressTeam {
                            {
                                id = team.id;
                                name = team.name;
                                logoUrl = team.logoUrl;
                                scenario = teamData.scenario;
                                positions = {
                                    firstBase = teamData.positions.firstBase.id;
                                    secondBase = teamData.positions.secondBase.id;
                                    thirdBase = teamData.positions.thirdBase.id;
                                    shortStop = teamData.positions.shortStop.id;
                                    leftField = teamData.positions.leftField.id;
                                    centerField = teamData.positions.centerField.id;
                                    rightField = teamData.positions.rightField.id;
                                    pitcher = teamData.positions.pitcher.id;
                                };
                            };
                        };
                        let matchPredictions = switch (predictionsOrNull) {
                            case (null) [];
                            case (?predictions) predictions[matchId]
                            |> Trie.iter(_)
                            |> Iter.toArray(_);
                        };
                        {
                            team1 = mapTeam(match.0.team1, match.1.team1);
                            team2 = mapTeam(match.0.team2, match.1.team2);
                            aura = match.0.aura.aura;
                            predictions = matchPredictions;
                        };
                    },
                )
                |> Iter.toArray(_);
                predictionsOrNull := null; // Close predictions

                let ?newMatchGroups = Util.arrayUpdateElementSafe<Season.InProgressSeasonMatchGroupVariant>(
                    season.matchGroups,
                    matchGroupId,
                    #inProgress({
                        time = scheduledMatchGroup.time;
                        stadiumId = stadiumId;
                        matches = inProgressMatches;
                    }),
                ) else return #matchGroupNotFound;
                seasonStatus := #inProgress({
                    season with
                    matchGroups = newMatchGroups;
                });

                #ok;
            };
        };

    };

    public shared ({ caller }) func onMatchGroupComplete(
        request : Types.OnMatchGroupCompleteRequest
    ) : async Types.OnMatchGroupCompleteResult {
        if (not isStadium(caller)) {
            return #notAuthorized;
        };
        Debug.print("On Match group complete called for: " # Nat.toText(request.id));
        let #inProgress(season) = seasonStatus else return #seasonNotOpen;
        let ?stadiumId = stadiumIdOrNull else return #notAuthorized;
        if (caller != stadiumId) {
            return #notAuthorized;
        };

        let seed = try {
            await Random.blob();
        } catch (err) {
            return #seedGenerationError(Error.message(err));
        };
        let prng = PseudoRandomX.fromSeed(Blob.hash(seed));

        // Get current match group
        let ?matchGroup = Util.arrayGetSafe<Season.InProgressSeasonMatchGroupVariant>(
            season.matchGroups,
            request.id,
        ) else return #matchGroupNotFound;
        let inProgressMatchGroup = switch (matchGroup) {
            case (#inProgress(matchGroupState)) matchGroupState;
            case (_) return #matchGroupNotInProgress;
        };

        let completedMatches : [Season.CompletedMatch] = IterTools.zip(
            Iter.fromArray(inProgressMatchGroup.matches),
            Iter.fromArray(request.matches),
        )
        |> Iter.map(
            _,
            func((inProgressMatch : Season.InProgressMatch, completedMatch : Season.CompletedMatchWithoutPredictions)) : Season.CompletedMatch {
                {
                    completedMatch with
                    predictions = inProgressMatch.predictions;
                };
            },
        )
        |> Iter.toArray(_);

        // Update status to completed
        let updatedMatchGroup : Season.CompletedMatchGroup = {
            time = inProgressMatchGroup.time;
            matches = completedMatches;
        };

        let ?newMatchGroups = Util.arrayUpdateElementSafe<Season.InProgressSeasonMatchGroupVariant>(
            season.matchGroups,
            request.id,
            #completed(updatedMatchGroup),
        ) else return #matchGroupNotFound;

        let completedMatchGroups = Buffer.Buffer<Season.CompletedMatchGroup>(season.matchGroups.size());
        label f for (matchGroup in Iter.fromArray(newMatchGroups)) {
            switch (matchGroup) {
                case (#completed(completedMatchGroup)) completedMatchGroups.add(completedMatchGroup);
                case (_) break f; // Break on first incomplete match
            };
        };

        let updatedTeamStandings : [Season.TeamStandingInfo] = calculateTeamStandings(Buffer.toArray(completedMatchGroups));

        await* awardUserPoints(completedMatches);

        let updatedSeason = {
            season with
            teamStandings = ?updatedTeamStandings;
            matchGroups = newMatchGroups;
        };
        seasonStatus := #inProgress(updatedSeason);

        // Get next match group to schedule
        let nextMatchGroupId = request.id + 1;
        let ?nextMatchGroup = Util.arrayGetSafe<Season.InProgressSeasonMatchGroupVariant>(
            updatedSeason.matchGroups,
            nextMatchGroupId,
        ) else {
            // Season is over because cant find more match groups
            try {
                ignore await closeSeason(); // TODO how to not await this?
            } catch (err) {
                Debug.print("Failed to close season: " # Error.message(err));
            };
            return #ok;
        };
        switch (nextMatchGroup) {
            case (#notScheduled(matchGroup)) {
                // Schedule next match group
                let allTeams = getTeamsArray();
                // TODO how to reschedule if it fails?
                let allPlayers = await PlayersActor.getAllPlayers();
                let allScenarios = getScenarioTemplateArray();
                scheduleMatchGroup(
                    nextMatchGroupId,
                    matchGroup,
                    updatedSeason,
                    allTeams,
                    allPlayers,
                    allScenarios,
                    prng,
                );
            };
            case (_) {
                // TODO
                // Anything else is a bad state
                // Print out error, but don't fail the call
                Debug.print("Unable to schedule next match group " # Nat.toText(nextMatchGroupId) # " because it is not in the correct state: " # debug_show (nextMatchGroup));
            };
        };
        #ok;
    };

    public shared ({ caller }) func closeSeason() : async Types.CloseSeasonResult {
        if (not isAdminId(caller)) {
            return #notAuthorized;
        };
        if (seasonStatus == #starting) {
            // TODO how to handle this?
            seasonStatus := #notStarted;
            return #ok;
        };
        let #inProgress(inProgressSeason) = seasonStatus else return #seasonNotOpen;
        let completedMatchGroups = switch (buildCompletedMatchGroups(inProgressSeason)) {
            case (#ok(completedMatchGroups)) completedMatchGroups;
            case (#matchGroupsNotComplete) {
                // TODO put in bad state vs delete
                seasonStatus := #notStarted;
                return #ok;
            };
        };
        let teamStandings = calculateTeamStandings(completedMatchGroups);
        let completedTeams = Trie.toArray(
            teams,
            func(k : Principal, v : Team.Team) : Season.CompletedSeasonTeam {
                let ?standingIndex = teamStandings
                |> Iter.fromArray(_)
                |> IterTools.findIndex(_, func(s : Season.TeamStandingInfo) : Bool = s.id == k) else Debug.trap("Team not found in standings: " # Principal.toText(k));
                let standingInfo = teamStandings[standingIndex];

                {
                    id = k;
                    name = v.name;
                    logoUrl = v.logoUrl;
                    wins = standingInfo.wins;
                    losses = standingInfo.losses;
                    totalScore = standingInfo.totalScore;
                };
            },
        );
        let finalMatch = completedMatchGroups[completedMatchGroups.size() - 1].matches[0];
        let (champion, runnerUp) = switch (finalMatch.winner) {
            case (#team1) (finalMatch.team1, finalMatch.team2);
            case (#team2) (finalMatch.team2, finalMatch.team1);
            case (#tie) {
                // Break tie by their win/loss ratio
                let getTeamStanding = func(teamId : Principal) : Nat {
                    let ?teamStanding = IterTools.findIndex(Iter.fromArray(teamStandings), func(s : Season.TeamStandingInfo) : Bool = s.id == teamId) else Debug.trap("Team not found in standings: " # Principal.toText(teamId));
                    teamStanding;
                };
                let team1Standing = getTeamStanding(finalMatch.team1.id);
                let team2Standing = getTeamStanding(finalMatch.team2.id);
                // TODO how to communicate why the team with the higher standing is the champion?
                if (team1Standing > team2Standing) {
                    (finalMatch.team1, finalMatch.team2);
                } else {
                    (finalMatch.team2, finalMatch.team1);
                };
            };
        };

        seasonStatus := #completed({
            championTeamId = champion.id;
            runnerUpTeamId = runnerUp.id;
            teams = completedTeams;
            matchGroups = completedMatchGroups;
        });
        #ok;
    };
    private func updateTeamEntropy(teamId : Principal, delta : Int) : () {
        let ?team = Trie.get(teams, buildPrincipalKey(teamId), Principal.equal) else Debug.trap("Team not found: " # Principal.toText(teamId));
        let newTeam = {
            team with
            entropy = team.entropy + delta;
        };
        let (newTeams, _) = Trie.put(teams, buildPrincipalKey(teamId), Principal.equal, newTeam);
        teams := newTeams;
    };

    private func getTeamsArray() : [TeamWithId] {
        teams
        |> Trie.toArray(
            _,
            func(k : Principal, v : Team.Team) : TeamWithId = {
                v with
                id = k;
            },
        );
    };

    private func getScenarioTemplateArray() : [Scenario.Template] {
        scenarioTemplates
        |> Trie.iter(_)
        |> Iter.map(_, func((k, v) : (Text, Scenario.Template)) : Scenario.Template = v)
        |> Iter.toArray(_);
    };

    private func awardUserPoints(completedMatches : [Season.CompletedMatch]) : async* () {
        let awards = Buffer.Buffer<UserTypes.AwardPointsRequest>(0);
        for (match in Iter.fromArray(completedMatches)) {
            for ((userId, teamId) in Iter.fromArray(match.predictions)) {
                if (teamId == match.winner) {
                    // Award points
                    awards.add({
                        userId = userId;
                        points = 10;
                    });
                };
            };
        };

        let error : ?Text = try {
            switch (await UsersActor.awardPoints(Buffer.toArray(awards))) {
                case (#ok) null;
                case (#notAuthorized) ?"League is not authorized to award user points";
            };
        } catch (err) {
            // TODO how to handle this?
            ?Error.message(err);
        };
        switch (error) {
            case (null) ();
            case (?error) Debug.print("Failed to award user points: " # error);
        };
    };

    private func getTeamInfo(teamId : Principal) : Season.TeamInfo {
        let ?team = Trie.get(teams, buildPrincipalKey(teamId), Principal.equal) else Debug.trap("Team not found: " # Principal.toText(teamId));
        {
            id = teamId;
            name = team.name;
            logoUrl = team.logoUrl;
        };
    };

    private func isAdminId(id : Principal) : Bool {
        if (id == Principal.fromActor(LeagueActor)) {
            // League is admin
            return true;
        };
        TrieSet.mem(admins, id, Principal.hash(id), Principal.equal);
    };

    private func isStadium(id : Principal) : Bool {
        let ?stadiumId = stadiumIdOrNull else return false;
        id == stadiumId;
    };

    private func archiveSeason(season : Season.CompletedSeason) : () {
        let historicalSeasonsBuffer = Buffer.fromArray<Season.CompletedSeason>(historicalSeasons);
        historicalSeasonsBuffer.add(season);
        seasonStatus := #notStarted;
        historicalSeasons := Buffer.toArray(historicalSeasonsBuffer);
    };

    private func scheduleMatchGroup(
        matchGroupId : Nat,
        matchGroup : Season.NotScheduledMatchGroup,
        inProgressSeason : Season.InProgressSeason,
        allTeams : [Team.TeamWithId],
        allPlayers : [PlayerTypes.PlayerWithId],
        allScenarios : [Scenario.Template],
        prng : Prng,
    ) : () {
        let timeDiff = matchGroup.time - Time.now();
        Debug.print("Scheduling match group " # Nat.toText(matchGroupId) # " in " # Int.toText(timeDiff) # " nanoseconds");
        let duration = if (timeDiff <= 0) {
            // Schedule immediately
            #nanoseconds(0);
        } else {
            #nanoseconds(Int.abs(timeDiff));
        };
        let timerId = Timer.setTimer(
            duration,
            func() : async () {
                let result = try {
                    await startMatchGroup(matchGroupId);
                } catch (err) {
                    Debug.print("Match group '" # Nat.toText(matchGroupId) # "' start callback failed: " # Error.message(err));
                    return;
                };
                let message = switch (result) {
                    case (#ok) "Match group started";
                    case (#matchGroupNotFound) "Match group not found";
                    case (#notAuthorized) "Not authorized";
                    case (#notScheduledYet) "Match group not scheduled yet";
                    case (#alreadyStarted) "Match group already started";
                    case (#matchErrors(errors)) "Match group errors: " # debug_show (errors);
                };
                Debug.print("Match group '" # Nat.toText(matchGroupId) # "' start callback: " # message);
            },
        );

        let compileTeamInfo = func(teamAssignment : Season.TeamAssignment) : Season.TeamInfo {
            switch (teamAssignment) {
                case (#predetermined(teamInfo)) teamInfo;
                case (#seasonStandingIndex(standingIndex)) {
                    // get team based on current season standing
                    let ?standings = inProgressSeason.teamStandings else Debug.trap("Season standings not found. Match Group Id: " # Nat.toText(matchGroupId));

                    let ?teamWithStanding = Util.arrayGetSafe<Season.TeamStandingInfo>(
                        standings,
                        standingIndex,
                    ) else Debug.trap("Standing not found. Standings: " # debug_show (standings) # " Standing index: " # Nat.toText(standingIndex));

                    getTeamInfo(teamWithStanding.id);
                };
                case (#winnerOfMatch(matchId)) {
                    let previousMatchGroupId : Nat = matchGroupId - 1;
                    // get winner of match in previous match group
                    let ?previousMatchGroup = Util.arrayGetSafe<Season.InProgressSeasonMatchGroupVariant>(
                        inProgressSeason.matchGroups,
                        previousMatchGroupId,
                    ) else Debug.trap("Previous match group not found, cannot get winner of match. Match Group Id: " # Nat.toText(previousMatchGroupId));
                    let #completed(completedMatchGroup) = previousMatchGroup else Debug.trap("Previous match group not completed, cannot get winner of match. Match Group Id: " # Nat.toText(matchGroupId));
                    let ?match = Util.arrayGetSafe<Season.CompletedMatch>(
                        completedMatchGroup.matches,
                        matchId,
                    ) else Debug.trap("Previous match not found, cannot get winner of match. Match Id: " # Nat.toText(matchId));

                    if (match.winner == #team1) {
                        match.team1;
                    } else {
                        match.team2;
                    };
                };
            };
        };
        let allTeamIds = allTeams
        |> Iter.fromArray(_)
        |> Iter.map(_, func(t : Team.TeamWithId) : Principal = t.id)
        |> Iter.toArray(_);
        let allPlayerIds = allPlayers
        |> Iter.fromArray(_)
        |> Iter.map(_, func(p : PlayerTypes.PlayerWithId) : Nat32 = p.id)
        |> Iter.toArray(_);

        let scheduledMatchGroup : Season.ScheduledMatchGroup = {
            time = matchGroup.time;
            timerId = timerId;
            matches = matchGroup.matches
            |> Iter.fromArray(_)
            |> Iter.map(
                _,
                func(m : Season.NotScheduledMatch) : Season.ScheduledMatch {
                    let team1WithoutScenario = compileTeamInfo(m.team1);
                    let team2WithoutScenario = compileTeamInfo(m.team2);
                    let instance1 = ScenarioUtil.getRandomScenario(
                        prng,
                        team1WithoutScenario.id,
                        team2WithoutScenario.id,
                        allTeamIds,
                        allPlayerIds,
                        allScenarios,
                    );
                    let instance2 = ScenarioUtil.getRandomScenario(
                        prng,
                        team2WithoutScenario.id,
                        team1WithoutScenario.id,
                        allTeamIds,
                        allPlayerIds,
                        allScenarios,
                    );

                    {
                        team1 = {
                            team1WithoutScenario with
                            scenario = instance1
                        };
                        team2 = {
                            team2WithoutScenario with
                            scenario = instance2
                        };
                        aura = getRandomMatchAura(prng);
                    };
                },
            )
            |> Iter.toArray(_);
        };

        let ?newMatchGroups = Util.arrayUpdateElementSafe<Season.InProgressSeasonMatchGroupVariant>(
            inProgressSeason.matchGroups,
            matchGroupId,
            #scheduled(scheduledMatchGroup),
        ) else return Debug.trap("Match group not found: " # Nat.toText(matchGroupId));

        seasonStatus := #inProgress({
            inProgressSeason with
            matchGroups = newMatchGroups;
        });
        let matchCount = scheduledMatchGroup.matches.size();
        predictionsOrNull := ?Array.tabulate(matchCount, func(i : Nat) : Trie.Trie<Principal, Team.TeamId> = Trie.empty()); // Open predictions

    };

    private func buildTeamInitData(
        matchGroupId : Nat,
        team : Season.ScheduledTeamInfo,
        allPlayers : [PlayerTypes.PlayerWithId],
        prng : Prng,
    ) : async* StadiumTypes.StartMatchTeam {

        let teamPlayers = allPlayers
        |> Iter.fromArray(_)
        |> IterTools.mapFilter(
            _,
            func(p : PlayerTypes.PlayerWithId) : ?Player.PlayerWithId {
                if (p.teamId != team.id) {
                    null;
                } else {
                    ?{
                        p with
                        teamId = team.id
                    };
                };
            },
        )
        |> Iter.toArray(_);

        let teamActor = actor (Principal.toText(team.id)) : TeamTypes.TeamActor;
        let options : TeamTypes.MatchGroupVoteResult = try {
            // Get match options from the team itself
            let result : TeamTypes.GetMatchGroupVoteResult = await teamActor.getMatchGroupVote(matchGroupId);
            switch (result) {
                case (#ok(o)) o;
                case (#noVotes) {
                    // If no votes, pick a random choice
                    let choice : Nat8 = 0; // TODO
                    {
                        scenarioChoice = choice;
                    };
                };
                case (#notAuthorized) return Debug.trap("League is not authorized to get match options from team: " # Principal.toText(team.id));
            };
        } catch (err : Error.Error) {
            return Debug.trap("Failed to get team '" # Principal.toText(team.id) # "': " # Error.message(err));
        };

        let getPosition = func(position : FieldPosition.FieldPosition) : Player.PlayerWithId {
            let playerOrNull = teamPlayers
            |> Iter.fromArray(_)
            |> IterTools.find(_, func(p : Player.PlayerWithId) : Bool = p.position == position);
            switch (playerOrNull) {
                case (null) Debug.trap("Team " # Principal.toText(team.id) # " is missing a player in position: " # debug_show (position)); // TODO
                case (?player) player;
            };
        };
        let effectOutcomes = ScenarioUtil.resolveScenario(prng, team.scenario, options.scenarioChoice);

        let pitcher = getPosition(#pitcher);
        let firstBase = getPosition(#firstBase);
        let secondBase = getPosition(#secondBase);
        let thirdBase = getPosition(#thirdBase);
        let shortStop = getPosition(#shortStop);
        let leftField = getPosition(#leftField);
        let centerField = getPosition(#centerField);
        let rightField = getPosition(#rightField);
        {
            id = team.id;
            name = team.name;
            logoUrl = team.logoUrl;
            scenario = {
                team.scenario with
                choice = options.scenarioChoice;
                effectOutcomes = effectOutcomes;
            };
            positions = {
                pitcher = pitcher;
                firstBase = firstBase;
                secondBase = secondBase;
                thirdBase = thirdBase;
                shortStop = shortStop;
                leftField = leftField;
                centerField = centerField;
                rightField = rightField;
            };
        };
    };

    private func getOrCreateStadium() : async* {
        #ok : Principal;
        #stadiumCreationError : Text;
    } {
        switch (stadiumIdOrNull) {
            case (null) ();
            case (?id) return #ok(id);
        };

        if (not stadiumFactoryInitialized) {
            let #ok = await StadiumFactoryActor.setLeague(Principal.fromActor(LeagueActor)) else Debug.trap("Failed to set league on stadium factory");
            stadiumFactoryInitialized := true;
        };
        let createStadiumResult = try {
            await StadiumFactoryActor.createStadiumActor();
        } catch (err) {
            return #stadiumCreationError(Error.message(err));
        };
        switch (createStadiumResult) {
            case (#ok(id)) {
                stadiumIdOrNull := ?id;
                #ok(id);
            };
            case (#stadiumCreationError(error)) return #stadiumCreationError(error);
        };
    };

    private func buildCompletedMatchGroups(
        season : Season.InProgressSeason
    ) : { #ok : [Season.CompletedMatchGroup]; #matchGroupsNotComplete } {
        let completedMatchGroups = Buffer.Buffer<Season.CompletedMatchGroup>(season.matchGroups.size());
        for (matchGroup in Iter.fromArray(season.matchGroups)) {
            let completedMatchGroup = switch (matchGroup) {
                case (#completed(completedMatchGroup)) completedMatchGroup;
                case (#notScheduled(notScheduledMatchGroup)) return #matchGroupsNotComplete;
                case (#scheduled(scheduledMatchGroup)) return #matchGroupsNotComplete;
                case (#inProgress(inProgressMatchGroup)) return #matchGroupsNotComplete;
            };
            completedMatchGroups.add(completedMatchGroup);
        };
        #ok(Buffer.toArray(completedMatchGroups));
    };

    private func calculateTeamStandings(
        matchGroups : [Season.CompletedMatchGroup]
    ) : [Season.TeamStandingInfo] {
        var teamScores = Trie.empty<Principal, Season.TeamStandingInfo>();
        let updateTeamScore = func(
            teamId : Principal,
            score : Int,
            state : { #win; #loss; #tie },
        ) : () {

            let teamKey = {
                key = teamId;
                hash = Principal.hash(teamId);
            };
            let currentScore = switch (Trie.get(teamScores, teamKey, Principal.equal)) {
                case (null) {
                    {
                        wins = 0;
                        losses = 0;
                        totalScore = 0;
                    };
                };
                case (?score) score;
            };

            let (wins, losses) = switch (state) {
                case (#win) (currentScore.wins + 1, currentScore.losses);
                case (#loss) (currentScore.wins, currentScore.losses + 1);
                case (#tie) (currentScore.wins, currentScore.losses);
            };

            // Update with +1
            let (newTeamScores, _) = Trie.put<Principal, Season.TeamStandingInfo>(
                teamScores,
                teamKey,
                Principal.equal,
                {
                    id = teamId;
                    wins = wins;
                    losses = losses;
                    totalScore = currentScore.totalScore + score;
                },
            );
            teamScores := newTeamScores;
        };

        // Populate scores
        label f1 for (matchGroup in Iter.fromArray(matchGroups)) {
            label f2 for (match in Iter.fromArray(matchGroup.matches)) {
                let (team1State, team2State) = switch (match.winner) {
                    case (#team1) (#win, #loss);
                    case (#team2) (#loss, #win);
                    case (#tie) (#tie, #tie);
                };
                updateTeamScore(match.team1.id, match.team1.score, team1State);
                updateTeamScore(match.team2.id, match.team2.score, team2State);
            };
        };
        teamScores
        |> Trie.iter(_)
        |> Iter.map(
            _,
            func((k, v) : (Principal, Season.TeamStandingInfo)) : Season.TeamStandingInfo = v,
        )
        |> IterTools.sort(
            _,
            func(a : Season.TeamStandingInfo, b : Season.TeamStandingInfo) : Order.Order {
                if (a.wins > b.wins) {
                    #greater;
                } else if (a.wins < b.wins) {
                    #less;
                } else {
                    if (a.losses < b.losses) {
                        #greater;
                    } else if (a.losses > b.losses) {
                        #less;
                    } else {
                        if (a.totalScore > b.totalScore) {
                            #greater;
                        } else if (a.totalScore < b.totalScore) {
                            #less;
                        } else {
                            #equal;
                        };
                    };
                };
            },
        )
        |> Iter.toArray(_);
    };

    private func buildPrincipalKey(id : Principal) : {
        key : Principal;
        hash : Hash.Hash;
    } {
        { key = id; hash = Principal.hash(id) };
    };

    private func arrayToIdTrie<T>(items : [T], getId : (T) -> Nat32) : Trie.Trie<Nat32, T> {
        var trie = Trie.empty<Nat32, T>();
        for (item in Iter.fromArray(items)) {
            let id = getId(item);
            let key = {
                key = id;
                hash = id;
            };
            let (newTrie, _) = Trie.put(trie, key, Nat32.equal, item);
            trie := newTrie;
        };
        trie;
    };
    private func getRandomMatchAura(prng : Prng) : MatchAura.MatchAuraWithMetaData {
        // TODO
        let auras = Buffer.fromArray<MatchAura.MatchAura>([
            #lowGravity,
            #explodingBalls,
            #fastBallsHardHits,
            #moreBlessingsAndCurses,
            #moveBasesIn,
            #doubleOrNothing,
            #windy,
            #rainy,
            #foggy,
            #extraStrike,
        ]);
        prng.shuffleBuffer(auras);
        let aura = auras.get(0);
        {
            MatchAura.getMetaData(aura) with
            aura = aura;
        };
    };

};
