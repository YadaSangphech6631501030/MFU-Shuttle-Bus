<script setup lang="ts">
import { computed } from 'vue';
import type { Bus, Report, Station, User } from '../types';

const props = defineProps<{
  buses: Bus[];
  onlineBuses: number;
  pendingReports: number;
  reports: Report[];
  stations: Station[];
  text: Record<string, any>;
  users: User[];
}>();

function fillTemplate(template: string, values: Record<string, string | number>) {
  return template.replace(/\{(\w+)\}/g, (_, key) => String(values[key] ?? ''));
}

function stationWaiting(station: Station) {
  const waiting = Number(station.waiting ?? 0);
  return Number.isFinite(waiting) ? waiting : 0;
}

function stationDensityLevel(station: Station) {
  const waiting = stationWaiting(station);
  const status = String(station.status ?? 'LOW').toUpperCase();

  if (status === 'HIGH' || waiting >= 20) return 'HIGH';
  if (status === 'MEDIUM' || waiting >= 10) return 'MEDIUM';
  return 'LOW';
}

const stationSummaries = computed(() => props.stations.map((station) => ({
  waiting: stationWaiting(station),
  level: stationDensityLevel(station),
})));

const totalWaiting = computed(() => stationSummaries.value.reduce((sum, item) => sum + item.waiting, 0));
const highCrowdStations = computed(() => stationSummaries.value.filter((item) => item.level === 'HIGH').length);
const busyStations = computed(() => stationSummaries.value.filter((item) => item.level === 'MEDIUM').length);
</script>

<template>
  <section class="grid dashboard-grid">
    <article class="stat-card split-stat-card">
      <span>Crowd status</span>
      <div class="split-stat">
        <div>
          <strong>{{ highCrowdStations }}</strong>
          <small>High</small>
        </div>
        <div>
          <strong>{{ busyStations }}</strong>
          <small>Medium</small>
        </div>
      </div>
    </article>
    <article class="stat-card">
      <span>Waiting now</span>
      <strong>{{ totalWaiting }}</strong>
      <small>passengers across all stations</small>
    </article>
    <article class="stat-card">
      <span>{{ text.onlineBuses }}</span>
      <strong>{{ onlineBuses }}</strong>
      <small>{{ fillTemplate(text.fromTotalBuses, { count: buses.length }) }}</small>
    </article>
    <article class="stat-card">
      <span>{{ text.pendingReports }}</span>
      <strong>{{ pendingReports }}</strong>
      <small>{{ text.unresolvedItems }}</small>
    </article>
    <article class="stat-card">
      <span>{{ text.totalStations }}</span>
      <strong>{{ stations.length }}</strong>
      <small>{{ text.activeStops }}</small>
    </article>
    <article class="stat-card">
      <span>{{ text.usersCount }}</span>
      <strong>{{ users.length }}</strong>
      <small>{{ text.systemAccounts }}</small>
    </article>
  </section>
</template>
