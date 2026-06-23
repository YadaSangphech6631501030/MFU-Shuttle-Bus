<script setup lang="ts">
import { computed } from 'vue';
import type { Bus } from '../types';

const props = defineProps<{
  buses: Bus[];
  text: Record<string, any>;
}>();

function busName(bus: Bus) {
  return bus.busId || bus.busNumber || bus.licensePlate || props.text.unknownBus;
}

function busLine(bus: Bus) {
  return bus.line ? `${props.text.line} ${bus.line}` : props.text.noLine;
}

function busStatus(bus: Bus) {
  if (isOffline(bus)) return 'OFFLINE';
  return String(bus.status || 'unknown').toUpperCase();
}

function isOffline(bus: Bus) {
  const status = String(bus.status || '').toLowerCase();
  return status === 'offline' || status === 'stopped';
}

function connectionLabel(bus: Bus) {
  return isOffline(bus) ? props.text.offline : props.text.online;
}

const onlineBuses = computed(() => props.buses.filter((bus) => !isOffline(bus)).length);
const offlineBuses = computed(() => props.buses.length - onlineBuses.value);
</script>

<template>
  <section class="bus-page">
    <article class="panel">
      <div class="bus-header">
        <div>
          <h2>{{ text.allBuses }}</h2>
          <p>{{ text.busesDescription }}</p>
        </div>
        <span>{{ buses.length }} {{ text.busesUnit }}</span>
      </div>

      <section class="grid bus-stat-grid">
        <article class="bus-mini-stat online">
          <span>{{ text.online }}</span>
          <strong>{{ onlineBuses }}</strong>
        </article>
        <article class="bus-mini-stat offline">
          <span>{{ text.offline }}</span>
          <strong>{{ offlineBuses }}</strong>
        </article>
        <article class="bus-mini-stat total">
          <span>{{ text.total }}</span>
          <strong>{{ buses.length }}</strong>
        </article>
      </section>

      <div class="bus-list simple">
        <article
          v-for="bus in buses"
          :key="bus._id || bus.busId || bus.busNumber"
          class="bus-card simple"
          :class="{ offline: isOffline(bus) }"
        >
          <div class="bus-card-main">
            <span class="bus-icon" :class="{ muted: isOffline(bus) }">
              {{ busName(bus).slice(0, 2).toUpperCase() }}
            </span>
            <div class="bus-card-title">
              <strong>{{ text.busPrefix }} {{ busName(bus) }}</strong>
              <small>{{ busLine(bus) }} &middot; {{ bus.driverName || text.noDriver }}</small>
            </div>
          </div>

          <span class="bus-status-pill" :class="{ offline: isOffline(bus), online: !isOffline(bus) }">
            {{ connectionLabel(bus) }}
          </span>
        </article>
      </div>
    </article>
  </section>
</template>
