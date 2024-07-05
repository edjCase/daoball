import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import PseudoRandomX "mo:xtended-random/PseudoRandomX";
import Types "MainActorTypes";
import Season "../models/Season";
import Scenario "../models/Scenario";
import SeasonHandler "../handlers/SeasonHandler";
import PredictionHandler "../handlers/PredictionHandler";
import ScenarioHandler "../handlers/ScenarioHandler";
import PlayerHandler "../handlers/PlayerHandler";
import TeamsHandler "../handlers/TeamsHandler";
import UserHandler "../handlers/UserHandler";
import SimulationHandler "../handlers/SimulationHandler";
import Dao "../Dao";
import Result "mo:base/Result";
import Nat32 "mo:base/Nat32";
import Player "../models/Player";
import TeamDao "../models/TeamDao";
import FieldPosition "../models/FieldPosition";
import Team "../models/Team";
import Trait "../models/Trait";
import LiveState "../models/LiveState";
import LeagueDao "../models/LeagueDao";
import Skill "../models/Skill";
import IterTools "mo:itertools/Iter";

actor MainActor : Types.Actor {
    // Types  ---------------------------------------------------------
    type Prng = PseudoRandomX.PseudoRandomGenerator;

    // Stables ---------------------------------------------------------

    stable var benevolentDictator : Types.BenevolentDictatorState = #open;
    stable var seasonStableData : SeasonHandler.StableData = {
        seasonStatus = #notStarted;
        teamStandings = null;
        predictions = [];
    };
    stable var predictionStableData : PredictionHandler.StableData = {
        matchGroups = [];
    };
    stable var scenarioStableData : ScenarioHandler.StableData = {
        scenarios = [];
    };
    stable var daoStableData : Dao.StableData<LeagueDao.ProposalContent> = {
        proposalDuration = #days(3);
        proposals = [];
        votingThreshold = #percent({
            percent = 50;
            quorum = ?20;
        });
    };

    stable var playerStableData : PlayerHandler.StableData = {
        players = [];
        retiredPlayers = [];
        unusedFluff = [];
    };

    stable var teamStableData : TeamsHandler.StableData = {
        entropyThreshold = 100;
        traits = [];
        teams = [];
    };

    stable var userStableData : UserHandler.StableData = {
        users = [];
    };

    stable var simulationStableData : SimulationHandler.StableData = {
        matchGroups = [];
    };

    // Unstables ---------------------------------------------------------

    var playerHandler = PlayerHandler.PlayerHandler(playerStableData);

    private func processEffectOutcome(effectOutcome : Scenario.EffectOutcome) : () {
        switch (effectOutcome) {
            case (#injury(injuryEffect)) {
                let ?player = playerHandler.getPosition(injuryEffect.target.teamId, injuryEffect.target.position) else Debug.trap("Position " # FieldPosition.toText(injuryEffect.target.position) # " not found in team " # Nat.toText(injuryEffect.target.teamId));

                switch (playerHandler.updateCondition(player.id, #injured)) {
                    case (#ok) ();
                    case (#err(e)) Debug.trap("Error updating player condition: " # debug_show (e));
                };
            };
            case (#entropy(entropyEffect)) {
                switch (teamsHandler.updateEntropy(entropyEffect.teamId, entropyEffect.delta)) {
                    case (#ok) ();
                    case (#err(#overThreshold)) (); // Will check for this after processing outcomes, ignore for now
                    case (#err(e)) Debug.trap("Error updating team entropy: " # debug_show (e));
                };
            };
            case (#energy(e)) {
                switch (teamsHandler.updateEnergy(e.teamId, e.delta)) {
                    case (#ok) ();
                    case (#err(e)) #err(debug_show (e));
                };
            };
            case (#skill(s)) {
                switch (playerHandler.updateSkill(s.playerId, s.skill, s.delta)) {
                    case (#ok) ();
                    case (#err(e)) #err(debug_show (e));
                };
            };
            case (#teamTrait(t)) {
                let result = switch (t.kind) {
                    case (#add) teamsHandler.addTraitToTeam(t.teamId, t.traitId);
                    case (#remove) teamsHandler.removeTraitFromTeam(t.teamId, t.traitId);
                };
                switch (result) {
                    case (#ok(_)) ();
                    case (#err(e)) #err(debug_show (e));
                };
            };
        };
    };

    var predictionHandler = PredictionHandler.Handler(predictionStableData);
    var scenarioHandler = ScenarioHandler.Handler<system>(scenarioStableData, processEffectOutcome);

    let seasonEventHandler : SeasonHandler.EventHandler = {
        onSeasonStart = func(_ : Season.InProgressSeason) : async* () {};
        onMatchGroupSchedule = func(matchGroupId : Nat, matchGroup : Season.ScheduledMatchGroup) : async* () {
            predictionHandler.addMatchGroup(matchGroupId, matchGroup.matches.size());
        };
        onMatchGroupStart = func(matchGroupId : Nat, _ : Season.InProgressMatchGroup) : async* () {
            predictionHandler.closeMatchGroup(matchGroupId);
        };
        onMatchGroupComplete = func(matchGroupId : Nat, matchGroup : Season.CompletedMatchGroup) : async* () {
            Debug.print("On match group complete event hook called for match group: " # Nat.toText(matchGroupId));
            teamsHandler.onMatchGroupComplete(request.matchGroup);
        };
        onSeasonEnd = func(_ : SeasonHandler.EndedSeasonVariant) : async* () {
            // TODO archive vs delete
            Debug.print("Season complete, clearing season data");
            predictionHandler.clear();
            // TODO teams reset energy/entropy? or is that a scenario thing

            switch (teamsHandler.onSeasonEnd()) {
                case (#ok) ();
                case (#err(#notAuthorized)) Debug.print("Error: League is not authorized to notify team of season completion");
            };

            switch (usersHandler.onSeasonEnd()) {
                case (#ok) ();
                case (#err(#notAuthorized)) Debug.print("League is not authorized to call users actor 'onSeasonEnd'");
            };

            switch (playersHandler.onSeasonEnd()) {
                case (#ok) ();
                case (#err(#notAuthorized)) Debug.print("League is not authorized to call players actor 'onSeasonEnd'");
            };
        };
    };

    var seasonHandler = SeasonHandler.SeasonHandler<system>(seasonStableData, seasonEventHandler);

    func onLeagueProposalExecute(proposal : Dao.Proposal<LeagueDao.ProposalContent>) : async* Result.Result<(), Text> {
        // TODO change league proposal for team data to be a simple approve w/ callback. Dont need to expose all the update routes
        switch (proposal.content) {
            case (#changeTeamName(c)) {
                let result = teamsHandler.updateName(c.teamId, c.name);
                let error = switch (result) {
                    case (#ok) return #ok;
                    case (#err(#teamNotFound)) "Team not found";
                    case (#err(#nameTaken)) "Name is already taken";
                };
                #err("Failed to update team name: " # error);
            };
            case (#changeTeamColor(c)) {
                let result = teamsHandler.updateColor(c.teamId, c.color);
                let error = switch (result) {
                    case (#ok) return #ok;
                    case (#err(#teamNotFound)) "Team not found";
                };
                #err("Failed to update team color: " # error);
            };
            case (#changeTeamLogo(c)) {
                let result = teamsHandler.updateLogo(c.teamId, c.logoUrl);
                let error = switch (result) {
                    case (#ok) return #ok;
                    case (#err(#teamNotFound)) "Team not found";
                };
                #err("Failed to update team logo: " # error);
            };
            case (#changeTeamMotto(c)) {
                let result = teamsHandler.updateMotto(c.teamId, c.motto);
                let error = switch (result) {
                    case (#ok) return #ok;
                    case (#err(#teamNotFound)) "Team not found";
                };
                #err("Failed to update team motto: " # error);
            };
            case (#changeTeamDescription(c)) {
                let result = teamsHandler.updateDescription(c.teamId, c.description);
                let error = switch (result) {
                    case (#ok) return #ok;
                    case (#err(#teamNotFound)) "Team not found";
                };
                #err("Failed to update team description: " # error);
            };
        };
    };
    func onLeagueProposalReject(_ : Dao.Proposal<LeagueDao.ProposalContent>) : async* () {}; // TODO
    func onLeagueProposalValidate(_ : LeagueDao.ProposalContent) : async* Result.Result<(), [Text]> {
        #ok; // TODO
    };
    var leagueDao = Dao.Dao<system, LeagueDao.ProposalContent>(
        daoStableData,
        onLeagueProposalExecute,
        onLeagueProposalReject,
        onLeagueProposalValidate,
    );

    func buildTeamDao<system>(
        teamId : Nat,
        data : Dao.StableData<TeamDao.ProposalContent>,
    ) : Dao.Dao<TeamDao.ProposalContent> {

        func onProposalExecute(proposal : Dao.Proposal<TeamDao.ProposalContent>) : async* Result.Result<(), Text> {
            let createLeagueProposal = func(leagueProposalContent : LeagueDao.ProposalContent) : async* Result.Result<(), Text> {
                let members = userHandler.getTeamOwners(null);
                let result = await* leagueDao.createProposal(proposal.proposerId, leagueProposalContent, members);
                switch (result) {
                    case (#ok(_)) #ok;
                    case (#err(#notAuthorized)) #err("Not authorized to create change name proposal in league DAO");
                    case (#err(#invalid(errors))) {
                        let errorText = errors.vals()
                        |> IterTools.fold(
                            _,
                            "",
                            func(acc : Text, error : Text) : Text = acc # error # "\n",
                        );
                        #err("Invalid proposal:\n" # errorText);
                    };
                };
            };
            switch (proposal.content) {
                case (#train(train)) {
                    // TODO atomic operation
                    let player = switch (playerHandler.getPosition(teamId, train.position)) {
                        case (?player) player;
                        case (null) return #err("Player not found in position " # debug_show (train.position) # " for team " # Nat.toText(teamId));
                    };
                    let trainCost = Skill.get(player.skills, train.skill); // Cost is the current skill level
                    switch (teamsHandler.updateEnergy(teamId, -trainCost, false)) {
                        case (#ok) ();
                        case (#err(#notEnoughEnergy)) return #err("Not enough energy to train player");
                        case (#err(#teamNotFound)) return #err("Team not found: " # Nat.toText(teamId));
                    };
                    switch (playerHandler.updateSkill(player.id, train.skill, 1)) {
                        case (#ok) #ok;
                        case (#err(#playerNotFound)) #err("Player not found: " # Nat32.toText(player.id));
                    };
                };
                case (#changeName(n)) {
                    let leagueProposal = #changeTeamName({
                        teamId = teamId;
                        name = n.name;
                    });
                    await* createLeagueProposal(leagueProposal);
                };
                case (#swapPlayerPositions(swap)) {
                    switch (playerHandler.swapTeamPositions(teamId, swap.position1, swap.position2)) {
                        case (#ok) #ok;
                    };
                };
                case (#changeColor(changeColor)) {
                    await* createLeagueProposal(#changeTeamColor({ teamId = teamId; color = changeColor.color }));
                };
                case (#changeLogo(changeLogo)) {
                    await* createLeagueProposal(#changeTeamLogo({ teamId = teamId; logoUrl = changeLogo.logoUrl }));
                };
                case (#changeMotto(changeMotto)) {
                    await* createLeagueProposal(#changeTeamMotto({ teamId = teamId; motto = changeMotto.motto }));
                };
                case (#changeDescription(changeDescription)) {
                    await* createLeagueProposal(#changeTeamDescription({ teamId = teamId; description = changeDescription.description }));
                };
                case (#modifyLink(modifyLink)) {
                    switch (teamsHandler.modifyLink(teamId, modifyLink.name, modifyLink.url)) {
                        case (#ok) #ok;
                        case (#err(#teamNotFound)) #err("Team not found: " # Nat.toText(teamId));
                        case (#err(#urlRequired)) #err("URL is required when adding a new link");
                    };
                };
            };
        };

        func onProposalReject(proposal : Dao.Proposal<TeamDao.ProposalContent>) : async* () {
            Debug.print("Rejected proposal: " # debug_show (proposal));
        };
        func onProposalValidate(_ : TeamDao.ProposalContent) : async* Result.Result<(), [Text]> {
            #ok; // TODO
        };
        let dao = Dao.Dao<system, TeamDao.ProposalContent>(data, onProposalExecute, onProposalReject, onProposalValidate);
        dao;
    };

    func onLeagueCollapse() : () {
        Debug.print("Entropy threshold reached, triggering league collapse");
        seasonHandler.onLeagueCollapse();
        scenarioHandler.onLeagueCollapse();
    };

    var teamsHandler = TeamsHandler.Handler<system>(teamStableData, buildTeamDao, onLeagueCollapse);

    var userHandler = UserHandler.UserHandler(userStableData);

    func onMatchGroupComplete<system>(data : SimulationHandler.OnMatchGroupCompleteData) : () {

        let result = seasonHandler.onMatchGroupComplete<system>(data, prng);

        let errorMessage = switch (result) {
            case (#ok) {
                // Remove match group if successfully passed info to the league
                let matchGroupKey = buildMatchGroupKey(id);
                let (newMatchGroups, _) = Trie.remove(matchGroups, matchGroupKey, Nat.equal);
                matchGroups := newMatchGroups;
                return #ok(#completed);
            };
            case (#err(#matchGroupNotFound)) "Failed: Match group not found - " # Nat.toText(id);
            case (#err(#seasonNotOpen)) "Failed: Season not open";
            case (#err(#matchGroupNotInProgress)) "Failed: Match group not in progress";
        };
        Debug.print("On Match Group Complete Result - " # errorMessage);
        // Award users points for their predictions
        awardUserPoints(matchGroupId, completedMatches);
    };

    var simulationHandler = SimulationHandler.Handler<system>(simulationStableData, onMatchGroupComplete);

    // System Methods ---------------------------------------------------------

    system func preupgrade() {
        seasonStableData := seasonHandler.toStableData();
        predictionStableData := predictionHandler.toStableData();
        scenarioStableData := scenarioHandler.toStableData();
        daoStableData := dao.toStableData();
        playerStableData := playerHandler.toStableData();
        teamStableData := teamsHandler.toStableData();
        userStableData := userHandler.toStableData();
        simulationStableData := simulationHandler.toStableData();
    };

    system func postupgrade() {
        seasonHandler := SeasonHandler.SeasonHandler<system>(seasonStableData, seasonEventHandler);
        predictionHandler := PredictionHandler.Handler(predictionStableData);
        scenarioHandler := ScenarioHandler.Handler<system>(scenarioStableData, processEffectOutcome);
        dao := Dao.Dao<system, Types.ProposalContent>(
            daoStableData,
            onLeagueProposalExecute,
            onLeagueProposalReject,
            onLeagueProposalValidate,
        );
        playerHandler := PlayerHandler.PlayerHandler(playerStableData);
        teamsHandler := TeamsHandler.Handler<system>(teamStableData, buildTeamDao, onLeagueCollapse);
        userHandler := UserHandler.UserHandler(userStableData);
        simulationHandler := SimulationHandler.Handler<system>(simulationStableData, onMatchGroupComplete);
    };

    // Public Methods ---------------------------------------------------------

    public shared ({ caller }) func claimBenevolentDictatorRole() : async Types.ClaimBenevolentDictatorRoleResult {
        if (Principal.isAnonymous(caller)) {
            return #err(#notAuthenticated);
        };
        if (benevolentDictator != #open) {
            return #err(#notOpenToClaim);
        };
        benevolentDictator := #claimed(caller);
        #ok;
    };

    public shared ({ caller }) func setBenevolentDictatorState(state : Types.BenevolentDictatorState) : async Types.SetBenevolentDictatorStateResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        benevolentDictator := state;
        #ok;
    };

    public query func getBenevolentDictatorState() : async Types.BenevolentDictatorState {
        benevolentDictator;
    };

    public query func getSeasonStatus() : async Season.SeasonStatus {
        seasonHandler.seasonStatus;
    };

    public shared ({ caller }) func createProposal(request : Types.CreateProposalRequest) : async Types.CreateProposalResult {
        let members = userHandler.getTeamOwners(null);
        await* leagueDao.createProposal<system>(caller, request.content, members);
    };

    public shared query func getProposal(id : Nat) : async Types.GetProposalResult {
        switch (leagueDao.getProposal(id)) {
            case (?proposal) return #ok(proposal);
            case (null) return #err(#proposalNotFound);
        };
    };

    public shared query func getProposals(count : Nat, offset : Nat) : async Types.GetProposalsResult {
        #ok(leagueDao.getProposals(count, offset));
    };

    public shared ({ caller }) func voteOnProposal(request : Types.VoteOnProposalRequest) : async Types.VoteOnProposalResult {
        await* leagueDao.vote(request.proposalId, caller, request.vote);
    };

    public query func getTeamStandings() : async Types.GetTeamStandingsResult {
        let ?standings = seasonHandler.teamStandings else return #err(#notFound);
        #ok(Buffer.toArray(standings));
    };

    public query func getScenario(scenarioId : Nat) : async Types.GetScenarioResult {
        let ?scenario = scenarioHandler.getScenario(scenarioId) else return #err(#notFound);
        #ok(scenario);
    };

    public query func getScenarios() : async Types.GetScenariosResult {
        let openScenarios = scenarioHandler.getScenarios(false);
        #ok(openScenarios);
    };

    public shared ({ caller }) func addScenario(scenario : Types.AddScenarioRequest) : async Types.AddScenarioResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        let members = userHandler.getTeamOwners(null);
        let teams = teamsHandler.getAll();
        scenarioHandler.add<system>(scenario, members, teams);
    };

    public shared query ({ caller }) func getScenarioVote(request : Types.GetScenarioVoteRequest) : async Types.GetScenarioVoteResult {
        scenarioHandler.getVote(request.scenarioId, caller);
    };

    public shared ({ caller }) func voteOnScenario(request : Types.VoteOnScenarioRequest) : async Types.VoteOnScenarioResult {
        scenarioHandler.vote(request.scenarioId, caller, request.value);
    };

    public shared ({ caller }) func startSeason(request : Types.StartSeasonRequest) : async Types.StartSeasonResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        Debug.print("Starting season");
        let seedBlob = try {
            await Random.blob();
        } catch (err) {
            return #err(#seedGenerationError(Error.message(err)));
        };

        let teamsArray = teamsHandler.getAll();

        let allPlayers = playerHandler.getAll(null);

        let prng = PseudoRandomX.fromBlob(seedBlob);
        seasonHandler.startSeason<system>(
            prng,
            request.startTime,
            request.weekDays,
            teamsArray,
            allPlayers,
        );
    };

    public shared ({ caller }) func predictMatchOutcome(request : Types.PredictMatchOutcomeRequest) : async Types.PredictMatchOutcomeResult {
        let ?nextScheduled = seasonHandler.getNextScheduledMatchGroup() else return #err(#predictionsClosed);
        predictionHandler.predictMatchOutcome(
            nextScheduled.matchGroupId,
            request.matchId,
            caller,
            request.winner,
        );
    };

    public shared query ({ caller }) func getMatchGroupPredictions(matchGroupId : Nat) : async Types.GetMatchGroupPredictionsResult {
        predictionHandler.getMatchGroupSummary(matchGroupId, ?caller);
    };

    public shared query func getLiveMatchGroupState(matchGroupId : Nat) : async Result.Result<LiveState.LiveMatchGroupState, Types.GetLiveMatchGroupStateError> {
        simulationHandler.getLiveMatchGroupState(matchGroupId);
    };

    public shared ({ caller }) func startMatchGroup(matchGroupId : Nat) : async Types.StartMatchGroupResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };

        seasonHandler.startMatchGroup(matchGroupId);

    };

    public shared ({ caller }) func closeSeason() : async Types.CloseSeasonResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        seasonHandler.close();
    };

    public shared ({ caller }) func addFluff(request : Types.CreatePlayerFluffRequest) : async Types.CreatePlayerFluffResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        playerHandler.addFluff(request);
    };

    public query func getPlayer(id : Nat32) : async Types.GetPlayerResult {
        switch (playerHandler.get(id)) {
            case (?player) {
                #ok(player);
            };
            case (null) {
                #err(#notFound);
            };
        };
    };

    public query func getPosition(teamId : Nat, position : FieldPosition.FieldPosition) : async Result.Result<Player.Player, Types.GetPositionError> {
        switch (playerHandler.getPosition(teamId, position)) {
            case (?player) #ok(player);
            case (null) #err(#teamNotFound);
        };
    };

    public query func getTeamPlayers(teamId : Nat) : async [Player.Player] {
        playerHandler.getAll(?teamId);
    };

    public query func getAllPlayers() : async [Player.Player] {
        playerHandler.getAll(null);
    };

    public shared ({ caller }) func cancelMatchGroup(
        request : Types.CancelMatchGroupRequest
    ) : async Types.CancelMatchGroupResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        simulationHandler.cancelMatchGroup(request.id);
    };

    // TODO remove
    public shared ({ caller }) func finishMatchGroup(id : Nat) : async Types.FinishMatchGroupResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        simulationHandler.finishMatchGroup(id);
    };

    public shared query func getEntropyThreshold() : async Nat {
        teamsHandler.getEntropyThreshold();
    };

    public shared query func getTeams() : async [Team.Team] {
        teamsHandler.getAll();
    };

    public shared ({ caller }) func createTeam(request : Types.CreateTeamRequest) : async Types.CreateTeamResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        teamsHandler.create<system>(request);
        playerHandler.populateTeamRoster(request.teamId);
    };

    public shared query func getTraits() : async [Trait.Trait] {
        teamsHandler.getTraits();
    };

    public shared ({ caller }) func createTeamTrait(request : Types.CreateTeamTraitRequest) : async Types.CreateTeamTraitResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        teamsHandler.createTrait(request);
    };

    public shared ({ caller }) func createTeamProposal(teamId : Nat, request : Types.CreateProposalRequest) : async Types.CreateProposalResult {
        let members = switch (userHandler.getTeamOwners(?teamId)) {
            case (#ok(members)) members;
        };
        let isAMember = members
        |> Iter.fromArray(_)
        |> Iter.filter(
            _,
            func(member : Dao.Member) : Bool = member.id == caller,
        )
        |> _.next() != null;
        if (not isAMember) {
            return #err(#notAuthorized);
        };
        await* teamsHandler.createProposal<system>(teamId, caller, request, members);
    };

    public shared query func getTeamProposal(teamId : Nat, id : Nat) : async Types.GetProposalResult {
        teamsHandler.getProposal(teamId, id);
    };

    public shared query func getTeamProposals(teamId : Nat, count : Nat, offset : Nat) : async Types.GetProposalsResult {
        teamsHandler.getProposals(teamId, count, offset);
    };

    public shared ({ caller }) func voteOnTeamProposal(teamId : Nat, request : Types.VoteOnProposalRequest) : async Types.VoteOnProposalResult {
        await* teamsHandler.voteOnProposal(teamId, caller, request);
    };

    public shared query func getUser(userId : Principal) : async Types.GetUserResult {
        let ?user = userHandler.get(userId) else return #err(#notFound);
        #ok(user);
    };

    public shared query func getUserStats() : async Types.GetUserStatsResult {
        let stats = userHandler.getStats();
        #ok(stats);
    };

    public shared query func getUserLeaderboard(request : Types.GetUserLeaderboardRequest) : async Types.GetUserLeaderboardResult {
        let topUsers = userHandler.getUserLeaderboard(request.count, request.offset);
        #ok(topUsers);
    };

    public shared query func getTeamOwners(request : Types.GetTeamOwnersRequest) : async Types.GetTeamOwnersResult {
        let owners = userHandler.getTeamOwners(request);
        #ok(owners);
    };

    public shared ({ caller }) func setFavoriteTeam(userId : Principal, teamId : Nat) : async Types.SetUserFavoriteTeamResult {
        if (Principal.isAnonymous(userId)) {
            return #err(#identityRequired);
        };
        if (caller != userId and not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        let ?_ = teamsHandler.get(teamId) else return #err(#teamNotFound);
        userHandler.setFavoriteTeam(userId, teamId);
    };

    public shared ({ caller }) func addTeamOwner(request : Types.AddTeamOwnerRequest) : async Types.AddTeamOwnerResult {
        if (not isLeagueOrBDFN(caller)) {
            return #err(#notAuthorized);
        };
        let ?_ = teamsHandler.get(request.teamId) else return #err(#teamNotFound);
        userHandler.addTeamOwner(request);
    };

    // Private Methods ---------------------------------------------------------

    private func awardUserPoints(
        matchGroupId : Nat,
        completedMatches : [Season.CompletedMatch],
    ) : () {

        // Award users points for their predictions
        let anyAwards = switch (predictionHandler.getMatchGroup(matchGroupId)) {
            case (null) false;
            case (?matchGroupPredictions) {
                let awards = Buffer.Buffer<{ userId : Principal; points : Nat }>(0);
                var i = 0;
                for (match in Iter.fromArray(completedMatches)) {
                    if (i >= matchGroupPredictions.size()) {
                        Debug.trap("Match group predictions and completed matches do not match in size. Invalid state. Matches: " # debug_show (completedMatches) # " Predictions: " # debug_show (matchGroupPredictions));
                    };
                    let matchPredictions = matchGroupPredictions[i];
                    i += 1;
                    for ((userId, teamId) in Iter.fromArray(matchPredictions)) {
                        if (teamId == match.winner) {
                            // Award points
                            awards.add({
                                userId = userId;
                                points = 10; // TODO amount?
                            });
                        };
                    };
                };
                if (awards.size() > 0) {
                    for (award in awards.vals()) {
                        switch (userHandler.awardPoints(award.userId, award.points)) {
                            case (#ok) ();
                            case (#err(#userNotFound)) Debug.trap("User not found: " # Principal.toText(award.userId));
                        };
                    };
                    true;
                } else {
                    false;
                };
            };
        };
        if (not anyAwards) {
            Debug.print("No user points to award, skipping...");
        };
    };

    private func isLeagueOrBDFN(id : Principal) : Bool {
        if (id == Principal.fromActor(MainActor)) {
            // League is admin
            return true;
        };
        switch (benevolentDictator) {
            case (#open or #disabled) false;
            case (#claimed(claimantId)) return id == claimantId;
        };
    };

};
