import Trie "mo:base/Trie";
import Player "../models/Player";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import PseudoRandomX "mo:random/PseudoRandomX";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Result "mo:base/Result";
import Types "Types";
import FieldPosition "../models/FieldPosition";
import PlayerHandler "PlayerHandler";
// import LeagueActor "canister:league"; TODO

actor : Types.PlayerActor {
    type Prng = PseudoRandomX.PseudoRandomGenerator;

    stable var playerStableData : PlayerHandler.StableData = {
        players = [];
        retiredPlayers = [];
        unusedFluff = [];
    };
    stable var teamsCanisterId : ?Principal = null;
    stable var stats = Trie.empty<Nat32, Trie.Trie<Nat, Player.PlayerMatchStats>>();

    var playerHandler = PlayerHandler.PlayerHandler(playerStableData);

    system func preupgrade() {
        playerStableData := playerHandler.toStableData();
    };

    system func postupgrade() {
        playerHandler := PlayerHandler.PlayerHandler(playerStableData);
    };

    public shared ({ caller }) func setTeamsCanisterId(canisterId : Principal) : async Types.SetTeamsCanisterIdResult {
        if (not isLeague(caller)) {
            return #err(#notAuthorized);
        };
        teamsCanisterId := ?canisterId;
        #ok;
    };

    public shared ({ caller }) func addFluff(request : Types.CreatePlayerFluffRequest) : async Types.CreatePlayerFluffResult {
        if (not isLeague(caller)) {
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

    public shared ({ caller }) func populateTeamRoster(teamId : Nat) : async Types.PopulateTeamRosterResult {
        if (not isLeague(caller)) {
            return #err(#notAuthorized);
        };
        playerHandler.populateTeamRoster(teamId);
    };

    public shared ({ caller }) func applyEffects(request : Types.ApplyEffectsRequest) : async Types.ApplyEffectsResult {
        if (not isLeague(caller)) {
            return #err(#notAuthorized);
        };
        playerHandler.applyEffects(request);
    };

    public shared ({ caller }) func swapTeamPositions(
        teamId : Nat,
        position1 : FieldPosition.FieldPosition,
        position2 : FieldPosition.FieldPosition,
    ) : async Types.SwapPlayerPositionsResult {
        if (teamsCanisterId == null) {
            Debug.trap("Teams canister ID is not set");
        };
        if (?caller != teamsCanisterId and not isLeague(caller)) {
            return #err(#notAuthorized);
        };
        playerHandler.swapTeamPositions(teamId, position1, position2);
    };

    public shared ({ caller }) func addMatchStats(matchGroupId : Nat, playerStats : [Player.PlayerMatchStatsWithId]) : async Types.AddMatchStatsResult {
        if (not isLeague(caller)) {
            return #err(#notAuthorized);
        };

        let matchGroupKey = {
            key = matchGroupId;
            hash = Nat32.fromNat(matchGroupId); // TODO
        };
        for (playerStat in Iter.fromArray(playerStats)) {
            let playerKey = {
                key = playerStat.playerId;
                hash = playerStat.playerId;
            };
            let playerMatchGroupStats = switch (Trie.get(stats, playerKey, Nat32.equal)) {
                case (null) Trie.empty<Nat, Player.PlayerMatchStats>();
                case (?p) p;
            };

            let (newPlayerMatchGroupStats, oldPlayerStat) = Trie.put(playerMatchGroupStats, matchGroupKey, Nat.equal, playerStat);
            if (oldPlayerStat != null) {
                Debug.trap("Player match stats already exist for match group: " # Nat.toText(matchGroupId) # " and player: " # Nat32.toText(playerStat.playerId));
            };
            let (newStats, _) = Trie.put(stats, playerKey, Nat32.equal, newPlayerMatchGroupStats);
            stats := newStats;
        };
        #ok;
    };

    public shared ({ caller }) func onSeasonEnd() : async Types.OnSeasonEndResult {
        if (not isLeague(caller)) {
            return #err(#notAuthorized);
        };
        // TODO archive?
        stats := Trie.empty<Nat32, Trie.Trie<Nat, Player.PlayerMatchStats>>();
        #ok;
    };

    private func isLeague(_ : Principal) : Bool {
        // TODO
        // caller == Principal.fromActor(LeagueActor);
        true;
    };
};
