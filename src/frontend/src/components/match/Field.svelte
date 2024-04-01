<script lang="ts">
  import {
    BaseState,
    PlayerStateWithId,
  } from "../../ic-agent/declarations/stadium";
  import { FieldPositionEnum, toEnum } from "../../models/FieldPosition";
  import {
    LiveMatch,
    LiveMatchState,
    LiveTeamDetails,
  } from "../../stores/LiveMatchGroupStore";
  import FieldPlayer from "./FieldPlayer.svelte";
  import FieldBase from "./FieldBase.svelte";
  import { BaseEnum } from "../../models/Base";
  import FieldBall from "./FieldBall.svelte";
  import { tweened } from "svelte/motion";

  export let match: LiveMatch;

  let getPlayerOrNull = (
    playerId: [number] | [],
  ): PlayerStateWithId | undefined => {
    if (playerId.length == 0) return undefined;
    let id = playerId[0];
    return match.liveState?.players.find((p) => p.id == id) || undefined;
  };

  let getPlayer = (playerId: number): PlayerStateWithId => {
    let playerOrNull = getPlayerOrNull([playerId]);
    if (!playerOrNull) {
      throw new Error("Player not found");
    }
    return playerOrNull;
  };

  type LiveData = {
    liveState: LiveMatchState;
    offenseTeam: LiveTeamDetails;
    defenseTeam: LiveTeamDetails;
  };

  const pitcherPosition = { x: 45, y: 60 };
  const firstBasePosition = { x: 85, y: 50 };
  const secondBasePosition = { x: 60, y: 25 };
  const thirdBasePosition = { x: 5, y: 50 };
  const shortStopPosition = { x: 25, y: 30 };
  const centerFieldPosition = { x: 45, y: 0 };
  const leftFieldPosition = { x: 5, y: 10 };
  const rightFieldPosition = { x: 85, y: 10 };

  const homeBaseLocation = { x: 45, y: 80 };
  const firstBaseLocation = { x: 70, y: 45 };
  const secondBaseLocation = { x: 45, y: 20 };
  const thirdBaseLocation = { x: 20, y: 45 };

  let liveData: LiveData | undefined;

  let eventText: string | undefined;

  const ballLocation = tweened(pitcherPosition);
  const playerPositions = [];

  type AnimationTurn = {
    duration: number;
    operations: (() => void)[];
  };

  let animationTurns: AnimationTurn[] = [];

  let getPositionCoordinates = (
    position: FieldPositionEnum,
  ): { x: number; y: number } => {
    switch (position) {
      case FieldPositionEnum.FirstBase:
        return firstBasePosition;
      case FieldPositionEnum.CenterField:
        return centerFieldPosition;
      case FieldPositionEnum.LeftField:
        return leftFieldPosition;
      case FieldPositionEnum.RightField:
        return rightFieldPosition;
      case FieldPositionEnum.SecondBase:
        return secondBasePosition;
      case FieldPositionEnum.ShortStop:
        return shortStopPosition;
      case FieldPositionEnum.ThirdBase:
        return thirdBasePosition;
      case FieldPositionEnum.Pitcher:
        return pitcherPosition;
      default:
        throw new Error("Not implemented position: " + position);
    }
  };

  let getPlayerBaseCoordinates = (
    playerId: number,
    bases: BaseState,
    initialBases: BaseState,
  ): { x: number; y: number } | undefined => {
    if (playerId == bases.atBat) {
      return homeBaseLocation;
    } else if (bases.firstBase.length > 0 && playerId == bases.firstBase[0]) {
      return firstBaseLocation;
    } else if (bases.secondBase.length > 0 && playerId == bases.secondBase[0]) {
      return secondBaseLocation;
    } else if (bases.thirdBase.length > 0 && playerId == bases.thirdBase[0]) {
      return thirdBaseLocation;
    }
    // Fallback to base position of last turn + 1, since they are not on the field anymore
    if (playerId == initialBases.atBat) {
      return firstBaseLocation;
    } else if (
      initialBases.firstBase.length > 0 &&
      playerId == initialBases.firstBase[0]
    ) {
      return secondBaseLocation;
    } else if (
      initialBases.secondBase.length > 0 &&
      playerId == initialBases.secondBase[0]
    ) {
      return thirdBaseLocation;
    } else if (
      initialBases.thirdBase.length > 0 &&
      playerId == initialBases.thirdBase[0]
    ) {
      return homeBaseLocation;
    }
    return undefined;
  };

  $: if (match.liveState) {
    eventText = undefined;
    let offenseTeam;
    let defenseTeam;

    if ("team1" in match.liveState.offenseTeamId) {
      offenseTeam = match.team1;
      defenseTeam = match.team2;
    } else {
      offenseTeam = match.team2;
      defenseTeam = match.team1;
    }
    liveData = {
      liveState: match.liveState,
      offenseTeam: offenseTeam,
      defenseTeam: defenseTeam,
    };
    if (match.log && match.log.rounds.length > 0) {
      let currentRound = match.log.rounds[match.log.rounds.length - 1];
      let lastTurn = currentRound.turns[currentRound.turns.length - 1];
      if (lastTurn.events.length > 0) {
        lastTurn.events.forEach((e) => {
          if ("pitch" in e) {
            animationTurns.push({
              duration: 1000,
              operations: [
                () => {
                  ballLocation.set(homeBaseLocation);
                },
              ],
            });
          } else if ("swing" in e) {
            if (e.swing.)
            animationTurns[animationTurns.length - 1].operations.push(() => {
              ballLocation.set(secondBaseLocation);
            });
          } else {
            throw new Error("Not implemented event: " + JSON.stringify(e));
          }
        });
      }
    }
  } else {
    liveData = undefined;
  }
