export const idlFactory = ({ IDL }) => {
  const ChoiceRequirement = IDL.Rec();
  const Trait = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
  });
  const CreatureStats = IDL.Record({
    'magic' : IDL.Int,
    'speed' : IDL.Int,
    'defense' : IDL.Int,
    'attack' : IDL.Int,
  });
  const CreatureLocationKind = IDL.Variant({
    'common' : IDL.Null,
    'zoneIds' : IDL.Vec(IDL.Text),
  });
  const Creature = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'stats' : CreatureStats,
    'weaponId' : IDL.Text,
    'location' : CreatureLocationKind,
    'health' : IDL.Nat,
  });
  const Item = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
  });
  const UnlockRequirement = IDL.Variant({ 'acheivementId' : IDL.Text });
  const CharacterModifier = IDL.Variant({
    'magic' : IDL.Int,
    'trait' : IDL.Text,
    'gold' : IDL.Nat,
    'item' : IDL.Text,
    'speed' : IDL.Int,
    'defense' : IDL.Int,
    'attack' : IDL.Int,
    'health' : IDL.Int,
  });
  const Class = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'weaponId' : IDL.Text,
    'unlockRequirement' : IDL.Opt(UnlockRequirement),
    'modifiers' : IDL.Vec(CharacterModifier),
  });
  const Race = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'modifiers' : IDL.Vec(CharacterModifier),
  });
  const Zone = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
  });
  const Achievement = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
  });
  const ImageKind = IDL.Variant({ 'png' : IDL.Null });
  const Image = IDL.Record({
    'id' : IDL.Text,
    'data' : IDL.Vec(IDL.Nat8),
    'kind' : ImageKind,
  });
  const GeneratedDataFieldNat = IDL.Record({
    'max' : IDL.Nat,
    'min' : IDL.Nat,
  });
  const GeneratedDataFieldText = IDL.Record({
    'options' : IDL.Vec(IDL.Tuple(IDL.Text, IDL.Float64)),
  });
  const GeneratedDataFieldValue = IDL.Variant({
    'nat' : GeneratedDataFieldNat,
    'text' : GeneratedDataFieldText,
  });
  const GeneratedDataField = IDL.Record({
    'id' : IDL.Text,
    'value' : GeneratedDataFieldValue,
    'name' : IDL.Text,
  });
  const TextValue = IDL.Variant({
    'raw' : IDL.Text,
    'dataField' : IDL.Text,
    'weighted' : IDL.Vec(IDL.Tuple(IDL.Text, IDL.Float64)),
  });
  const RandomOrSpecificTextValue = IDL.Variant({
    'specific' : TextValue,
    'random' : IDL.Null,
  });
  const NatValue = IDL.Variant({
    'raw' : IDL.Nat,
    'dataField' : IDL.Text,
    'random' : IDL.Tuple(IDL.Nat, IDL.Nat),
  });
  const CharacterStatKind = IDL.Variant({
    'magic' : IDL.Null,
    'speed' : IDL.Null,
    'defense' : IDL.Null,
    'attack' : IDL.Null,
  });
  const Effect = IDL.Variant({
    'reward' : IDL.Null,
    'removeTrait' : RandomOrSpecificTextValue,
    'damage' : NatValue,
    'heal' : NatValue,
    'achievement' : IDL.Text,
    'upgradeStat' : IDL.Tuple(CharacterStatKind, NatValue),
    'addItem' : TextValue,
    'addTrait' : TextValue,
    'removeGold' : NatValue,
    'removeItem' : RandomOrSpecificTextValue,
  });
  const CombatCreatureKind = IDL.Variant({
    'id' : IDL.Text,
    'filter' : IDL.Record({
      'location' : IDL.Variant({
        'any' : IDL.Null,
        'zone' : IDL.Text,
        'common' : IDL.Null,
      }),
    }),
  });
  const CombatPath = IDL.Record({ 'creatures' : IDL.Vec(CombatCreatureKind) });
  const OutcomePathKind = IDL.Variant({
    'effects' : IDL.Vec(Effect),
    'combat' : CombatPath,
  });
  const Condition = IDL.Variant({
    'hasGold' : NatValue,
    'hasItem' : TextValue,
    'hasTrait' : TextValue,
  });
  const WeightedOutcomePath = IDL.Record({
    'weight' : IDL.Float64,
    'pathId' : IDL.Text,
    'condition' : IDL.Opt(Condition),
  });
  const OutcomePath = IDL.Record({
    'id' : IDL.Text,
    'kind' : OutcomePathKind,
    'description' : IDL.Text,
    'paths' : IDL.Vec(WeightedOutcomePath),
  });
  ChoiceRequirement.fill(
    IDL.Variant({
      'all' : IDL.Vec(ChoiceRequirement),
      'any' : IDL.Vec(ChoiceRequirement),
      'trait' : IDL.Text,
      'gold' : IDL.Nat,
      'item' : IDL.Text,
      'class' : IDL.Text,
      'race' : IDL.Text,
      'stat' : IDL.Tuple(CharacterStatKind, IDL.Nat),
    })
  );
  const Choice = IDL.Record({
    'id' : IDL.Text,
    'description' : IDL.Text,
    'requirement' : IDL.Opt(ChoiceRequirement),
    'pathId' : IDL.Text,
  });
  const LocationKind = IDL.Variant({
    'common' : IDL.Null,
    'zoneIds' : IDL.Vec(IDL.Text),
  });
  const ScenarioMetaData = IDL.Record({
    'id' : IDL.Text,
    'data' : IDL.Vec(GeneratedDataField),
    'name' : IDL.Text,
    'description' : IDL.Text,
    'paths' : IDL.Vec(OutcomePath),
    'imageId' : IDL.Text,
    'choices' : IDL.Vec(Choice),
    'location' : LocationKind,
    'undecidedPathId' : IDL.Text,
  });
  const WeaponDamage = IDL.Record({
    'max' : IDL.Nat,
    'min' : IDL.Nat,
    'attacks' : IDL.Nat,
  });
  const StatKind = IDL.Variant({
    'magic' : IDL.Null,
    'speed' : IDL.Null,
    'defense' : IDL.Null,
    'attack' : IDL.Null,
  });
  const StatBoostKind = IDL.Variant({
    'addBasePercent' : IDL.Nat,
    'addFlat' : IDL.Nat,
    'addStatPercent' : IDL.Tuple(StatKind, IDL.Nat),
  });
  const WeaponAttribute = IDL.Variant({
    'damage' : IDL.Null,
    'criticalChance' : IDL.Null,
    'criticalMultiplier' : IDL.Null,
    'accuracy' : IDL.Null,
  });
  const StatBoost = IDL.Record({
    'kind' : StatBoostKind,
    'attribute' : WeaponAttribute,
  });
  const WeaponStats = IDL.Record({
    'damage' : WeaponDamage,
    'criticalChance' : IDL.Nat,
    'boosts' : IDL.Vec(StatBoost),
    'criticalMultiplier' : IDL.Nat,
    'accuracy' : IDL.Int,
  });
  const WeaponRequirement = IDL.Variant({
    'magic' : IDL.Int,
    'speed' : IDL.Int,
    'defense' : IDL.Int,
    'attack' : IDL.Int,
  });
  const Weapon = IDL.Record({
    'id' : IDL.Text,
    'name' : IDL.Text,
    'description' : IDL.Text,
    'baseStats' : WeaponStats,
    'requirements' : IDL.Opt(WeaponRequirement),
  });
  const AddGameContentRequest = IDL.Variant({
    'trait' : Trait,
    'creature' : Creature,
    'item' : Item,
    'class' : Class,
    'race' : Race,
    'zone' : Zone,
    'achievement' : Achievement,
    'image' : Image,
    'scenario' : ScenarioMetaData,
    'weapon' : Weapon,
  });
  const AddGameContentResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : IDL.Variant({
      'notAuthorized' : IDL.Null,
      'invalid' : IDL.Vec(IDL.Text),
    }),
  });
  const AddUserToGameRequest = IDL.Record({
    'userId' : IDL.Principal,
    'gameId' : IDL.Nat,
  });
  const AddUserToGameResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : IDL.Variant({
      'alreadyJoined' : IDL.Null,
      'notAuthorized' : IDL.Null,
      'gameNotFound' : IDL.Null,
    }),
  });
  const CreateGameError = IDL.Variant({
    'noTraits' : IDL.Null,
    'noWeapons' : IDL.Null,
    'noCreaturesForZone' : IDL.Text,
    'noZones' : IDL.Null,
    'noItems' : IDL.Null,
    'noScenariosForZone' : IDL.Text,
    'noClasses' : IDL.Null,
    'noCreatures' : IDL.Null,
    'noRaces' : IDL.Null,
    'noScenarios' : IDL.Null,
    'noImages' : IDL.Null,
    'alreadyInitialized' : IDL.Null,
  });
  const CreateGameResult = IDL.Variant({
    'ok' : IDL.Nat,
    'err' : CreateGameError,
  });
  const MotionContent = IDL.Record({
    'title' : IDL.Text,
    'description' : IDL.Text,
  });
  const CreateWorldProposalRequest = IDL.Variant({ 'motion' : MotionContent });
  const CreateWorldProposalError = IDL.Variant({
    'invalid' : IDL.Vec(IDL.Text),
    'notEligible' : IDL.Null,
  });
  const CreateWorldProposalResult = IDL.Variant({
    'ok' : IDL.Nat,
    'err' : CreateWorldProposalError,
  });
  const CharacterStats = IDL.Record({
    'magic' : IDL.Int,
    'speed' : IDL.Int,
    'defense' : IDL.Int,
    'attack' : IDL.Int,
  });
  const CharacterWithMetaData = IDL.Record({
    'gold' : IDL.Nat,
    'traits' : IDL.Vec(Trait),
    'class' : Class,
    'race' : Race,
    'stats' : CharacterStats,
    'items' : IDL.Vec(Item),
    'weapon' : Weapon,
    'health' : IDL.Nat,
  });
  const Difficulty = IDL.Variant({
    'easy' : IDL.Null,
    'hard' : IDL.Null,
    'medium' : IDL.Null,
  });
  const ChoiceVotingPower_1 = IDL.Record({
    'votingPower' : IDL.Nat,
    'choice' : IDL.Nat,
  });
  const VotingSummary = IDL.Record({
    'votingPowerByChoice' : IDL.Vec(ChoiceVotingPower_1),
    'undecidedVotingPower' : IDL.Nat,
    'totalVotingPower' : IDL.Nat,
  });
  const ChoiceVotingPower_2 = IDL.Record({
    'votingPower' : IDL.Nat,
    'choice' : Difficulty,
  });
  const VotingSummary_1 = IDL.Record({
    'votingPowerByChoice' : IDL.Vec(ChoiceVotingPower_2),
    'undecidedVotingPower' : IDL.Nat,
    'totalVotingPower' : IDL.Nat,
  });
  const AxialCoordinate = IDL.Record({ 'q' : IDL.Int, 'r' : IDL.Int });
  const Location = IDL.Record({
    'id' : IDL.Nat,
    'scenarioId' : IDL.Nat,
    'coordinate' : AxialCoordinate,
    'zoneId' : IDL.Text,
  });
  const GameStateWithMetaData = IDL.Variant({
    'notStarted' : IDL.Null,
    'completed' : IDL.Record({
      'turns' : IDL.Nat,
      'character' : CharacterWithMetaData,
      'difficulty' : Difficulty,
    }),
    'voting' : IDL.Record({
      'characterVotes' : VotingSummary,
      'characterOptions' : IDL.Vec(CharacterWithMetaData),
      'difficultyVotes' : VotingSummary_1,
    }),
    'inProgress' : IDL.Record({
      'character' : CharacterWithMetaData,
      'turn' : IDL.Nat,
      'locations' : IDL.Vec(Location),
    }),
  });
  const GameWithMetaData = IDL.Record({
    'id' : IDL.Nat,
    'guestUserIds' : IDL.Vec(IDL.Principal),
    'state' : GameStateWithMetaData,
    'hostUserId' : IDL.Principal,
  });
  const GetCurrentGameResult = IDL.Variant({
    'ok' : IDL.Opt(GameWithMetaData),
    'err' : IDL.Variant({ 'notAuthenticated' : IDL.Null }),
  });
  const GetGameRequest = IDL.Record({ 'gameId' : IDL.Nat });
  const GetGameResult = IDL.Variant({
    'ok' : GameWithMetaData,
    'err' : IDL.Variant({ 'gameNotFound' : IDL.Null }),
  });
  const GetScenarioRequest = IDL.Record({
    'scenarioId' : IDL.Nat,
    'gameId' : IDL.Nat,
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
  const GeneratedDataFieldInstanceValue = IDL.Variant({
    'nat' : IDL.Nat,
    'text' : IDL.Text,
  });
  const GeneratedDataFieldInstance = IDL.Record({
    'id' : IDL.Text,
    'value' : GeneratedDataFieldInstanceValue,
  });
  const Outcome = IDL.Record({
    'messages' : IDL.Vec(IDL.Text),
    'choiceOrUndecided' : IDL.Opt(IDL.Text),
  });
  const Scenario = IDL.Record({
    'id' : IDL.Nat,
    'voteData' : ScenarioVote,
    'metaDataId' : IDL.Text,
    'metaData' : ScenarioMetaData,
    'data' : IDL.Vec(GeneratedDataFieldInstance),
    'availableChoiceIds' : IDL.Vec(IDL.Text),
    'outcome' : IDL.Opt(Outcome),
  });
  const GetScenarioError = IDL.Variant({
    'notFound' : IDL.Null,
    'gameNotFound' : IDL.Null,
    'gameNotActive' : IDL.Null,
  });
  const GetScenarioResult = IDL.Variant({
    'ok' : Scenario,
    'err' : GetScenarioError,
  });
  const GetScenarioVoteRequest = IDL.Record({
    'scenarioId' : IDL.Nat,
    'gameId' : IDL.Nat,
  });
  const GetScenarioVoteError = IDL.Variant({
    'gameNotFound' : IDL.Null,
    'gameNotActive' : IDL.Null,
    'scenarioNotFound' : IDL.Null,
  });
  const GetScenarioVoteResult = IDL.Variant({
    'ok' : ScenarioVote,
    'err' : GetScenarioVoteError,
  });
  const GetScenariosRequest = IDL.Record({ 'gameId' : IDL.Nat });
  const GetScenariosError = IDL.Variant({
    'gameNotFound' : IDL.Null,
    'gameNotActive' : IDL.Null,
  });
  const GetScenariosResult = IDL.Variant({
    'ok' : IDL.Vec(Scenario),
    'err' : GetScenariosError,
  });
  const GetTopUsersRequest = IDL.Record({
    'count' : IDL.Nat,
    'offset' : IDL.Nat,
  });
  const Time = IDL.Int;
  const User = IDL.Record({
    'id' : IDL.Principal,
    'createTime' : Time,
    'achievementIds' : IDL.Vec(IDL.Text),
    'points' : IDL.Nat,
  });
  const PagedResult_1 = IDL.Record({
    'data' : IDL.Vec(User),
    'count' : IDL.Nat,
    'totalCount' : IDL.Nat,
    'offset' : IDL.Nat,
  });
  const GetTopUsersResult = IDL.Variant({ 'ok' : PagedResult_1 });
  const GetUserError = IDL.Variant({ 'notFound' : IDL.Null });
  const GetUserResult = IDL.Variant({ 'ok' : User, 'err' : GetUserError });
  const UserStats = IDL.Record({ 'userCount' : IDL.Nat });
  const GetUserStatsResult = IDL.Variant({
    'ok' : UserStats,
    'err' : IDL.Null,
  });
  const GetUsersRequest = IDL.Variant({ 'all' : IDL.Null });
  const GetUsersResult = IDL.Variant({ 'ok' : IDL.Vec(User) });
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
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const Token = IDL.Record({ 'arbitrary_data' : IDL.Text });
  const StreamingCallbackHttpResponse = IDL.Record({
    'token' : IDL.Opt(Token),
    'body' : IDL.Vec(IDL.Nat8),
  });
  const CallbackStrategy = IDL.Record({
    'token' : Token,
    'callback' : IDL.Func([Token], [StreamingCallbackHttpResponse], ['query']),
  });
  const StreamingStrategy = IDL.Variant({ 'Callback' : CallbackStrategy });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'upgrade' : IDL.Opt(IDL.Bool),
    'streaming_strategy' : IDL.Opt(StreamingStrategy),
    'status_code' : IDL.Nat16,
  });
  const HttpUpdateRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const JoinError = IDL.Variant({ 'alreadyMember' : IDL.Null });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : JoinError });
  const StartGameVoteRequest = IDL.Record({ 'gameId' : IDL.Nat });
  const StartGameVoteResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : IDL.Variant({
      'notAuthorized' : IDL.Null,
      'gameNotFound' : IDL.Null,
      'gameAlreadyStarted' : IDL.Null,
    }),
  });
  const VoteOnNewGameRequest = IDL.Record({
    'difficulty' : Difficulty,
    'gameId' : IDL.Nat,
    'characterId' : IDL.Nat,
  });
  const VoteOnNewGameError = IDL.Variant({
    'invalidCharacterId' : IDL.Null,
    'alreadyVoted' : IDL.Null,
    'votingClosed' : IDL.Null,
    'alreadyStarted' : IDL.Null,
    'gameNotFound' : IDL.Null,
    'notEligible' : IDL.Null,
    'gameNotActive' : IDL.Null,
  });
  const VoteOnNewGameResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : VoteOnNewGameError,
  });
  const VoteOnScenarioRequest = IDL.Record({
    'scenarioId' : IDL.Nat,
    'value' : IDL.Text,
    'gameId' : IDL.Nat,
  });
  const VoteOnScenarioError = IDL.Variant({
    'alreadyVoted' : IDL.Null,
    'votingClosed' : IDL.Null,
    'invalidChoice' : IDL.Null,
    'gameNotFound' : IDL.Null,
    'notEligible' : IDL.Null,
    'gameNotActive' : IDL.Null,
    'scenarioNotFound' : IDL.Null,
    'choiceRequirementNotMet' : IDL.Null,
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
    'alreadyVoted' : IDL.Null,
    'votingClosed' : IDL.Null,
    'notEligible' : IDL.Null,
  });
  const VoteOnWorldProposalResult = IDL.Variant({
    'ok' : IDL.Null,
    'err' : VoteOnWorldProposalError,
  });
  return IDL.Service({
    'addGameContent' : IDL.Func(
        [AddGameContentRequest],
        [AddGameContentResult],
        [],
      ),
    'addUserToGame' : IDL.Func(
        [AddUserToGameRequest],
        [AddUserToGameResult],
        [],
      ),
    'createGame' : IDL.Func([], [CreateGameResult], []),
    'createWorldProposal' : IDL.Func(
        [CreateWorldProposalRequest],
        [CreateWorldProposalResult],
        [],
      ),
    'getClasses' : IDL.Func([], [IDL.Vec(Class)], ['query']),
    'getCurrentGame' : IDL.Func([], [GetCurrentGameResult], ['query']),
    'getGame' : IDL.Func([GetGameRequest], [GetGameResult], ['query']),
    'getItems' : IDL.Func([], [IDL.Vec(Item)], ['query']),
    'getRaces' : IDL.Func([], [IDL.Vec(Race)], ['query']),
    'getScenario' : IDL.Func(
        [GetScenarioRequest],
        [GetScenarioResult],
        ['query'],
      ),
    'getScenarioMetaDataList' : IDL.Func(
        [],
        [IDL.Vec(ScenarioMetaData)],
        ['query'],
      ),
    'getScenarioVote' : IDL.Func(
        [GetScenarioVoteRequest],
        [GetScenarioVoteResult],
        ['query'],
      ),
    'getScenarios' : IDL.Func(
        [GetScenariosRequest],
        [GetScenariosResult],
        ['query'],
      ),
    'getTopUsers' : IDL.Func(
        [GetTopUsersRequest],
        [GetTopUsersResult],
        ['query'],
      ),
    'getTraits' : IDL.Func([], [IDL.Vec(Trait)], ['query']),
    'getUser' : IDL.Func([IDL.Principal], [GetUserResult], ['query']),
    'getUserStats' : IDL.Func([], [GetUserStatsResult], ['query']),
    'getUsers' : IDL.Func([GetUsersRequest], [GetUsersResult], ['query']),
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
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'http_request_update' : IDL.Func([HttpUpdateRequest], [HttpResponse], []),
    'join' : IDL.Func([], [Result], []),
    'startGameVote' : IDL.Func(
        [StartGameVoteRequest],
        [StartGameVoteResult],
        [],
      ),
    'voteOnNewGame' : IDL.Func(
        [VoteOnNewGameRequest],
        [VoteOnNewGameResult],
        [],
      ),
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
