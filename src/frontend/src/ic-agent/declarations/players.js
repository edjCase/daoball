export const idlFactory = ({ IDL }) => {
  const CreatePlayerFluffRequest = IDL.Record({
    'title' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'likes' : IDL.Vec(IDL.Text),
    'quirks' : IDL.Vec(IDL.Text),
    'dislikes' : IDL.Vec(IDL.Text),
  });
  const InvalidError = IDL.Variant({
    'nameTaken' : IDL.Null,
    'nameNotSpecified' : IDL.Null,
  });
  const CreatePlayerFluffError = IDL.Variant({
    'notAuthorized' : IDL.Null,
    'invalid' : IDL.Vec(InvalidError),
  });
  const CreatePlayerFluffResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : CreatePlayerFluffError,
  });
  const PlayerId = IDL.Nat32;
  const PlayerMatchStatsWithId = IDL.Record({
    'playerId' : PlayerId,
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
  const AddMatchStatsError = IDL.Variant({ 'notAuthorized' : IDL.Null });
  const AddMatchStatsResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : AddMatchStatsError,
  });
  const Duration = IDL.Variant({
    'matches' : IDL.Nat,
    'indefinite' : IDL.Null,
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
  const TargetPositionInstance = IDL.Record({
    'teamId' : IDL.Nat,
    'position' : FieldPosition,
  });
  const SkillPlayerEffectOutcome = IDL.Record({
    'duration' : Duration,
    'skill' : Skill,
    'target' : TargetPositionInstance,
    'delta' : IDL.Int,
  });
  const InjuryPlayerEffectOutcome = IDL.Record({
    'target' : TargetPositionInstance,
  });
  const PlayerEffectOutcome = IDL.Variant({
    'skill' : SkillPlayerEffectOutcome,
    'injury' : InjuryPlayerEffectOutcome,
  });
  const ApplyEffectsRequest = IDL.Vec(PlayerEffectOutcome);
  const ApplyEffectsError = IDL.Variant({ 'notAuthorized' : IDL.Null });
  const ApplyEffectsResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : ApplyEffectsError,
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
  const GetPlayerError = IDL.Variant({ 'notFound' : IDL.Null });
  const GetPlayerResult = IDL.Variant({
    'ok' : Player,
    'err' : GetPlayerError,
  });
  const GetPositionError = IDL.Variant({ 'teamNotFound' : IDL.Null });
  const Result = IDL.Variant({ 'ok' : Player, 'err' : GetPositionError });
  const OnSeasonEndError = IDL.Variant({ 'notAuthorized' : IDL.Null });
  const OnSeasonEndResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : OnSeasonEndError,
  });
  const PopulateTeamRosterError = IDL.Variant({
    'missingFluff' : IDL.Null,
    'notAuthorized' : IDL.Null,
  });
  const PopulateTeamRosterResult = IDL.Variant({
    'ok' : IDL.Vec(Player),
    'err' : PopulateTeamRosterError,
  });
  const SetTeamsCanisterIdError = IDL.Variant({ 'notAuthorized' : IDL.Null });
  const SetTeamsCanisterIdResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : SetTeamsCanisterIdError,
  });
  const SwapPlayerPositionsError = IDL.Variant({ 'notAuthorized' : IDL.Null });
  const SwapPlayerPositionsResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : SwapPlayerPositionsError,
  });
  return IDL.Service({
    'addFluff' : IDL.Func(
        [CreatePlayerFluffRequest],
        [CreatePlayerFluffResult],
        [],
      ),
    'addMatchStats' : IDL.Func(
        [IDL.Nat, IDL.Vec(PlayerMatchStatsWithId)],
        [AddMatchStatsResult],
        [],
      ),
    'applyEffects' : IDL.Func([ApplyEffectsRequest], [ApplyEffectsResult], []),
    'getAllPlayers' : IDL.Func([], [IDL.Vec(Player)], ['query']),
    'getPlayer' : IDL.Func([IDL.Nat32], [GetPlayerResult], ['query']),
    'getPosition' : IDL.Func([IDL.Nat, FieldPosition], [Result], ['query']),
    'getTeamPlayers' : IDL.Func([IDL.Nat], [IDL.Vec(Player)], ['query']),
    'onSeasonEnd' : IDL.Func([], [OnSeasonEndResult], []),
    'populateTeamRoster' : IDL.Func([IDL.Nat], [PopulateTeamRosterResult], []),
    'setTeamsCanisterId' : IDL.Func(
        [IDL.Principal],
        [SetTeamsCanisterIdResult],
        [],
      ),
    'swapTeamPositions' : IDL.Func(
        [IDL.Nat, FieldPosition, FieldPosition],
        [SwapPlayerPositionsResult],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
