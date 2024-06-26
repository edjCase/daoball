<script lang="ts">
    import { CheckSolid, FileCopyOutline } from "flowbite-svelte-icons";
    import LoginButton from "../../components/common/LoginButton.svelte";
    import { User } from "../../ic-agent/declarations/users";
    import { identityStore } from "../../stores/IdentityStore";
    import { userStore } from "../../stores/UserStore";
    import { teamStore } from "../../stores/TeamStore";
    import UserPseudonym from "./UserPseudonym.svelte";
    import TeamLogo from "../team/TeamLogo.svelte";

    $: identity = $identityStore;
    $: teams = $teamStore;

    let user: User | undefined;
    let idCopied = false;

    $: {
        if (identity.getPrincipal().isAnonymous()) {
            user = undefined;
        } else {
            userStore.subscribeUser(identity.getPrincipal(), (u) => {
                user = u;
            });
        }
    }
    $: team = teams?.find((t) => t.id == user?.team[0]?.id);
    $: coOwner = user?.team[0]?.kind && "owner" in user.team[0].kind;

    let copyPrincipal = () => {
        if (!identity.getPrincipal().isAnonymous()) {
            idCopied = true;
            navigator.clipboard.writeText(identity.getPrincipal().toString());
            setTimeout(() => {
                idCopied = false;
            }, 2000); // wait for 2 seconds
        }
    };
</script>

<div class="bg-gray-800 p-4">
    {#if user}
        <div class="bg-gray-900 rounded-lg shadow-md p-6 w-full max-w-md">
            <div class="text-2xl font-bold mb-4">User Profile</div>
            <div class="mb-4">
                <div class="font-bold text-xl mb-2">Name</div>
                <div>
                    <UserPseudonym userId={user.id} />
                </div>
            </div>
            <div class="mb-4">
                <div class="font-bold text-xl mb-2">Id</div>
                <div class="flex items-center mt-2">
                    <div class="text-sm text-center mr-2">
                        {identity.getPrincipal().toString()}
                    </div>

                    {#if idCopied}
                        <CheckSolid size="lg" />
                    {:else}
                        <FileCopyOutline on:click={copyPrincipal} size="lg" />
                    {/if}
                </div>
            </div>
            <div class="mb-4">
                <div class="font-bold text-xl mb-2">Team</div>
                {#if team}
                    <TeamLogo {team} size="md" />
                    <div class="text-center">{team.name}</div>
                    <div class="text-center text-sm text-gray-400">
                        {coOwner ? "Co-Owner" : "Fan"}
                    </div>
                {:else}
                    <div>None</div>
                {/if}
            </div>
            <div class="mb-4">
                <div class="font-bold text-xl mb-2">Points - {user.points}</div>
            </div>
        </div>
    {/if}

    <div class="mt-4">
        <LoginButton />
    </div>
</div>
