import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type Base = { 'homeBase' : null } |
  { 'thirdBase' : null } |
  { 'secondBase' : null } |
  { 'firstBase' : null };
export interface BaseState {
  'atBat' : PlayerId,
  'thirdBase' : [] | [PlayerId],
  'secondBase' : [] | [PlayerId],
  'firstBase' : [] | [PlayerId],
}
export interface CancelMatchGroupRequest { 'id' : bigint }
export type CancelMatchGroupResult = { 'ok' : null } |
  { 'matchGroupNotFound' : null };
export type Effect = { 'skill' : { 'skill' : [] | [Skill], 'delta' : bigint } };
export type Event = {
    'out' : { 'playerId' : PlayerId__1, 'reason' : OutReason }
  } |
  { 'throw' : { 'to' : PlayerId__1, 'from' : PlayerId__1 } } |
  { 'newBatter' : { 'playerId' : PlayerId__1 } } |
  { 'teamSwap' : { 'atBatPlayerId' : PlayerId__1, 'offenseTeamId' : TeamId } } |
  { 'hitByBall' : { 'playerId' : PlayerId__1 } } |
  {
    'catch' : {
      'difficulty' : { 'value' : bigint, 'crit' : boolean },
      'playerId' : PlayerId__1,
      'roll' : { 'value' : bigint, 'crit' : boolean },
    }
  } |
  { 'auraTrigger' : { 'id' : MatchAura, 'description' : string } } |
  {
    'traitTrigger' : {
      'id' : Trait,
      'playerId' : PlayerId__1,
      'description' : string,
    }
  } |
  { 'safeAtBase' : { 'base' : Base, 'playerId' : PlayerId__1 } } |
  { 'score' : { 'teamId' : TeamId, 'amount' : bigint } } |
  {
    'swing' : {
      'pitchRoll' : { 'value' : bigint, 'crit' : boolean },
      'playerId' : PlayerId__1,
      'roll' : { 'value' : bigint, 'crit' : boolean },
      'outcome' : { 'hit' : HitLocation } |
        { 'strike' : null } |
        { 'foul' : null },
    }
  } |
  { 'injury' : { 'playerId' : number, 'injury' : Injury } } |
  {
    'pitch' : {
      'roll' : { 'value' : bigint, 'crit' : boolean },
      'pitcherId' : PlayerId__1,
    }
  } |
  { 'matchEnd' : { 'reason' : MatchEndReason } } |
  { 'death' : { 'playerId' : number } };
export type FieldPosition = { 'rightField' : null } |
  { 'leftField' : null } |
  { 'thirdBase' : null } |
  { 'pitcher' : null } |
  { 'secondBase' : null } |
  { 'shortStop' : null } |
  { 'centerField' : null } |
  { 'firstBase' : null };
export type HitLocation = { 'rightField' : null } |
  { 'stands' : null } |
  { 'leftField' : null } |
  { 'thirdBase' : null } |
  { 'pitcher' : null } |
  { 'secondBase' : null } |
  { 'shortStop' : null } |
  { 'centerField' : null } |
  { 'firstBase' : null };
export type Injury = { 'twistedAnkle' : null } |
  { 'brokenArm' : null } |
  { 'brokenLeg' : null } |
  { 'concussion' : null };
export interface Match {
  'log' : MatchLog,
  'team1' : TeamState,
  'team2' : TeamState,
  'aura' : MatchAura,
  'outs' : bigint,
  'offenseTeamId' : TeamId,
  'players' : Array<PlayerStateWithId>,
  'bases' : BaseState,
  'strikes' : bigint,
}
export type MatchAura = { 'foggy' : null } |
  { 'moveBasesIn' : null } |
  { 'extraStrike' : null } |
  { 'moreBlessingsAndCurses' : null } |
  { 'fastBallsHardHits' : null } |
  { 'explodingBalls' : null } |
  { 'lowGravity' : null } |
  { 'doubleOrNothing' : null } |
  { 'windy' : null } |
  { 'rainy' : null };
export type MatchEndReason = { 'noMoreRounds' : null } |
  { 'error' : string };
export interface MatchGroupWithId {
  'id' : bigint,
  'tickTimerId' : bigint,
  'currentSeed' : number,
  'matches' : Array<TickResult>,
}
export interface MatchLog { 'rounds' : Array<RoundLog> }
export type MatchStatus = { 'completed' : MatchStatusCompleted } |
  { 'inProgress' : null };
export interface MatchStatusCompleted { 'reason' : MatchEndReason }
export type OutReason = { 'strikeout' : null } |
  { 'ballCaught' : null } |
  { 'hitByBall' : null };
