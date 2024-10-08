import { ScenarioMetaData } from "../../ic-agent/declarations/main";
import { decodeBase64ToImage } from "../../utils/PixelUtil";

export const scenario: ScenarioMetaData =
{
    id: "knowledge_nexus",
    name: "Knowledge Nexus",
    description: "You enter a floating library of ancient wisdom. Books zip through the air, occasionally bonking distracted readers on the head.",
    location: {
        // zoneIds: ["ancient_ruins"], TODO
        common: null
    },
    category: { "encounter": null },
    image: decodeBase64ToImage("XzktQzUrNz0rRDwwQkIwP1g/T0kzRTswSUA1RTsrTT41TkU2V0Q7YFVqoUM2Ulo/V0wvO2FCTGZFSmlIUFE2PkItQVQ5RF48S29PVVpHSUwzS0QrMiwgMDQnNUkxRlE0QU80RE07VE0+WUszXFlAdlVBZk5CXlg6XUQ0TUEuRoBqYDMkOYdjZ1Q7S082WVU8V0QxRD8yR0k3Skw0VU87T0AzSkc5VXFLeTRMV0Y3VEw5TFg7Lk8xTFk2ZV5BYmVHTmpJZlpNYjBGT0s2TE89VEw2U2JBWC8rP1A5Uy4yT0wyTTA7VjpDWSgnQDM7U1FMU1M4UFE7UT8+UyEdLCEbLFFCT35Oe2VBV148U1tDXndMdG5IcXRIdWI0c04lagEAAQEDAgEDAQQBAwECAwUBBgEDBAACAgIDAQcBCAQHAQkBCgELAQwBDQEMAQ4DBwEAAwcCAgEAAQMBAAECAQEBBAIFAQ8BBAIBAQQCAwUAAxABEQESARMBFAIVAhMBEgEEAxABFgIXARACGAESAQQDAAEHAQkCCwEMAQ0BDAEOAQoBBwIAAQMBGQESARcBFAMXARoBBAEQAxIBEAIVARABFgEUAhYBFwEVARsCHAIdARsCEgIVAxcBBAEQAR4BHwEgARQBFgIYARYBAAECAQABIQEiAQsBIwELASMBJAENASQBJQEmAScBDgEoASkBFQEZARgBEgEWBCABBAEYASoBGAEbAh8BFwERARgBEwEEASsHHAEWASwBBAEVAxgBFQEWAS0CFwETAioBHgIAAQIBJgEuAQkCCgELAQwCDQElAQsCCgEuAS8BLgEpAQcBAwEsARgBGQEFAQYBFQEEAxIBGwMXARYBKgEWBRwBKwMcAR0BHwEgARUBFgEXAREBMAEgAR8BFwESAiwBMQECAgABIgEyAgkBCgIMASQCDQElAQsBDgEKASgBMwEnASgBBwEpATACKgEXASABFQEEARcBFgEXARUBFgEXARgBLAEVBhwBNAUcAR8BFQETAREBGAEEAR8CFwEsARgBKQMAAjUBBwEKAQ4CDAEkAw0BJAElAQwCCwEKAQ4BNgEAAQMBAAEeARgBLAEWAhUCGAESARUBEgEWARgBKgccAR0CAgMcAhUBEwESARgBBAEWARcBEwEsAR4CAgIpATUCDgIlASQDNwINAzcBJAEMAQ4BCgE1AQIBAAEBAQABHgEYASoBEQEbARMBGAESARUBEQESARYBKwIcAgQCFQEcASsBOAEUARsBHAEdAhUDGAEVARYCLAEFAwIBKQE1AQ4BDAElAjcBJQMkAg0BJAElBCQCOQEoASkBAgIpARYBEgEYARABGAEsARgBFQEXARIBAQEwAhwDGwEUAQQBKQE4AQQBBgEbAh0BBAETARcBEwEwARYBKgETASsBAAECAikBCgEMAQ0DJAEuASUCJAINASUBJAIlASQBNwEkASUBOQExAwIBMAETARgBEAEYARcBGAEVARIBEQErATcBFQEcAQQBOgEaASABBAEDASQBMAEEAR0BFQEeAQQBEgEUARIBFQIYAQQBKwEBAikBCwEMASQBDQIkAiUBJgElASQCDQIkASYCJQEkAQ0BJAElASgBKQECAQkBAgEVARMBEAEYARYBGAEEARgBEAEwATcBEAEbARABBgIVAQQBNQENARsBOwEbATABFQEbARABLQEQATwBGAERASsBAAICAQoBCwEkAjcCJAElAi4BPQEkAw0BNwElAT4BJQE3AQ0BNwElASMBOQEpAQICAAIWAj8BEQEfARIBEAEEAUABIAMQARoBIAEdAQABOAEbATsBGwEVARICEwMYARQBBgEVAQIBKQECAQ4CJAE3ASQBPQElAS4BIwEnAT0BJAINASQDJQIkAjcBJAE3ATYBKQE5AQIBMQEbBiwBFgEEAUECEAEKAkIBLQEXAQEBQwEWAQEIHQEUASkBDwMpAQsBDQIkASUBPgEiATMBPQE2AQwBJAINAiUBLgIlBiQBMAFEAikBEAcbARoBJgEzASkBRQFGAUABEQUQAhsBAQEVAQQBEAEbARABFQEeASkBAgEuATUBCwMkAScBIwEoATMCLgIlASQCDQElASYCOQEuASIBJQMkASgBQwEpATABKwEVASACFwETAhsBIAERBRMBEgEdARwBHQNHAh0BHgEfAREBEwEbAQECKQNFASUBJAElAQsCNQECAS4BJwEvATMBIwEMAyQBJwEiATUBKAE5ASEBJwIlAS8BKAEzAUgBAgEVAREDEwEBBB0CHAEdAisBBAEcASsCSQEBAx0BAQMbAhUBSgEoAUoBLwIlASgBCQEHAUUBSgEoATMCKAEOASMBNgE5AygCSAIpATMBRQInASkBAgFDATIBHQEbARUCEAEBAh0BSwFMAU0BKwIcASsBQQEQASgCJAECARUBHQEbARUBEAEUARsBHgEoAQYBSgEhAS4BJwEoASkBAAEmAkoBSAIoAwIEKQEOASgBLgEaAigBKQEoASIBRQEoAQIBMAEVAQYBPAEgARUBGwEdARUBQgENAU4BAAEVAQEBFQFBARYBSAEkAQwBCAIVARsBSgEfAT8BGwIaAR4BJwEEAR4BQwECAikCKAFKASgCAgIHATUBCQIoAwICKAFDASgCKQE1AUUBSAFKAhUBPAEFAT8BMgEbAQEBMQE4AQ0BOAFCARABHwEQASQBFAEtASQBDAECAQEBSgEbASgBFgEYARACLQEgAS4CHgE6ASkBAgEHASgBSgEzAQIDBwFPAQsCNQFBAgcBKAEAAQIBKAFFASkBSgIpAUgBBAEbARUBEwEYARYBOgEbARUBKQE4AQ0COAEtAhABLAFQAQYBDAE4ATkBHgEVAQQBDgEUARgCEAEGARYBFAEEAUoBOgI1AQkBSgEyASkBAgEHASEBNAFPAVEBNAE6AU8CMQEJATUBKQEDASkBFQEaASABFgEGAR0BFQEEARMBGAEWATQBBAEVAQABOAIkATgBGgIEBRgBHwIUAQQBOQEWARgCEAIdARwBFgEVASABPAIoBCkBEQETATABMgEwASgBNQFQAQUBLQEYAykBAgEpARoBMAEEASsBAgEdAQQBEwEYARQBUQEVAQYBIAEXARgCLAEqARgBLAgcAQQBKAEWARgBBAEGAR0BKwEBARgBGwEEASABSgEzAgIBQwERASABAgEVAwIBAAErASkBGgEWARMBOgFKASkBGgEEARUBHQErAUkBKwEEARMBGAEUAVEBFQkbATgBQgEcAR0BHAJHATgBBAEOARQBGAEQASABAAEJARYBEgEpARsBBgEVAQABMQEEARUBBAICAQkEIwEJAgIBBAIGARUBMAEpAgQBAwELAU4BKwEQAT8BGAEUAVEBGwccAh0BDQE4ARUBBAEbAkIBOAEEASgBFgEYARABHwECAQkBCAEYAQcBEAEEAikBMQEVAR4BAAEJAiMBCQFNAQsDIwEoAQICAAECAQMBKQEVATABCAEMAUsBHQEfAT8BGAE7AVEBCQFLAUcDHAFBAQIBBAEOAQ0BOAEIAQYBIAEIAUIBOAEEASgBFgEYARABHwERARcBLQEWAQYBHwIpATEBAAEpATECIwEMAj0BTQEkASMBIgEMAyMBAgEpARQBBgEVASABCAEMAUwBHQEUARMBGAEUAVEBCQFMAUkCKwEAAUABIAEGAQwBDQFSAQgBBgEQAQgBQgE4AQQBKAEWARgCEAQcAR0BHwEeAQYCMgECAT0DJQEjAk0BJAFMATgCDAElASMBAgEpARgBFwEVARABFQEtAgQBHwETARgBFAFRAQcBOAEIARABIAE2AUEBFwEtASQCOAE6AQYBLQEEAUsBDAEEARoBFgEYARABFAEdAysBHQEfARUBBgFDAVABKQMlAUcBSQFCAjgBDAI4ASYBJQEjASkBAQIrAhUBKwIcARUBHgETARgBFAFEAQMBOAE6AR8BIAE6ARMBFwEtASQBKgETARIBLAEqARIBFQEQARsBHgEWARgBEAEfAQIBAAEZAQcBAQEQAQYDHQECAiQBJQFNAVMBHAEQARsBVAFNAQwBIwElASMCAgEKATIBHgEVASsBRwEIARsBHgE/ARgBFAEvAQQBOAIzAyUBGgEjAQwGHQEbAR0BFQEeARYBGAIfAgIBPwFMARsBEAEVAUoBCQEHASgEJAFNAVMBMwEsAU0CTAIkASMCAgEJAU8CEAEJAQABGQEbAR4BPwEYARQBLwEbAUMHGAETBxwBTQEbAR4BFgEYASABHwEuAVIBGAFMAR0CEAEyATgBQgE1AyQDTQFHAU4BJAE4AkwCPQEpARoBGQEdAhABAgEAARkBGwEeAT8BGAEUAS8BGwEdAxwBTQQcAh0BSQEBAR0CHAFLARsBBgEWARgCIAEXARYBFwEWAR0CEAIEARUBKQMkB00BOAEMASUBIwECAR0BHAEdAhABHwE0ARQBGwEeAT8BGAEUAS8BGwIcASsBAAIkAUcEHQFLARsBFQIBATgBBAEGARYBGAIQARwBKwIcAR0DEAEdAU4BKQIkASUBTQEqASwBTAFJASoBLAFNAQ0CJQFKAQABCgFVARABGwIdASsBHQEVAT8BGAEUAVEBGwEdAQEBMQEoAiQBUgEEARsCEAE4AQQBFwEfAQgBOAEEAQYBFgEYAiABCgE4AgIBGwIQAQQBDgELASkCJAJJASoELAEqAU0BTAEkASUBKQEZARgBOAEQARsBAQFHAUsBAQEVAT8BKgEUAS8CGwEQASgBCgEMAUwBQgEGAxABOAEpARcBHwFCASQBGwEGARYBGAEfARABTgE4ASkBOwEbARQBEAEWAR8BBgFKASQCTQFJAxsBHAIbAk0BDQElASkDKwEbARABCQEAAUwBGwEVAT8BGAEUAS8DGwEIASgBJAEMAUIBBAEbASABAwE4ASkBBAEpAUIBCgEbAQYBFgEYAR8BFAEHATgBEQE7ARsCEAEdAQEBTgEoASQBTQFJAU0BVgEsATsCGwFWASwBJAFJASQBFQEAAQoBCwEbARABBwEJATgBGwEVAT8BGAEUAS8BGwEVAQIBIwEoASEBJAFSAQUBEAQSAhcCFAEbAR4BFgEYARABFAIXAREBGQEbAhABBAEBAUwBKQEkAU0BRwEkAUcFUwFNAUsBTQEkAQQBEwEHAQoBGwEQAQcBCQE4ARsBFQETASoBFAEFARsBOwMSAhgBEwISCBwBGwEwARYBGAEfARABKwEcASsBHAEdAxACFgEpASQDTQFJAVMBHAFNAlMBTQFJAU0BJAEEAQEBTAEDARQBGwEBAQIBBgEbARUBPwEqARQBBQEbCRwGHQIrARsBMAEfARgBIAEQAQABTAErAQgBHQMQAisBKQEkAk0BUwFHARwDTQJTAUkBTQEkARUCFgEgARABGwQcARsBPwEqARQBBQEbAh0BAQJHARwDHQEQARsBAwEAAU4BJAEKAQABGwEGARYBGAEfARABSgFMAR4BGQEdARABHwEoAQsBCQECASQCTQJTARwCTQFLAU0BUwFJAU0BJAEVAQABHQE4ARQBGwIrAUcBHAEbAREBGAEUAQUBGwEdAQgBOAEMAQgBFQEEATgCFAEWATEBNQE4AQ0BQgEDARsBBgEWARgBHwEQAQoBOAEfAVIBGwIQASABFgEtAQIBJAJNAlMDTQFMAU0BUwJNASQBFQIJATgBFAEQAgkBTAEeARsBPwEYARQBBQEbARUBCAE4ASQBCAEEARUBOAEUAQQBFgIyATgBDQFCAQMBGwEeAR8BGAEfARQDEgEUAR0CEAIdAQIBAwEkAk0CUwJNAUkBTAFHARwBTQIkASkBIAIaAR4BEAEJAQsBTAEGARsBPwEYARQBBQIbAQgBDQEkAhYBAgENARQBJQEiAREBJAM4AQEBGwEeAR8BGAEUARABHAIrARwBHQEEARABKQE1AQoBAgEkAk0CUwJNAUkBTAE4AUcBTQIkASsCHQErAhABBwFLATgBAwEbAREBGAEUAQUBFQEJAU4BOAEKARcBFgFKAQwBMgIbARABFQEQARUBEAIbATABHwEYARQBEAErAgcBAgEdARUBEAEjASYBQgEVAiQBTQFTARwDSQFMASQBSQFNAiQBAgE6ARYBUgMQAR8BFgEQARsBEQEYARQBLwEVBRMEGAIcAh0CRwIBARsBMAEfARgBHwEEAQIBBwELARkBGwEUAR8DHgEVAyQBTQEcA0kBSwEkAUkBTQEkATcBAgMVAhsDHQFCARUBEQEYARQBLwEbBR0DHAErAgEBKwEBATgBQgIdARsBMAEfARgBHwEVATMBBwFOAU8BGwEEAR4BPAJIARUDJAJNAUkBSwFMAUkBDAFOAU0BKwUCARUBGwEdASsBBwE4ARsBEQEYARQBLwEbBB0CFQIEAR0BIAEwAQYBIAE4AUIBMgEEARsBBAEfARgCHwQQASABFQI8AhoBSgIoATMCTQFJAksBSQFMAUsBSQEHARQEAgEVARsBAQECAUkBOAEQAREBGAEUAQ8BGwEdAgQCMAEGAQcBMgIEAQYBIAFDASQBQgEwAQQBGwEQAR8BGAEfAQEBFQFQAjwCUAI8AkoBBQIqASwCTQFJAksBTQFMATgBSwFJAUoCGgE8AUoBBAEbAQEBCgI4ARABEQEYARQBLwMbAwQBHgE1ASgBBAFMAR4BIAEiASQBTAEEARUBGwEQARQBGAEQARcBPAFIBlABRQEzA1ABMAEcAU0BSQFLAkkBTQEkA0sBHgFQAzwCHgIwAQQBEAEXARIBFAFRAxsDLQEwAQoBCwEVARQBFgIYARMCEgEVAhsBEAERARsBVwFKAiIBLgEzAlABRQEzA0oBKAEyAk0BSQFOAUkBTAFNAUwCDAFJAUsEUAI8AVABPAEtBRABGwEQARYBFwERBBgBEwIWAxcCEgEVAxcBFgEeAVgBJQINASYCMwFFATMBSgIsARMBGAE6Ak0BSQFOAkkBTAFNASQCDAEkBVABLQE6AQYCGwEYAiwBEgEbARcBEwcYAxIBEQEfARUBAQMVAR4BEAEeAQwDDQEmATACFQElAkACPgFZATcCSQFNAUsBTQFMA00BSwIkBlABGgFKAR0CGwEVAhsBFQcdARsBEAMDASsBAQEcASsBHQIBARUBIAEVAiQBJgJBASgBMANAAy4BRQEzASsBIAEdASsCHQEUAgICKwIBASsCAgQVAhsEEAEbAxwBGwEWARcBHQIfAQEBGwEGASAEHQEbARUBEAEtARUBQQEkAUECJQEoATkBJANAAiwCPgEXAlACPAEdARsBKwJKAUUBOgEtARgBEgEqAQICFQEBAQQDGwEVAQYBFQIcAR0BGgEdAhsCAQEXARYCBAEbAh0BGwEQARYBFAERAQYBJQINASQBQQEuAVoBPgEnASYBJwMuAigBMwELASMBJQEPAQUCGAEGBCgDKQMVARsBFQEtAhcBFgETAgEBGwEEASwBHQEUARcBGAEWASwCAQMdARABIAEUAh8BEAEPASQCDQE+AT0BWgEsAkACWwVaAVsGWghAATMBFQEbAxUBFgEXARMBEAIbAR0CGwE+AQEBGwEqARABEgEBAx0BBAEbAhYCFwEeAS8EJAFcAVsBXAFaASwBWgRWAiwBVgFcAloDLAFaAlwBNwFaASwCQAEjAxUBEAEgAxYBEgEQARsBKwEVARsBRQIbARMBFQEWAx0CGwEgAhABGwEQASABLQEeAT0BVgFcATcBXAIsAjcELAJcAVoBXAE3AlwBNwFaASwBVgEsATcBWwE3AkABXQE9ARUBHwIbBhABFQEdARUBKQIbARgEUwEcARsBHgEWAR8FIAEuASUENwEsAVYCNwFWDTcELAE3BFsBPgEQARYBIAIQAh4BEAEXAh0CAQEdARsBEgVTCBsBBAEnAVsBXAE3AVwCLBA3AVwCNwJcASwBWgE3AVwBWwE+BRABPAEQASABEBRTAQkBWwRcASwVNwFcATcBLAM3AVwBQAEkAV0ZUwEjAV0BVgE3AVodLAE3AlwBWgFbASMXUwEJAVsCVgE3AVsDXQNbAT4BXQFaAzcBXAE3AlwNWwFWAlwCVgFdAV4VUwEcAV4MVgJaC1sBXAlWAloDVgFdHFMDVANTAlQCUwVUBFMBVAFTAlQCUwRUAlMBVAJTAVQMUw=="),
    paths: [
        {
            id: "start",
            description: "The air hums with arcane energy, and you swear you can hear the books whispering secrets. What do you do?",
            kind: {
                choice: {
                    choices: [
                        {
                            id: "study_magic",
                            description: "Study ancient texts to expand your magical knowledge. Hope you brought your reading glasses!",
                            requirement: [],
                            effects: [],
                            nextPath: {
                                multi: [
                                    {
                                        weight: { value: 0.7, kind: { attributeScaled: { wisdom: null } } },
                                        description: "You successfully decipher an ancient tome. Your brain feels bigger, but your hat size remains the same.",
                                        effects: [{ addItemWithTags: ["book"] }],
                                        pathId: []
                                    },
                                    {
                                        weight: { value: 0.3, kind: { raw: null } },
                                        description: "The text is too complex. You end up reading 'Ancient Runes for Dummies' instead.",
                                        effects: [],
                                        pathId: []
                                    }
                                ]
                            }
                        },
                        {
                            id: "learn_combat",
                            description: "Learn new combat techniques from old battle manuals. Hopefully, they're not just elaborate dance instructions.",
                            requirement: [],
                            effects: [],
                            nextPath: {
                                multi: [
                                    {
                                        weight: { value: 0.5, kind: { attributeScaled: { strength: null } } },
                                        description: "You master an ancient fighting technique. Your muscles now ripple with knowledge.",
                                        effects: [{ addItem: "battle_manual" }],
                                        pathId: []
                                    },
                                    {
                                        weight: { value: 0.5, kind: { attributeScaled: { dexterity: null } } },
                                        description: "You learn a set of defensive maneuvers. You can now dodge responsibility AND attacks!",
                                        effects: [{ addItem: "evasion_scroll" }],
                                        pathId: []
                                    }
                                ]
                            }
                        },
                        {
                            id: "decipher_map",
                            description: "Attempt to decipher an old map. It's either a treasure map or yesterday's lunch menu.",
                            requirement: [],
                            effects: [],
                            nextPath: {
                                multi: [
                                    {
                                        weight: { value: 0.6, kind: { attributeScaled: { wisdom: null } } },
                                        description: "You successfully decipher the map, revealing the location of a hidden treasure. X marks the spot... or is that a ketchup stain?",
                                        effects: [{ addItem: "treasure_map" }],
                                        pathId: []
                                    },
                                    {
                                        weight: { value: 0.4, kind: { raw: null } },
                                        description: "The map remains a mystery. You're pretty sure you're holding it upside down, but it doesn't help.",
                                        effects: [],
                                        pathId: []
                                    }
                                ]
                            }
                        },
                        {
                            id: "leave",
                            description: "Leave the Knowledge Nexus. Your brain is full, and you can't remember where you parked your horse anyway.",
                            requirement: [],
                            effects: [],
                            nextPath: { none: null }
                        }
                    ]
                }
            }
        }
    ],
    unlockRequirement: { none: null }
};