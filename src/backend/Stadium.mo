import Principal "mo:base/Principal";
import Player "Player";
import DateTime "mo:datetime/DateTime";
import Time "mo:base/Time";
import Nat32 "mo:base/Nat32";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";

module {
    type FieldPosition = Player.FieldPosition;
    type Base = Player.Base;

    type PlayerId = Nat32;

    public type RegisterResult = {
        #ok;
        #matchNotFound;
        #teamNotInMatch;
        #matchAlreadyStarted;
        #invalidInfo : [RegistrationInfoError];
    };

    public type RegistrationInfoError = {
        #invalidOffering : Nat32;
        #invalidSpecialRule : Nat32;
    };

    public type ScheduleMatchResult = {
        #ok : Nat32;
        #timeNotAvailable;
        #duplicateTeams;
    };

    public type TeamId = {
        #team1;
        #team2;
    };

    public type MatchTurn = {
        events : [MatchEvent];
    };

    public type MatchEvent = {
        #pitch : { pitchRoll : Nat };
        #hit : { hitRoll : Nat };
        #run : { fromBase : Base; toBase : Base };
        #foul;
        #strike;
        #out : PlayerId;
        #playerMovedBases : {
            playerId : PlayerId;
            base : Base;
        };
        #playerInjured : {
            playerId : PlayerId;
            injury : Player.Injury;
        };
        #playerSubstituted : {
            playerId : PlayerId;
        };
        #score : {
            teamId : TeamId;
            amount : Int;
        };
        #endRound;
        #endMatch : MatchEndReason;
    };

    public type MatchEndReason = {
        #noMoreRounds;
        #outOfPlayers : TeamId or { #bothTeams };
    };

    public type PlayerState = {
        name : Text;
        teamId : TeamId;
        condition : Player.PlayerCondition;
        skills : Player.PlayerSkills;
        position : FieldPosition;
    };

    public type PlayerStateWithId = PlayerState and {
        id : PlayerId;
    };

    public type TeamState = {
        id : Principal;
        score : Int;
        offeringId : Nat32;
    };

    public type MatchState = {
        #notStarted;
        #inProgress : InProgressMatchState;
        #completed : CompletedMatchState;
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

    public type InProgressMatchState = {
        offenseTeamId : TeamId;
        team1 : TeamState;
        team2 : TeamState;
        specialRuleId : ?Nat32;
        players : [PlayerStateWithId];
        batter : ?PlayerId;
        field : FieldState;
        turns : [MatchTurn];
        round : Nat;
        outs : Nat;
        strikes : Nat;
    };

    public type CompletedMatchState = {
        #absentTeam : TeamId;
        #allAbsent;
        #played : CompletedMatchResult;
    };

    public type CompletedMatchResult = {
        team1 : CompletedTeamState;
        team2 : CompletedTeamState;
        winner : TeamId;
        initialState : InProgressMatchState;
        turns : [MatchTurn];
    };

    public type CompletedTeamState = {
        id : Principal;
        score : Int;
    };

    public type StartMatchResult = {
        #ok : InProgressMatchState;
        #matchNotFound;
        #matchAlreadyStarted;
        #completed : CompletedMatchState;
    };

    public type StadiumActor = actor {
        getMatch : shared query (id : Nat32) -> async ?MatchWithId;
        getMatches : shared query () -> async [MatchWithId];
        tickMatch : shared (id : Nat32) -> async TickMatchResult;
        startMatch : shared (matchId : Nat32) -> async StartMatchResult;
        scheduleMatch : shared (teamIds : (Principal, Principal), time : Time.Time) -> async ScheduleMatchResult;
    };

    public type Stadium = {
        name : Text;
    };

    public type Offering = {
        deities : [Text];
        effects : [Text];
    };

    public type OfferingWithId = Offering and {
        id : Nat32;
    };

    public type SpecialRule = {
        name : Text;
        description : Text;
    };

    public type SpecialRuleWithId = SpecialRule and {
        id : Nat32;
    };

    public type Match = {
        teams : (MatchTeamInfo, MatchTeamInfo);
        time : Time.Time;
        offerings : [OfferingWithId];
        specialRules : [SpecialRuleWithId];
        state : MatchState;
    };

    public type MatchWithTimer = Match and {
        timerId : ?Nat;
    };

    public type MatchWithId = Match and {
        id : Nat32;
        stadiumId : Principal;
    };
    public type TickMatchResult = {
        #ok : InProgressMatchState;
        #matchNotFound;
        #matchOver : CompletedMatchState;
        #notStarted;
    };

    public type MatchOptions = {
        offeringId : Nat32;
        specialRuleVotes : [(Nat32, Nat)];
    };

    public type MatchTeamInfo = {
        id : Principal;
        predictionVotes : Nat;
    };
};
