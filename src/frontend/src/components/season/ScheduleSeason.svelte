<script lang="ts">
  import { Button, Checkbox, Input, Label } from "flowbite-svelte";
  import { scheduleStore } from "../../stores/ScheduleStore";
  import { dateToNanoseconds } from "../../utils/DateUtils";
  import { leagueAgentFactory } from "../../ic-agent/League";
  import {
    DayOfWeek,
    InProgressSeasonMatchGroupVariant,
    SeasonStatus,
  } from "../../ic-agent/declarations/league";
  import { stadiumAgentFactory } from "../../ic-agent/Stadium";

  let now = new Date();
  let dayOfWeek = now.getDay();
  let initialDateValue = new Date(now.getTime() + 2 * 60 * 1000); // TODO
  let startTime: bigint = dateToNanoseconds(initialDateValue);

  let sunday: boolean = dayOfWeek === 0;
  let monday: boolean = dayOfWeek === 1;
  let tuesday: boolean = dayOfWeek === 2;
  let wednesday: boolean = dayOfWeek === 3;
  let thursday: boolean = dayOfWeek === 4;
  let friday: boolean = dayOfWeek === 5;
  let saturday: boolean = dayOfWeek === 6;

  let scheduleSeason = async () => {
    if (!startTime) {
      console.error("No start time");
      return;
    }
    console.log("Scheduling season", startTime);

    let leagueAgent = await leagueAgentFactory();
    let weekDays: DayOfWeek[] = [];
    if (sunday) {
      weekDays.push({ sunday: null });
    }
    if (monday) {
      weekDays.push({ monday: null });
    }
    if (tuesday) {
      weekDays.push({ tuesday: null });
    }
    if (wednesday) {
      weekDays.push({ wednesday: null });
    }
    if (thursday) {
      weekDays.push({ thursday: null });
    }
    if (friday) {
      weekDays.push({ friday: null });
    }
    if (saturday) {
      weekDays.push({ saturday: null });
    }

    let result = await leagueAgent.startSeason({
      startTime: startTime,
      weekDays: weekDays,
    });
    if ("ok" in result) {
      console.log("Scheduled season");
      scheduleStore.refetch();
    } else {
      console.error("Failed to schedule season", result);
    }
  };
  let closeSeason = async () => {
    let leagueAgent = await leagueAgentFactory();
    let result = await leagueAgent.closeSeason();

    if ("ok" in result) {
      console.log("Closed season");
      scheduleStore.refetch();
    } else {
      console.error("Failed to close season", result);
    }
  };
  let setStartTime = (e: any) => {
    if (!e.currentTarget) {
      return;
    }
    startTime = dateToNanoseconds(new Date(e.currentTarget.value));
  };

  let scheduleStatus: SeasonStatus | undefined;
  scheduleStore.subscribeStatus((value) => {
    scheduleStatus = value;
  });

  function toLocalISOString(date: Date) {
    let year = date.getFullYear();
    let month = ("0" + (date.getMonth() + 1)).slice(-2);
    let day = ("0" + date.getDate()).slice(-2);
    let hours = ("0" + date.getHours()).slice(-2);
    let minutes = ("0" + date.getMinutes()).slice(-2);
    return `${year}-${month}-${day}T${hours}:${minutes}`;
  }

  const forceStartNextMatchGroup =
    (matchGroups: InProgressSeasonMatchGroupVariant[]) => async () => {
      let leagueAgent = await leagueAgentFactory();
      let nextMatchGroupId = matchGroups.findIndex(
        (matchGroup) => "scheduled" in matchGroup,
      );
      if (nextMatchGroupId < 0) {
        console.error("No next match group");
        return;
      }
      let result = await leagueAgent.startMatchGroup(BigInt(nextMatchGroupId));

      if ("ok" in result) {
        console.log("Forced start next match group");

        scheduleStore.refetch();
      } else {
        console.error("Failed to force start next match group", result);
      }
    };

  const finishMatchGroup =
    (matchGroups: InProgressSeasonMatchGroupVariant[]) => async () => {
      let liveMatchId = matchGroups.findIndex(
        (matchGroup) => "inProgress" in matchGroup,
      );
      if (liveMatchId < 0) {
        console.error("No live match group");
        return;
      }
      let stadiumAgent = await stadiumAgentFactory();
      await stadiumAgent.finishMatchGroup(BigInt(liveMatchId));
      console.log("Finished match group");
    };
</script>

<div class="container">
  {#if scheduleStatus && ("inProgress" in scheduleStatus || "starting" in scheduleStatus)}
    {#if "inProgress" in scheduleStatus}
      <Button
        on:click={forceStartNextMatchGroup(
          scheduleStatus.inProgress.matchGroups,
        )}>Force Start Next Match Group</Button
      >
      <Button on:click={finishMatchGroup(scheduleStatus.inProgress.matchGroups)}
        >Finish Match Group</Button
      >
    {/if}
    <Button on:click={closeSeason}>Close Season</Button>
  {:else}
    <Input
      type="datetime-local"
      on:change={setStartTime}
      value={toLocalISOString(initialDateValue)}
    />
    <div class="flex">
      <Checkbox bind:checked={sunday} />
      <Label>Sunday</Label>
    </div>
    <div class="flex">
      <Checkbox bind:checked={monday} />
      <Label>Monday</Label>
    </div>
    <div class="flex">
      <Checkbox bind:checked={tuesday} />
      <Label>Tuesday</Label>
    </div>
    <div class="flex">
      <Checkbox bind:checked={wednesday} />
      <Label>Wednesday</Label>
    </div>
    <div class="flex">
      <Checkbox bind:checked={thursday} />
      <Label>Thursday</Label>
    </div>
    <div class="flex">
      <Checkbox bind:checked={friday} />
      <Label>Friday</Label>
    </div>
    <div class="flex">
      <Checkbox bind:checked={saturday} />
      <Label>Saturday</Label>
    </div>
    <Button on:click={scheduleSeason}>Schedule Season</Button>
  {/if}
</div>

<style>
  .container {
    width: 200px;
  }
</style>
