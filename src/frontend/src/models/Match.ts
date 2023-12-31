
import { Principal } from "@dfinity/principal";
import { TeamIdOrTie } from "./Team";
import { OfferingWithMetaData } from "./Offering";


export type MatchGroupDetails = {
    id: number;
    time: bigint;
    matches: MatchDetails[];
    state: 'NotScheduled' | 'Scheduled' | 'InProgress' | 'Completed';
};

export type MatchDetails = {
    id: number;
    time: bigint;
    matchGroupId: number;
    team1: TeamDetails;
    team2: TeamDetails;
    offerings: OfferingWithMetaData[] | undefined;
    winner: TeamIdOrTie | undefined;
    state: MatchState;
    error: string | undefined;
};
export type MatchState = 'NotScheduled' | 'Scheduled' | 'InProgress' | 'Played' | 'Error';

export type TeamDetails = {
    id: Principal;
    name: string;
    logoUrl: string;
    score: number | undefined;
};
