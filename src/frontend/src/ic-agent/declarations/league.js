export const idlFactory = ({ IDL }) => {
  const Effect = IDL.Rec();
  const Time = IDL.Int;
  const TargetTeam = IDL.Variant({ 'choosingTeam' : IDL.Null });
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
  const TargetPosition = IDL.Record({
    'teamId' : TargetTeam,
    'position' : FieldPosition,
  });
  const Target = IDL.Variant({
    'teams' : IDL.Vec(TargetTeam),
    'league' : IDL.Null,
    'positions' : IDL.Vec(TargetPosition),
  });
  const Injury = IDL.Variant({
    'twistedAnkle' : IDL.Null,
    'brokenArm' : IDL.Null,
    'brokenLeg' : IDL.Null,
    'concussion' : IDL.Null,
  });
  Effect.fill(
    IDL.Variant({
      'allOf' : IDL.Vec(Effect),
      'noEffect' : IDL.Null,
      'oneOf' : IDL.Vec(IDL.Tuple(IDL.Nat, Effect)),
      'entropy' : IDL.Record({ 'team' : TargetTeam, 'delta' : IDL.Int }),
      'skill' : IDL.Record({
        'duration' : Duration,
        'skill' : Skill,
        'target' : Target,
        'delta' : IDL.Int,
      }),
      'injury' : IDL.Record({ 'target' : Target, 'injury' : Injury }),
      'energy' : IDL.Record({
        'value' : IDL.Variant({ 'flat' : IDL.Int }),
        'team' : TargetTeam,
      }),
    })
  );
  const MetaEffect = IDL.Variant({
    'lottery' : IDL.Record({
      'prize' : Effect,
      'options' : IDL.Vec(IDL.Record({ 'tickets' : IDL.Nat })),
    }),
    'noEffect' : IDL.Null,
    'threshold' : IDL.Record({
      'threshold' : IDL.Nat,
      'over' : Effect,
      'under' : Effect,
      'options' : IDL.Vec(
        IDL.Record({
          'value' : IDL.Variant({
            'fixed' : IDL.Int,
            'weightedChance' : IDL.Vec(IDL.Tuple(IDL.Nat, IDL.Int)),
          }),
        })
      ),
    }),
    'pickASide' : IDL.Record({
      'options' : IDL.Vec(IDL.Record({ 'sideId' : IDL.Text })),
    }),
    'proportionalBid' : IDL.Record({
      'prize' : IDL.Variant({
        'skill' : IDL.Record({
          'total' : IDL.Nat,
          'duration' : Duration,
          'skill' : Skill,
          'target' : IDL.Variant({ 'position' : FieldPosition }),
        }),
      }),
      'options' : IDL.Vec(IDL.Record({ 'bidValue' : IDL.Nat })),
    }),
    'leagueChoice' : IDL.Record({
      'options' : IDL.Vec(IDL.Record({ 'effect' : Effect })),
    }),
  });
  const ScenarioOptionWithEffect = IDL.Record({
    'title' : IDL.Text,
    'description' : IDL.Text,
    'effect' : Effect,
  });
  const AddScenarioRequest = IDL.Record({
    'id' : IDL.Text,
    'startTime' : Time,
    'title' : IDL.Text,
    'endTime' : Time,
    'metaEffect' : MetaEffect,
    'teamIds' : IDL.Vec(IDL.Nat),
    'description' : IDL.Text,
    'options' : IDL.Vec(ScenarioOptionWithEffect),
  });
  const AddScenarioResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'invalid' : IDL.Vec(IDL.Text),
  });
  const ClaimBenevolentDictatorRoleResult = IDL.Variant({
    'ok' : IDL.Null,
    'notOpenToClaim' : IDL.Null,
  });
  const CloseSeasonResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'seasonNotOpen' : IDL.Null,
  });
  const ProposalContent = IDL.Variant({
    'changeTeamName' : IDL.Record({ 'name' : IDL.Text, 'teamId' : IDL.Nat }),
  });
  const CreateProposalRequest = IDL.Record({ 'content' : ProposalContent });
  const CreateProposalResult = IDL.Variant({
    'ok' : IDL.Nat,
    'notAuthorized' : IDL.Null,
  });
  const CreateTeamRequest = IDL.Record({
    'motto' : IDL.Text,
    'name' : IDL.Text,
    'color' : IDL.Tuple(IDL.Nat8, IDL.Nat8, IDL.Nat8),
    'description' : IDL.Text,
    'logoUrl' : IDL.Text,
  });
  const CreateTeamResult = IDL.Variant({
    'ok' : IDL.Nat,
    'nameTaken' : IDL.Null,
    'noStadiumsExist' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'teamsCallError' : IDL.Text,
    'populateTeamRosterCallError' : IDL.Text,
  });
  const BenevolentDictatorState = IDL.Variant({
    'open' : IDL.Null,
    'claimed' : IDL.Principal,
    'disabled' : IDL.Null,
  });
  const TeamId = IDL.Variant({ 'team1' : IDL.Null, 'team2' : IDL.Null });
  const MatchPredictionSummary = IDL.Record({
    'team1' : IDL.Nat,
    'team2' : IDL.Nat,
    'yourVote' : IDL.Opt(TeamId),
  });
  const MatchGroupPredictionSummary = IDL.Record({
    'matches' : IDL.Vec(MatchPredictionSummary),
  });
  const GetMatchGroupPredictionsResult = IDL.Variant({
    'ok' : MatchGroupPredictionSummary,
    'notFound' : IDL.Null,
  });
  const Vote = IDL.Record({
    'value' : IDL.Opt(IDL.Bool),
    'votingPower' : IDL.Nat,
  });
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
  });
  const PagedResult = IDL.Record({
    'data' : IDL.Vec(Proposal),
    'count' : IDL.Nat,
    'offset' : IDL.Nat,
  });
  const GetProposalsResult = IDL.Variant({ 'ok' : PagedResult });
  const ScenarioStateResolved = IDL.Record({
    'teamChoices' : IDL.Vec(
      IDL.Record({ 'option' : IDL.Nat, 'teamId' : IDL.Nat })
    ),
  });
  const ScenarioOption = IDL.Record({
    'title' : IDL.Text,
    'description' : IDL.Text,
  });
  const Scenario = IDL.Record({
    'id' : IDL.Text,
    'title' : IDL.Text,
    'description' : IDL.Text,
    'state' : IDL.Variant({
      'notStarted' : IDL.Null,
      'resolved' : ScenarioStateResolved,
      'inProgress' : IDL.Null,
    }),
    'options' : IDL.Vec(ScenarioOption),
  });
  const GetScenarioResult = IDL.Variant({
    'ok' : Scenario,
    'notStarted' : IDL.Null,
    'notFound' : IDL.Null,
  });
  const GetScenariosResult = IDL.Variant({ 'ok' : IDL.Vec(Scenario) });
  const TeamPositions = IDL.Record({
    'rightField' : IDL.Nat32,
    'leftField' : IDL.Nat32,
    'thirdBase' : IDL.Nat32,
    'pitcher' : IDL.Nat32,
    'secondBase' : IDL.Nat32,
    'shortStop' : IDL.Nat32,
    'centerField' : IDL.Nat32,
    'firstBase' : IDL.Nat32,
  });
  const CompletedSeasonTeam = IDL.Record({
    'id' : IDL.Nat,
    'name' : IDL.Text,
    'color' : IDL.Tuple(IDL.Nat8, IDL.Nat8, IDL.Nat8),
    'wins' : IDL.Nat,
    'losses' : IDL.Nat,
    'totalScore' : IDL.Int,
    'logoUrl' : IDL.Text,
    'positions' : TeamPositions,
  });
  const CompletedMatchTeam = IDL.Record({ 'id' : IDL.Nat, 'score' : IDL.Int });
  const MatchAura = IDL.Variant({
    'foggy' : IDL.Null,
    'moveBasesIn' : IDL.Null,
    'extraStrike' : IDL.Null,
    'moreBlessingsAndCurses' : IDL.Null,
    'fastBallsHardHits' : IDL.Null,
    'explodingBalls' : IDL.Null,
    'lowGravity' : IDL.Null,
    'doubleOrNothing' : IDL.Null,
    'windy' : IDL.Null,
    'rainy' : IDL.Null,
  });
  const TeamIdOrTie = IDL.Variant({
    'tie' : IDL.Null,
    'team1' : IDL.Null,
    'team2' : IDL.Null,
  });
  const CompletedMatch = IDL.Record({
    'team1' : CompletedMatchTeam,
    'team2' : CompletedMatchTeam,
    'aura' : MatchAura,
    'winner' : TeamIdOrTie,
  });
  const CompletedMatchGroup = IDL.Record({
    'time' : Time,
    'matches' : IDL.Vec(CompletedMatch),
  });
  const CompletedSeason = IDL.Record({
    'teams' : IDL.Vec(CompletedSeasonTeam),
    'runnerUpTeamId' : IDL.Nat,
    'matchGroups' : IDL.Vec(CompletedMatchGroup),
    'championTeamId' : IDL.Nat,
  });
  const TeamInfo = IDL.Record({
    'id' : IDL.Nat,
    'name' : IDL.Text,
    'color' : IDL.Tuple(IDL.Nat8, IDL.Nat8, IDL.Nat8),
    'logoUrl' : IDL.Text,
    'positions' : TeamPositions,
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
  const PlayerWithId = IDL.Record({
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
    'traitIds' : IDL.Vec(IDL.Text),
  });
  const ScheduledTeamInfo = IDL.Record({ 'id' : IDL.Nat });
  const MatchAuraWithMetaData = IDL.Record({
    'aura' : MatchAura,
    'name' : IDL.Text,
    'description' : IDL.Text,
  });
  const ScheduledMatch = IDL.Record({
    'team1' : ScheduledTeamInfo,
    'team2' : ScheduledTeamInfo,
    'aura' : MatchAuraWithMetaData,
  });
  const ScheduledMatchGroup = IDL.Record({
    'stadiumId' : IDL.Principal,
    'time' : Time,
    'matches' : IDL.Vec(ScheduledMatch),
    'timerId' : IDL.Nat,
  });
  const InProgressTeam = IDL.Record({ 'id' : IDL.Nat });
  const InProgressMatch = IDL.Record({
    'team1' : InProgressTeam,
    'team2' : InProgressTeam,
    'aura' : MatchAura,
  });
  const InProgressMatchGroup = IDL.Record({
    'stadiumId' : IDL.Principal,
    'time' : Time,
    'matches' : IDL.Vec(InProgressMatch),
  });
  const TeamAssignment = IDL.Variant({
    'winnerOfMatch' : IDL.Nat,
    'predetermined' : IDL.Nat,
    'seasonStandingIndex' : IDL.Nat,
  });
  const NotScheduledMatch = IDL.Record({
    'team1' : TeamAssignment,
    'team2' : TeamAssignment,
  });
  const NotScheduledMatchGroup = IDL.Record({
    'time' : Time,
    'matches' : IDL.Vec(NotScheduledMatch),
  });
  const InProgressSeasonMatchGroupVariant = IDL.Variant({
    'scheduled' : ScheduledMatchGroup,
    'completed' : CompletedMatchGroup,
    'inProgress' : InProgressMatchGroup,
    'notScheduled' : NotScheduledMatchGroup,
  });
  const InProgressSeason = IDL.Record({
    'teams' : IDL.Vec(TeamInfo),
    'players' : IDL.Vec(PlayerWithId),
    'matchGroups' : IDL.Vec(InProgressSeasonMatchGroupVariant),
  });
  const SeasonStatus = IDL.Variant({
    'notStarted' : IDL.Null,
    'starting' : IDL.Null,
    'completed' : CompletedSeason,
    'inProgress' : InProgressSeason,
  });
  const TeamStandingInfo = IDL.Record({
    'id' : IDL.Nat,
    'wins' : IDL.Nat,
    'losses' : IDL.Nat,
    'totalScore' : IDL.Int,
  });
  const GetTeamStandingsResult = IDL.Variant({
    'ok' : IDL.Vec(TeamStandingInfo),
    'notFound' : IDL.Null,
  });
  const TeamWithId = IDL.Record({
    'id' : IDL.Nat,
    'motto' : IDL.Text,
    'name' : IDL.Text,
    'color' : IDL.Tuple(IDL.Nat8, IDL.Nat8, IDL.Nat8),
    'description' : IDL.Text,
    'entropy' : IDL.Nat,
    'logoUrl' : IDL.Text,
    'energy' : IDL.Int,
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
  const OnMatchGroupCompleteRequest = IDL.Record({
    'id' : IDL.Nat,
    'matches' : IDL.Vec(CompletedMatch),
    'playerStats' : IDL.Vec(PlayerMatchStatsWithId),
  });
  const OnMatchGroupCompleteResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'seedGenerationError' : IDL.Text,
    'matchGroupNotFound' : IDL.Null,
    'seasonNotOpen' : IDL.Null,
    'matchGroupNotInProgress' : IDL.Null,
  });
  const PredictMatchOutcomeRequest = IDL.Record({
    'winner' : IDL.Opt(TeamId),
    'matchId' : IDL.Nat,
  });
  const PredictMatchOutcomeResult = IDL.Variant({
    'ok' : IDL.Null,
    'predictionsClosed' : IDL.Null,
    'matchNotFound' : IDL.Null,
    'matchGroupNotFound' : IDL.Null,
    'identityRequired' : IDL.Null,
  });
  const SetBenevolentDictatorStateResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
  });
  const TeamIdOrBoth = IDL.Variant({
    'team1' : IDL.Null,
    'team2' : IDL.Null,
    'bothTeams' : IDL.Null,
  });
  const StartMatchError = IDL.Variant({ 'notEnoughPlayers' : TeamIdOrBoth });
  const StartMatchGroupResult = IDL.Variant({
    'ok' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'notScheduledYet' : IDL.Null,
    'matchGroupNotFound' : IDL.Null,
    'alreadyStarted' : IDL.Null,
    'matchErrors' : IDL.Vec(
      IDL.Record({ 'error' : StartMatchError, 'matchId' : IDL.Nat })
    ),
  });
  const DayOfWeek = IDL.Variant({
    'tuesday' : IDL.Null,
    'wednesday' : IDL.Null,
    'saturday' : IDL.Null,
    'thursday' : IDL.Null,
    'sunday' : IDL.Null,
    'friday' : IDL.Null,
    'monday' : IDL.Null,
  });
  const StartSeasonRequest = IDL.Record({
    'startTime' : Time,
    'weekDays' : IDL.Vec(DayOfWeek),
  });
  const StartSeasonResult = IDL.Variant({
    'ok' : IDL.Null,
    'noStadiumsExist' : IDL.Null,
    'notAuthorized' : IDL.Null,
    'seedGenerationError' : IDL.Text,
    'alreadyStarted' : IDL.Null,
    'idTaken' : IDL.Null,
    'invalidArgs' : IDL.Text,
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
  });
  return IDL.Service({
    'addScenario' : IDL.Func([AddScenarioRequest], [AddScenarioResult], []),
    'claimBenevolentDictatorRole' : IDL.Func(
        [],
        [ClaimBenevolentDictatorRoleResult],
        [],
      ),
    'clearTeams' : IDL.Func([], [], []),
    'closeSeason' : IDL.Func([], [CloseSeasonResult], []),
    'createProposal' : IDL.Func(
        [CreateProposalRequest],
        [CreateProposalResult],
        [],
      ),
    'createTeam' : IDL.Func([CreateTeamRequest], [CreateTeamResult], []),
    'getBenevolentDictatorState' : IDL.Func(
        [],
        [BenevolentDictatorState],
        ['query'],
      ),
    'getMatchGroupPredictions' : IDL.Func(
        [IDL.Nat],
        [GetMatchGroupPredictionsResult],
        ['query'],
      ),
    'getProposal' : IDL.Func([IDL.Nat], [GetProposalResult], ['query']),
    'getProposals' : IDL.Func(
        [IDL.Nat, IDL.Nat],
        [GetProposalsResult],
        ['query'],
      ),
    'getScenario' : IDL.Func([IDL.Text], [GetScenarioResult], ['query']),
    'getScenarios' : IDL.Func([], [GetScenariosResult], ['query']),
    'getSeasonStatus' : IDL.Func([], [SeasonStatus], ['query']),
    'getTeamStandings' : IDL.Func([], [GetTeamStandingsResult], ['query']),
    'getTeams' : IDL.Func([], [IDL.Vec(TeamWithId)], ['query']),
    'onMatchGroupComplete' : IDL.Func(
        [OnMatchGroupCompleteRequest],
        [OnMatchGroupCompleteResult],
        [],
      ),
    'predictMatchOutcome' : IDL.Func(
        [PredictMatchOutcomeRequest],
        [PredictMatchOutcomeResult],
        [],
      ),
    'setBenevolentDictatorState' : IDL.Func(
        [BenevolentDictatorState],
        [SetBenevolentDictatorStateResult],
        [],
      ),
    'startMatchGroup' : IDL.Func([IDL.Nat], [StartMatchGroupResult], []),
    'startSeason' : IDL.Func([StartSeasonRequest], [StartSeasonResult], []),
    'voteOnProposal' : IDL.Func(
        [VoteOnProposalRequest],
        [VoteOnProposalResult],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
