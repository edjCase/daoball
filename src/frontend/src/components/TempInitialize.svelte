<script lang="ts">
  import {
    leagueAgentFactory,
    type CreateDivisionRequest,
  } from "../ic-agent/League";
  import { playerLedgerAgentFactory } from "../ic-agent/PlayerLedger";
  import { divisionStore } from "../stores/DivisionStore";
  import type { Principal } from "@dfinity/principal";
  import { stadiumStore } from "../stores/StadiumStore";
  import { teamStore } from "../stores/TeamStore";
  import { playerStore } from "../stores/PlayerStore";

  let createStadiums = async function () {
    let stadiums = [
      {
        name: "Stadium 1",
      },
      {
        name: "Stadium 2",
      },
    ];
    let promises = [];
    for (let i in stadiums) {
      let stadium = stadiums[i];
      let promise = leagueAgentFactory()
        .createStadium(stadium)
        .then((result) => {
          if ("ok" in result) {
            console.log("Created stadium: ", result.ok);
          } else if ("nameTaken" in result) {
            console.log("Stadium name taken: ", stadium);
          } else {
            console.log("Failed to make stadium: ", stadium);
          }
        });
      promises.push(promise);
    }
    await Promise.all(promises);
    stadiumStore.refetch();
  };

  let createDivisions = async function () {
    let divisions: CreateDivisionRequest[] = [
      {
        name: "Division 1",
      },
      // TODO multiple divisions
      // {
      //   name: "Division 2",
      // },
    ];
    let promises = [];
    for (let i in divisions) {
      let division = divisions[i];
      let promise = leagueAgentFactory()
        .createDivision(division)
        .then((result) => {
          if ("ok" in result) {
            console.log("Created division: ", result.ok);
          } else if ("nameTaken" in result) {
            console.log("Division name taken: ", division);
          } else {
            console.log("Failed to make division: ", division);
          }
        });
      promises.push(promise);
    }
    await Promise.all(promises);
    divisionStore.refetch();
  };

  let createTeams = async function (): Promise<
    {
      id: Principal | null;
      players: any[];
    }[]
  > {
    let teams = [
      {
        id: null,
        name: "Crabz",
        logoUrl:
          "https://imgs.search.brave.com/OFu2Rv3v86otnalo0qA4e59PZtqCmw5IOZIIH5PIH8o/rs:fit:860:0:0/g:ce/aHR0cHM6Ly90NC5m/dGNkbi5uZXQvanBn/LzAxLzc3LzEzLzQ1/LzM2MF9GXzE3NzEz/NDU0OF9kN1ljYlBW/TDVselMxWG5mMTlC/QXEybGFKU2U1QnV2/Zi5qcGc",
        tokenName: "Crabz",
        tokenSymbol: "CRABZ",
        divisionId: 0,
        players: [
          {
            name: "Shelldon Pinch",
            position: { pitcher: null },
          },
          {
            name: "Coraline Claw",
            position: { firstBase: null },
          },
          {
            name: "Sandy Shore",
            position: { secondBase: null },
          },
          {
            name: "Barnacle Bill",
            position: { thirdBase: null },
          },
          {
            name: "Tidepool Tim",
            position: { shortStop: null },
          },
          {
            name: "Wharf Willy",
            position: { leftField: null },
          },
          {
            name: "Ocean Oliver",
            position: { centerField: null },
          },
          {
            name: "Waverly Waters",
            position: { rightField: null },
          },
          {
            name: "Kelpie Krab",
            position: { pitcher: null },
          },
          {
            name: "Anemone Andy",
            position: { firstBase: null },
          },
          {
            name: "Reef Ricky",
            position: { secondBase: null },
          },
          {
            name: "Mussel Mike",
            position: { thirdBase: null },
          },
          {
            name: "Bubbly Bob",
            position: { shortStop: null },
          },
          {
            name: "Tsunami Tami",
            position: { leftField: null },
          },
          {
            name: "Harbor Harry",
            position: { centerField: null },
          },
          {
            name: "Beachcomber Betty",
            position: { rightField: null },
          },
        ],
      },
      {
        id: null,
        name: "Lobsterz",
        logoUrl:
          "https://imgs.search.brave.com/cIAAkBmDWBtXzxwWspYcqbg2M2aiTOKDqGAsuGkhY_I/rs:fit:860:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzAyLzA0LzczLzky/LzM2MF9GXzIwNDcz/OTI5MV9LM25mZEdK/d0FrSjlLQnVLUlZp/NHhtWEtVaU94OXlR/Si5qcGc",
        tokenName: "Lobsterz",
        tokenSymbol: "LOBZ",
        divisionId: 0,
        players: [
          {
            name: "Lobster Larry",
            position: { pitcher: null },
          },
          {
            name: "Coral Courtney",
            position: { firstBase: null },
          },
          {
            name: "Buoyant Benny",
            position: { secondBase: null },
          },
          {
            name: "Reefy Ruth",
            position: { thirdBase: null },
          },
          {
            name: "Shelly Shore",
            position: { shortStop: null },
          },
          {
            name: "Pincer Paul",
            position: { leftField: null },
          },
          {
            name: "Tidal Tina",
            position: { centerField: null },
          },
          {
            name: "Oceanic Olga",
            position: { rightField: null },
          },
          {
            name: "Abyss Andy",
            position: { pitcher: null },
          },
          {
            name: "Marina Mary",
            position: { firstBase: null },
          },
          {
            name: "Current Chris",
            position: { secondBase: null },
          },
          {
            name: "Seaweed Sally",
            position: { thirdBase: null },
          },
          {
            name: "Whirlpool Willie",
            position: { shortStop: null },
          },
          {
            name: "Surfing Sam",
            position: { leftField: null },
          },
          {
            name: "Nautical Nancy",
            position: { centerField: null },
          },
          {
            name: "Divey Dave",
            position: { rightField: null },
          },
        ],
      },
      {
        id: null,
        name: "Jellyz",
        logoUrl:
          "https://imgs.search.brave.com/4ZUlZt5Y_B7DSKkE3GO58ZVXlM2RxGkoOukG7U6Gqqk/rs:fit:860:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/ZnJlZS12ZWN0b3Iv/amVsbHlmaXNoLXNl/YS1hbmltYWwtY2Fy/dG9vbi1zdGlja2Vy/XzEzMDgtNzg1MzAu/anBnP3NpemU9NjI2/JmV4dD1qcGc",
        tokenName: "Jellyz",
        tokenSymbol: "JELZ",
        divisionId: 0,
        players: [
          {
            name: "Jellybean Jill",
            position: { pitcher: null },
          },
          {
            name: "Tentacle Ted",
            position: { firstBase: null },
          },
          {
            name: "Stinger Steve",
            position: { secondBase: null },
          },
          {
            name: "Bubbly Bill",
            position: { thirdBase: null },
          },
          {
            name: "Floaty Frank",
            position: { shortStop: null },
          },
          {
            name: "Mano-War Maria",
            position: { leftField: null },
          },
          {
            name: "Pulsing Polly",
            position: { centerField: null },
          },
          {
            name: "Drifty Dave",
            position: { rightField: null },
          },
          {
            name: "Moonbeam Molly",
            position: { pitcher: null },
          },
          {
            name: "Luminous Lou",
            position: { firstBase: null },
          },
          {
            name: "Hydro Harry",
            position: { secondBase: null },
          },
          {
            name: "Glowy Gwen",
            position: { thirdBase: null },
          },
          {
            name: "Blubber Bob",
            position: { shortStop: null },
          },
          {
            name: "Necton Ned",
            position: { leftField: null },
          },
          {
            name: "Cnidarian Cindy",
            position: { centerField: null },
          },
          {
            name: "Zephyr Zoe",
            position: { rightField: null },
          },
        ],
      },
      {
        id: null,
        name: "Toadz",
        logoUrl:
          "https://imgs.search.brave.com/Rm7Nj0SD_nUMzAjs3we-upMoynWtEwkB2WacPgf9IAQ/rs:fit:860:0:0/g:ce/aHR0cHM6Ly9tZWRp/YS5pc3RvY2twaG90/by5jb20vaWQvMTIw/OTE0MjI2Mi92ZWN0/b3IvZnJvZy1sb2dv/LmpwZz9zPTYxMng2/MTImdz0wJms9MjAm/Yz02YU4tSF83eUNH/bEwzQmZ1YVcwY3hl/cmo4bzNmd25WZkVP/TnZMOHVxVE80PQ",
        tokenName: "Toadz",
        tokenSymbol: "TOADZ",
        divisionId: 0,
        players: [
          {
            name: "Toadstool Todd",
            position: { pitcher: null },
          },
          {
            name: "Hoppy Hank",
            position: { firstBase: null },
          },
          {
            name: "Boggy Bill",
            position: { secondBase: null },
          },
          {
            name: "Pond Paul",
            position: { thirdBase: null },
          },
          {
            name: "Croaky Chris",
            position: { shortStop: null },
          },
          {
            name: "Lily Lily",
            position: { leftField: null },
          },
          {
            name: "Ribbit Rick",
            position: { centerField: null },
          },
          {
            name: "Swampy Sue",
            position: { rightField: null },
          },
          {
            name: "Muddy Mike",
            position: { pitcher: null },
          },
          {
            name: "Warty Wendy",
            position: { firstBase: null },
          },
          {
            name: "Bumpy Bob",
            position: { secondBase: null },
          },
          {
            name: "Puddle Pete",
            position: { thirdBase: null },
          },
          {
            name: "Tadpole Tim",
            position: { shortStop: null },
          },
          {
            name: "Froggy Fran",
            position: { leftField: null },
          },
          {
            name: "Algae Amy",
            position: { centerField: null },
          },
          {
            name: "Marshy Matt",
            position: { rightField: null },
          },
        ],
      },
    ];
    let leagueAgent = leagueAgentFactory();
    let promises = [];
    for (let i in teams) {
      let team = teams[i];
      let promise = leagueAgent.createTeam(team).then((result) => {
        if ("ok" in result) {
          let teamId = result.ok;
          team.id = teamId;
          console.log("Created team: ", teamId);
        } else {
          console.log("Failed to make team: ", team);
        }
      });
      promises.push(promise);
    }
    await Promise.all(promises);
    teamStore.refetch();
    return teams.map((t) => {
      return { id: t.id, players: t.players };
    });
  };

  let createPlayers = async function (
    teamId: Principal | null,
    players: { name: string; position: any }[]
  ) {
    if (teamId === null) {
      return;
    }
    let playerLedgerAgent = playerLedgerAgentFactory();
    let promises = [];
    for (let j in players) {
      let player = players[j];
      let promise = playerLedgerAgent
        .create({
          name: player.name,
          position: player.position,
          teamId: [teamId],
        })
        .then((result) => {
          if ("created" in result) {
            console.log("Created player: ", result.created);
          } else {
            console.log("Failed to make player: ", player, result.invalid);
          }
        });
      promises.push(promise);
    }
    await Promise.all(promises);
  };

  let initialize = async function () {
    await createStadiums();
    await createDivisions();
    let teams = await createTeams();
    for (let i in teams) {
      let team = teams[i];
      await createPlayers(team.id, team.players);
    }
    playerStore.refetch();
  };
</script>

<button on:click={initialize}>Initialize With Default Data</button>