export interface Player {
  'id' : number,
  'title' : string,
  'name' : string,
  'description' : string,
  'likes' : Array<string>,
  'teamId' : bigint,
  'position' : FieldPosition,
  'quirks' : Array<string>,
  'dislikes' : Array<string>,
  'skills' : Skills,
}
export type PlayerCondition = { 'ok' : null } |
  { 'dead' : null } |
  { 'injured' : Injury };
export type PlayerId = number;
export type PlayerId__1 = number;
export interface PlayerMatchStats {
  'battingStats' : {
    'homeRuns' : bigint,
    'hits' : bigint,
    'runs' : bigint,
    'strikeouts' : bigint,
    'atBats' : bigint,
  },
  'injuries' : bigint,
  'pitchingStats' : {
    'homeRuns' : bigint,
    'pitches' : bigint,
    'hits' : bigint,
    'runs' : bigint,
    'strikeouts' : bigint,
    'strikes' : bigint,
  },
  'catchingStats' : {
    'missedCatches' : bigint,
    'throwOuts' : bigint,
    'throws' : bigint,
    'successfulCatches' : bigint,
  },
}
export interface PlayerStateWithId {
  'id' : PlayerId,
  'name' : string,
  'matchStats' : PlayerMatchStats,
  'teamId' : TeamId,
  'skills' : Skills,
  'condition' : PlayerCondition,
}
export type ResetTickTimerResult = { 'ok' : null } |
  { 'matchGroupNotFound' : null };
export interface RoundLog { 'turns' : Array<TurnLog> }
export type SetLeagueResult = { 'ok' : null } |
  { 'notAuthorized' : null };
export type Skill = { 'battingAccuracy' : null } |
  { 'throwingAccuracy' : null } |
  { 'speed' : null } |
  { 'catching' : null } |
  { 'battingPower' : null } |
  { 'defense' : null } |
  { 'throwingPower' : null };
export interface Skills {
  'battingAccuracy' : bigint,
  'throwingAccuracy' : bigint,
  'speed' : bigint,
  'catching' : bigint,
  'battingPower' : bigint,
  'defense' : bigint,
  'throwingPower' : bigint,
}
export interface StartMatchGroupRequest {
  'id' : bigint,
  'matches' : Array<StartMatchRequest>,
}
export type StartMatchGroupResult = { 'ok' : null } |
  { 'noMatchesSpecified' : null };
export interface StartMatchRequest {
  'team1' : StartMatchTeam,
  'team2' : StartMatchTeam,
  'aura' : MatchAura,
}
export interface StartMatchTeam {
  'id' : bigint,
  'name' : string,
  'color' : [number, number, number],
  'logoUrl' : string,
  'positions' : {
    'rightField' : Player,
    'leftField' : Player,
    'thirdBase' : Player,
    'pitcher' : Player,
    'secondBase' : Player,
    'shortStop' : Player,
    'centerField' : Player,
    'firstBase' : Player,
  },
}
export type TeamId = { 'team1' : null } |
  { 'team2' : null };
export interface TeamPositions {
  'rightField' : number,
  'leftField' : number,
  'thirdBase' : number,
  'pitcher' : number,
  'secondBase' : number,
  'shortStop' : number,
  'centerField' : number,
  'firstBase' : number,
}
export interface TeamState {
  'id' : bigint,
  'name' : string,
  'color' : [number, number, number],
  'score' : bigint,
  'logoUrl' : string,
  'positions' : TeamPositions,
}
export type TickMatchGroupResult = { 'completed' : null } |
  { 'matchGroupNotFound' : null } |
  {
    'onStartCallbackError' : { 'notAuthorized' : null } |
      { 'notScheduledYet' : null } |
      { 'matchGroupNotFound' : null } |
      { 'alreadyStarted' : null } |
      { 'unknown' : string }
  } |
  { 'inProgress' : null };
export interface TickResult { 'match' : Match, 'status' : MatchStatus }
export interface Trait {
  'id' : string,
  'effects' : Array<Effect>,
  'name' : string,
  'description' : string,
}
export interface TurnLog {
  'initialBaseState' : BaseState,
  'events' : Array<Event>,
}
export interface _SERVICE {
  'cancelMatchGroup' : ActorMethod<
    [CancelMatchGroupRequest],
    CancelMatchGroupResult
  >,
  'getMatchGroup' : ActorMethod<[bigint], [] | [MatchGroupWithId]>,
  'getMatchGroups' : ActorMethod<[], Array<MatchGroupWithId>>,
  'resetTickTimer' : ActorMethod<[bigint], ResetTickTimerResult>,
  'setLeague' : ActorMethod<[Principal], SetLeagueResult>,
  'startMatchGroup' : ActorMethod<
    [StartMatchGroupRequest],
    StartMatchGroupResult
  >,
  'tickMatchGroup' : ActorMethod<[bigint], TickMatchGroupResult>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
