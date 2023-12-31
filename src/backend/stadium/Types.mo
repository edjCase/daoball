import Principal "mo:base/Principal";
import Player "../models/Player";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Offering "../models/Offering";
import MatchAura "../models/MatchAura";
import Base "../models/Base";
import Team "../models/Team";
import FieldPosition "../models/FieldPosition";
import Season "../models/Season";

module {
    type FieldPosition = FieldPosition.FieldPosition;
    type Base = Base.Base;
    type PlayerId = Player.PlayerId;

    public type StadiumActor = actor {
        getMatchGroup : query (id : Nat) -> async ?MatchGroupWithId;
        tickMatchGroup : (id : Nat) -> async TickMatchGroupResult;
        resetTickTimer : (matchGroupId : Nat) -> async ResetTickTimerResult;
        startMatchGroup : (request : StartMatchGroupRequest) -> async StartMatchGroupResult;
    };

    public type StadiumFactoryActor = actor {
        createStadiumActor : () -> async CreateStadiumResult;
        getStadiumActors : () -> async [StadiumActorInfoWithId];
        updateCanisters : () -> async ();
    };

    public type StadiumActorInfo = {};

    public type StadiumActorInfoWithId = StadiumActorInfo and {
        id : Principal;
    };

    public type CreateStadiumResult = {
        #ok : Principal;
        #stadiumCreationError : Text;
    };

    public type StartMatchGroupRequest = {
        id : Nat;
        matches : [StartMatchRequest];
    };

    public type Team = {
        id : Principal;
        name : Text;
        logoUrl : Text;
    };

    public type StartMatchTeam = Team and {
        offering : Offering.Offering;
        championId : PlayerId;
        players : [Player.PlayerWithId];
    };

    public type StartMatchRequest = {
        team1 : StartMatchTeam;
        team2 : StartMatchTeam;
        aura : MatchAura.MatchAura;
    };

    public type StartMatchGroupError = {
        #noMatchesSpecified;
        #matchErrors : [{
            matchId : Nat;
            error : StartMatchError;
        }];
    };

    public type StartMatchError = {
        #notEnoughPlayers : Team.TeamIdOrBoth;
    };

    public type StartMatchGroupResult = StartMatchGroupError or {
        #ok;
    };

    public type MatchVariant = {
        #inProgress : InProgressMatch;
        #completed : Season.CompletedMatchWithoutPredictions;
    };
    public type InProgressMatch = {
        team1 : TeamState;
        team2 : TeamState;
        offenseTeamId : Team.TeamId;
        aura : MatchAura.MatchAura;
        players : [PlayerStateWithId];
        field : FieldState;
        log : [LogEntry];
        round : Nat;
        outs : Nat;
        strikes : Nat;
    };

    public type PlayerNotFoundError = {
        id : PlayerId;
        teamId : ?Team.TeamId;
    };

    public type PlayerExpectedOnFieldError = {
        id : PlayerId;
        onOffense : Bool;
        description : Text;
    };

    public type BrokenStateError = {
        #playerNotFound : PlayerNotFoundError;
        #playerExpectedOnField : PlayerExpectedOnFieldError;
    };

    public type MatchGroup = {
        matches : [MatchVariant];
        tickTimerId : Nat;
        currentSeed : Nat32;
    };

    public type MatchGroupWithId = MatchGroup and {
        id : Nat;
    };

    public type ResetTickTimerResult = {
        #ok;
        #matchGroupNotFound;
    };

    public type PlayerState = {
        name : Text;
        teamId : Team.TeamId;
        condition : Player.PlayerCondition;
        skills : Player.Skills;
        position : FieldPosition;
    };

    public type PlayerStateWithId = PlayerState and {
        id : PlayerId;
    };

    public type DefenseFieldState = {
        firstBase : PlayerId;
        secondBase : PlayerId;
        thirdBase : PlayerId;
        shortStop : PlayerId;
        pitcher : PlayerId;
        leftField : PlayerId;
        centerField : PlayerId;
        rightField : PlayerId;
    };

    public type OffenseFieldState = {
        atBat : PlayerId;
        firstBase : ?PlayerId;
        secondBase : ?PlayerId;
        thirdBase : ?PlayerId;
    };

    public type FieldState = {
        defense : DefenseFieldState;
        offense : OffenseFieldState;
    };

    public type LogEntry = {
        message : Text;
        isImportant : Bool;
    };

    public type TickMatchGroupResult = {
        #inProgress;
        #matchGroupNotFound;
        #onStartCallbackError : {
            #unknown : Text;
            #notScheduledYet;
            #alreadyStarted;
            #notAuthorized;
            #matchGroupNotFound;
        };
        #completed;
    };

    public type Player = {
        id : PlayerId;
        name : Text;
    };

    public type TeamState = Team and {
        score : Int;
        offering : Offering.Offering;
        championId : PlayerId;
    };

};
