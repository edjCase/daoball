<script lang="ts">
  import { Navbar, NavBrand } from "flowbite-svelte";
  import { Link } from "svelte-routing";
  import UserMenu from "../user/UserMenu.svelte";
  import TeamNavSummary from "../team/TeamNavSummary.svelte";
</script>

<Navbar rounded color="form" class="mb-2">
  <NavBrand>
    <Link to="/">
      <img src="/images/logo.png" class="h-16" alt="DAOball Logo" />
    </Link>
  </NavBrand>

  <UserMenu />
  <TeamNavSummary />
</Navbar>
