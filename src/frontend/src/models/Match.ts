import { TeamIdOrTie } from "../ic-agent/declarations/main";


export type MatchGroupDetails = {
    id: bigint;
    time: bigint;
    matches: MatchDetails[];
    state: 'NotScheduled' | 'Scheduled' | 'InProgress' | 'Completed';
};

export type MatchDetails = {
    id: bigint;
    time: bigint;
    matchGroupId: bigint;
    team1: TeamDetailsOrUndetermined;
    team2: TeamDetailsOrUndetermined;
    winner: TeamIdOrTie | undefined;
    state: MatchState;
};
export type MatchState = 'NotScheduled' | 'Scheduled' | 'InProgress' | 'Played' | 'Error';

export type TeamDetails = {
    id: bigint;
};

export type TeamDetailsWithScore = TeamDetails & { score: bigint | undefined };

export type TeamDetailsOrUndetermined =
    | TeamDetailsWithScore
    | { winnerOfMatch: number }
    | { seasonStandingIndex: number };