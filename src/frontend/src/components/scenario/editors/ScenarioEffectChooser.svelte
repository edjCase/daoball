<script lang="ts">
    import { Select } from "flowbite-svelte";
    import { Effect } from "../../../ic-agent/declarations/league";
    import ScenarioEffectEditor from "./ScenarioEffectEditor.svelte";

    export let value: Effect;
    $: selectedType = Object.keys(value)[0];
    let onChange = (e: Event) => {
        selectedType = (e.target as HTMLSelectElement).value;
        if (selectedType === "allOf") {
            value = {
                allOf: [
                    {
                        noEffect: null,
                    },
                ],
            };
        } else if (selectedType === "oneOf") {
            value = {
                oneOf: [
                    {
                        weight: BigInt(1),
                        description: "",
                        effect: {
                            noEffect: null,
                        },
                    },
                ],
            };
        } else if (selectedType === "entropy") {
            value = {
                entropy: {
                    delta: BigInt(0),
                    target: { contextual: null },
                },
            };
        } else if (selectedType === "energy") {
            value = {
                energy: {
                    target: { contextual: null },
                    value: { flat: BigInt(1) },
                },
            };
        } else if (selectedType === "skill") {
            value = {
                skill: {
                    target: {
                        position: { random: null },
                        team: { contextual: null },
                    },
                    skill: { random: null },
                    duration: { matches: BigInt(1) },
                    delta: BigInt(0),
                },
            };
        } else if (selectedType === "injury") {
            value = {
                injury: {
                    target: {
                        position: { random: null },
                        team: { contextual: null },
                    },
                },
            };
        } else if (selectedType === "teamTrait") {
            value = {
                teamTrait: {
                    kind: { add: null },
                    target: { contextual: null },
                    traitId: "",
                },
            };
        } else if (selectedType === "noEffect") {
            value = {
                noEffect: null,
            };
        } else {
            throw new Error(`Unknown effect type: ${selectedType}`);
        }
    };

    const types = [
        {
            name: "All Of",
            value: "allOf",
        },
        {
            name: "One Of",
            value: "oneOf",
        },
        {
            name: "Entropy",
            value: "entropy",
        },
        {
            name: "Energy",
            value: "energy",
        },
        {
            name: "Skill",
            value: "skill",
        },
        {
            name: "Injury",
            value: "injury",
        },
        {
            name: "Team Trait",
            value: "teamTrait",
        },
        {
            name: "No Effect",
            value: "noEffect",
        },
    ];
</script>

<Select items={types} on:change={onChange} value={selectedType} />
<ScenarioEffectEditor bind:value />
