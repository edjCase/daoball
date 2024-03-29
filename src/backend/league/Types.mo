import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Player "../models/Player";
import Team "../models/Team";
import Season "../models/Season";
import Scenario "../models/Scenario";
import Dao "../Dao";
import CommonTypes "../Types";
import Components "mo:datetime/Components";

module {
    public type LeagueActor = actor {
        getTeams : query () -> async [Team.TeamWithId];
        getSeasonStatus : query () -> async Season.SeasonStatus;
        getTeamStandings : query () -> async GetTeamStandingsResult;
        startSeason : (request : StartSeasonRequest) -> async StartSeasonResult;
        closeSeason : () -> async CloseSeasonResult;
        createTeam : (request : CreateTeamRequest) -> async CreateTeamResult;
        predictMatchOutcome : (request : PredictMatchOutcomeRequest) -> async PredictMatchOutcomeResult;
        getMatchGroupPredictions : query (matchGroupId : Nat) -> async GetMatchGroupPredictionsResult;
        startMatchGroup : (id : Nat) -> async StartMatchGroupResult;
        onMatchGroupComplete : (request : OnMatchGroupCompleteRequest) -> async OnMatchGroupCompleteResult;

        createProposal : (request : CreateProposalRequest) -> async CreateProposalResult;
        getProposal : query (Nat) -> async GetProposalResult;
        getProposals : query (count : Nat, offset : Nat) -> async GetProposalsResult;
        getScenario : query (Text) -> async GetScenarioResult;
        getScenarios : query () -> async GetScenariosResult;
        voteOnProposal : VoteOnProposalRequest -> async VoteOnProposalResult;
        clearTeams : () -> async (); // TODO remove

        claimBenevolentDictatorRole : () -> async ClaimBenevolentDictatorRoleResult;
        setBenevolentDictatorState : (state : BenevolentDictatorState) -> async SetBenevolentDictatorStateResult;
        getBenevolentDictatorState : query () -> async BenevolentDictatorState;
    };

    public type ClaimBenevolentDictatorRoleResult = {
        #ok;
        #notOpenToClaim;
    };

    public type SetBenevolentDictatorStateResult = {
        #ok;
        #notAuthorized;
    };

    public type GetProposalResult = {
        #ok : Proposal;
        #proposalNotFound;
    };

    public type GetProposalsResult = {
        #ok : CommonTypes.PagedResult<Proposal>;
    };

    public type Proposal = Dao.Proposal<ProposalContent>;

    public type ProposalContent = {
        #changeTeamName : {
            teamId : Nat;
            name : Text;
        };
    };

    public type VoteOnProposalRequest = {
        proposalId : Nat;
        vote : Bool;
    };

    public type VoteOnProposalResult = {
        #ok;
        #notAuthorized;
        #proposalNotFound;
        #alreadyVoted;
        #votingClosed;
    };

    public type CreateProposalRequest = {
        content : ProposalContent;
    };

    public type CreateProposalResult = {
        #ok : Nat;
        #notAuthorized;
    };

    public type GetScenarioResult = {
        #ok : Scenario;
        #notFound;
        #notStarted;
    };

    public type GetScenariosResult = {
        #ok : [Scenario];
    };

    public type ScenarioStateResolved = {
        teamChoices : [{
            teamId : Nat;
            option : Nat;
        }];
    };

    public type Scenario = {
        id : Text;
        title : Text;
        description : Text;
        options : [Scenario.ScenarioOption];
        state : {
            #notStarted;
            #inProgress;
            #resolved : ScenarioStateResolved;
        };

    };

    public type BenevolentDictatorState = {
        #open;
        #claimed : Principal;
        #disabled;
    };

    public type TeamStandingInfo = {
        id : Nat;
        wins : Nat;
        losses : Nat;
        totalScore : Int;
    };

    public type GetTeamStandingsResult = {
        #ok : [TeamStandingInfo];
        #notFound;
    };

    public type ProcessEffectOutcomesRequest = {
        outcomes : [Scenario.EffectOutcome];
    };

    public type ProcessEffectOutcomesResult = {
        #ok;
        #notAuthorized;
        #seasonNotInProgress;
    };

    public type GetMatchGroupPredictionsResult = {
        #ok : MatchGroupPredictionSummary;
        #notFound;
    };

    public type MatchGroupPredictionSummary = {
        matches : [MatchPredictionSummary];
    };

    public type MatchPredictionSummary = {
        team1 : Nat;
        team2 : Nat;
        yourVote : ?Team.TeamId;
    };

    public type PredictMatchOutcomeRequest = {
        matchId : Nat;
        winner : ?Team.TeamId;
    };

    public type PredictMatchOutcomeResult = {
        #ok;
        #matchGroupNotFound;
        #matchNotFound;
        #predictionsClosed;
        #identityRequired;
    };

    // On start
    public type StartMatchGroupResult = {
        #ok;
        #matchGroupNotFound;
        #notAuthorized;
        #notScheduledYet;
        #alreadyStarted;
        #matchErrors : [{
            matchId : Nat;
            error : StartMatchError;
        }];
    };

    public type StartMatchError = {
        #notEnoughPlayers : Team.TeamIdOrBoth;
    };

    // Start season
    public type StartSeasonRequest = {
        startTime : Time.Time;
        weekDays : [Components.DayOfWeek];
    };

    public type AddScenarioRequest = {
        id : Text;
        startTime : Time.Time;
        endTime : Time.Time;
        title : Text;
        description : Text;
        options : [Scenario.ScenarioOptionWithEffect];
        metaEffect : Scenario.MetaEffect;
        teamIds : [Nat];
    };

    public type AddScenarioResult = {
        #ok;
        #invalid : [Text];
        #notAuthorized;
    };

    public type StartSeasonResult = {
        #ok;
        #alreadyStarted;
        #idTaken;
        #noStadiumsExist;
        #seedGenerationError : Text;
        #invalidArgs : Text;
        #notAuthorized;
    };

    public type CloseSeasonResult = {
        #ok;
        #notAuthorized;
        #seasonNotOpen;
    };

    // On complete

    public type OnMatchGroupCompleteRequest = {
        id : Nat;
        matches : [Season.CompletedMatch];
        playerStats : [Player.PlayerMatchStatsWithId];
    };

    public type FailedMatchResult = {
        message : Text;
    };

    public type OnMatchGroupCompleteResult = {
        #ok;
        #seasonNotOpen;
        #matchGroupNotFound;
        #matchGroupNotInProgress;
        #seedGenerationError : Text;
        #notAuthorized;
    };

    // Create Team

    public type CreateTeamRequest = {
        name : Text;
        logoUrl : Text;
        motto : Text;
        description : Text;
        color : (Nat8, Nat8, Nat8);
    };

    public type CreateTeamResult = {
        #ok : Nat;
        #nameTaken;
        #noStadiumsExist;
        #teamsCallError : Text;
        #notAuthorized;
        #populateTeamRosterCallError : Text;
    };
};
