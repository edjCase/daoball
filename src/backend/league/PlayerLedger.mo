import Trie "mo:base/Trie";
import Player "../Player";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
// import LeagueActor "canister:league"; TODO

actor PlayerLedger {

    type Player = Player.Player;
    type PlayerWithId = Player.PlayerWithId;

    stable var nextPlayerId : Nat32 = 1;
    stable var players = Trie.empty<Nat32, Player>();
    var teamPlayers = Trie.empty<Principal, Nat32>();

    public type PlayerCreationOptions = {
        name : Text;
        teamId : ?Principal;
        position : Player.FieldPosition;
    };

    public shared ({ caller }) func create(options : PlayerCreationOptions) : async Nat32 {
        assertLeague(caller);
        let id = nextPlayerId;
        nextPlayerId += 1;
        let player = generatePlayer(options);
        let playerInfo : Player = {
            player with
            teamId = options.teamId;
        };
        let key = {
            key = id;
            hash = id;
        };
        let (newPlayers, oldPlayer) = Trie.put(players, key, Nat32.equal, playerInfo);
        if (oldPlayer != null) {
            Debug.trap("Player id '" # Nat32.toText(id) # "' already exists");
        };
        players := newPlayers;
        id;
    };

    public query ({ caller }) func getPlayer(id : Nat32) : async {
        #ok : Player;
        #notFound;
    } {
        let key = {
            key = id;
            hash = id;
        };
        let playerInfo = Trie.get(players, key, Nat32.equal);
        switch (playerInfo) {
            case (?playerInfo) #ok(playerInfo);
            case (null) #notFound;
        };
    };

    public query func getTeamPlayers(teamId : ?Principal) : async [PlayerWithId] {
        let teamPlayers = Trie.filter(players, func(k : Nat32, p : Player) : Bool = p.teamId == teamId);
        Trie.toArray(teamPlayers, func(k : Nat32, p : Player) : PlayerWithId = { p with id = k });
    };

    public query func getAllPlayers() : async [PlayerWithId] {
        Trie.toArray(players, func(k : Nat32, p : Player) : PlayerWithId = { p with id = k });
    };

    public shared ({ caller }) func setPlayerTeam(playerId : Nat32, teamId : ?Principal) : async {
        #ok;
        #playerNotFound;
    } {
        assertLeague(caller);
        let playerKey = {
            key = playerId;
            hash = playerId;
        };
        let ?playerInfo = Trie.get(players, playerKey, Nat32.equal) else return #playerNotFound;
        let newPlayerInfo = {
            playerInfo with
            teamId = teamId;
        };
        let (newPlayers, _) = Trie.put(players, playerKey, Nat32.equal, newPlayerInfo);
        players := newPlayers;
        #ok;
    };

    private func assertLeague(caller : Principal) {
        // TODO
        // if (caller != Principal.fromActor(LeagueActor)) {
        //     Debug.trap("Only the league can create players");
        // };
    };

    private func generatePlayer(options : PlayerCreationOptions) : Player {
        {
            name = options.name;
            teamId = null;
            energy = 100;
            energyRecoveryRate = 10;
            condition = #ok;
            position = options.position;
            skills = {
                batting = 0;
                throwing = 0;
                catching = 0;
            };
        };
    };
};