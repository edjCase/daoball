import Principal "mo:base/Principal";
import Player "Player";
import DateTime "mo:datetime/DateTime";
import Time "mo:base/Time";
import Nat32 "mo:base/Nat32";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";

module {
    type FieldPosition = Player.FieldPosition;
    type Base = Player.Base;

    public type RegisterResult = {
        #ok;
        #matchNotFound;
        #teamNotInMatch;
        #matchAlreadyStarted;
        #invalidLineup : [PlayerValidationError];
    };

    public type ScheduleMatchResult = {
        #ok;
        #timeNotAvailable;
        #duplicateTeams;
    };

    public type TeamLineup = {
        starters : Trie.Trie<FieldPosition, Nat32>;
        battingOrder : [FieldPosition];
        substitutes : [Nat32];
    };

    public type TeamId = {
        #team1;
        #team2;
    };

    public type TeamSide = {
        #offense;
        #defense;
    };

    public type EventEffect = {
        #none;
        #increaseScore : {
            teamId : TeamId;
            amount : Int;
        };
        #subPlayer : {
            playerOutId : Nat32;
        };
        #setPlayerCondition : {
            playerId : Nat32;
            condition : Player.PlayerCondition;
        };
        #increaseEnergy : {
            playerId : Nat32;
            amount : Int;
        };
        #movePlayerToBase : {
            playerId : Nat32;
            base : ?Base;
        };
        #addStrike : {
            playerId : Nat32;
        };
        #addOut : {
            playerId : Nat32;
        };
        #endRound;
    };

    public type Event = {
        description : Text;
        effect : EventEffect;
    };

    public type PlayerState = {
        name : Text;
        teamId : TeamId;
        energy : Int;
        condition : Player.PlayerCondition;
        skills : Player.PlayerSkills;
        preferredPosition : FieldPosition;
    };

    public type TeamState = {
        id : Principal;
        name : Text;
        score : Int;
        positions : Trie.Trie<FieldPosition, Nat32>;
        battingOrder : [FieldPosition];
        substitutes : [Nat32];
        currentBatter : FieldPosition;
    };

    public type BaseInfo = {
        player : ?Nat;
    };

    public type MatchState = {
        #notStarted;
        #inProgress : InProgressMatchState;
        #completed : CompletedMatchState;
    };

    public type InProgressMatchState = {
        offenseTeamId : TeamId;
        team1 : TeamState;
        team2 : TeamState;
        players : Trie.Trie<Nat32, PlayerState>;
        events : [Event];
        bases : Trie.Trie<Base, Nat32>;
        round : Nat;
        outs : Nat;
        strikes : Nat;
    };

    public type CompletedMatchState = {
        #absentTeam : TeamId;
        #allAbsent;
        #gameResult : {
            team1 : TeamState;
            team2 : TeamState;
            players : Trie.Trie<Nat32, PlayerState>;
            events : [Event];
            winner : TeamId;
        };
    };

    public type StadiumActor = actor {
        registerForMatch : (id : Nat32, teamConfig : TeamLineup) -> async RegisterResult;
        scheduleMatch : (teamIds : (Principal, Principal), time : Time.Time) -> async ScheduleMatchResult;
    };

    public type Stadium = {
        canister : StadiumActor;
        name : Text;
    };

    public type Match = {
        teams : (MatchTeamInfo, MatchTeamInfo);
        time : Time.Time;
        winner : ?Principal;
        timerId : Nat;
        state : MatchState;
    };

    public type MatchTeamInfo = {
        id : Principal;
        lineup : ?TeamLineup;
        score : ?Nat;
        predictionVotes : Nat;
    };

    public type PlayerValidationError = {
        #notOnTeam : Nat32;
        #usedInMultiplePositions : Nat32;
    };
};
