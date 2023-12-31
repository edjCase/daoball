import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import { createActor } from './Actor';
import { InterfaceFactory, Nat } from '@dfinity/candid/lib/cjs/idl';
import { IDL } from "@dfinity/candid";
import { SeasonStatus, SeasonStatusIdl } from '../models/Season';
import { Offering, OfferingIdl } from '../models/Offering';
import { MatchAura, MatchAuraIdl } from '../models/MatchAura';
import { Player, PlayerIdl } from './PlayerLedger';
import { Team, TeamIdOrTie, TeamIdOrTieIdl, TeamIdl } from '../models/Team';

export type Time = bigint;
export const TimeIdl = IDL.Int;
export type Nat = bigint;
export type Nat32 = number;
export type Nat64 = number;
export type Int = number;
export type Bool = boolean;
export type Text = string;


export type TeamStartData = {
  offering: Offering;
  championId: Nat32;
  players: Player[];
};
export const TeamStartDataIdl = IDL.Record({
  offering: OfferingIdl,
  championId: IDL.Nat32,
  players: IDL.Vec(PlayerIdl),
});

export type MatchStartData = {
  team1: TeamStartData;
  team2: TeamStartData;
  aura: MatchAura;
};
export const MatchStartDataIdl = IDL.Record({
  team1: TeamStartDataIdl,
  team2: TeamStartDataIdl,
  aura: MatchAuraIdl,
});


export type StartSeasonRequest = {
  startTime: Time;
};
export const StartSeasonRequestIdl = IDL.Record({
  startTime: TimeIdl,
});

export type StartSeasonResult =
  | { ok: null }
  | { alreadyStarted: null }
  | { noStadiumsExist: null }
  | { seedGenerationError: Text }
  | { noTeams: null }
  | { oddNumberOfTeams: null };
export const StartSeasonResultIdl = IDL.Variant({
  ok: IDL.Null,
  alreadyStarted: IDL.Null,
  noStadiumsExist: IDL.Null,
  seedGenerationError: IDL.Text,
  noTeams: IDL.Null,
  oddNumberOfTeams: IDL.Null,
});

export type CloseSeasonResult =
  | { ok: null }
  | { seasonInProgress: null }
  | { notAuthorized: null }
  | { seasonNotOpen: null };
export const CloseSeasonResultIdl = IDL.Variant({
  ok: IDL.Null,
  seasonInProgress: IDL.Null,
  notAuthorized: IDL.Null,
  seasonNotOpen: IDL.Null,
});

export type CreateTeamRequest = {
  name: Text;
  logoUrl: Text;
  tokenName: Text;
  tokenSymbol: Text;
  motto: Text;
  description: Text;
};
export const CreateTeamRequestIdl = IDL.Record({
  name: IDL.Text,
  logoUrl: IDL.Text,
  tokenName: IDL.Text,
  tokenSymbol: IDL.Text,
  motto: IDL.Text,
  description: IDL.Text,
});

export type CreateTeamResult =
  | { ok: Principal }
  | { nameTaken: null }
  | { noStadiumsExist: null };
export const CreateTeamResultIdl = IDL.Variant({
  ok: IDL.Principal,
  nameTaken: IDL.Null,
  noStadiumsExist: IDL.Null,
});

export type MintRequest = {
  amount: Nat;
  teamId: Principal;
};
export const MintRequestIdl = IDL.Record({
  amount: IDL.Nat,
  teamId: IDL.Principal,
});

export type TimeError =
  | { TooOld: null }
  | { CreatedInFuture: { ledger_time: Nat64 } };
export const TimeErrorIdl = IDL.Variant({
  TooOld: IDL.Null,
  CreatedInFuture: IDL.Record({ ledger_time: IDL.Nat64 }),
});

export type TransferError =
  | TimeError
  | { BadFee: { expected_fee: Nat } }
  | { BadBurn: { min_burn_amount: Nat } }
  | { InsufficientFunds: { balance: Nat } }
  | { Duplicate: { duplicate_of: Nat } }
  | { TemporarilyUnavailable: null }
  | { GenericError: { error_code: Nat; message: Text } };
export const TransferErrorIdl = IDL.Variant({
  TooOld: IDL.Null,
  CreatedInFuture: IDL.Record({ ledger_time: IDL.Nat64 }),
  BadFee: IDL.Record({ expected_fee: IDL.Nat }),
  BadBurn: IDL.Record({ min_burn_amount: IDL.Nat }),
  InsufficientFunds: IDL.Record({ balance: IDL.Nat }),
  Duplicate: IDL.Record({ duplicate_of: IDL.Nat }),
  TemporarilyUnavailable: IDL.Null,
  GenericError: IDL.Record({ error_code: IDL.Nat, message: IDL.Text }),
});

export type MintResult =
  | { ok: Nat }
  | { teamNotFound: null }
  | { transferError: TransferError };
export const MintResultIdl = IDL.Variant({
  ok: IDL.Nat,
  teamNotFound: IDL.Null,
  transferError: TransferErrorIdl,
});

export type MatchPrediction = {
  winner: TeamIdOrTie;
};
export const MatchPredictionIdl = IDL.Record({
  winner: TeamIdOrTieIdl
});

export type PredictMatchOutcomeRequest = {
  matchId: Nat32;
  prediction: MatchPrediction;
};
export const PredictMatchOutcomeRequestIdl = IDL.Record({
  matchId: IDL.Nat32,
  prediction: MatchPredictionIdl,
});

export type PredictMatchOutcomeResult =
  | { ok: null }
  | { matchNotFound: null }
  | { matchGroupNotFound: null }
  | { predictionsClosed: null }
  | { identityRequired: null };
export const PredictMatchOutcomeResultIdl = IDL.Variant({
  ok: IDL.Null,
  matchNotFound: IDL.Null,
  matchGroupNotFound: IDL.Null,
  predictionsClosed: IDL.Null,
  identityRequired: IDL.Null,
});

export interface _SERVICE {
  'getTeams': ActorMethod<[], Array<Team>>,
  'getSeasonStatus': ActorMethod<[], SeasonStatus>,
  'startSeason': ActorMethod<[StartSeasonRequest], StartSeasonResult>,
  'createTeam': ActorMethod<[CreateTeamRequest], CreateTeamResult>,
  'predictMatchOutcome': ActorMethod<[PredictMatchOutcomeRequest], PredictMatchOutcomeResult>;
  'mint': ActorMethod<[MintRequest], MintResult>,
  'updateLeagueCanisters': ActorMethod<[], undefined>,
}



export const idlFactory: InterfaceFactory = ({ }) => {

  return IDL.Service({
    'getTeams': IDL.Func([], [IDL.Vec(TeamIdl)], ['query']),
    'getSeasonStatus': IDL.Func([], [SeasonStatusIdl], ['query']),
    'startSeason': IDL.Func([StartSeasonRequestIdl], [StartSeasonResultIdl], []),
    'createTeam': IDL.Func([CreateTeamRequestIdl], [CreateTeamResultIdl], []),
    'predictMatchOutcome': IDL.Func([PredictMatchOutcomeRequestIdl], [PredictMatchOutcomeResultIdl], []),
    'mint': IDL.Func([MintRequestIdl], [MintResultIdl], []),
    'updateLeagueCanisters': IDL.Func([], [], []),
  });
};


const canisterId = process.env.CANISTER_ID_LEAGUE || "";
// Keep factory due to changing identity
export let leagueAgentFactory = () => createActor<_SERVICE>(canisterId, idlFactory);

