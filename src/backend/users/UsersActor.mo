import Trie "mo:base/Trie";
import Player "../models/Player";
import Nat32 "mo:base/Nat32";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import TextX "mo:xtended-text/TextX";
import IterTools "mo:itertools/Iter";
import Types "./Types";
// import LeagueActor "canister:league"; TODO

actor UsersActor {

    stable var users : Trie.Trie<Principal, Types.User> = Trie.empty();

    public shared query ({ caller }) func get(userId : Principal) : async Types.GetUserResult {
        if (caller != userId and not isLeague(caller)) {
            return #notAuthorized;
        };
        let ?user = Trie.get(users, buildPrincipalKey(userId), Principal.equal) else return #notFound;
        #ok(user);
    };

    // TODO should there be a get all?
    public shared query ({ caller }) func getAll() : async [Types.User] {
        Trie.iter(users)
        |> Iter.map(
            _,
            func((_, user) : (Principal, Types.User)) : Types.User = user,
        )
        |> Iter.toArray(_);
    };

    public shared query ({ caller }) func getTeamOwners(teamId : Principal) : async [Types.TeamOwnerInfo] {
        Trie.iter(users)
        |> IterTools.mapFilter(
            _,
            func((userId, user) : (Principal, Types.User)) : ?Types.TeamOwnerInfo {
                let ?team = user.team else return null;
                if (team.id != teamId) {
                    return null;
                };
                let #owner(o) = team.kind else return null;
                ?{
                    id = userId;
                    votingPower = o.votingPower;
                };
            },
        )
        |> Iter.toArray(_);
    };

    public shared ({ caller }) func setFavoriteTeam(userId : Principal, teamId : Principal) : async Types.SetUserFavoriteTeamResult {
        if (Principal.isAnonymous(userId)) {
            return #identityRequired;
        };
        if (caller != userId and not isLeague(caller)) {
            return #notAuthorized;
        };
        let userInfo = getUserInfoInternal(userId);
        switch (userInfo.team) {
            case (?team) {
                return #alreadySet;
            };
            case (null) {
                let teamExists = true; // TODO get all team ids and check if teamId is in there
                if (not teamExists) {
                    return #teamNotFound;
                };
                updateUser(
                    userId,
                    func(user : Types.User) : Types.User = {
                        user with
                        teamAssociation = ?{
                            id = teamId;
                            kind = #fan;
                        };
                    },
                );
            };
        };
        #ok;
    };

    public shared ({ caller }) func addTeamOwner(request : Types.AddTeamOwnerRequest) : async Types.AddTeamOwnerResult {
        if (not isLeague(caller)) {
            return #notAuthorized;
        };
        let userInfo = getUserInfoInternal(request.userId);
        switch (userInfo.team) {
            case (?team) {
                if (team.id != request.teamId) {
                    return #onOtherTeam(team.id);
                };
            };
            case (null) {
                let teamExists = true; // TODO get all team ids and check if teamId is in there
                if (not teamExists) {
                    return #teamNotFound;
                };
            };
        };
        updateUser(
            request.userId,
            func(user : Types.User) : Types.User = {
                user with
                team = ?{
                    id = request.teamId;
                    kind = #owner({ votingPower = request.votingPower });
                };
            },
        );
        #ok;
    };

    // TODO change to BoomDAO or ledger
    public shared ({ caller }) func awardPoints(awards : [Types.AwardPointsRequest]) : async Types.AwardPointsResult {
        if (not isLeague(caller)) {
            return #notAuthorized;
        };
        for (award in Iter.fromArray(awards)) {
            updateUser(
                award.userId,
                func(user : Types.User) : Types.User = {
                    user with
                    points = user.points + award.points;
                },
            );
        };
        #ok;
    };

    private func updateUser(userId : Principal, f : (Types.User) -> Types.User) {
        let userInfo = getUserInfoInternal(userId);
        let newUserInfo = f(userInfo);
        let key = buildPrincipalKey(userId);
        let (newUsers, _) = Trie.put(users, key, Principal.equal, newUserInfo);
        users := newUsers;
    };

    private func getUserInfoInternal(userId : Principal) : Types.User {
        switch (Trie.get(users, buildPrincipalKey(userId), Principal.equal)) {
            case (?userInfo) userInfo;
            case (null) {
                {
                    id = userId;
                    team = null;
                    points = 0;
                };
            };
        };
    };

    private func buildPrincipalKey(id : Principal) : {
        key : Principal;
        hash : Hash.Hash;
    } {
        { key = id; hash = Principal.hash(id) };
    };

    private func isLeague(caller : Principal) : Bool {
        // TODO
        // return caller == Principal.fromActor(LeagueActor);
        return true;
    };

    private func assertLeague(caller : Principal) {
        // TODO
        // if (!isLeague(caller)) {
        //     Debug.trap("Only the league can create players");
        // };
    };
};
