export const idlFactory = ({ IDL }) => {
  const CancelMatchGroupRequest = IDL.Record({ 'id' : IDL.Nat });
  const CancelMatchGroupResult = IDL.Variant({
    'ok' : IDL.Null,
    'matchGroupNotFound' : IDL.Null,
  });
  const PlayerId = IDL.Nat32;
  const BaseState = IDL.Record({
    'atBat' : PlayerId,
    'thirdBase' : IDL.Opt(PlayerId),
    'secondBase' : IDL.Opt(PlayerId),
    'firstBase' : IDL.Opt(PlayerId),
  });
  const PlayerId__1 = IDL.Nat32;
  const OutReason = IDL.Variant({
    'strikeout' : IDL.Null,
    'ballCaught' : IDL.Null,
    'hitByBall' : IDL.Null,
  });
  const TeamId = IDL.Variant({ 'team1' : IDL.Null, 'team2' : IDL.Null });
  const MatchAura = IDL.Variant({
    'foggy' : IDL.Null,
    'moveBasesIn' : IDL.Null,
    'extraStrike' : IDL.Null,
    'moreBlessingsAndCurses' : IDL.Null,
    'fastBallsHardHits' : IDL.Null,
    'explodingBalls' : IDL.Null,
    'lowGravity' : IDL.Null,
    'doubleOrNothing' : IDL.Null,
    'windy' : IDL.Null,
    'rainy' : IDL.Null,
  });
  const Skill = IDL.Variant({
    'battingAccuracy' : IDL.Null,
    'throwingAccuracy' : IDL.Null,
    'speed' : IDL.Null,
    'catching' : IDL.Null,
    'battingPower' : IDL.Null,
    'defense' : IDL.Null,
    'throwingPower' : IDL.Null,
  });
  const Effect = IDL.Variant({
    'skill' : IDL.Record({ 'skill' : IDL.Opt(Skill), 'delta' : IDL.Int }),
  });
  const Trait = IDL.Record({
    'id' : IDL.Text,
    'effects' : IDL.Vec(Effect),
    'name' : IDL.Text,
    'description' : IDL.Text,
  });
  const Base = IDL.Variant({
    'homeBase' : IDL.Null,
    'thirdBase' : IDL.Null,
    'secondBase' : IDL.Null,
    'firstBase' : IDL.Null,
  });
  const HitLocation = IDL.Variant({
    'rightField' : IDL.Null,
    'stands' : IDL.Null,
    'leftField' : IDL.Null,
    'thirdBase' : IDL.Null,
    'pitcher' : IDL.Null,
    'secondBase' : IDL.Null,
    'shortStop' : IDL.Null,
    'centerField' : IDL.Null,
    'firstBase' : IDL.Null,
  });
  const Injury = IDL.Variant({
    'twistedAnkle' : IDL.Null,
    'brokenArm' : IDL.Null,
    'brokenLeg' : IDL.Null,
    'concussion' : IDL.Null,
  });
  const MatchEndReason = IDL.Variant({
    'noMoreRounds' : IDL.Null,
    'error' : IDL.Text,
  });
  const Event = IDL.Variant({
    'out' : IDL.Record({ 'playerId' : PlayerId__1, 'reason' : OutReason }),
    'throw' : IDL.Record({ 'to' : PlayerId__1, 'from' : PlayerId__1 }),
    'newBatter' : IDL.Record({ 'playerId' : PlayerId__1 }),
    'teamSwap' : IDL.Record({
      'atBatPlayerId' : PlayerId__1,
      'offenseTeamId' : TeamId,
    }),
    'hitByBall' : IDL.Record({ 'playerId' : PlayerId__1 }),
    'catch' : IDL.Record({
      'difficulty' : IDL.Record({ 'value' : IDL.Int, 'crit' : IDL.Bool }),
      'playerId' : PlayerId__1,
      'roll' : IDL.Record({ 'value' : IDL.Int, 'crit' : IDL.Bool }),
    }),
    'auraTrigger' : IDL.Record({ 'id' : MatchAura, 'description' : IDL.Text }),
    'traitTrigger' : IDL.Record({
      'id' : Trait,
      'playerId' : PlayerId__1,
      'description' : IDL.Text,
    }),
    'safeAtBase' : IDL.Record({ 'base' : Base, 'playerId' : PlayerId__1 }),
    'score' : IDL.Record({ 'teamId' : TeamId, 'amount' : IDL.Int }),
    'swing' : IDL.Record({
      'pitchRoll' : IDL.Record({ 'value' : IDL.Int, 'crit' : IDL.Bool }),
      'playerId' : PlayerId__1,
      'roll' : IDL.Record({ 'value' : IDL.Int, 'crit' : IDL.Bool }),
      'outcome' : IDL.Variant({
        'hit' : HitLocation,
        'strike' : IDL.Null,
        'foul' : IDL.Null,
      }),
    }),
    'injury' : IDL.Record({ 'playerId' : IDL.Nat32, 'injury' : Injury }),
    'pitch' : IDL.Record({
      'roll' : IDL.Record({ 'value' : IDL.Int, 'crit' : IDL.Bool }),
      'pitcherId' : PlayerId__1,
    }),
    'matchEnd' : IDL.Record({ 'reason' : MatchEndReason }),
    'death' : IDL.Record({ 'playerId' : IDL.Nat32 }),
  });
  const TurnLog = IDL.Record({
    'initialBaseState' : BaseState,
    'events' : IDL.Vec(Event),
  });
  const RoundLog = IDL.Record({ 'turns' : IDL.Vec(TurnLog) });
  const MatchLog = IDL.Record({ 'rounds' : IDL.Vec(RoundLog) });
  const TeamPositions = IDL.Record({
    'rightField' : IDL.Nat32,
    'leftField' : IDL.Nat32,
    'thirdBase' : IDL.Nat32,
    'pitcher' : IDL.Nat32,
    'secondBase' : IDL.Nat32,
    'shortStop' : IDL.Nat32,
    'centerField' : IDL.Nat32,
    'firstBase' : IDL.Nat32,
  });
  const TeamState = IDL.Record({
    'id' : IDL.Nat,
    'name' : IDL.Text,
    'color' : IDL.Tuple(IDL.Nat8, IDL.Nat8, IDL.Nat8),
    'score' : IDL.Int,
    'logoUrl' : IDL.Text,
    'positions' : TeamPositions,
  });
  const PlayerMatchStats = IDL.Record({
    'battingStats' : IDL.Record({
      'homeRuns' : IDL.Nat,
      'hits' : IDL.Nat,
      'runs' : IDL.Nat,
      'strikeouts' : IDL.Nat,
      'atBats' : IDL.Nat,
    }),
    'injuries' : IDL.Nat,
    'pitchingStats' : IDL.Record({
      'homeRuns' : IDL.Nat,
      'pitches' : IDL.Nat,
      'hits' : IDL.Nat,
      'runs' : IDL.Nat,
      'strikeouts' : IDL.Nat,
      'strikes' : IDL.Nat,
    }),
    'catchingStats' : IDL.Record({
      'missedCatches' : IDL.Nat,
      'throwOuts' : IDL.Nat,
      'throws' : IDL.Nat,
      'successfulCatches' : IDL.Nat,
    }),
  });
  const Skills = IDL.Record({
    'battingAccuracy' : IDL.Int,
    'throwingAccuracy' : IDL.Int,
    'speed' : IDL.Int,
    'catching' : IDL.Int,
    'battingPower' : IDL.Int,
    'defense' : IDL.Int,
    'throwingPower' : IDL.Int,
  });
  const PlayerCondition = IDL.Variant({
    'ok' : IDL.Null,
    'dead' : IDL.Null,
    'injured' : Injury,
  });
  const PlayerStateWithId = IDL.Record({
    'id' : PlayerId,
    'name' : IDL.Text,
    'matchStats' : PlayerMatchStats,
    'teamId' : TeamId,
    'skills' : Skills,
    'condition' : PlayerCondition,
  });
  const Match = IDL.Record({
    'log' : MatchLog,
    'team1' : TeamState,
    'team2' : TeamState,
    'aura' : MatchAura,
    'outs' : IDL.Nat,
    'offenseTeamId' : TeamId,
    'players' : IDL.Vec(PlayerStateWithId),
    'bases' : BaseState,
    'strikes' : IDL.Nat,
  });
  const MatchStatusCompleted = IDL.Record({ 'reason' : MatchEndReason });
  const MatchStatus = IDL.Variant({
    'completed' : MatchStatusCompleted,
    'inProgress' : IDL.Null,
  });
  const TickResult = IDL.Record({ 'match' : Match, 'status' : MatchStatus });
  const MatchGroupWithId = IDL.Record({
    'id' : IDL.Nat,
    'tickTimerId' : IDL.Nat,
    'currentSeed' : IDL.Nat32,
    'matches' : IDL.Vec(TickResult),
  });
  const ResetTickTimerResult = IDL.Variant({
    'ok' : IDL.Null,
    'matchGroupNotFound' : IDL.Null,
  });
  const SetLeagueResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
  });
  const FieldPosition = IDL.Variant({
    'rightField' : IDL.Null,
    'leftField' : IDL.Null,
    'thirdBase' : IDL.Null,
    'pitcher' : IDL.Null,
    'secondBase' : IDL.Null,
    'shortStop' : IDL.Null,
    'centerField' : IDL.Null,
    'firstBase' : IDL.Null,
  });
  const Player = IDL.Record({
    'id' : IDL.Nat32,
    'title' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'likes' : IDL.Vec(IDL.Text),
    'teamId' : IDL.Nat,
    'position' : FieldPosition,
    'quirks' : IDL.Vec(IDL.Text),
    'dislikes' : IDL.Vec(IDL.Text),
    'skills' : Skills,
  });
  const StartMatchTeam = IDL.Record({
    'id' : IDL.Nat,
    'name' : IDL.Text,
    'color' : IDL.Tuple(IDL.Nat8, IDL.Nat8, IDL.Nat8),
    'logoUrl' : IDL.Text,
    'positions' : IDL.Record({
      'rightField' : Player,
      'leftField' : Player,
      'thirdBase' : Player,
      'pitcher' : Player,
      'secondBase' : Player,
      'shortStop' : Player,
      'centerField' : Player,
      'firstBase' : Player,
    }),
  });
  const StartMatchRequest = IDL.Record({
    'team1' : StartMatchTeam,
    'team2' : StartMatchTeam,
    'aura' : MatchAura,
  });
  const StartMatchGroupRequest = IDL.Record({
    'id' : IDL.Nat,
    'matches' : IDL.Vec(StartMatchRequest),
  });
  const StartMatchGroupResult = IDL.Variant({
    'ok' : IDL.Null,
    'noMatchesSpecified' : IDL.Null,
  });
  const TickMatchGroupResult = IDL.Variant({
    'completed' : IDL.Null,
    'matchGroupNotFound' : IDL.Null,
    'onStartCallbackError' : IDL.Variant({
      'notAuthorized' : IDL.Null,
      'notScheduledYet' : IDL.Null,
      'matchGroupNotFound' : IDL.Null,
      'alreadyStarted' : IDL.Null,
      'unknown' : IDL.Text,
    }),
    'inProgress' : IDL.Null,
  });
  return IDL.Service({
    'cancelMatchGroup' : IDL.Func(
        [CancelMatchGroupRequest],
        [CancelMatchGroupResult],
        [],
      ),
    'getMatchGroup' : IDL.Func(
        [IDL.Nat],
        [IDL.Opt(MatchGroupWithId)],
        ['query'],
      ),
    'getMatchGroups' : IDL.Func([], [IDL.Vec(MatchGroupWithId)], ['query']),
    'resetTickTimer' : IDL.Func([IDL.Nat], [ResetTickTimerResult], []),
    'setLeague' : IDL.Func([IDL.Principal], [SetLeagueResult], []),
    'startMatchGroup' : IDL.Func(
        [StartMatchGroupRequest],
        [StartMatchGroupResult],
        [],
      ),
    'tickMatchGroup' : IDL.Func([IDL.Nat], [TickMatchGroupResult], []),
  });
};
export const init = ({ IDL }) => { return []; };
