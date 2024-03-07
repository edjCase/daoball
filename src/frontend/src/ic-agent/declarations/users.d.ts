import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface AwardPointsRequest { 'userId' : Principal, 'points' : bigint }
export type AwardPointsResult = { 'ok' : null } |
  { 'notAuthorized' : null };
export type GetUserResult = { 'ok' : User } |
  { 'notAuthorized' : null } |
  { 'notFound' : null };
export type SetUserFavoriteTeamResult = { 'ok' : null } |
  { 'notAuthorized' : null } |
  { 'alreadySet' : null } |
  { 'identityRequired' : null } |
  { 'teamNotFound' : null };
export type TeamAssociationKind = { 'fan' : null } |
  { 'owner' : null };
export interface User {
  'teamAssociation' : [] | [{ 'id' : Principal, 'kind' : TeamAssociationKind }],
  'points' : bigint,
}
export interface _SERVICE {
  'awardPoints' : ActorMethod<[Array<AwardPointsRequest>], AwardPointsResult>,
  'get' : ActorMethod<[Principal], GetUserResult>,
  'setFavoriteTeam' : ActorMethod<
    [Principal, Principal],
    SetUserFavoriteTeamResult
  >,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];