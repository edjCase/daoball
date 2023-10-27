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

module {
    type PlayerState = Stadium.PlayerState;
    type PlayerStateWithId = Stadium.PlayerStateWithId;
    type MatchTurn = Stadium.MatchTurn;
    type MatchEvent = Stadium.MatchEvent;
    type MatchState = Stadium.MatchState;
    type TeamState = Stadium.TeamState;
    type MatchOptions = Stadium.MatchOptions;
    type InProgressMatchState = Stadium.InProgressMatchState;
    type CompletedMatchState = Stadium.CompletedMatchState;
    type PlayerWithId = Player.PlayerWithId;
    type FieldPosition = Player.FieldPosition;
    type Base = Player.Base;
    type TeamId = Stadium.TeamId;
    type PlayerSkills = Player.PlayerSkills;
    type PlayerId = Nat32;
    type DefenseFieldState = Stadium.DefenseFieldState;
    type OffenseFieldState = Stadium.OffenseFieldState;

    type StartedMatchState = {
        #inProgress : InProgressMatchState;
        #completed : CompletedMatchState;
    };

    type Result<T> = {
        #ok : T;
        #matchEnded;
    };

    public class MatchStateMachine(initialState : StartedMatchState) {
        var state : StartedMatchState = initialState;

        public func processEvent(event : MatchEvent) : Result<()> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            let newState : StartedMatchState = switch (event) {
                case (#pitch(p)) pitch(inProgressState, p);
                case (#foul) foul(inProgressState);
                case (#hit(h)) hit(inProgressState, h);
                case (#run(r)) run(inProgressState, r);
                case (#strike) strike(inProgressState);
                case (#out(o)) out(inProgressState, o);
                case (#playerMovedBases(pmb)) playerMovedBases(inProgressState, pmb);
                case (#endRound) endRound(inProgressState);
                case (#playerInjured(pi)) injurePlayer(inProgressState, pi);
                case (#playerSubstituted(ps)) substitutePlayer(inProgressState, ps);
                case (#score(s)) score(inProgressState, s);
                case (#endMatch(reason)) endMatch(inProgressState, reason);
            };

            state := {
                state with
                turns = turns
            };
            #ok;
        };

        public func getPlayerAtPosition(catchLocation : FieldPosition) : Result<PlayerStateWithId> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            let playerId = switch (catchLocation) {
                case (#firstBase) inProgressState.field.defense.firstBase;
                case (#secondBase) inProgressState.field.defense.secondBase;
                case (#thirdBase) inProgressState.field.defense.thirdBase;
                case (#shortStop) inProgressState.field.defense.shortStop;
                case (#pitcher) inProgressState.field.defense.pitcher;
                case (#leftField) inProgressState.field.defense.leftField;
                case (#centerField) inProgressState.field.defense.centerField;
                case (#rightField) inProgressState.field.defense.rightField;
            };
            let player = getPlayer(inProgressState, playerId);
            #ok(player);
        };

        public func getDefensePositionOfPlayer(playerId : PlayerId) : Result<?FieldPosition> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            if (inProgressState.field.defense.firstBase == playerId) {
                return #ok(? #firstBase);
            };
            if (inProgressState.field.defense.secondBase == playerId) {
                return #ok(? #secondBase);
            };
            if (inProgressState.field.defense.thirdBase == playerId) {
                return #ok(? #thirdBase);
            };
            if (inProgressState.field.defense.shortStop == playerId) {
                return #ok(? #shortStop);
            };
            if (inProgressState.field.defense.pitcher == playerId) {
                return #ok(? #pitcher);
            };
            if (inProgressState.field.defense.leftField == playerId) {
                return #ok(? #leftField);
            };
            if (inProgressState.field.defense.centerField == playerId) {
                return #ok(? #centerField);
            };
            if (inProgressState.field.defense.rightField == playerId) {
                return #ok(? #rightField);
            };
            #ok(null);
        };

        public func getOffensePositionOfPlayer(playerId : PlayerId) : Result<?Base> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            if (inProgressState.field.offense.firstBase == ?playerId) {
                return #ok(? #firstBase);
            };
            if (inProgressState.field.offense.secondBase == ?playerId) {
                return #ok(? #secondBase);
            };
            if (inProgressState.field.offense.thirdBase == ?playerId) {
                return #ok(? #thirdBase);
            };
            if (inProgressState.field.offense.atBat == playerId) {
                return #ok(? #homeBase);
            };
            #ok(null);
        };

        public func getPlayerAtBase(base : Base) : Result<?PlayerStateWithId> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            let playerId = switch (base) {
                case (#firstBase) inProgressState.field.offense.firstBase;
                case (#secondBase) inProgressState.field.offense.secondBase;
                case (#thirdBase) inProgressState.field.offense.thirdBase;
                case (#homeBase) ?inProgressState.field.offense.atBat;
            };
            let player = switch (playerId) {
                case (null) null;
                case (?playerId) ?getPlayer(inProgressState, playerId);
            };
            #ok(player);
        };

        public func getBatter() : Result<PlayerStateWithId> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            let player = getPlayer(inProgressState, inProgressState.field.offense.atBat);
            #ok(player);
        };

        public func getOffenseTeam() : Result<TeamState> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            let team = switch (inProgressState.offenseTeamId) {
                case (#team1) inProgressState.team1;
                case (#team2) inProgressState.team2;
            };
            #ok(team);
        };

        public func getDefenseTeam() : Result<TeamState> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            let team = switch (inProgressState.offenseTeamId) {
                case (#team1) inProgressState.team2;
                case (#team2) inProgressState.team1;
            };
            #ok(team);
        };

        public func getTeam(teamId : TeamId) : Result<TeamState> {
            let #ok(inProgressState) = assertInProgress() else return #matchEnded;
            let team = switch (teamId) {
                case (#team1) inProgressState.team1;
                case (#team2) inProgressState.team2;
            };
            #ok(team);
        };

        private func assertInProgress() : Result<InProgressMatchState> {
            switch (state) {
                case (#inProgress(s)) #ok(s);
                case (#completed(s)) #matchEnded;
            };
        };

        private func getPlayer(inProgressState : InProgressMatchState, playerId : PlayerId) : PlayerStateWithId {
            let ?player = Array.find<PlayerStateWithId>(inProgressState.players, func(p) = p.id == playerId) else trapWithEvents("Player not found: " # Nat32.toText(playerId));
            player;
        };

        private func trapWithEvents(state : InProgressMatchState, message : Text) : None {
            let messageWithEvents = state.turns.vals()
            |> Iter.map<MatchTurn, Text>(
                _,
                func(e : MatchTurn) : Text = e.events.vals() |> IterTools.fold<MatchEvent, Text>(
                    _,
                    message,
                    func(m : Text, e : MatchEvent) : Text = m # "\n" # debug_show (e),
                ),
            )
            |> IterTools.fold<Text, Text>(
                _,
                message,
                func(m : Text, e : Text) : Text = m # "\n---\n" # e,
            );
            Debug.trap(messageWithEvents);
        };

        private func strike(inProgressState : InProgressMatchState) : StartedMatchState {
            var newState = {
                inProgressState with strikes = inProgressState.strikes + 1
            };
            if (newState.strikes >= 3) {
                out(newState, newState.field.offense.atBat);
            } else {
                #inProgress(newState);
            };
        };

        private func out(inProgressState : InProgressMatchState, playerId : Nat32) : StartedMatchState {
            var newState = {
                inProgressState with
                outs = inProgressState.outs + 1;
                strikes = 0;
            };
            if (newState.outs >= 3) {
                return endRound(newState);
            };
            removePlayerFromField(playerId);

        };

        private func playerMovedBases(inProgressState : InProgressMatchState, { base : Base; playerId : PlayerId }) : StartedMatchState {
            let ?oldPosition = getOffensePositionOfPlayer(playerId) else trapWithEvents("Player not on base, cannot move: " # Nat32.toText(playerId));

            switch (base) {
                case (#firstBase) state.field.offense.firstBase := ?playerId;
                case (#secondBase) state.field.offense.secondBase := ?playerId;
                case (#thirdBase) state.field.offense.thirdBase := ?playerId;
                // TODO should this be legal?
                case (#homeBase) {
                    processEvent(#score({ teamId = state.offenseTeamId; amount = 1 }));
                    removePlayerFromField(playerId);
                };
            };
            // Remove from old position
            switch (oldPosition) {
                case (#firstBase) state.field.offense.firstBase := null;
                case (#secondBase) state.field.offense.secondBase := null;
                case (#thirdBase) state.field.offense.thirdBase := null;
                case (#homeBase) {
                    let ?nextBatterId = getRandomAvailablePlayer(?state.offenseTeamId, null, true) else {
                        return processEvent(#endMatch(#outOfPlayers(state.offenseTeamId)));
                    };
                    state.field.offense.atBat := nextBatterId;
                };
            };
        };

        private func endRound(inProgressState : InProgressMatchState) : StartedMatchState {
            let newState = {
                inProgressState with
                strikes = 0;
                outs = 0;
                round = inProgressState.round + 1;
            };
            if (newState.round > 9) {
                // End match if no more rounds
                return endMatch(newState);
            };
            let (newOffenseTeamId, newDefenseTeamId) = switch (newState.offenseTeamId) {
                case (#team1)(#team2, #team1);
                case (#team2)(#team1, #team2);
            };
            state.offenseTeamId := newOffenseTeamId;
            let (newDefense, newOffense) = switch ((buildNewDefense(newDefenseTeamId), buildNewOffense(newOffenseTeamId))) {
                case (null, null) return processEvent(#endMatch(#outOfPlayers(#bothTeams)));
                case (?d, null) return processEvent(#endMatch(#outOfPlayers(newOffenseTeamId)));
                case (null, ?o) return processEvent(#endMatch(#outOfPlayers(newDefenseTeamId)));
                case (?d, ?o)(d, o);
            };
            #inProgress(
                {
                    newState with
                    offenseTeamId = newOffenseTeamId;
                    field = {
                        field with
                        defense = newDefense;
                        offense = newOffense;
                    };

                }
            );
        };
        private func buildNewDefense(teamId : TeamId) : ?DefenseFieldState {
            do ? {
                {
                    pitcher = getRandomAvailablePlayer(?teamId, ? #pitcher, false)!;
                    firstBase = getRandomAvailablePlayer(?teamId, ? #firstBase, false)!;
                    secondBase = getRandomAvailablePlayer(?teamId, ? #secondBase, false)!;
                    thirdBase = getRandomAvailablePlayer(?teamId, ? #thirdBase, false)!;
                    shortStop = getRandomAvailablePlayer(?teamId, ? #shortStop, false)!;
                    leftField = getRandomAvailablePlayer(?teamId, ? #leftField, false)!;
                    centerField = getRandomAvailablePlayer(?teamId, ? #centerField, false)!;
                    rightField = getRandomAvailablePlayer(?teamId, ? #rightField, false)!;
                };
            };
        };

        private func buildNewOffense(teamId : TeamId) : ?OffenseFieldState {

            do ? {
                {
                    atBat = getRandomAvailablePlayer(?teamId, null, false)!;
                    firstBase = null;
                    secondBase = null;
                    thirdBase = null;
                };
            };
        };

        private func injurePlayer(inProgressState : InProgressMatchState, { playerId : Nat32; injury : Player.Injury }) {
            let player = getPlayer(inProgressState, playerId);
            let newState = {
                inProgressState with
                players = Array.map<PlayerStateWithId, PlayerStateWithId>(
                    inProgressState.players,
                    func(p) = if (p.id == playerId) {
                        { p with condition = #injured(injury) };
                    } else {
                        p;
                    },
                );
            };
            if (getDefensePositionOfPlayer(playerId) != null) {
                processEvent(#playerSubstituted({ playerId = playerId }));
            };
        };

        private func substitutePlayer(
            inProgressState : InProgressMatchState,
            {
                playerOutId : Nat32;
                playerInId : Nat32;
            },
        ) {
            let playerOut = getPlayer(playerOutId);
            let team = switch (playerOut.teamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
            let ?fieldPosition = getDefensePositionOfPlayer(playerOutId) else trapWithEvents("Player not on field, cannot sub out: " # Nat32.toText(playerId));

            let newDefenseField = switch (fieldPosition) {
                case (#firstBase) {
                    { state.field.defense with firstBase = playerInId };
                };
                case (#secondBase) {
                    { state.field.defense with secondBase = playerInId };
                };
                case (#thirdBase) {
                    { state.field.defense with thirdBase = playerInId };
                };
                case (#shortStop) {
                    { state.field.defense with shortStop = playerInId };
                };
                case (#pitcher) {
                    { state.field.defense with pitcher = playerInId };
                };
                case (#leftField) {
                    { state.field.defense with leftField = playerInId };
                };
                case (#centerField) {
                    { state.field.defense with centerField = playerInId };
                };
                case (#rightField) {
                    { state.field.defense with rightField = playerInId };
                };
            };
            {
                state with
                field = {
                    state.field with
                    defense = newDefenseField;
                };
            };
        };

        private func score(inProgressState : InProgressMatchState, { teamId : TeamId; amount : Int }) {
            let team = switch (teamId) {
                case (#team1) state.team1;
                case (#team2) state.team2;
            };
            team.score += amount;
        };

        private func endMatch(inProgressState : InProgressMatchState, reason : Stadium.MatchEndReason) {
            // TODO
        };

        private func removePlayerFromField(inProgressState : InProgressMatchState, playerId : PlayerId) {
            let ?position = getOffensePositionOfPlayer(playerId) else trapWithEvents("Player not on field, cannot remove: " # Nat32.toText(playerId));

            switch (position) {
                case (#firstBase) state.field.offense.firstBase := null;
                case (#secondBase) state.field.offense.secondBase := null;
                case (#thirdBase) state.field.offense.thirdBase := null;
                case (#homeBase) {
                    let ?nextBatterId = getRandomAvailablePlayer(?state.offenseTeamId, null, true) else {
                        return processEvent(#endMatch(#outOfPlayers(state.offenseTeamId)));
                    };
                    state.field.offense.atBat := nextBatterId;
                };
            };
        };

    };
};
