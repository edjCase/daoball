<script lang="ts">
  type Location = { x: number; y: number };

  export let location: Location;
</script>

<circle cx={location.x} cy={location.y} r="2" fill="white" />
