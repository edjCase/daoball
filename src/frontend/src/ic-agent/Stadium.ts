import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import { createActor } from './Actor';
import type { InterfaceFactory } from '@dfinity/candid/lib/cjs/idl';


export type Time = bigint;
export type TeamConfig = {
  'pitcher': number,
  'catcher': number,
  'firstBase': number,
  'secondBase': number,
  'thirdBase': number,
  'shortStop': number,
  'leftField': number,
  'centerField': number,
  'rightField': number,
  'battingOrder': number[],
  'substitutes': number[]
};
export type MatchTeam = {
  'id': Principal,
  'config': [] | [TeamConfig],
  'score': [] | [bigint],
  'predictionVotes': bigint
};
export type Match = { 'id': number, teams: [MatchTeam, MatchTeam], 'time': Time, 'winner': [] | [Principal] };
export interface _SERVICE {
  'getMatches': ActorMethod<[], Match[]>,
}



export const idlFactory: InterfaceFactory = ({ IDL }) => {
  const TeamConfig = IDL.Record({
    'pitcher': IDL.Nat32,
    'catcher': IDL.Nat32,
    'firstBase': IDL.Nat32,
    'secondBase': IDL.Nat32,
    'thirdBase': IDL.Nat32,
    'shortStop': IDL.Nat32,
    'leftField': IDL.Nat32,
    'centerField': IDL.Nat32,
    'rightField': IDL.Nat32,
    'battingOrder': IDL.Vec(IDL.Nat32),
    'substitutes': IDL.Vec(IDL.Nat32)
  });
  const MatchTeamInfo = IDL.Record({
    'id': IDL.Principal,
    'config': IDL.Opt(TeamConfig),
    'score': IDL.Opt(IDL.Nat),
    'predictionVotes': IDL.Nat
  });
  const Match = IDL.Record({
    'id': IDL.Nat32,
    'teams': IDL.Tuple(MatchTeamInfo, MatchTeamInfo),
    'time': IDL.Int,
    'winner': IDL.Opt(IDL.Principal)
  });
  return IDL.Service({
    'getMatches': IDL.Func([], [IDL.Vec(Match)], ['query']),
  });
};
export const stadiumAgentFactory = (canisterId: string | Principal) => createActor<_SERVICE>(canisterId, idlFactory);