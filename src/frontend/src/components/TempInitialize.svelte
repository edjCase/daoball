<script lang="ts">
  import { CreatePlayerFluffResult } from "../ic-agent/declarations/players";
  import { teamStore } from "../stores/TeamStore";
  import { playerStore } from "../stores/PlayerStore";
  import { teams as teamData } from "../data/TeamData";
  import { players as playerData } from "../data/PlayerData";
  import { teamTraits as traitData } from "../data/TeamTraitData";
  import { leagueAgentFactory } from "../ic-agent/League";
  import { playersAgentFactory } from "../ic-agent/Players";
  import LoadingButton from "./common/LoadingButton.svelte";
  import { teamsAgentFactory } from "../ic-agent/Teams";
  import { traitStore } from "../stores/TraitStore";

  $: teams = $teamStore;
  $: players = $playerStore;

  let createTeams = async function (): Promise<void> {
    let leagueAgent = await leagueAgentFactory();
    let promises = [];
    for (let i = 0; i < teamData.length; i++) {
      let team = teamData[i];
      let promise = leagueAgent.createTeam(team).then(async (result) => {
        if ("ok" in result) {
          let teamId = result.ok;
          console.log("Created team: ", teamId);
        } else {
          console.log("Failed to make team: ", result);
        }
      });
      promises.push(promise);
    }
    await Promise.all(promises);
    await teamStore.refetch();
    await playerStore.refetch();
  };

  let createPlayers = async function () {
    let playersAgent = await playersAgentFactory();
    let promises = [];
    // loop over count
    for (let player of playerData) {
      let promise = playersAgent
        .addFluff({
          name: player.name,
          title: player.title,
          description: player.description,
          likes: player.likes,
          dislikes: player.dislikes,
          quirks: player.quirks,
        })
        .then((result: CreatePlayerFluffResult) => {
          if ("ok" in result) {
            console.log("Added player fluff: ", player.name);
          } else {
            console.error("Failed to add player fluff: ", player.name, result);
          }
        });
      promises.push(promise);
    }
    await Promise.all(promises);
  };

  let createTeamTraits = async function () {
    let teamsAgent = await teamsAgentFactory();
    let promises = [];
    for (let trait of traitData) {
      let promise = teamsAgent.createTeamTrait(trait).then(async (result) => {
        if ("ok" in result) {
          let traitId = result.ok;
          console.log("Created trait: ", traitId);
        } else {
          console.log("Failed to make trait: ", result);
        }
      });
      promises.push(promise);
    }
    await Promise.all(promises);
    await traitStore.refetch();
  };

  let initialize = async function () {
    await createPlayers();
    await createTeams();
    await createTeamTraits();
  };
</script>

{#if !teams || !players || players.length + teams.length <= 0}
  <LoadingButton onClick={initialize}>
    Initialize With Default Data
  </LoadingButton>
{/if}
