import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface CreateProposalRequest { 'content' : ProposalContent }
export type CreateProposalResult = { 'ok' : bigint } |
  { 'notAuthorized' : null } |
  { 'teamNotFound' : null };
export type CreateTeamRequest = {};
export type CreateTeamResult = { 'ok' : { 'id' : bigint } } |
  { 'notAuthorized' : null };
export type FieldPosition = { 'rightField' : null } |
  { 'leftField' : null } |
  { 'thirdBase' : null } |
  { 'pitcher' : null } |
  { 'secondBase' : null } |
  { 'shortStop' : null } |
  { 'centerField' : null } |
  { 'firstBase' : null };
export type GetCyclesResult = { 'ok' : bigint } |
  { 'notAuthorized' : null };
export type GetProposalResult = { 'ok' : Proposal } |
  { 'proposalNotFound' : null } |
  { 'teamNotFound' : null };
export type GetProposalsResult = { 'ok' : PagedResult } |
  { 'teamNotFound' : null };
export interface GetScenarioVoteRequest { 'scenarioId' : string }
export type GetScenarioVoteResult = {
    'ok' : [] | [{ 'option' : bigint, 'votingPower' : bigint }]
  } |
  { 'teamNotFound' : null } |
  { 'scenarioNotFound' : null };
export interface GetScenarioVotingResultsRequest { 'scenarioId' : string }
export type GetScenarioVotingResultsResult = { 'ok' : ScenarioVotingResults } |
  { 'notAuthorized' : null } |
  { 'scenarioNotFound' : null };
export interface OnNewScenarioRequest {
  'scenarioId' : string,
  'optionCount' : bigint,
}
export type OnNewScenarioResult = { 'ok' : null } |
  { 'notAuthorized' : null };
export interface OnScenarioVoteCompleteRequest { 'scenarioId' : string }
export type OnScenarioVoteCompleteResult = { 'ok' : null } |
  { 'notAuthorized' : null } |
  { 'scenarioNotFound' : null };
export type OnSeasonEndResult = { 'ok' : null } |
  { 'notAuthorized' : null };
export interface PagedResult {
  'data' : Array<Proposal>,
  'count' : bigint,
  'offset' : bigint,
}
export interface Proposal {
  'id' : bigint,
  'content' : ProposalContent,
  'timeStart' : bigint,
  'votes' : Array<[Principal, Vote]>,
  'statusLog' : Array<ProposalStatusLogEntry>,
  'endTimerId' : [] | [bigint],
  'proposer' : Principal,
  'timeEnd' : bigint,
}
export type ProposalContent = {
    'train' : { 'skill' : Skill, 'position' : FieldPosition }
  } |
  { 'changeName' : { 'name' : string } } |
  {
    'swapPlayerPositions' : {
      'position1' : FieldPosition,
      'position2' : FieldPosition,
    }
  };
export type ProposalStatusLogEntry = {
    'failedToExecute' : { 'time' : Time, 'error' : string }
  } |
  { 'rejected' : { 'time' : Time } } |
  { 'executing' : { 'time' : Time } } |
  { 'executed' : { 'time' : Time } };
export interface ScenarioTeamVotingResult {
  'option' : bigint,
  'teamId' : bigint,
}
export interface ScenarioVotingResults {
  'teamOptions' : Array<ScenarioTeamVotingResult>,
}
export type SetLeagueResult = { 'ok' : null } |
  { 'notAuthorized' : null };
export type Skill = { 'battingAccuracy' : null } |
  { 'throwingAccuracy' : null } |
  { 'speed' : null } |
  { 'catching' : null } |
  { 'battingPower' : null } |
  { 'defense' : null } |
  { 'throwingPower' : null };
export type Time = bigint;
export interface Vote { 'value' : [] | [boolean], 'votingPower' : bigint }
export interface VoteOnProposalRequest {
  'vote' : boolean,
  'proposalId' : bigint,
}
export type VoteOnProposalResult = { 'ok' : null } |
  { 'proposalNotFound' : null } |
  { 'notAuthorized' : null } |
  { 'alreadyVoted' : null } |
  { 'votingClosed' : null } |
  { 'teamNotFound' : null };
export interface VoteOnScenarioRequest {
  'scenarioId' : string,
  'option' : bigint,
}
export type VoteOnScenarioResult = { 'ok' : null } |
  { 'invalidOption' : null } |
  { 'notAuthorized' : null } |
  { 'alreadyVoted' : null } |
  { 'seasonStatusFetchError' : string } |
  { 'teamNotInScenario' : null } |
  { 'votingNotOpen' : null } |
  { 'teamNotFound' : null } |
  { 'scenarioNotFound' : null };
export interface _SERVICE {
  'createProposal' : ActorMethod<
    [bigint, CreateProposalRequest],
    CreateProposalResult
  >,
  'createTeam' : ActorMethod<[CreateTeamRequest], CreateTeamResult>,
  'getCycles' : ActorMethod<[], GetCyclesResult>,
  'getProposal' : ActorMethod<[bigint, bigint], GetProposalResult>,
  'getProposals' : ActorMethod<[bigint, bigint, bigint], GetProposalsResult>,
  'getScenarioVote' : ActorMethod<
    [GetScenarioVoteRequest],
    GetScenarioVoteResult
  >,
  'getScenarioVotingResults' : ActorMethod<
    [GetScenarioVotingResultsRequest],
    GetScenarioVotingResultsResult
  >,
  'onNewScenario' : ActorMethod<[OnNewScenarioRequest], OnNewScenarioResult>,
  'onScenarioVoteComplete' : ActorMethod<
    [OnScenarioVoteCompleteRequest],
    OnScenarioVoteCompleteResult
  >,
  'onSeasonEnd' : ActorMethod<[], OnSeasonEndResult>,
  'setLeague' : ActorMethod<[Principal], SetLeagueResult>,
  'voteOnProposal' : ActorMethod<
    [bigint, VoteOnProposalRequest],
    VoteOnProposalResult
  >,
  'voteOnScenario' : ActorMethod<
    [bigint, VoteOnScenarioRequest],
    VoteOnScenarioResult
  >,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
