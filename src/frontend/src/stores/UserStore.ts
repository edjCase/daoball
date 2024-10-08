import { writable } from 'svelte/store';
import { mainAgentFactory } from '../ic-agent/Main';
import { GetUserResult, User, UserStats } from '../ic-agent/declarations/main';
import { toJsonString } from '../utils/StringUtil';
import { Principal } from '@dfinity/principal';
import { getOrCreateAuthClient } from '../utils/AuthUtil';

export type UserData = {
    id: Principal;
    data: User;
};

function createUserStore() {
    let currentUserId: Principal | undefined = undefined;
    const currentUser = writable<UserData | undefined>(undefined);
    const userStats = writable<UserStats>();


    const refetchCurrentUser = async () => {
        if (!currentUserId) {
            return; // No user to fetch
        }
        let mainAgent = await mainAgentFactory();
        let result: GetUserResult = await mainAgent.getUser(currentUserId);
        if ('ok' in result) {
            currentUser.set({
                id: currentUserId,
                data: result.ok
            });
        }
        else if ('err' in result && 'notFound' in result.err) {
            let result = await mainAgent.register();
            if ('ok' in result) {
                console.log("Registered user", result.ok);
                currentUser.set({
                    id: currentUserId,
                    data: result.ok
                });
            } else {
                console.error("Failed to register user. Logging out", result);
                logout();
            }
        } else {
            throw new Error("Failed to get user: " + currentUserId + " " + toJsonString(result));
        }
    };

    const subscribeCurrentUser = (callback: (user: UserData | undefined) => void) => {
        return currentUser.subscribe(callback);
    };

    const subscribeStats = async (callback: (stats: UserStats | undefined) => void) => {
        userStats.subscribe(callback);
    };

    const refetchStats = async () => {
        let mainAgent = await mainAgentFactory();
        let result = await mainAgent.getUserStats();
        if ('ok' in result) {
            userStats.set(result.ok);
        } else {
            console.log("Error getting user stats", result);
        }
    };



    const login = async () => {
        let authClient = await getOrCreateAuthClient();
        const identityProvider =
            process.env.DFX_NETWORK === "ic"
                ? `https://identity.ic0.app`
                : `http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943`;
        await authClient.login({
            maxTimeToLive: BigInt(30) * BigInt(24) * BigInt(3_600_000_000_000), // 30 days
            identityProvider: identityProvider,
            onSuccess: async () => {
                console.log("Logged in");
                currentUserId = authClient.getIdentity().getPrincipal();
                await refetchCurrentUser();
            },
            onError: (err) => {
                console.error(err);
            }
        });
    };

    const logout = async () => {
        let authClient = await getOrCreateAuthClient();
        currentUserId = undefined;
        await authClient.logout();
        currentUser.set(undefined);
    };

    const checkForLogin = async () => {
        let authClient = await getOrCreateAuthClient();
        let identity = authClient.getIdentity();
        if (!identity.getPrincipal().isAnonymous()) {
            currentUserId = identity.getPrincipal();
            await refetchCurrentUser();
        } else {
            currentUserId = undefined;
        }
    }

    checkForLogin();
    refetchStats();
    return {
        login,
        logout,
        subscribe: subscribeCurrentUser,
        refetchCurrentUser,
        subscribeStats,
        refetchStats
    };
}

// Create a store
export const userStore = createUserStore();