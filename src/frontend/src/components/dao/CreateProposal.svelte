<script lang="ts">
    import { Select } from "flowbite-svelte";

    let proposalTypes = [
        {
            value: "trainPlayer",
            name: "Train Player",
        },
        {
            value: "changeName",
            name: "Change Team Name",
        },
    ];
    let selectedProposalType: string = proposalTypes[0].value;
</script>

<div class="text-3xl text-center">Create Proposal</div>
<Select items={proposalTypes} bind:value={selectedProposalType} />
<slot {selectedProposalType} />