</script>

{#if liveData}
  <div class="">
    <svg class="" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <rect width="100%" height="100%" fill="#F5F5F5" opacity={0.1} />

      <!-- Outfield -->
      <FieldPlayer
        x={leftFieldPosition.x}
        y={leftFieldPosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.leftField)}
        position={FieldPositionEnum.LeftField}
      />
      <FieldPlayer
        x={centerFieldPosition.x}
        y={centerFieldPosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.centerField)}
        position={FieldPositionEnum.CenterField}
      />
      <FieldPlayer
        x={rightFieldPosition.x}
        y={rightFieldPosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.rightField)}
        position={FieldPositionEnum.RightField}
      />

      <!-- Home base -->
      <FieldBase
        x={homeBaseLocation.x}
        y={homeBaseLocation.y}
        teamColor={liveData.offenseTeam.color}
        player={getPlayer(liveData.liveState.bases.atBat)}
        base={BaseEnum.HomeBase}
      />

      <!-- First base -->
      <FieldBase
        x={firstBaseLocation.x}
        y={firstBaseLocation.y}
        teamColor={liveData.offenseTeam.color}
        player={getPlayerOrNull(liveData.liveState.bases.firstBase)}
        base={BaseEnum.FirstBase}
      />

      <FieldPlayer
        x={firstBasePosition.x}
        y={firstBasePosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.firstBase)}
        position={FieldPositionEnum.FirstBase}
      />

      <!-- Second base -->
      <FieldBase
        x={secondBaseLocation.x}
        y={secondBaseLocation.y}
        teamColor={liveData.offenseTeam.color}
        player={getPlayerOrNull(liveData.liveState.bases.secondBase)}
        base={BaseEnum.SecondBase}
      />

      <FieldPlayer
        x={secondBasePosition.x}
        y={secondBasePosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.secondBase)}
        position={FieldPositionEnum.SecondBase}
      />

      <!-- Short stop -->
      <FieldPlayer
        x={shortStopPosition.x}
        y={shortStopPosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.shortStop)}
        position={FieldPositionEnum.ShortStop}
      />

      <!-- Third base -->
      <FieldBase
        x={thirdBaseLocation.x}
        y={thirdBaseLocation.y}
        teamColor={liveData.offenseTeam.color}
        player={getPlayerOrNull(liveData.liveState.bases.thirdBase)}
        base={BaseEnum.ThirdBase}
      />

      <FieldPlayer
        x={thirdBasePosition.x}
        y={thirdBasePosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.thirdBase)}
        position={FieldPositionEnum.ThirdBase}
      />

      <!-- Pitcher -->
      <FieldPlayer
        x={pitcherPosition.x}
        y={pitcherPosition.y}
        teamColor={liveData.defenseTeam.color}
        player={getPlayer(liveData.defenseTeam.positions.pitcher)}
        position={FieldPositionEnum.Pitcher}
      />

      <text x={10} y={88} font-size={8} fill="white">
        {eventText || ""}
      </text>

      <!-- Baseball -->
      <FieldBall location={$ballLocation} />

      <!-- Text -->
      <text x={60} y={88} font-size={3} fill="white">
        Strikes: {liveData.liveState.strikes}
      </text>
      <text x={60} y={93} font-size={3} fill="white">
        Outs: {liveData.liveState.outs}
      </text>
    </svg>
  </div>
{/if}
