export const idlFactory = ({ IDL }) => {
  const MotionContent = IDL.Record({
    'title' : IDL.Text,
    'description' : IDL.Text,
  });
  const CreateWorldProposalRequest = IDL.Variant({ 'motion' : MotionContent });
  const CreateWorldProposalError = IDL.Variant({
    'notAuthorized' : IDL.Null,
    'invalid' : IDL.Vec(IDL.Text),
  });
  const CreateWorldProposalResult = IDL.Variant({
    'ok' : IDL.Nat,
    'err' : CreateWorldProposalError,
  });
  const ChoiceVotingPower = IDL.Record({
    'votingPower' : IDL.Nat,
    'choice' : IDL.Text,
  });
  const ScenarioVoteChoice = IDL.Record({
    'votingPower' : IDL.Nat,
    'choice' : IDL.Opt(IDL.Text),
  });
  const ScenarioVote = IDL.Record({
    'votingPowerByChoice' : IDL.Vec(ChoiceVotingPower),
    'undecidedVotingPower' : IDL.Nat,
    'totalVotingPower' : IDL.Nat,
    'yourVote' : IDL.Opt(ScenarioVoteChoice),
  });
  const Data = IDL.Record({
    'size' : IDL.Text,
    'unusualFeature' : IDL.Text,
    'structureName' : IDL.Text,
    'material' : IDL.Text,
    'condition' : IDL.Text,
  });
  const ScenarioKind = IDL.Variant({ 'mysteriousStructure' : Data });
  const Outcome = IDL.Record({
    'messages' : IDL.Vec(IDL.Text),
    'choice' : IDL.Opt(IDL.Text),
  });
  const ScenarioOption = IDL.Record({
    'id' : IDL.Text,
    'description' : IDL.Text,
  });
  const Scenario = IDL.Record({
    'id' : IDL.Nat,
    'title' : IDL.Text,
    'voteData' : ScenarioVote,
    'kind' : ScenarioKind,
    'turn' : IDL.Nat,
    'description' : IDL.Text,
    'outcome' : IDL.Opt(Outcome),
    'options' : IDL.Vec(ScenarioOption),
  });
  const GetScenarioVoteRequest = IDL.Record({ 'scenarioId' : IDL.Nat });
  const GetScenarioVoteError = IDL.Variant({ 'scenarioNotFound' : IDL.Null });
  const GetScenarioVoteResult = IDL.Variant({
    'ok' : ScenarioVote,
    'err' : GetScenarioVoteError,
  });
  const GetTopUsersRequest = IDL.Record({
    'count' : IDL.Nat,
    'offset' : IDL.Nat,
  });
  const Time = IDL.Int;
  const User = IDL.Record({
    'id' : IDL.Principal,
    'inWorldSince' : Time,
    'level' : IDL.Nat,
  });
  const PagedResult_1 = IDL.Record({
    'data' : IDL.Vec(User),
    'count' : IDL.Nat,
    'totalCount' : IDL.Nat,
    'offset' : IDL.Nat,
  });
  const GetTopUsersResult = IDL.Variant({ 'ok' : PagedResult_1 });
  const GetUserError = IDL.Variant({
    'notAuthorized' : IDL.Null,
    'notFound' : IDL.Null,
  });
  const GetUserResult = IDL.Variant({ 'ok' : User, 'err' : GetUserError });
  const UserStats = IDL.Record({
    'totalUserLevel' : IDL.Int,
    'userCount' : IDL.Nat,
  });
  const GetUserStatsResult = IDL.Variant({
    'ok' : UserStats,
    'err' : IDL.Null,
  });
  const GetUsersRequest = IDL.Variant({ 'all' : IDL.Null });
  const GetUsersResult = IDL.Variant({ 'ok' : IDL.Vec(User) });
  const LocationKind = IDL.Variant({
    'scenario' : IDL.Nat,
    'unexplored' : IDL.Null,
  });
  const AxialCoordinate = IDL.Record({ 'q' : IDL.Int, 'r' : IDL.Int });
  const Location = IDL.Record({
    'id' : IDL.Nat,
    'kind' : LocationKind,
    'coordinate' : AxialCoordinate,
  });
  const World = IDL.Record({
    'turn' : IDL.Nat,
    'progenitor' : IDL.Principal,
    'locations' : IDL.Vec(Location),
  });
  const GetWorldError = IDL.Variant({ 'worldNotInitialized' : IDL.Null });
  const GetWorldResult = IDL.Variant({ 'ok' : World, 'err' : GetWorldError });
  const ProposalStatus = IDL.Variant({
    'failedToExecute' : IDL.Record({
      'executingTime' : Time,
      'error' : IDL.Text,
      'failedTime' : Time,
      'choice' : IDL.Opt(IDL.Bool),
    }),
    'open' : IDL.Null,
    'executing' : IDL.Record({
      'executingTime' : Time,
      'choice' : IDL.Opt(IDL.Bool),
    }),
    'executed' : IDL.Record({
      'executingTime' : Time,
      'choice' : IDL.Opt(IDL.Bool),
      'executedTime' : Time,
    }),
  });
  const ProposalContent = IDL.Variant({ 'motion' : MotionContent });
  const Vote = IDL.Record({
    'votingPower' : IDL.Nat,
    'choice' : IDL.Opt(IDL.Bool),
  });
  const WorldProposal = IDL.Record({
    'id' : IDL.Nat,
    'status' : ProposalStatus,
    'content' : ProposalContent,
    'timeStart' : IDL.Int,
    'votes' : IDL.Vec(IDL.Tuple(IDL.Principal, Vote)),
    'timeEnd' : IDL.Opt(IDL.Int),
    'proposerId' : IDL.Principal,
  });
  const GetWorldProposalError = IDL.Variant({ 'proposalNotFound' : IDL.Null });
  const GetWorldProposalResult = IDL.Variant({
    'ok' : WorldProposal,
    'err' : GetWorldProposalError,
  });
  const PagedResult = IDL.Record({
    'data' : IDL.Vec(WorldProposal),
    'count' : IDL.Nat,
    'totalCount' : IDL.Nat,
    'offset' : IDL.Nat,
  });
  const InitializeWorldError = IDL.Variant({ 'alreadyInitialized' : IDL.Null });
  const Result_1 = IDL.Variant({
    'ok' : IDL.Null,
    'err' : InitializeWorldError,
  });
  const JoinWorldError = IDL.Variant({
    'notAuthorized' : IDL.Null,
    'alreadyWorldMember' : IDL.Null,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : JoinWorldError });
  const VoteOnScenarioRequest = IDL.Record({
    'scenarioId' : IDL.Nat,
    'value' : IDL.Text,
  });
  const VoteOnScenarioError = IDL.Variant({
    'proposalNotFound' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'alreadyVoted' : IDL.Null,
    'votingClosed' : IDL.Null,
    'invalidChoice' : IDL.Null,
    'scenarioNotFound' : IDL.Null,
  });
  const VoteOnScenarioResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : VoteOnScenarioError,
  });
  const VoteOnWorldProposalRequest = IDL.Record({
    'vote' : IDL.Bool,
    'proposalId' : IDL.Nat,
  });
  const VoteOnWorldProposalError = IDL.Variant({
    'proposalNotFound' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'alreadyVoted' : IDL.Null,
    'votingClosed' : IDL.Null,
  });
  const VoteOnWorldProposalResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : VoteOnWorldProposalError,
  });
  return IDL.Service({
    'createWorldProposal' : IDL.Func(
        [CreateWorldProposalRequest],
        [CreateWorldProposalResult],
        [],
      ),
    'getProgenitor' : IDL.Func([], [IDL.Opt(IDL.Principal)], ['query']),
    'getScenario' : IDL.Func([IDL.Nat], [IDL.Opt(Scenario)], ['query']),
    'getScenarioVote' : IDL.Func(
        [GetScenarioVoteRequest],
        [GetScenarioVoteResult],
        ['query'],
      ),
    'getTopUsers' : IDL.Func(
        [GetTopUsersRequest],
        [GetTopUsersResult],
        ['query'],
      ),
    'getUser' : IDL.Func([IDL.Principal], [GetUserResult], ['query']),
    'getUserStats' : IDL.Func([], [GetUserStatsResult], ['query']),
    'getUsers' : IDL.Func([GetUsersRequest], [GetUsersResult], ['query']),
    'getWorld' : IDL.Func([], [GetWorldResult], ['query']),
    'getWorldProposal' : IDL.Func(
        [IDL.Nat],
        [GetWorldProposalResult],
        ['query'],
      ),
    'getWorldProposals' : IDL.Func(
        [IDL.Nat, IDL.Nat],
        [PagedResult],
        ['query'],
      ),
    'intializeWorld' : IDL.Func([], [Result_1], []),
    'joinWorld' : IDL.Func([], [Result], []),
    'voteOnScenario' : IDL.Func(
        [VoteOnScenarioRequest],
        [VoteOnScenarioResult],
        [],
      ),
    'voteOnWorldProposal' : IDL.Func(
        [VoteOnWorldProposalRequest],
        [VoteOnWorldProposalResult],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
