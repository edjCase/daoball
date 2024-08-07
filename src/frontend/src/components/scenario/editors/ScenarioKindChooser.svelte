<script lang="ts">
    import { Select } from "flowbite-svelte";
    import { ScenarioKindRequest } from "../../../ic-agent/declarations/main";
    import NoLeagueEffectScenarioEditor from "./scenarios/NoLeagueEffectScenarioEditor.svelte";
    import ProportionalBidScenarioEditor from "./scenarios/ProportionalBidScenarioEditor.svelte";
    import LotteryScenarioEditor from "./scenarios/LotteryScenarioEditor.svelte";
    import LeagueChoiceScenarioEditor from "./scenarios/LeagueChoiceScenarioEditor.svelte";
    import ThresholdScenarioEditor from "./scenarios/ThresholdScenarioEditor.svelte";
    import TextInputScenarioEditor from "./scenarios/TextInputScenarioEditor.svelte";

    export let value: ScenarioKindRequest;
    $: selectedType = Object.keys(value)[0];
    let onChange = (e: Event) => {
        selectedType = (e.target as HTMLSelectElement).value;
        if (selectedType === "threshold") {
            value = {
                threshold: {
                    undecidedAmount: { fixed: BigInt(0) },
                    options: [
                        {
                            title: "Contribute",
                            description:
                                "Contribute 1 to the threshold, but -1 random skill to a random player on the team for a match.",
                            currencyCost: BigInt(0),
                            traitRequirements: [],
                            value: { fixed: BigInt(1) },
                            teamEffect: {
                                skill: {
                                    duration: { matches: BigInt(1) },
                                    skill: { random: null },
                                    position: {
                                        position: { random: null },
                                        team: { contextual: null },
                                    },
                                    delta: BigInt(-1),
                                },
                            },
                        },
                        {
                            title: "Don't Contribute",
                            description:
                                "Don't contribute to the threshold, but no negative effect.",
                            currencyCost: BigInt(0),
                            traitRequirements: [],
                            value: { fixed: BigInt(0) },
                            teamEffect: { noEffect: null },
                        },
                    ],
                    success: {
                        effect: {
                            currency: {
                                team: { contextual: null },
                                value: { flat: BigInt(10) },
                            },
                        },
                        description: "+10 💰 for each team",
                    },
                    failure: {
                        effect: {
                            entropy: {
                                team: { contextual: null },
                                delta: BigInt(1),
                            },
                        },
                        description: "+1 🔥 for each team",
                    },
                    minAmount: BigInt(1),
                },
            };
        } else if (selectedType === "leagueChoice") {
            value = {
                leagueChoice: {
                    options: [
                        {
                            title: "Fast Start",
                            description:
                                "There is no time to wait, give us the 💰and crank up the 🔥. +10 💰+2 entropy per team",
                            currencyCost: BigInt(0),
                            leagueEffect: {
                                allOf: [
                                    {
                                        entropy: {
                                            delta: BigInt(2),
                                            team: {
                                                contextual: null,
                                            },
                                        },
                                    },
                                    {
                                        currency: {
                                            team: {
                                                contextual: null,
                                            },
                                            value: {
                                                flat: BigInt(10),
                                            },
                                        },
                                    },
                                ],
                            },
                            teamEffect: {
                                noEffect: null,
                            },
                            traitRequirements: [],
                        },
                        {
                            title: "Status Quo",
                            description:
                                "Things are in balance, lets not touch anything",
                            currencyCost: BigInt(0),
                            leagueEffect: {
                                noEffect: null,
                            },
                            teamEffect: {
                                noEffect: null,
                            },
                            traitRequirements: [],
                        },
                        {
                            title: "Cool Down",
                            description:
                                "Entropy is running too hot, lets cool it off by investing in our league. -5 💰-2 🔥 per team",
                            currencyCost: BigInt(0),
                            leagueEffect: {
                                allOf: [
                                    {
                                        entropy: {
                                            delta: BigInt(-2),
                                            team: {
                                                contextual: null,
                                            },
                                        },
                                    },
                                    {
                                        currency: {
                                            team: {
                                                contextual: null,
                                            },
                                            value: {
                                                flat: BigInt(-5),
                                            },
                                        },
                                    },
                                ],
                            },
                            teamEffect: {
                                noEffect: null,
                            },
                            traitRequirements: [],
                        },
                    ],
                },
            };
        } else if (selectedType === "lottery") {
            value = {
                lottery: {
                    minBid: BigInt(0),
                    prize: {
                        description: "+10 💰",
                        effect: {
                            currency: {
                                team: { contextual: null },
                                value: { flat: BigInt(10) },
                            },
                        },
                    },
                },
            };
        } else if (selectedType === "proportionalBid") {
            value = {
                proportionalBid: {
                    prize: {
                        description:
                            "+1 random skill for 1 match to a random player on the team",
                        kind: {
                            skill: {
                                duration: { matches: BigInt(1) },
                                skill: { random: null },
                                position: {
                                    position: { random: null },
                                    team: { contextual: null },
                                },
                            },
                        },
                        amount: BigInt(1),
                    },
                },
            };
        } else if (selectedType === "textInput") {
            value = {
                textInput: {
                    description: "Enter some text",
                },
            };
        } else if (selectedType === "noLeagueEffect") {
            value = {
                noLeagueEffect: {
                    options: [
                        {
                            title: "Option 1",
                            description: "Description 1",
                            currencyCost: BigInt(0),
                            traitRequirements: [],
                            teamEffect: { noEffect: null },
                        },
                        {
                            title: "Option 2",
                            description: "Description 2",
                            currencyCost: BigInt(0),
                            traitRequirements: [],
                            teamEffect: { noEffect: null },
                        },
                    ],
                },
            };
        } else {
            throw new Error(`Unknown meta effect type: ${selectedType}`);
        }
    };

    const types = [
        {
            name: "Threshold",
            value: "threshold",
        },
        {
            name: "League Choice",
            value: "leagueChoice",
        },
        {
            name: "Lottery",
            value: "lottery",
        },
        {
            name: "Proportional Bid",
            value: "proportionalBid",
        },
        {
            name: "Text Input",
            value: "textInput",
        },
        {
            name: "No League Effect",
            value: "noLeagueEffect",
        },
    ];
</script>

<Select items={types} on:change={onChange} value={selectedType} />
{#if "threshold" in value}
    <ThresholdScenarioEditor bind:value={value.threshold} />
{:else if "leagueChoice" in value}
    <LeagueChoiceScenarioEditor bind:value={value.leagueChoice} />
{:else if "lottery" in value}
    <LotteryScenarioEditor bind:value={value.lottery} />
{:else if "proportionalBid" in value}
    <ProportionalBidScenarioEditor bind:value={value.proportionalBid} />
{:else if "textInput" in value}
    <TextInputScenarioEditor bind:value={value.textInput} />
{:else if "noLeagueEffect" in value}
    <NoLeagueEffectScenarioEditor bind:value={value.noLeagueEffect} />
{:else}
    NOT IMPLEMENTED SCENARIO KIND : {selectedType}
{/if}
