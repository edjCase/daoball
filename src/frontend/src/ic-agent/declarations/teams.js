export const idlFactory = ({ IDL }) => {
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
  const ProposalContent = IDL.Variant({
    'train' : IDL.Record({ 'skill' : Skill, 'position' : FieldPosition }),
    'changeName' : IDL.Record({ 'name' : IDL.Text }),
    'swapPlayerPositions' : IDL.Record({
      'position1' : FieldPosition,
      'position2' : FieldPosition,
    }),
  });
  const CreateProposalRequest = IDL.Record({ 'content' : ProposalContent });
  const CreateProposalResult = IDL.Variant({
    'ok' : IDL.Nat,
    'notAuthorized' : IDL.Null,
    'teamNotFound' : IDL.Null,
  });
  const CreateTeamRequest = IDL.Record({});
  const CreateTeamResult = IDL.Variant({
    'ok' : IDL.Record({ 'id' : IDL.Nat }),
    'notAuthorized' : IDL.Null,
  });
  const GetCyclesResult = IDL.Variant({
    'ok' : IDL.Nat,
    'notAuthorized' : IDL.Null,
  });
  const Vote = IDL.Record({
    'value' : IDL.Opt(IDL.Bool),
    'votingPower' : IDL.Nat,
  });
  const Time = IDL.Int;
  const ProposalStatusLogEntry = IDL.Variant({
    'failedToExecute' : IDL.Record({ 'time' : Time, 'error' : IDL.Text }),
    'rejected' : IDL.Record({ 'time' : Time }),
    'executing' : IDL.Record({ 'time' : Time }),
    'executed' : IDL.Record({ 'time' : Time }),
  });
  const Proposal = IDL.Record({
    'id' : IDL.Nat,
    'content' : ProposalContent,
    'timeStart' : IDL.Int,
    'votes' : IDL.Vec(IDL.Tuple(IDL.Principal, Vote)),
    'statusLog' : IDL.Vec(ProposalStatusLogEntry),
    'endTimerId' : IDL.Opt(IDL.Nat),
    'proposer' : IDL.Principal,
    'timeEnd' : IDL.Int,
  });
  const GetProposalResult = IDL.Variant({
    'ok' : Proposal,
    'proposalNotFound' : IDL.Null,
    'teamNotFound' : IDL.Null,
  });
  const PagedResult = IDL.Record({
    'data' : IDL.Vec(Proposal),
    'count' : IDL.Nat,
    'offset' : IDL.Nat,
  });
  const GetProposalsResult = IDL.Variant({
    'ok' : PagedResult,
    'teamNotFound' : IDL.Null,
  });
  const GetScenarioVoteRequest = IDL.Record({ 'scenarioId' : IDL.Text });
  const GetScenarioVoteResult = IDL.Variant({
    'ok' : IDL.Opt(IDL.Record({ 'option' : IDL.Nat, 'votingPower' : IDL.Nat })),
    'teamNotFound' : IDL.Null,
    'scenarioNotFound' : IDL.Null,
  });
  const GetScenarioVotingResultsRequest = IDL.Record({
    'scenarioId' : IDL.Text,
  });
  const ScenarioTeamVotingResult = IDL.Record({
    'option' : IDL.Nat,
    'teamId' : IDL.Nat,
  });
  const ScenarioVotingResults = IDL.Record({
    'teamOptions' : IDL.Vec(ScenarioTeamVotingResult),
  });
  const GetScenarioVotingResultsResult = IDL.Variant({
    'ok' : ScenarioVotingResults,
    'notAuthorized' : IDL.Null,
    'scenarioNotFound' : IDL.Null,
  });
  const OnNewScenarioRequest = IDL.Record({
    'scenarioId' : IDL.Text,
    'optionCount' : IDL.Nat,
  });
  const OnNewScenarioResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
  });
  const OnScenarioVoteCompleteRequest = IDL.Record({ 'scenarioId' : IDL.Text });
  const OnScenarioVoteCompleteResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'scenarioNotFound' : IDL.Null,
  });
  const OnSeasonEndResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
  });
  const SetLeagueResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
  });
  const VoteOnProposalRequest = IDL.Record({
    'vote' : IDL.Bool,
    'proposalId' : IDL.Nat,
  });
  const VoteOnProposalResult = IDL.Variant({
    'ok' : IDL.Null,
    'proposalNotFound' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'alreadyVoted' : IDL.Null,
    'votingClosed' : IDL.Null,
    'teamNotFound' : IDL.Null,
  });
  const VoteOnScenarioRequest = IDL.Record({
    'scenarioId' : IDL.Text,
    'option' : IDL.Nat,
  });
  const VoteOnScenarioResult = IDL.Variant({
    'ok' : IDL.Null,
    'invalidOption' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'alreadyVoted' : IDL.Null,
    'seasonStatusFetchError' : IDL.Text,
    'teamNotInScenario' : IDL.Null,
    'votingNotOpen' : IDL.Null,
    'teamNotFound' : IDL.Null,
    'scenarioNotFound' : IDL.Null,
  });
  return IDL.Service({
    'createProposal' : IDL.Func(
        [IDL.Nat, CreateProposalRequest],
        [CreateProposalResult],
        [],
      ),
    'createTeam' : IDL.Func([CreateTeamRequest], [CreateTeamResult], []),
    'getCycles' : IDL.Func([], [GetCyclesResult], []),
    'getProposal' : IDL.Func(
        [IDL.Nat, IDL.Nat],
        [GetProposalResult],
        ['query'],
      ),
    'getProposals' : IDL.Func(
        [IDL.Nat, IDL.Nat, IDL.Nat],
        [GetProposalsResult],
        ['query'],
      ),
    'getScenarioVote' : IDL.Func(
        [GetScenarioVoteRequest],
        [GetScenarioVoteResult],
        ['query'],
      ),
    'getScenarioVotingResults' : IDL.Func(
        [GetScenarioVotingResultsRequest],
        [GetScenarioVotingResultsResult],
        [],
      ),
    'onNewScenario' : IDL.Func(
        [OnNewScenarioRequest],
        [OnNewScenarioResult],
        [],
      ),
    'onScenarioVoteComplete' : IDL.Func(
        [OnScenarioVoteCompleteRequest],
        [OnScenarioVoteCompleteResult],
        [],
      ),
    'onSeasonEnd' : IDL.Func([], [OnSeasonEndResult], []),
    'setLeague' : IDL.Func([IDL.Principal], [SetLeagueResult], []),
    'voteOnProposal' : IDL.Func(
        [IDL.Nat, VoteOnProposalRequest],
        [VoteOnProposalResult],
        [],
      ),
    'voteOnScenario' : IDL.Func(
        [IDL.Nat, VoteOnScenarioRequest],
        [VoteOnScenarioResult],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
