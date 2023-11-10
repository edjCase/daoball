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
import Iter "mo:base/Iter";
import TrieMap "mo:base/TrieMap";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Order "mo:base/Order";
import RandomX "mo:random/RandomX";
import PseudoRandomX "mo:random/PseudoRandomX";
import StadiumUtil "StadiumUtil";
import IterTools "mo:itertools/Iter";
import Team "../Team";

module {
    type PlayerState = Stadium.PlayerState;
    type LogEntry = Stadium.LogEntry;
    type StartedMatchState = Stadium.StartedMatchState;
    type TeamState = Stadium.TeamState;
    type MatchOptions = Stadium.MatchOptions;
    type InProgressMatchState = Stadium.InProgressMatchState;
    type PlayerWithId = Player.PlayerWithId;
    type FieldPosition = Player.FieldPosition;
    type Base = Player.Base;
    type TeamId = Stadium.TeamId;
    type PlayerSkills = Player.PlayerSkills;
    type PlayerId = Nat32;
    type Prng = PseudoRandomX.PseudoRandomGenerator;
    type MatchAura = Stadium.MatchAura;
    type Offering = Stadium.Offering;

    public type TeamInfo = {
        id : Principal;
        name : Text;
        players : [Stadium.MatchPlayer];
    };

    type SimulationResult = {
        #endMatch : Stadium.CompletedMatchState;
        #inProgress;
    };

    type MutableTeamState = {
        var score : Int;
        offering : Offering;
        championId : PlayerId;
    };

    type MutableDefenseFieldState = {
        var firstBase : PlayerId;
        var secondBase : PlayerId;
        var thirdBase : PlayerId;
        var shortStop : PlayerId;
        var pitcher : PlayerId;
        var leftField : PlayerId;
        var centerField : PlayerId;
        var rightField : PlayerId;
    };

    type MutableOffenseFieldState = {
        var atBat : PlayerId;
        var firstBase : ?PlayerId;
        var secondBase : ?PlayerId;
        var thirdBase : ?PlayerId;
    };

    type MutableFieldState = {
        var offense : MutableOffenseFieldState;
        var defense : MutableDefenseFieldState;
    };

    type MutableMatchState = {
        var offenseTeamId : TeamId;
        var team1 : MutableTeamState;
        var team2 : MutableTeamState;
        aura : MatchAura;
        var players : TrieMap.TrieMap<PlayerId, MutablePlayerState>;
        var log : Buffer.Buffer<LogEntry>;
        var field : MutableFieldState;
        var round : Nat;
        var outs : Nat;
        var strikes : Nat;
    };

    type MutablePlayerSkills = {
        var battingPower : Int;
        var battingAccuracy : Int;
        var throwingAccuracy : Int;
        var throwingPower : Int;
        var catching : Int;
        var defense : Int;
        var piety : Int;
        var speed : Int;
    };

    type MutablePlayerState = {
        var teamId : TeamId;
        var condition : Player.PlayerCondition;
        var skills : MutablePlayerSkills;
        var position : FieldPosition;
    };

    public type TeamInitData = {
        id : Principal;
        name : Text;
        offering : Offering;
        championId : PlayerId;
        players : [PlayerWithId];
    };

    public func initState(
        aura : MatchAura,
        team1 : TeamInitData,
        team2 : TeamInitData,
        team1StartOffense : Bool,
        prng : Prng,
    ) : InProgressMatchState {
        let eventLog = Buffer.Buffer<LogEntry>(0);
        logTeamOffering(team1, eventLog);
        logTeamOffering(team2, eventLog);
        logMatchAura(aura, eventLog);
        let (team1State, team1Players) = buildTeamState(team1, #team1, prng);
        let (team2State, team2Players) = buildTeamState(team2, #team2, prng);
        let (offensePlayers, defensePlayers) = if (team1StartOffense) {
            (team1Players, team2Players);
        } else {
            (team2Players, team1Players);
        };
        let ?offense = buildStartingOffense(offensePlayers, prng) else Debug.trap("Not enough offense players to start match"); // TODO trap?
        let ?defense = buildStartingDefense(defensePlayers, prng) else Debug.trap("Not enough defense players to start match"); // TODO trap?

        let players = Buffer.merge(
            team1Players,
            team2Players,
            func(
                p1 : Stadium.PlayerStateWithId,
                p2 : Stadium.PlayerStateWithId,
            ) : Order.Order = Nat32.compare(p1.id, p2.id),
        );
        {
            offenseTeamId = if (team1StartOffense) #team1 else #team2;
            team1 = team1State;
            team2 = team2State;
            aura = aura;
            log = Buffer.toArray(eventLog);
            players = Buffer.toArray(players);
            batter = null;
            field = {
                offense = offense;
                defense = defense;
            };
            round = 0;
            outs = 0;
            strikes = 0;
        };
    };

    private func logTeamOffering(team : TeamInitData, eventLog : Buffer.Buffer<LogEntry>) {
        let offeringMetaData = Stadium.getOfferingMetaData(team.offering);
        eventLog.add({
            description = "Team " # team.name # " Offering: " # offeringMetaData.description;
            isImportant = true;
        });
    };

    private func logMatchAura(aura : MatchAura, eventLog : Buffer.Buffer<LogEntry>) {
        let auraMetaData = Stadium.getMatchAuraMetaData(aura);
        eventLog.add({
            description = "Match Aura: " # auraMetaData.description;
            isImportant = true;
        });
    };

    private func buildTeamState(
        team : TeamInitData,
        teamId : TeamId,
        prng : Prng,
    ) : (TeamState, Buffer.Buffer<Stadium.PlayerStateWithId>) {

        var playerStates = team.players
        |> Iter.fromArray(_)
        |> Iter.map(
            _,
            func(player : PlayerWithId) : Stadium.PlayerStateWithId = {
                id = player.id;
                name = player.name;
                teamId = teamId;
                condition = #ok;
                skills = player.skills;
                position = player.position;
            },
        )
        |> Buffer.fromIter<Stadium.PlayerStateWithId>(_);

        let teamState = {
            id = team.id;
            name = team.name;
            score = 0;
            offering = team.offering;
            championId = team.championId;
        };

        switch (team.offering) {
            case (#shuffleAndBoost) {
                // Shuffle all the players' positions but boost their stats
                let currentPositions : Buffer.Buffer<FieldPosition> = playerStates
                |> Buffer.map(
                    _,
                    func(p : Stadium.PlayerStateWithId) : FieldPosition = p.position,
                );
                prng.shuffleBuffer(currentPositions);
                for (i in IterTools.range(0, playerStates.size())) {
                    let currentPlayerState = playerStates.get(i);
                    let updatedPlayerState = {
                        currentPlayerState with
                        position = currentPositions.get(i);
                        skills = {
                            // TODO how much to boost skills
                            battingPower = currentPlayerState.skills.battingPower + 1;
                            battingAccuracy = currentPlayerState.skills.battingAccuracy + 1;
                            throwingPower = currentPlayerState.skills.throwingPower + 1;
                            throwingAccuracy = currentPlayerState.skills.throwingAccuracy + 1;
                            catching = currentPlayerState.skills.catching + 1;
                            defense = currentPlayerState.skills.defense + 1;
                            piety = currentPlayerState.skills.piety + 1;
                            speed = currentPlayerState.skills.speed + 1;
                        };
                    };
                    playerStates.put(i, updatedPlayerState);
                };
            };
        };

        (teamState, playerStates);
    };

    private func buildPlayerState(player : PlayerWithId, teamId : TeamId) : Stadium.PlayerStateWithId {
        {
            id = player.id;
            name = player.name;
            teamId = teamId;
            condition = #ok;
            skills = player.skills;
            position = player.position;
        };
    };

    private func buildStartingOffense(players : Buffer.Buffer<Stadium.PlayerStateWithId>, prng : Prng) : ?Stadium.OffenseFieldState {
        if (players.size() < 1) {
            return null;
        };
        let randomIndex = prng.nextNat(0, players.size() - 1);
        let atBatPlayer = players.get(randomIndex);
        ?{
            atBat = atBatPlayer.id;
            firstBase = null;
            secondBase = null;
            thirdBase = null;
        };
    };

    private func buildStartingDefense(players : Buffer.Buffer<Stadium.PlayerStateWithId>, prng : Prng) : ?Stadium.DefenseFieldState {
        let getRandomPlayer = func(position : FieldPosition) : ?PlayerId {
            let playersWithPosition = Buffer.mapFilter<Stadium.PlayerStateWithId, Stadium.PlayerStateWithId>(
                players,
                func(p : Stadium.PlayerStateWithId) : ?Stadium.PlayerStateWithId {
                    if (p.position != position) null else ?p;
                },
            );
            if (playersWithPosition.size() < 1) {
                return null;
            };
            let index = prng.nextNat(0, playersWithPosition.size() - 1);
            ?playersWithPosition.get(index).id;
        };

        do ? {
            {
                firstBase = getRandomPlayer(#firstBase)!;
                secondBase = getRandomPlayer(#secondBase)!;
                thirdBase = getRandomPlayer(#thirdBase)!;
                shortStop = getRandomPlayer(#shortStop)!;
                pitcher = getRandomPlayer(#pitcher)!;
                leftField = getRandomPlayer(#leftField)!;
                centerField = getRandomPlayer(#centerField)!;
                rightField = getRandomPlayer(#rightField)!;
            };
        };
    };

    private func normalizeVotes(votes : Trie.Trie<MatchAura, Nat>) : Trie.Trie<MatchAura, Float> {
        var totalVotes = 0;
        for ((id, voteCount) in Trie.iter(votes)) {
            totalVotes += voteCount;
        };
        if (totalVotes == 0) {
            return Trie.empty();
        };
        Trie.mapFilter<MatchAura, Nat, Float>(
            votes,
            func(voteCount : (MatchAura, Nat)) : ?Float = ?(Float.fromInt(voteCount.1) / Float.fromInt(totalVotes)),
        );
    };

    public func tick(team1 : TeamInfo, team2 : TeamInfo, state : InProgressMatchState, random : Prng) : Stadium.StartedMatchState {
        let simulation = MatchSimulation(team1, team2, state, random);
        simulation.tick();
    };

    private func toMutableSkills(skills : PlayerSkills) : MutablePlayerSkills {
        {
            var battingPower = skills.battingPower;
            var battingAccuracy = skills.battingAccuracy;
            var throwingPower = skills.throwingPower;
            var throwingAccuracy = skills.throwingAccuracy;
            var catching = skills.catching;
            var defense = skills.defense;
            var piety = skills.piety;
            var speed = skills.speed;
        };
    };

    private func toMutableState(state : InProgressMatchState) : MutableMatchState {
        let players = state.players.vals()
        |> Iter.map<Stadium.PlayerStateWithId, (Nat32, MutablePlayerState)>(
            _,
            func(player : Stadium.PlayerStateWithId) : (Nat32, MutablePlayerState) {
                let state = {
                    var teamId = player.teamId;
                    var condition = player.condition;
                    var skills = toMutableSkills(player.skills);
                    var position = player.position;
                };
                (player.id, state);
            },
        )
        |> TrieMap.fromEntries<Nat32, MutablePlayerState>(_, Nat32.equal, func(h : Nat32) : Nat32 = h);

        let field = {
            var offense = {
                var atBat = state.field.offense.atBat;
                var firstBase = state.field.offense.firstBase;
                var secondBase = state.field.offense.secondBase;
                var thirdBase = state.field.offense.thirdBase;
            };
            var defense = {
                var firstBase = state.field.defense.firstBase;
                var secondBase = state.field.defense.secondBase;
                var thirdBase = state.field.defense.thirdBase;
                var shortStop = state.field.defense.shortStop;
                var pitcher = state.field.defense.pitcher;
                var leftField = state.field.defense.leftField;
                var centerField = state.field.defense.centerField;
                var rightField = state.field.defense.rightField;
            };
        };
        let log = Buffer.fromArray<LogEntry>(state.log);
        {
            var offenseTeamId = state.offenseTeamId;
            var team1 = toMutableTeam(state.team1);
            var team2 = toMutableTeam(state.team2);
            var players = players;
            aura = state.aura;
            var field = field;
            var log = log;
            var round = state.round;
            var outs = state.outs;
            var strikes = state.strikes;
        };
    };

    private func toMutableTeam(team : TeamState) : MutableTeamState {
        {
            var score = team.score;
            offering = team.offering;
            championId = team.championId;
        };
    };

    class MatchSimulation(team1 : TeamInfo, team2 : TeamInfo, initialState : InProgressMatchState, prng : Prng) {

        let state : MutableMatchState = toMutableState(initialState);

        public func tick() : Stadium.StartedMatchState {
            let divineInterventionRoll = if (state.aura == #moreBlessingsAndCurses) {
                prng.nextNat(0, 99);
            } else {
                prng.nextNat(0, 999);
            };
            let result = if (divineInterventionRoll <= 9) {
                state.log.add({
                    description = "Divine intervention!";
                    isImportant = true;
                });
                let ?randomPlayerId = getRandomAvailablePlayer(null, null, false) else Prelude.unreachable();
                blessOrCursePlayer(randomPlayerId);
            } else {
                pitch();
            };
            buildState(result);
        };

        private func getPlayerAtPosition(catchLocation : FieldPosition) : PlayerId {
            switch (catchLocation) {
                case (#firstBase) state.field.defense.firstBase;
                case (#secondBase) state.field.defense.secondBase;
                case (#thirdBase) state.field.defense.thirdBase;
                case (#shortStop) state.field.defense.shortStop;
                case (#pitcher) state.field.defense.pitcher;
                case (#leftField) state.field.defense.leftField;
                case (#centerField) state.field.defense.centerField;
                case (#rightField) state.field.defense.rightField;
            };
        };

        public func buildState(result : SimulationResult) : Stadium.StartedMatchState {
            switch (result) {
                case (#inProgress) {};
                case (#endMatch(s)) return #completed(s);
            };

            let players = Iter.toArray(
                Iter.map(
                    state.players.entries(),
                    func(player : (Nat32, MutablePlayerState)) : Stadium.PlayerStateWithId {
                        {
                            id = player.0;
                            teamId = player.1.teamId;
                            condition = player.1.condition;
                            position = player.1.position;
                            skills = {
                                battingPower = player.1.skills.battingPower;
                                battingAccuracy = player.1.skills.battingAccuracy;
                                throwingPower = player.1.skills.throwingPower;
                                throwingAccuracy = player.1.skills.throwingAccuracy;
                                catching = player.1.skills.catching;
                                defense = player.1.skills.defense;
                                piety = player.1.skills.piety;
                                speed = player.1.skills.speed;
                            };
                        };
                    },
                )
            );

            let field = {
                offense = {
                    atBat = state.field.offense.atBat;
                    firstBase = state.field.offense.firstBase;
                    secondBase = state.field.offense.secondBase;
                    thirdBase = state.field.offense.thirdBase;
                };
                defense = {
                    firstBase = state.field.defense.firstBase;
                    secondBase = state.field.defense.secondBase;
                    thirdBase = state.field.defense.thirdBase;
                    shortStop = state.field.defense.shortStop;
                    pitcher = state.field.defense.pitcher;
                    leftField = state.field.defense.leftField;
                    centerField = state.field.defense.centerField;
                    rightField = state.field.defense.rightField;
                };
            };

            let buildTeam = func(team : MutableTeamState) : TeamState {
                {
                    score = team.score;
                    offering = team.offering;
                    championId = team.championId;
                };
            };
            let log : [LogEntry] = Buffer.toArray(state.log);
            #inProgress({
                currentSeed = prng.getCurrentSeed();
                offenseTeamId = state.offenseTeamId;
                team1 = buildTeam(state.team1);
                team2 = buildTeam(state.team2);
                aura = state.aura;
                log = log;
                players = players;
                field = field;
                round = state.round;
                outs = state.outs;
                strikes = state.strikes;
            });
        };

        private func getRandomAvailablePlayer(teamId : ?TeamId, position : ?FieldPosition, notOnField : Bool) : ?PlayerId {
            // get random player
            let availablePlayers = getAvailablePlayers(teamId, position, notOnField);
            if (availablePlayers.size() < 1) {
                return null;
            };
            let randomIndex = prng.nextNat(0, availablePlayers.size() - 1);
            ?availablePlayers.get(randomIndex);

        };

        private func getAvailablePlayers(teamId : ?TeamId, position : ?FieldPosition, notOnField : Bool) : Buffer.Buffer<PlayerId> {

            var playersIter : Iter.Iter<(PlayerId, MutablePlayerState)> = state.players.entries()
            // Only good condition players
            |> Iter.filter(_, func(p : (PlayerId, MutablePlayerState)) : Bool = p.1.condition == #ok);
            if (notOnField) {
                // Only players not on the field
                playersIter := Iter.filter(
                    playersIter,
                    func(p : (PlayerId, MutablePlayerState)) : Bool {
                        getDefensePositionOfPlayer(p.0) == null and getBaseOfPlayer(p.0) == null;
                    },
                );
            };

            switch (teamId) {
                case (null) {};
                case (?t) {
                    // Only players on the specified team
                    playersIter := Iter.filter(playersIter, func(p : (PlayerId, MutablePlayerState)) : Bool = p.1.teamId == t);
                };
            };
            switch (position) {
                case (null) {};
                case (?po) {
                    // Only players assigned to a certain position
                    playersIter := Iter.filter(playersIter, func(p : (PlayerId, MutablePlayerState)) : Bool = p.1.position == po);
                };
            };
            playersIter
            |> Iter.map(_, func(p : (PlayerId, MutablePlayerState)) : PlayerId = p.0)
            |> Buffer.fromIter(_);
        };

        private func getPlayer(teamId : TeamId, playerId : PlayerId) : {
            #ok : Stadium.MatchPlayer;
            #playerNotFound : Stadium.PlayerNotFoundError;
        } {
            let team = getTeamInfo(teamId);
            let ?player = Array.find(
                team.players,
                func(p : Stadium.MatchPlayer) : Bool = p.id == playerId,
            ) else return #playerNotFound({
                id = playerId;
                teamId = ?teamId;
            });
            #ok(player);
        };

        private func getPlayerState(playerId : PlayerId) : {
            #ok : MutablePlayerState;
            #playerNotFound : Stadium.PlayerNotFoundError;
        } {
            let ?player = state.players.get(playerId) else return #playerNotFound({
                id = playerId;
                teamId = null;
            });
            #ok(player);
        };

        private func getDefensePositionOfPlayer(playerId : PlayerId) : ?FieldPosition {
            if (state.field.defense.firstBase == playerId) {
                return ? #firstBase;
            };
            if (state.field.defense.secondBase == playerId) {
                return ? #secondBase;
            };
            if (state.field.defense.thirdBase == playerId) {
                return ? #thirdBase;
            };
            if (state.field.defense.shortStop == playerId) {
                return ? #shortStop;
            };
            if (state.field.defense.pitcher == playerId) {
                return ? #pitcher;
            };
            if (state.field.defense.leftField == playerId) {
                return ? #leftField;
            };
            if (state.field.defense.centerField == playerId) {
                return ? #centerField;
            };
            if (state.field.defense.rightField == playerId) {
                return ? #rightField;
            };
            null;
        };

        private func getBaseOfPlayer(playerId : PlayerId) : ?Base {
            if (state.field.offense.firstBase == ?playerId) {
                return ? #firstBase;
            };
            if (state.field.offense.secondBase == ?playerId) {
                return ? #secondBase;
            };
            if (state.field.offense.thirdBase == ?playerId) {
                return ? #thirdBase;
            };
            if (state.field.offense.atBat == playerId) {
                return ? #homeBase;
            };
            null;
        };

        private func getPlayerAtBase(base : Base) : {
            #ok : ?MutablePlayerState;
            #playerNotFound : Stadium.PlayerNotFoundError;
        } {
            let playerId = switch (base) {
                case (#firstBase) state.field.offense.firstBase;
                case (#secondBase) state.field.offense.secondBase;
                case (#thirdBase) state.field.offense.thirdBase;
                case (#homeBase) ?state.field.offense.atBat;
            };
            switch (playerId) {
                case (null) #ok(null);
                case (?pId) switch (getPlayerState(pId)) {
                    case (#ok(p)) #ok(?p);
                    case (#playerNotFound(e)) #playerNotFound(e);
                };
            };
        };

        private func pitch() : SimulationResult {
            let pitcherState = switch (getPlayerState(state.field.defense.pitcher)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            let pitchRoll = prng.nextNat(0, 10) + pitcherState.skills.throwingAccuracy + pitcherState.skills.throwingPower;

            state.log.add({
                description = "Pitch";
                isImportant = false;
            });
            let atBatPlayerState = switch (getPlayerState(state.field.offense.atBat)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            let batterRoll = prng.nextInt(0, 20) + atBatPlayerState.skills.battingAccuracy + atBatPlayerState.skills.battingPower;
            let batterNetScore = batterRoll - pitchRoll;
            if (batterNetScore <= 0) {
                strike();
            } else {
                hit({ hitRoll = Int.abs(batterNetScore) });
            };
        };

        private func foul() : SimulationResult {
            state.log.add({
                description = "Foul ball";
                isImportant = true;
            });
            #inProgress;
        };

        private func hit({ hitRoll : Nat }) : SimulationResult {
            state.log.add({
                description = "Its a hit!";
                isImportant = true;
            });
            let precisionRoll = prng.nextInt(-2, 2) + hitRoll;
            if (precisionRoll < 0) {
                return foul();
            };
            let player = getPlayer(state.offenseTeamId, state.field.offense.atBat);
            if (precisionRoll > 10) {
                state.log.add({
                    description = "Homerun!";
                    isImportant = true;
                });
                // hit it out of the park
                return batterRun({ fromBase = #homeBase; ballLocation = null });
            };
            let location = switch (prng.nextInt(0, 7)) {
                case (0) #firstBase;
                case (1) #secondBase;
                case (2) #thirdBase;
                case (3) #shortStop;
                case (4) #pitcher;
                case (5) #leftField;
                case (6) #centerField;
                case (7) #rightField;
                case (_) Prelude.unreachable();
            };
            let catchingPlayerId = getPlayerAtPosition(location);
            let catchingPlayerState = switch (getPlayerState(catchingPlayerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            let catchRoll = prng.nextInt(-10, 10) + catchingPlayerState.skills.catching;
            if (catchRoll <= 0) {
                batterRun({
                    fromBase = #homeBase;
                    ballLocation = ?location;
                });
            } else {
                let locationText = switch (location) {
                    case (#firstBase) "at first base";
                    case (#secondBase) "at second base";
                    case (#thirdBase) "at third base";
                    case (#shortStop) "at short stop";
                    case (#pitcher) "at the pitching mound";
                    case (#leftField) "in left field";
                    case (#centerField) "in center field";
                    case (#rightField) "in right field";
                };
                let teamId = getDefenseTeamId();
                let catchingPlayer = switch (getPlayer(teamId, catchingPlayerId)) {
                    case (#ok(p)) p;
                    case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
                };
                state.log.add({
                    description = catchingPlayer.name # " caught the ball " # locationText # "!";
                    isImportant = true;
                });
                // Ball caught, batter is out
                out(state.field.offense.atBat);
            };

        };

        private func batterRun({
            ballLocation : ?FieldPosition;
        }) : SimulationResult {
            let battingPlayerState = switch (getPlayerState(state.field.offense.atBat)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };

            let runRoll : Int = prng.nextNat(0, 10) + battingPlayerState.skills.speed;
            let runPlayerToBase = func(playerId : ?PlayerId, fromBase : Base, toBase : Base) : SimulationResult {
                switch (playerId) {
                    case (null) {
                        #inProgress;
                    };
                    case (?pId) {
                        playerMovedBases({ playerId = pId; fromBase; toBase });
                    };
                };
            };
            switch (ballLocation) {
                case (null) {
                    // Home run
                    switch (runPlayerToBase(state.field.offense.thirdBase, #thirdBase, #homeBase)) {
                        case (#endMatch(m)) return #endMatch(m);
                        case (#inProgress) {};
                    };
                    switch (runPlayerToBase(state.field.offense.secondBase, #secondBase, #homeBase)) {
                        case (#endMatch(m)) return #endMatch(m);
                        case (#inProgress) {};
                    };
                    switch (runPlayerToBase(state.field.offense.firstBase, #firstBase, #homeBase)) {
                        case (#endMatch(m)) return #endMatch(m);
                        case (#inProgress) {};
                    };
                    runPlayerToBase(?state.field.offense.atBat, #homeBase, #homeBase);
                };
                case (?l) {
                    // TODO the other bases should be able to get out, but they just run free right now
                    switch (runPlayerToBase(state.field.offense.thirdBase, #thirdBase, #homeBase)) {
                        case (#endMatch(m)) return #endMatch(m);
                        case (#inProgress) {};
                    };
                    switch (runPlayerToBase(state.field.offense.secondBase, #secondBase, #thirdBase)) {
                        case (#endMatch(m)) return #endMatch(m);
                        case (#inProgress) {};
                    };
                    switch (runPlayerToBase(state.field.offense.firstBase, #firstBase, #secondBase)) {
                        case (#endMatch(m)) return #endMatch(m);
                        case (#inProgress) {};
                    };

                    let playerIdWithBall = getPlayerAtPosition(l);
                    let playerStateWithBall = switch (getPlayerState(playerIdWithBall)) {
                        case (#ok(p)) p;
                        case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
                    };
                    let canPickUpInTime = prng.nextInt(0, 10) + playerStateWithBall.skills.speed;
                    if (canPickUpInTime <= 0) {
                        return #inProgress;
                    };
                    // TODO against dodge/speed skill of runner
                    let throwRoll = prng.nextInt(-10, 10) + playerStateWithBall.skills.throwingAccuracy;
                    if (throwRoll <= 0) {
                        state.log.add({
                            description = "SAFE!";
                            isImportant = true;
                        });
                        playerMovedBases({
                            playerId = state.field.offense.atBat;
                            fromBase = #homeBase;
                            toBase = #firstBase;
                        });
                    } else {
                        let catchingPlayer = switch (getPlayer(getDefenseTeamId(), playerIdWithBall)) {
                            case (#ok(p)) p;
                            case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
                        };
                        let battingPlayer = switch (getPlayer(state.offenseTeamId, state.field.offense.atBat)) {
                            case (#ok(p)) p;
                            case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
                        };
                        state.log.add({
                            description = "Player " # catchingPlayer.name # " hit " # battingPlayer.name # "!";
                            isImportant = true;
                        });
                        let battingPlayerState = switch (getPlayerState(state.field.offense.atBat)) {
                            case (#ok(p)) p;
                            case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
                        };
                        let defenseRoll = prng.nextInt(-10, 10) + battingPlayerState.skills.defense;
                        let damageRoll = throwRoll - defenseRoll;
                        if (damageRoll > 5) {
                            let newInjury = switch (damageRoll) {
                                case (6) #twistedAnkle;
                                case (7) #brokenLeg;
                                case (8) #brokenArm;
                                case (_) #concussion;
                            };
                            switch (injurePlayer({ playerId = state.field.offense.atBat; injury = newInjury })) {
                                case (#endMatch(m)) return #endMatch(m);
                                case (#inProgress) {};
                            };
                        };
                        switch (out(state.field.offense.atBat)) {
                            case (#endMatch(m)) #endMatch(m);
                            case (#inProgress) #inProgress;
                        };

                    };

                };
            };

        };

        private func strike() : SimulationResult {
            state.strikes += 1;
            state.log.add({
                description = "Strike " # Nat.toText(state.strikes);
                isImportant = false;
            });
            if (state.strikes >= 3) {
                out(state.field.offense.atBat);
            } else {
                #inProgress;
            };
        };

        private func out(playerId : Nat32) : SimulationResult {
            state.strikes := 0;
            state.outs += 1;
            let outPlayer = switch (getPlayer(state.offenseTeamId, playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            state.log.add({
                description = "Player " # outPlayer.name # " is out";
                isImportant = true;
            });
            if (state.outs >= 3) {
                return endRound();
            };
            removePlayerFromBase(playerId);
        };

        private func playerMovedBases({
            fromBase : Base;
            toBase : Base;
            playerId : PlayerId;
        }) : SimulationResult {
            switch (toBase) {
                case (#firstBase) state.field.offense.firstBase := ?playerId;
                case (#secondBase) state.field.offense.secondBase := ?playerId;
                case (#thirdBase) state.field.offense.thirdBase := ?playerId;
                // TODO should this be legal?
                case (#homeBase) {
                    score({ teamId = state.offenseTeamId; amount = 1 });
                };
            };
            clearBase(fromBase);
        };

        private func endRound() : SimulationResult {
            state.strikes := 0;
            state.outs := 0;
            state.round += 1;
            state.log.add({
                description = "Round is over";
                isImportant = true;
            });
            if (state.round > 9) {
                // End match if no more rounds
                return endMatch(#noMoreRounds);
            };
            let (newOffenseTeamId, newDefenseTeamId) = switch (state.offenseTeamId) {
                case (#team1)(#team2, #team1);
                case (#team2)(#team1, #team2);
            };
            state.offenseTeamId := newOffenseTeamId;
            let newDefense = buildNewDefense(newDefenseTeamId);
            let newOffense = buildNewOffense(newOffenseTeamId);
            switch ((newDefense, newOffense)) {
                case (null, null) return endMatch(#outOfPlayers(#bothTeams));
                case (?d, null) return endMatch(#outOfPlayers(newOffenseTeamId));
                case (null, ?o) return endMatch(#outOfPlayers(newDefenseTeamId));
                case (?d, ?o) {
                    state.field.defense := d;
                    state.field.offense := o;
                };
            };
            let newState = [
                ("1st Base", state.field.defense.firstBase),
                ("2nd Base", state.field.defense.secondBase),
                ("3rd Base", state.field.defense.thirdBase),
                ("Short Stop", state.field.defense.shortStop),
                ("Pitcher", state.field.defense.pitcher),
                ("Left Field", state.field.defense.leftField),
                ("Center Field", state.field.defense.centerField),
                ("Right Field", state.field.defense.rightField),
            ];
            var newPositionText = "Team " # getTeamInfo(newDefenseTeamId).name # " is now on the field.\nNew positions -";
            for ((name, playerId) in Iter.fromArray(newState)) {
                let player = switch (getPlayer(newDefenseTeamId, playerId)) {
                    case (#ok(p)) p;
                    case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
                };
                newPositionText := newPositionText # "\n" # name # ": " # player.name;
            };
            state.log.add({
                description = newPositionText;
                isImportant = false;
            });
            #inProgress;
        };

        private func blessOrCursePlayer(playerId : PlayerId) : SimulationResult {
            if (prng.nextCoin()) {
                cursePlayer(playerId, null);
            } else {
                blessPlayer(playerId, null);
            };
        };

        private func injurePlayer({ playerId : Nat32; injury : Player.Injury }) : SimulationResult {
            let playerState = switch (getPlayerState(playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            playerState.condition := #injured(injury);
            let injuryText = switch (injury) {
                case (#twistedAnkle) "Twisted ankle";
                case (#brokenLeg) "Broken leg";
                case (#brokenArm) "Broken arm";
                case (#concussion) "Concussion";
            };
            let player = switch (getPlayer(playerState.teamId, playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            state.log.add({
                description = "Player " # player.name # " is injured: " # injuryText;
                isImportant = true;
            });
            if (getDefensePositionOfPlayer(playerId) != null) {
                // Swap if on field, base swap handled by batterRun
                substitutePlayer({ playerId = playerId });
            } else {
                #inProgress;
            };
        };

        private func cursePlayer(playerId : Nat32, curseOrRandom : ?Stadium.Curse) : SimulationResult {
            let playerState = switch (getPlayerState(playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            let curse = switch (curseOrRandom) {
                case (null) {
                    let curseRoll = prng.nextNat(0, 11);
                    switch (curseRoll) {
                        case (0) #skill(#battingPower);
                        case (1) #skill(#battingAccuracy);
                        case (2) #skill(#throwingPower);
                        case (3) #skill(#throwingAccuracy);
                        case (4) #skill(#catching);
                        case (5) #skill(#defense);
                        case (6) #skill(#piety);
                        case (7) #skill(#speed);
                        case (8) #injury(#twistedAnkle);
                        case (9) #injury(#brokenLeg);
                        case (10) #injury(#brokenArm);
                        case (11) #injury(#concussion);
                        case (_) Prelude.unreachable();
                    };
                };
                case (?c) c;
            };
            let (curseText, result) = switch (curse) {
                case (#skill(s)) {
                    modifyPlayerSkill(playerState.skills, s, -1); // TODO value
                    ("Decreased skill: " # debug_show (s), #inProgress);
                };
                case (#injury(i)) {
                    let result = injurePlayer({
                        playerId = playerId;
                        injury = i;
                    });
                    ("Injury: " # debug_show (i), result);
                };
            };
            let player = switch (getPlayer(playerState.teamId, playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            state.log.add({
                description = "Player " # player.name # " is cursed with : " # curseText;
                isImportant = true;
            });
            result;
        };

        private func blessPlayer(playerId : Nat32, blessingOrRandom : ?Stadium.Blessing) : SimulationResult {
            let playerState = switch (getPlayerState(playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            let blessing = switch (blessingOrRandom) {
                case (null) {
                    let blessingRoll = prng.nextNat(0, 7);
                    switch (blessingRoll) {
                        case (0) #skill(#battingPower);
                        case (1) #skill(#battingAccuracy);
                        case (2) #skill(#throwingPower);
                        case (3) #skill(#throwingAccuracy);
                        case (4) #skill(#catching);
                        case (5) #skill(#defense);
                        case (6) #skill(#piety);
                        case (7) #skill(#speed);
                        case (_) Prelude.unreachable();
                    };
                };
                case (?c) c;
            };
            let blessingText = switch (blessing) {
                case (#skill(s)) {
                    modifyPlayerSkill(playerState.skills, s, 1); // TODO value
                    "Increased skill: " # debug_show (s);
                };
            };
            let player = switch (getPlayer(playerState.teamId, playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            state.log.add({
                description = "Player " # player.name # " is blessed with : " # blessingText;
                isImportant = true;
            });
            #inProgress;
        };

        private func modifyPlayerSkill(skills : MutablePlayerSkills, skill : Player.Skill, value : Int) {

            switch (skill) {
                case (#battingPower) skills.battingPower += value;
                case (#battingAccuracy) skills.battingAccuracy += value;
                case (#throwingPower) skills.throwingPower += value;
                case (#throwingAccuracy) skills.throwingAccuracy += value;
                case (#catching) skills.catching += value;
                case (#defense) skills.defense += value;
                case (#piety) skills.piety += value;
                case (#speed) skills.speed += value;
            };
        };

        private func substitutePlayer({ playerId : Nat32 }) : SimulationResult {
            let playerOutState = switch (getPlayerState(playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            let team = switch (playerOutState.teamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
            let ?fieldPosition = getDefensePositionOfPlayer(playerId) else return endMatch(#stateBroken(#playerExpectedOnField({ id = playerId; onOffense = true; description = "Player not on field, cannot substitute" })));

            var availablePlayers = getAvailablePlayers(?playerOutState.teamId, ?fieldPosition, true);
            if (availablePlayers.size() < 1) {
                return endMatch(#outOfPlayers(playerOutState.teamId));
            };
            // Get random from available players
            let randomIndex = prng.nextNat(0, availablePlayers.size() - 1);
            let subPlayerId = availablePlayers.get(randomIndex);
            let subPlayer = switch (getPlayer(playerOutState.teamId, subPlayerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            let playerOut = switch (getPlayer(playerOutState.teamId, playerId)) {
                case (#ok(p)) p;
                case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
            };
            state.log.add({
                description = "Player " # playerOut.name # " is being substituted by " # subPlayer.name;
                isImportant = true;
            });
            switch (fieldPosition) {
                case (#firstBase) state.field.defense.firstBase := subPlayerId;
                case (#secondBase) state.field.defense.secondBase := subPlayerId;
                case (#thirdBase) state.field.defense.thirdBase := subPlayerId;
                case (#shortStop) state.field.defense.shortStop := subPlayerId;
                case (#pitcher) state.field.defense.pitcher := subPlayerId;
                case (#leftField) state.field.defense.leftField := subPlayerId;
                case (#centerField) state.field.defense.centerField := subPlayerId;
                case (#rightField) state.field.defense.rightField := subPlayerId;
            };
            #inProgress;
        };

        private func score({ teamId : TeamId; amount : Int }) {
            let team = getTeamState(teamId);
            team.score += amount;
            state.log.add({
                description = "Team " # getTeamInfo(teamId).name # " scored " # Int.toText(amount) # " points!";
                isImportant = true;
            });
        };

        private func endMatch(reason : Stadium.MatchEndReason) : SimulationResult {
            let (winner, message) = switch (reason) {
                case (#noMoreRounds) {
                    let winner = if (state.team1.score > state.team2.score) {
                        #team1;
                    } else if (state.team1.score == state.team2.score) {
                        #tie;
                    } else {
                        #team2;
                    };
                    (winner, "Match ended due to no more rounds");
                };
                case (#outOfPlayers(teamId)) {
                    switch (teamId) {
                        case (#bothTeams) {
                            (#tie, "Match ended due to both teams running out of players");
                        };
                        case (#team1) {
                            (#team1, "Match ended due to team '" # getTeamInfo(#team1).name # "' running out of players");
                        };
                        case (#team2) {
                            (#team2, "Match ended due to team '" # getTeamInfo(#team2).name # "' running out of players");
                        };
                    };
                };
                case (#stateBroken(e)) {
                    (#tie, "Match ended due to the game being in a broken state: " # debug_show (e));
                };
            };
            state.log.add({
                description = message;
                isImportant = true;
            });
            switch (winner) {
                case (#tie) state.log.add({
                    description = "The match ended in a tie!";
                    isImportant = true;
                });
                case (#team1) state.log.add({
                    description = "Team " # getTeamInfo(#team1).name # " wins!";
                    isImportant = true;
                });
                case (#team2) state.log.add({
                    description = "Team " # getTeamInfo(#team2).name # " wins!";
                    isImportant = true;
                });
            };

            let log : [LogEntry] = Buffer.toArray(state.log);
            switch (reason) {
                case (#stateBroken(e)) #endMatch(#stateBroken({ log = log; error = e }));
                case (_) #endMatch(#played({ team1 = { id = team1.id; score = state.team1.score }; team2 = { id = team2.id; score = state.team2.score }; log = log; winner = winner }));
            };
        };

        private func removePlayerFromBase(playerId : PlayerId) : SimulationResult {
            let ?position = getBaseOfPlayer(playerId) else return endMatch(#stateBroken(#playerExpectedOnField({ id = playerId; onOffense = false; description = "Player not on base, cannot remove from field" })));
            clearBase(position);
        };

        private func clearBase(base : Base) : SimulationResult {
            switch (base) {
                case (#firstBase) state.field.offense.firstBase := null;
                case (#secondBase) state.field.offense.secondBase := null;
                case (#thirdBase) state.field.offense.thirdBase := null;
                case (#homeBase) {
                    let ?nextBatterId = getRandomAvailablePlayer(?state.offenseTeamId, null, true) else {
                        return endMatch(#outOfPlayers(state.offenseTeamId));
                    };
                    state.field.offense.atBat := nextBatterId;
                    let nextBatter = switch (getPlayer(state.offenseTeamId, nextBatterId)) {
                        case (#ok(p)) p;
                        case (#playerNotFound(e)) return endMatch(#stateBroken(#playerNotFound(e)));
                    };
                    state.log.add({
                        description = "Player " # nextBatter.name # " is up to bat";
                        isImportant = true;
                    });
                };
            };
            #inProgress;
        };

        private func buildNewDefense(teamId : TeamId) : ?MutableDefenseFieldState {
            do ? {
                {
                    var pitcher = getRandomAvailablePlayer(?teamId, ? #pitcher, false)!;
                    var firstBase = getRandomAvailablePlayer(?teamId, ? #firstBase, false)!;
                    var secondBase = getRandomAvailablePlayer(?teamId, ? #secondBase, false)!;
                    var thirdBase = getRandomAvailablePlayer(?teamId, ? #thirdBase, false)!;
                    var shortStop = getRandomAvailablePlayer(?teamId, ? #shortStop, false)!;
                    var leftField = getRandomAvailablePlayer(?teamId, ? #leftField, false)!;
                    var centerField = getRandomAvailablePlayer(?teamId, ? #centerField, false)!;
                    var rightField = getRandomAvailablePlayer(?teamId, ? #rightField, false)!;
                };
            };
        };

        private func buildNewOffense(teamId : TeamId) : ?MutableOffenseFieldState {

            do ? {
                {
                    var atBat = getRandomAvailablePlayer(?teamId, null, false)!;
                    var firstBase = null;
                    var secondBase = null;
                    var thirdBase = null;
                };
            };
        };

        private func getOffenseTeamState() : MutableTeamState {
            switch (state.offenseTeamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
        };

        private func getDefenseTeamState() : MutableTeamState {
            switch (state.offenseTeamId) {
                case (#team1) state.team2;
                case (#team2) state.team1;
            };
        };

        private func getDefenseTeamId() : TeamId {
            switch (state.offenseTeamId) {
                case (#team1) #team2;
                case (#team2) #team1;
            };
        };

        private func getTeamState(teamId : TeamId) : MutableTeamState {
            switch (teamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
        };

        private func getTeamInfo(teamId : TeamId) : TeamInfo {
            switch (teamId) {
                case (#team1) team1;
                case (#team2) team2;
            };
        };

    };
};
