<script lang="ts">
    import {
        ProportionalBidScenarioOutcome,
        ProportionalBidScenario,
    } from "../../../ic-agent/declarations/league";
    import { Team } from "../../../ic-agent/declarations/teams";
    import { toJsonString } from "../../../utils/StringUtil";

    export let scenario: ProportionalBidScenario;
    export let outcome: ProportionalBidScenarioOutcome;
    export let teams: Team[];

    const getTeamName = (teamId: bigint) => {
        return teams.find((team) => team.id === teamId)?.name ?? "Unknown";
    };
</script>

{#each outcome.bids as bid}
    Prize: {scenario.prize.amount} of {toJsonString(scenario.prize.kind)}
    <div class="text-xl text-center">
        {getTeamName(bid.teamId)} got {bid.proportion}
    </div>
{/each}
