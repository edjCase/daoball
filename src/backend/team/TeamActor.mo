import Player "../models/Player";
import Principal "mo:base/Principal";
import Team "../models/Team";
import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import TrieSet "mo:base/TrieSet";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import None "mo:base/None";
import HashMap "mo:base/HashMap";
import { ic } "mo:ic";
import StadiumTypes "../stadium/Types";
import PlayersTypes "../players/Types";
import IterTools "mo:itertools/Iter";
import LeagueTypes "../league/Types";
import Types "Types";
import MatchAura "../models/MatchAura";
import Season "../models/Season";
import Util "../Util";
import Scenario "../models/Scenario";
import TeamState "./TeamState";
import ScenarioVoting "ScenarioVoting";
import Dao "../Dao";
// TODO cant use because of generating did files for JS/TS
// import UsersActor "cansiter:users";
import UserTypes "../users/Types";

shared (install) actor class TeamActor(
  leagueId : Principal,
  usersActorId : Principal,
) : async Types.TeamActor = this {

  let usersActor = actor (Principal.toText(usersActorId)) : UserTypes.Actor;

  stable var stableData = {
    scenarioVoting : [ScenarioVoting.Data] = [];
    dao : Dao.StableData<Types.ProposalContent> = {
      members = [];
      proposals = [];
      proposalDuration = #days(3);
      votingThreshold = #percent({
        percent = 50;
        quorum = ?20;
      });
    };
  };

  func onExecute(proposal : Dao.Proposal<Types.ProposalContent>) : async* () {
    switch (proposal.content) {
      case (#trainPlayer(trainPlayer)) {
        Debug.print("Training player: " # debug_show (trainPlayer));
      };
    };
  };

  func onReject(proposal : Dao.Proposal<Types.ProposalContent>) : async* () {
    Debug.print("Rejected proposal: " # debug_show (proposal));
  };

  var dao = Dao.Dao<Types.ProposalContent>(stableData.dao, onExecute, onReject);

  var scenarioVotingManager = ScenarioVoting.Manager(stableData.scenarioVoting);

  system func preupgrade() {
    stableData := {
      stableData with
      scenarioVoting = scenarioVotingManager.toStableData();
      dao = dao.toStableData();
    };
  };

  system func postupgrade() {
    dao := Dao.Dao<Types.ProposalContent>(stableData.dao, onExecute, onReject);
    scenarioVotingManager := ScenarioVoting.Manager(stableData.scenarioVoting);
  };

  public shared ({ caller }) func voteOnScenario(request : Types.VoteOnScenarioRequest) : async Types.VoteOnScenarioResult {
    let ?handler = scenarioVotingManager.getHandler(request.scenarioId) else return #scenarioNotFound;
    switch (await usersActor.get(caller)) {
      case (#ok(user)) {
        let ?team = user.team else return #notAuthorized;
        if (team.id != Principal.fromActor(this)) {
          return #notAuthorized;
        };
        let #owner(o) = team.kind else return #notAuthorized;
        handler.vote(caller, o.votingPower, request.option);
      };
      case (#notFound or #notAuthorized) #notAuthorized;
    };
  };

  public shared query ({ caller }) func getScenarioVote(request : Types.GetScenarioVoteRequest) : async Types.GetScenarioVoteResult {
    let ?handler = scenarioVotingManager.getHandler(request.scenarioId) else return #scenarioNotFound;
    #ok(handler.getVote(caller));
  };

  public shared ({ caller }) func createProposal(request : Types.CreateProposalRequest) : async Types.CreateProposalResult {
    let members = await usersActor.getTeamOwners(Principal.fromActor(this));
    dao.createProposal(caller, request.content, members);
  };

  public shared query ({ caller }) func getProposal(id : Nat) : async ?Types.Proposal {
    dao.getProposal(id);
  };

  public shared query ({ caller }) func getProposals() : async [Types.Proposal] {
    dao.getProposals();
  };

  public shared ({ caller }) func voteOnProposal(request : Types.VoteOnProposalRequest) : async Types.VoteOnProposalResult {
    await* dao.vote(request.proposalId, caller, request.vote);
  };

  public shared ({ caller }) func getWinningScenarioOption(request : Types.GetWinningScenarioOptionRequest) : async Types.GetWinningScenarioOptionResult {
    if (caller != leagueId) {
      return #notAuthorized;
    };
    let ?handler = scenarioVotingManager.getHandler(request.scenarioId) else return #scenarioNotFound;
    let ?winningOption = handler.calculateWinningOption() else return #noVotes;
    #ok(winningOption);
  };

  public shared ({ caller }) func onNewScenario(request : Types.OnNewScenarioRequest) : async Types.OnNewScenarioResult {
    if (caller != leagueId) {
      return #notAuthorized;
    };
    scenarioVotingManager.add(request.scenarioId, request.optionCount);
    #ok;
  };

  public shared ({ caller }) func onScenarioVoteComplete(request : Types.OnScenarioVoteCompleteRequest) : async Types.OnScenarioVoteCompleteResult {
    if (caller != leagueId) {
      return #notAuthorized;
    };
    switch (scenarioVotingManager.remove(request.scenarioId)) {
      case (#ok) #ok;
      case (#notFound) #scenarioNotFound;
    };
  };

  public shared ({ caller }) func onSeasonComplete() : async Types.OnSeasonCompleteResult {
    if (caller != leagueId) {
      return #notAuthorized;
    };
    // TODO
    #ok;
  };

  public shared ({ caller }) func getCycles() : async Types.GetCyclesResult {
    if (caller != leagueId) {
      return #notAuthorized;
    };
    let canisterStatus = await ic.canister_status({
      canister_id = Principal.fromActor(this);
    });
    return #ok(canisterStatus.cycles);
  };
};
