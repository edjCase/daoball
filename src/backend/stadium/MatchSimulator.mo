import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Nat32 "mo:base/Nat32";
import Stadium "../Stadium";
import Player "../Player";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Random "mo:base/Random";
import Int "mo:base/Int";
import Int32 "mo:base/Int32";
import Prelude "mo:base/Prelude";
import Nat8 "mo:base/Nat8";
import Rng "../Rng";

module {
    type PlayerState = Stadium.PlayerState;
    type Event = Stadium.Event;
    type BaseInfo = Stadium.BaseInfo;
    type MatchState = Stadium.MatchState;
    type TeamState = Stadium.TeamState;
    type TeamLineup = Stadium.TeamLineup;
    type InProgressMatchState = Stadium.InProgressMatchState;
    type PlayerWithId = Player.PlayerWithId;
    type FieldPosition = Player.FieldPosition;
    type Base = Player.Base;
    type TeamId = Stadium.TeamId;
    type TeamSide = Stadium.TeamSide;
    type PlayerSkills = Player.PlayerSkills;

    type MutableTeamState = {
        id : Principal;
        name : Text;
        var score : Int;
        var battingOrder : Buffer.Buffer<FieldPosition>;
        var positions : Trie.Trie<FieldPosition, Nat32>;
        var substitutes : Buffer.Buffer<Nat32>;
        var currentBatter : FieldPosition;
    };

    type MutableMatchState = {
        var offenseTeamId : TeamId;
        var team1 : MutableTeamState;
        var team2 : MutableTeamState;
        var players : Trie.Trie<Nat32, MutablePlayerState>;
        var events : Buffer.Buffer<Event>;
        var bases : Trie.Trie<Base, Nat32>;
        var round : Nat;
        var outs : Nat;
        var strikes : Nat;
    };

    type MutablePlayerSkills = {
        var batting : Int;
        var throwing : Int;
        var catching : Int;
    };

    type MutablePlayerState = {
        var name : Text;
        var teamId : TeamId;
        var energy : Int;
        var condition : Player.PlayerCondition;
        var skills : MutablePlayerSkills;
        var preferredPosition : FieldPosition;
    };

    type HitLocation = {
        #outOfPark;
        #firstBase;
        #secondBase;
        #thirdBase;
        #shortStop;
        #pitcher;
        #leftField;
        #centerField;
        #rightField;
    };

    public type TeamInitData = {
        id : Principal;
        name : Text;
        lineup : ?TeamLineup;
        players : [PlayerWithId];
    };

    public func initState(team1 : TeamInitData, team2 : TeamInitData, team1StartOffense : Bool) : MatchState {

        let (team1Lineup, team2Lineup) : (TeamLineup, TeamLineup) = switch (team1.lineup, team2.lineup) {
            case (null, null) return #completed(#allAbsent);
            case (null, ?_) return #completed(#absentTeam(#team1));
            case (?_, null) return #completed(#absentTeam(#team2));
            case (?team1Lineup, ?team2Lineup)(team1Lineup, team2Lineup);
        };
        var players = Trie.empty<Nat32, PlayerState>();
        let addPlayer = func(player : PlayerWithId, teamId : TeamId) {
            let playerState : PlayerState = {
                name = player.name;
                teamId = teamId;
                energy = player.energy;
                condition = player.condition;
                skills = player.skills;
                preferredPosition = player.position;
            };
            let key = {
                key = player.id;
                hash = player.id;
            };
            let (newPlayers, _) = Trie.put<Nat32, PlayerState>(players, key, Nat32.equal, playerState);
            players := newPlayers;
        };
        for (player in team1.players.vals()) {
            addPlayer(player, #team1);
        };
        for (player in team2.players.vals()) {
            addPlayer(player, #team2);
        };
        let defenseLineup = if (team1StartOffense) team2Lineup else team1Lineup;
        let initTeamState = func(id : Principal, name : Text, lineup : TeamLineup) : TeamState {
            {
                id = id;
                name = name;
                score = 0;
                battingOrder = lineup.battingOrder;
                currentBatter = lineup.battingOrder.get(0);
                substitutes = lineup.substitutes;
                positions = lineup.starters;
            };
        };
        #inProgress({
            offenseTeamId = if (team1StartOffense) #team1 else #team2;
            team1 = initTeamState(team1.id, team1.name, team1Lineup);
            team2 = initTeamState(team2.id, team2.name, team2Lineup);
            events = [];
            players = players;
            bases = Trie.empty();
            round = 0;
            outs = 0;
            strikes = 0;
        });
    };

    public func tick(state : InProgressMatchState, rng : Rng.Rng) : MatchState {
        let simulation = MatchSimulation(state, rng);

        pitch(simulation);

        simulation.buildState();
    };

    private func pitch(simulation : MatchSimulation) {
        let atBatPlayerId = switch (simulation.getPlayerAtBase(#homeBase)) {
            case (null) sendNextPlayerToBat(simulation);
            case (?playerId) playerId;
        };
        let atBatPlayer = simulation.getPlayer(atBatPlayerId);
        let pitcherId = switch (simulation.getPlayerWithPosition(#pitcher, #defense)) {
            case (null) Debug.trap("No pitcher found"); // TODO
            case (?playerId) playerId;
        };
        let pitcher = simulation.getPlayer(pitcherId);
        let pitchRoll = simulation.randomInt(0, 10) + pitcher.skills.throwing;
        let batterRoll = simulation.randomInt(0, 10) + atBatPlayer.skills.batting;
        let batterNetScore = batterRoll - pitchRoll;
        if (batterNetScore < 0) {
            simulation.addEvent({
                description = "Strike"; // TODO # Nat.toText(simulation.strike + 1);
                effect = #addStrike({
                    playerId = atBatPlayerId;
                });
            });
        } else {
            hit(simulation, atBatPlayerId, batterNetScore);
        };
    };

    private func hit(simulation : MatchSimulation, atBatPlayerId : Nat32, batterNetScore : Int) {
        let precisionRoll = simulation.randomInt(-2, 2) + batterNetScore;
        if (precisionRoll < 0) {
            simulation.addEvent({
                description = "Foul";
                effect = #none;
            });
        } else {
            let player = simulation.getPlayer(atBatPlayerId);
            let hitLocation = if (precisionRoll > 10) {
                simulation.addEvent({
                    description = player.name # " hits a homerun!";
                    effect = #none;
                });
                #outOfPark;
            } else {
                let (location, name) = switch (simulation.randomInt(0, 7)) {
                    case (0)(#firstBase, "first base");
                    case (1)(#secondBase, "second base");
                    case (2)(#thirdBase, "third base");
                    case (3)(#shortStop, "short stop");
                    case (4)(#pitcher, "pitcher");
                    case (5)(#leftField, "left field");
                    case (6)(#centerField, "center field");
                    case (7)(#rightField, "right field");
                    case (_) Prelude.unreachable();
                };
                simulation.addEvent({
                    description = player.name # " hits the ball to " # name;
                    effect = #none;
                });
                location;
            };
            run(simulation, atBatPlayerId, hitLocation);
        };
    };

    private func run(simulation : MatchSimulation, playerId : Nat32, hitLocation : HitLocation) {
        switch (hitLocation) {
            case (#outOfPark) {
                simulation.addEvent({
                    description = "Home run!";
                    effect = #none;
                });
            };
            case (#firstBase) tryCatch(simulation, playerId, #firstBase);
            case (#secondBase) tryCatch(simulation, playerId, #secondBase);
            case (#thirdBase) tryCatch(simulation, playerId, #thirdBase);
            case (#shortStop) tryCatch(simulation, playerId, #shortStop);
            case (#pitcher) tryCatch(simulation, playerId, #pitcher);
            case (#leftField) tryCatch(simulation, playerId, #leftField);
            case (#centerField) tryCatch(simulation, playerId, #centerField);
            case (#rightField) tryCatch(simulation, playerId, #rightField);
        };

    };

    private func tryCatch(simulation : MatchSimulation, battingPlayerId : Nat32, catchLocation : FieldPosition) {
        let catchingPlayerId = switch (simulation.getPlayerWithPosition(catchLocation, #defense)) {
            case (null) {
                // TODO handle someone from different location catching
                Debug.trap("No player found at " # Player.toTextFieldPosition(catchLocation));
            };
            case (?playerId) playerId;
        };
        let catchingPlayer = simulation.getPlayer(catchingPlayerId);
        let catchRoll = simulation.randomInt(-10, 10) + catchingPlayer.skills.catching;
        if (catchRoll <= 0) {
            simulation.addEvent({
                description = catchingPlayer.name # " misses the catch";
                effect = #none;
            });
            let canPickUpInTime = simulation.randomInt(0, 10) + catchingPlayer.skills.catching;
            if (canPickUpInTime > 0) {
                simulation.addEvent({
                    description = catchingPlayer.name # " picks up the ball";
                    effect = #none;
                });
                // TODO against dodge/speed skill of runner
                let throwRoll = simulation.randomInt(-10, 10) + catchingPlayer.skills.throwing;
                if (throwRoll <= 0) {
                    simulation.addEvent({
                        description = catchingPlayer.name # " misses the throw";
                        effect = #none;
                    });
                    simulation.addEvent({
                        description = "Runner is safe";
                        effect = #movePlayerToBase({
                            playerId = battingPlayerId;
                            base = ? #firstBase;
                        });
                    });
                } else {
                    simulation.addEvent({
                        description = catchingPlayer.name # " throws the ball and hits the player";
                        // TODO damage player?
                        effect = #addOut({
                            playerId = battingPlayerId;
                        });
                    });
                };
            } else {
                simulation.addEvent({
                    description = catchingPlayer.name # " cannot pick up the ball in time";
                    effect = #none;
                });
            };
        } else {
            simulation.addEvent({
                description = catchingPlayer.name # " catches the ball";
                effect = #addOut({
                    playerId = battingPlayerId;
                });
            });
        };
    };

    private func sendNextPlayerToBat(simulation : MatchSimulation) : Nat32 {
        let nextBatterPosition = simulation.incrementBattingOrder();
        let nextBatterId = switch (simulation.getPlayerWithPosition(nextBatterPosition, #offense)) {
            case (null) Debug.trap("No player found at " # Player.toTextFieldPosition(nextBatterPosition));
            case (?playerId) playerId;
        };
        let nextBatter = simulation.getPlayer(nextBatterId);
        simulation.addEvent({
            description = nextBatter.name # " is up to bat";
            effect = #movePlayerToBase({
                playerId = nextBatterId;
                base = ? #homeBase;
            });
        });
        nextBatterId;
    };
    // TODO handle limited entropy from random by refetching entropy from the chain
    class MatchSimulation(initialState : InProgressMatchState, rng : Rng.Rng) {

        private func toMutableSkills(skills : PlayerSkills) : MutablePlayerSkills {
            {
                var batting = skills.batting;
                var throwing = skills.throwing;
                var catching = skills.catching;
            };
        };

        private func toMutableState(state : InProgressMatchState) : MutableMatchState {
            let mutablePlayers = Trie.mapFilter(
                state.players,
                func(id : Nat32, player : PlayerState) : ?MutablePlayerState {
                    ?{
                        var name = player.name;
                        var teamId = player.teamId;
                        var energy = player.energy;
                        var condition = player.condition;
                        var skills = toMutableSkills(player.skills);
                        var preferredPosition = player.preferredPosition;
                    };
                },
            );
            {
                var offenseTeamId = state.offenseTeamId;
                var team1 = toMutableTeam(initialState.team1);
                var team2 = toMutableTeam(initialState.team2);
                var players = mutablePlayers;
                var events = Buffer.fromArray(initialState.events);
                var bases = initialState.bases;
                var round = initialState.round;
                var outs = initialState.outs;
                var strikes = initialState.strikes;
            };
        };

        private func toMutableTeam(team : TeamState) : MutableTeamState {
            {
                id = team.id;
                name = team.name;
                var score = team.score;
                var battingOrder = Buffer.fromArray(team.battingOrder);
                var currentBatter = team.currentBatter;
                var substitutes = Buffer.fromArray(team.substitutes);
                var positions = team.positions;
            };
        };

        let state : MutableMatchState = toMutableState(initialState);

        public func buildState() : MatchState {
            let players = Trie.mapFilter(
                state.players,
                func(id : Nat32, player : MutablePlayerState) : ?PlayerState {
                    ?{
                        name = player.name;
                        teamId = player.teamId;
                        energy = player.energy;
                        condition = player.condition;
                        preferredPosition = player.preferredPosition;
                        skills = {
                            batting = player.skills.batting;
                            throwing = player.skills.throwing;
                            catching = player.skills.catching;
                        };
                    };
                },
            );
            let buildTeam = func(team : MutableTeamState) : TeamState {
                {
                    id = team.id;
                    name = team.name;
                    score = team.score;
                    battingOrder = Buffer.toArray(team.battingOrder);
                    currentBatter = team.currentBatter;
                    substitutes = Buffer.toArray(team.substitutes);
                    positions = team.positions;
                };
            };
            if (state.round > 10) {
                return #completed(
                    #gameResult({
                        team1 = buildTeam(state.team1);
                        team2 = buildTeam(state.team2);
                        events = Buffer.toArray(state.events);
                        players = players;
                        winner = if (state.team1.score > state.team2.score) #team1 else #team2;
                    })
                );
            };
            #inProgress({
                offenseTeamId = state.offenseTeamId;
                team1 = buildTeam(state.team1);
                team2 = buildTeam(state.team2);
                events = Buffer.toArray(state.events);
                players = players;
                bases = state.bases;
                round = state.round;
                outs = state.outs;
                strikes = state.strikes;
            });
        };

        public func randomInt(min : Int, max : Int) : Int {
            rng.randomInt(min, max);
        };

        public func getPlayerWithPosition(position : FieldPosition, side : TeamSide) : ?Nat32 {
            let key : Trie.Key<FieldPosition> = {
                key = position;
                hash = Player.hashFieldPosition(position);
            };
            let team = switch (side) {
                case (#offense) getOffenseTeam();
                case (#defense) getDefenseTeam();
            };
            Trie.get(team.positions, key, Player.equalFieldPosition);
        };

        public func getPlayerAtBase(base : Base) : ?Nat32 {
            let key : Trie.Key<Base> = {
                key = base;
                hash = Player.hashBase(base);
            };
            Trie.get(state.bases, key, Player.equalBase);
        };

        public func incrementBattingOrder() : FieldPosition {
            let team = switch (state.offenseTeamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
            var i = 0;
            label l loop {
                let position = team.battingOrder.get(i);
                if (position == team.currentBatter) {
                    break l;
                };
                i += 1;
            };
            let nextBatterIndex = i + 1;
            let nextBatter = if (nextBatterIndex >= team.battingOrder.size()) {
                // Loop back to first batter
                team.battingOrder.get(0);
            } else {
                team.battingOrder.get(nextBatterIndex);
            };
            team.currentBatter := nextBatter;
            nextBatter;
        };

        public func getPlayer(playerId : Nat32) : MutablePlayerState {
            let key = {
                key = playerId;
                hash = playerId;
            };
            let ?player = Trie.get(state.players, key, Nat32.equal) else Debug.trap("Player not found: " # Nat32.toText(playerId));
            player;
        };

        public func addEvent(event : Event) : () {
            state.events.add(event);
            switch (event.effect) {
                case (#subPlayer({ playerOutId })) {
                    let playerOut = getPlayer(playerOutId);
                    let team = switch (playerOut.teamId) {
                        case (#team1) state.team1;
                        case (#team2) state.team2;
                    };
                    let fieldPosition = playerOut.preferredPosition; // TODO not always true

                    // TODO improve sub logic such as dedicated field positions
                    // Swap sub for player, if any left
                    switch (team.substitutes.removeLast()) {
                        case (null) {
                            addEvent({
                                description = playerOut.name # " cannot be subbed out because there is no substitute available";
                                effect = #none;
                            });
                        };
                        case (?subPlayerId) {
                            // Swap the players in the batting order
                            let key = {
                                key = fieldPosition;
                                hash = Player.hashFieldPosition(fieldPosition);
                            };
                            let (newPositions, _) = Trie.put(team.positions, key, Player.equalFieldPosition, subPlayerId);
                            team.positions := newPositions;
                        };
                    };

                };
                case (#increaseScore({ teamId; amount })) {
                    let team = switch (teamId) {
                        case (#team1) state.team1;
                        case (#team2) state.team2;
                    };
                    team.score := team.score + amount;
                };
                case (#setPlayerCondition({ playerId; condition })) {
                    let player = getPlayer(playerId);
                    player.condition := condition;
                    let substituteOut = switch (condition) {
                        case (#ok) false;
                        case (#injured(i)) true;
                        case (#dead) true;
                    };
                    if (substituteOut) {
                        addEvent({
                            description = player.name # " has been substituted out due to condition";
                            effect = #subPlayer({
                                playerOutId = playerId;
                            });
                        });
                    };
                };
                case (#increaseEnergy({ playerId; amount })) {
                    let player = getPlayer(playerId);
                    player.energy := player.energy + amount;
                    if (player.energy <= 0) {
                        addEvent({
                            description = player.name # " has run out of energy and needs to be substituted out";
                            effect = #subPlayer({
                                playerOutId = playerId;
                            });
                        });
                    };
                };
                case (#movePlayerToBase({ playerId; base })) {
                    // TODO what if other player is already at that position?

                    // Remove player from previous base
                    for ((base, playerIdOnBase) in Trie.iter(state.bases)) {
                        if (playerIdOnBase == playerId) {
                            let key = {
                                key = base;
                                hash = Player.hashBase(base);
                            };
                            let (newBases, _) = Trie.replace(state.bases, key, Player.equalBase, null);
                            state.bases := newBases;
                        };
                    };

                    if (base == ? #homeBase) {
                        // Score
                        addEvent({
                            description = getPlayer(playerId).name # " scores";
                            effect = #increaseScore({
                                teamId = getPlayer(playerId).teamId;
                                amount = 1;
                            });
                        });
                        return;
                    };

                    switch (base) {
                        case (null) {};
                        case (?base) {
                            let key = {
                                key = base;
                                hash = Player.hashBase(base);
                            };
                            let playerIdOnBase = Trie.get(state.bases, key, Player.equalBase);
                            switch (playerIdOnBase) {
                                case (null) {
                                    // Skip, no one on destination base
                                };
                                case (?playerIdOnBase) {
                                    // TODO does this work well enough?
                                    // Have player on the destination base go to next base before this player can go there
                                    let nextBase = switch (base) {
                                        case (#homeBase) #firstBase;
                                        case (#firstBase) #secondBase;
                                        case (#secondBase) #thirdBase;
                                        case (#thirdBase) #homeBase;
                                    };
                                    addEvent({
                                        description = getPlayer(playerIdOnBase).name # " is forced to run to " # Player.toTextBase(nextBase);
                                        effect = #movePlayerToBase({
                                            playerId = playerIdOnBase;
                                            base = ?nextBase;
                                        });
                                    });

                                };
                            };
                            // Update bases
                            let (newBases, _) = Trie.put(state.bases, key, Player.equalBase, playerId);
                            state.bases := newBases;
                        };
                    };

                };
                case (#addStrike({ playerId })) {
                    state.strikes += 1;
                    if (state.strikes >= 3) {
                        addEvent({
                            description = "Strikeout";
                            effect = #addOut({
                                playerId = playerId;
                            });
                        });
                    };
                };
                case (#addOut({ playerId })) {
                    state.outs += 1;
                    addEvent({
                        description = "Out"; // TODO
                        effect = #movePlayerToBase({
                            playerId = playerId;
                            base = null;
                        });
                    });
                    if (state.outs >= 3) {
                        addEvent({
                            description = "Round over";
                            effect = #endRound;
                        });
                    };
                };
                case (#endRound) {
                    state.outs := 0;
                    state.round += 1;
                    let (newOffenseTeamId, newDefenseTeamId) = switch (state.offenseTeamId) {
                        case (#team1)(#team2, #team1);
                        case (#team2)(#team1, #team2);
                    };
                    state.offenseTeamId := newOffenseTeamId;
                };
                case (#none) {
                    // Skip
                };
            };
        };

        private func getOffenseTeam() : MutableTeamState {
            switch (state.offenseTeamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
        };

        private func getDefenseTeam() : MutableTeamState {
            switch (state.offenseTeamId) {
                case (#team1) state.team2;
                case (#team2) state.team1;
            };
        };

        private func getTeam(teamId : TeamId) : MutableTeamState {
            switch (teamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
        };

    };
};
