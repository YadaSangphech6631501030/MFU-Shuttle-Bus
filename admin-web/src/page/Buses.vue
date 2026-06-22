<script setup lang="ts">
import type { Bus } from '../types';

defineProps<{
  buses: Bus[];
  text: Record<string, any>;
}>();
</script>

<template>
  <section class="panel">
    <div class="panel-heading">
      <h2>{{ text.allBuses }}</h2>
      <span>{{ buses.length }} buses</span>
    </div>
    <div class="card-list">
      <article v-for="bus in buses" :key="bus._id || bus.busId" class="list-card">
        <div>
          <strong>{{ bus.busId || bus.licensePlate || text.unknownBus }}</strong>
          <p>{{ bus.driverName || text.noDriver }} &middot; {{ bus.line || text.noLine }}</p>
        </div>
        <span class="chip">{{ bus.status || 'unknown' }}</span>
      </article>
    </div>
  </section>
</template>
