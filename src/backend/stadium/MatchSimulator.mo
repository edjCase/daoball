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
import RandomX "mo:random/RandomX";
import PsuedoRandomX "mo:random/PsuedoRandomX";
import StadiumUtil "StadiumUtil";
import IterTools "mo:itertools/Iter";
import MatchStateMachine "MatchStateMachine";

module {
    type PlayerState = Stadium.PlayerState;
    type PlayerStateWithId = Stadium.PlayerStateWithId;
    type MatchTurn = Stadium.MatchTurn;
    type MatchEvent = Stadium.MatchEvent;
    type MatchState = Stadium.MatchState;
    type TeamState = Stadium.TeamState;
    type MatchOptions = Stadium.MatchOptions;
    type InProgressMatchState = Stadium.InProgressMatchState;
    type PlayerWithId = Player.PlayerWithId;
    type FieldPosition = Player.FieldPosition;
    type Base = Player.Base;
    type TeamId = Stadium.TeamId;
    type PlayerSkills = Player.PlayerSkills;
    type PlayerId = Nat32;
    type Prng = PsuedoRandomX.PsuedoRandomGenerator;

    public type TeamInitData = {
        id : Principal;
        offeringId : Nat32;
        specialRuleVotes : Trie.Trie<Nat32, Nat>;
        players : [PlayerWithId];
    };

    public func initState(
        specialRules : [Stadium.SpecialRule],
        team1 : TeamInitData,
        team2 : TeamInitData,
        team1StartOffense : Bool,
        rand : Prng,
    ) : InProgressMatchState {
        var players = Buffer.Buffer<Stadium.PlayerStateWithId>(team1.players.size() + team2.players.size());
        let addPlayer = func(player : PlayerWithId, teamId : TeamId) {
            let playerState : Stadium.PlayerStateWithId = {
                id = player.id;
                name = player.name;
                teamId = teamId;
                condition = player.condition;
                skills = player.skills;
                position = player.position;
            };
            players.add(playerState);
        };
        for (player in team1.players.vals()) {
            addPlayer(player, #team1);
        };
        for (player in team2.players.vals()) {
            addPlayer(player, #team2);
        };
        let specialRuleId = calculateSpecialRule(specialRules, team1.specialRuleVotes, team2.specialRuleVotes);

        let (offenseTeam, defenseTeam) = if (team1StartOffense) {
            (team1, team2);
        } else {
            (team2, team1);
        };
        let randomIndex = rand.nextNat(0, offenseTeam.players.size() - 1);
        let atBatPlayer = offenseTeam.players.get(randomIndex);
        let ?defense = buildStartingDefense(defenseTeam.players, rand) else Debug.trap("No more random entropy");

        {
            offenseTeamId = if (team1StartOffense) #team1 else #team2;
            team1 = {
                id = team1.id;
                score = 0;
                offeringId = team1.offeringId;
            };
            team2 = {
                id = team2.id;
                score = 0;
                offeringId = team2.offeringId;
            };
            specialRuleId = specialRuleId;
            turns = [];
            players = Buffer.toArray(players);
            batter = null;
            field = {
                offense = {
                    atBat = atBatPlayer.id;
                    firstBase = null;
                    secondBase = null;
                    thirdBase = null;
                };
                defense = defense;
            };
            round = 0;
            outs = 0;
            strikes = 0;
        };
    };

    private func buildStartingDefense(players : [PlayerWithId], rand : Prng) : ?Stadium.DefenseFieldState {
        let getRandomPlayer = func(position : FieldPosition) : ?PlayerId {
            let playersWithPosition = Array.filter(players, func(p : PlayerWithId) : Bool = p.position == position);
            if (playersWithPosition.size() < 1) {
                return null;
            };
            let index = rand.nextNat(0, playersWithPosition.size() - 1);
            ?playersWithPosition[index].id;
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

    private func calculateSpecialRule(
        specialRules : [Stadium.SpecialRule],
        team1Votes : Trie.Trie<Nat32, Nat>,
        team2Votes : Trie.Trie<Nat32, Nat>,
    ) : ?Nat32 {
        let team1NormalizedVotes = normalizeVotes(team1Votes);
        let team2NormalizedVotes = normalizeVotes(team2Votes);
        var winningRule : ?(Nat32, Float) = null;
        // TODO rule index vs id
        var id : Nat32 = 0;
        for (rule in Array.vals(specialRules)) {
            let key = {
                key = id;
                hash = id;
            };
            let team1Vote : Float = switch (Trie.get(team1NormalizedVotes, key, Nat32.equal)) {
                case (null) 0;
                case (?v) v;
            };
            let team2Vote : Float = switch (Trie.get(team2NormalizedVotes, key, Nat32.equal)) {
                case (null) 0;
                case (?v) v;
            };
            let voteCount = team1Vote + team2Vote;
            switch (winningRule) {
                case (null) winningRule := ?(id, voteCount);
                case (?(id, c)) {
                    if (voteCount > c) {
                        winningRule := ?(id, voteCount);
                    };
                    // TODO what if tie?
                };
            };
            id += 1;
        };
        switch (winningRule) {
            case (null) null;
            case (?(id, voteCount)) ?id;
        };
    };

    private func normalizeVotes(votes : Trie.Trie<Nat32, Nat>) : Trie.Trie<Nat32, Float> {
        var totalVotes = 0;
        for ((id, voteCount) in Trie.iter(votes)) {
            totalVotes += voteCount;
        };
        if (totalVotes == 0) {
            return Trie.empty();
        };
        Trie.mapFilter<Nat32, Nat, Float>(
            votes,
            func(voteCount : (Nat32, Nat)) : ?Float = ?(Float.fromInt(voteCount.1) / Float.fromInt(totalVotes)),
        );
    };

    public func tick(state : InProgressMatchState, random : Prng) : MatchState {
        let stateMachine = MatchStateMachine.MatchStateMachine(state);
        let simulation = MatchSimulation(stateMachine, random);
        simulation.tick();
    };

    // TODO handle limited entropy from random by refetching entropy from the chain
    class MatchSimulation(stateMachine : MatchStateMachine.MatchStateMachine, random : Prng) {

        public func tick() : MatchState {
            let divineInterventionRoll = random.nextNat(0, 999);
            if (divineInterventionRoll >= 991) {
                // TODO divine intervention
            };
            let pitcher = stateMachine.getPlayerAtPosition(#pitcher);
            let pitchRoll = random.nextNat(0, 10) + pitcher.skills.throwingAccuracy + pitcher.skills.throwingPower;

            stateMachine.pitch();
            processEvent(#pitch({ pitchRoll }));
            stateMachine.getState();
        };

        private func isEndState() : ?Stadium.CompletedMatchState {
            let buildTeam = func(team : MutableTeamState) : Stadium.CompletedTeamState {
                {
                    id = team.id;
                    score = team.score;
                };
            };

            let turns : [Turn] = freezeTurns(state.turns);
            if (state.round >= 9) {
                let winner = if (state.team1.score > state.team2.score) {
                    #team1;
                } else if (state.team1.score == state.team2.score) {
                    #team1; // TODO do random
                } else {
                    #team2;
                };
                return ? #played(
                    {
                        team1 = buildTeam(state.team1);
                        team2 = buildTeam(state.team2);
                        turns = turns;
                        winner = winner;
                        initialState = initialState;
                    }
                );
            };
            let minPlayerCount = 8; // TODO
            let team1PlayerCount = Iter.size(IterTools.mapFilter(state.players.vals(), func(p : MutablePlayerState) : ?MutablePlayerState = if (p.teamId == #team1) { ?p } else { null }));
            let team2PlayerCount = Iter.size(IterTools.mapFilter(state.players.vals(), func(p : MutablePlayerState) : ?MutablePlayerState = if (p.teamId == #team2) { ?p } else { null }));
            if (team1PlayerCount < minPlayerCount or team2PlayerCount < minPlayerCount) {
                let winner = if (team1PlayerCount >= minPlayerCount) {
                    #team1;
                } else if (team2PlayerCount >= minPlayerCount) {
                    #team2;
                } else {
                    #team2; // TODO random
                };
                return ? #played({
                    team1 = buildTeam(state.team1);
                    team2 = buildTeam(state.team2);
                    turns = turns;
                    winner = winner;
                    initialState = initialState;
                });
            };
            null;
        };

        private func getRandomAvailablePlayer(teamId : ?TeamId, position : ?FieldPosition, notOnField : Bool) : ?PlayerId {
            // get random player
            let availablePlayers = getAvailablePlayers(teamId, position, notOnField);
            if (availablePlayers.size() < 1) {
                return null;
            };
            let randomIndex = random.nextNat(0, availablePlayers.size() - 1);
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
                        getDefensePositionOfPlayer(p.0) == null and getOffensePositionOfPlayer(p.0) == null;
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

        private func sub() {

            var availablePlayers = getAvailablePlayers(?playerOut.teamId, ?fieldPosition, true);
            if (availablePlayers.size() < 1) {
                return processEvent(#endMatch(#outOfPlayers(playerOut.teamId)));
            };
            // Get random from available players
            let randomIndex = random.nextNat(0, availablePlayers.size() - 1);
            let subPlayerId = availablePlayers.get(randomIndex);
        };

        private func pitch({ pitchRoll : Nat }) {
            let atBatPlayer = stateMachine.getPlayer(state.field.offense.atBat);
            let batterRoll = random.nextInt(0, 10) + atBatPlayer.skills.battingAccuracy + atBatPlayer.skills.battingPower;
            let batterNetScore = batterRoll - pitchRoll;
            if (batterNetScore <= 0) {
                processEvent(#strike);
            } else {
                processEvent(#hit({ hitRoll = Int.abs(batterNetScore) }));
            };
        };

        private func foul() {
            // TODO
        };

        private func hit({ hitRoll : Nat }) {
            let precisionRoll = random.nextInt(-2, 2) + hitRoll;
            if (precisionRoll < 0) {
                processEvent(#foul);
                return;
            };
            let player = getPlayer(state.field.offense.atBat);
            if (precisionRoll > 10) {
                // hit it out of the park
                processEvent(#run({ base = #homeBase; ballLocation = null; runRoll = 0 }));
                return;
            };
            let location = switch (random.nextInt(0, 7)) {
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
            let catchingPlayer = getPlayer(catchingPlayerId);
            let catchRoll = random.nextInt(-10, 10) + catchingPlayer.skills.catching;
            if (catchRoll <= 0) {
                let runRoll : Nat = random.nextNat(0, 10) + player.skills.speed;
                processEvent(#run({ base = #homeBase; ballLocation = ?location; runRoll = runRoll }));
            } else {
                // Ball caught, batter is out
                processEvent(#out(state.field.offense.atBat));
            };

        };

        private func run({
            base : Base;
            ballLocation : ?FieldPosition;
            runRoll : Nat;
        }) {
            switch (ballLocation) {
                case (null) {
                    // Home run
                    // TODO run to each base or just home?
                    // 3rd -> Home
                    if (stateMachine.getPlayerAtBase(#thirdBase) != null) {
                        stateMachine.processEvent(#run({ fromBase = #thirdBase; toBase = #homeBase }));
                    };
                    // 2nd -> Home
                    if (stateMachine.getPlayerAtBase(#secondBase) != null) {
                        stateMachine.processEvent(#run({ fromBase = #secondBase; toBase = #homeBase }));
                    };
                    // 1st -> Home
                    if (stateMachine.getPlayerAtBase(#firstBase) != null) {
                        stateMachine.processEvent(#run({ fromBase = #firstBase; toBase = #homeBase }));
                    };
                    // Batter -> Home
                    if (stateMachine.getPlayerAtBase(#homeBase) != null) {
                        stateMachine.processEvent(#run({ fromBase = #homeBase; toBase = #homeBase }));
                    };
                };
                case (?l) {
                    // TODO the other bases should be able to get out, but they just run free right now
                    // 3rd -> Home
                    if (stateMachine.getPlayerAtBase(#thirdBase) != null) {
                        stateMachine.processEvent(#run({ fromBase = #thirdBase; toBase = #homeBase }));
                    };
                    // 2nd -> 3rd
                    if (stateMachine.getPlayerAtBase(#secondBase) != null) {
                        stateMachine.processEvent(#run({ fromBase = #secondBase; toBase = #thirdBase }));
                    };
                    // 1st -> 2nd
                    if (stateMachine.getPlayerAtBase(#firstBase) != null) {
                        stateMachine.processEvent(#run({ fromBase = #firstBase; toBase = #secondBase }));
                    };

                    let runningPlayer = stateMachine.getBatter();
                    let catchingPlayer = stateMachine.getPlayerAtPosition(l);
                    let pickupSpeedRoll = random.nextInt(0, 10) + catchingPlayer.skills.speed;
                    let canPickUpInTime = runRoll - pickupSpeedRoll > 0;
                    let isSafe = if (canPickUpInTime) {
                        // TODO against dodge/speed skill of runner
                        let throwRoll = random.nextInt(-10, 10) + catchingPlayer.skills.throwingAccuracy;
                        if (throwRoll <= 0) {
                            true;
                        } else {
                            let defenseRoll = random.nextInt(-10, 10) + runningPlayer.skills.defense;
                            let damageRoll = throwRoll - defenseRoll;
                            if (damageRoll > 5) {
                                let newInjury = switch (damageRoll) {
                                    case (6) #twistedAnkle;
                                    case (7) #brokenLeg;
                                    case (8) #brokenArm;
                                    case (_) #concussion;
                                };
                                // TODO this + out? dont they need to leave the field if out?
                                processEvent(#playerInjured({ playerId = runningPlayer.id; injury = newInjury }));
                                false;
                            } else {
                                true;
                            };
                        };
                    } else {
                        true;
                    };
                    if (isSafe) {
                        stateMachine.processEvent(#run({ fromBase = #homeBase; toBase = #firstBase }));
                    } else {
                        processEvent(#out(runningPlayer.id));
                    };

                };
            };

        };

    };
};
