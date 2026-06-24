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
  <section class="bus-page dashboard-page">
    <header class="dashboard-page-header bus-page-header">
      <div>
        <p class="eyebrow">{{ text.tabs.buses }}</p>
        <h1>{{ text.allBuses }}</h1>
      </div>
      <span class="bus-total-chip">{{ buses.length }} {{ text.busesUnit }}</span>
    </header>

    <section class="dashboard-metric-grid bus-stat-grid">
      <article class="dashboard-metric-card">
        <div>
          <span>{{ text.online }}</span>
          <strong>{{ onlineBuses }}</strong>
          <small>{{ text.onlineBuses }}</small>
        </div>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M7 16h.01" />
          <path d="M17 16h.01" />
          <path d="M7 20v-2" />
          <path d="M17 20v-2" />
          <path d="M5 11h14" />
          <path d="M6 18h12a2 2 0 0 0 2-2V8a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v8a2 2 0 0 0 2 2" />
        </svg>
      </article>
      <article class="dashboard-metric-card">
        <div>
          <span>{{ text.offline }}</span>
          <strong>{{ offlineBuses }}</strong>
          <small>{{ text.busesDescription }}</small>
        </div>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M3 3l18 18" />
          <path d="M7 16h.01" />
          <path d="M17 16h.01" />
          <path d="M7 20v-2" />
          <path d="M17 20v-2" />
          <path d="M5 11h6" />
          <path d="M14 11h5" />
          <path d="M6 18h12a2 2 0 0 0 2-2V8a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v8a2 2 0 0 0 2 2" />
        </svg>
      </article>
      <article class="dashboard-metric-card">
        <div>
          <span>{{ text.total }}</span>
          <strong>{{ buses.length }}</strong>
          <small>{{ text.busesUnit }}</small>
        </div>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M9 12h6" />
          <path d="M9 16h6" />
          <path d="M9 8h2" />
          <path d="M9 3h6l1 2h3v16H5V5h3l1-2Z" />
        </svg>
      </article>
    </section>

    <article class="dashboard-chart-panel bus-list-panel">
      <div class="dashboard-panel-heading bus-list-heading">
        <div>
          <h2>{{ text.allBuses }}</h2>
          <span>{{ text.busesDescription }}</span>
        </div>
      </div>
      <div class="bus-list simple">
        <article
          v-for="bus in buses"
          :key="bus._id || bus.busId || bus.busNumber"
          class="bus-card simple"
          :class="{ offline: isOffline(bus) }"
        >
          <div class="bus-card-main">
            <span class="bus-icon" :class="{ muted: isOffline(bus) }">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M7 16h.01" />
                <path d="M17 16h.01" />
                <path d="M7 20v-2" />
                <path d="M17 20v-2" />
                <path d="M5 11h14" />
                <path d="M8 6h8" />
                <path d="M6 18h12a2 2 0 0 0 2-2V8a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v8a2 2 0 0 0 2 2" />
              </svg>
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
