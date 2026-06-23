<script setup lang="ts">
import { computed } from 'vue';
import type { Bus, CrowdThresholds, Report, Station, User } from '../types';

const props = defineProps<{
  buses: Bus[];
  crowdThresholds: CrowdThresholds;
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

  if (waiting >= props.crowdThresholds.high) return 'HIGH';
  if (waiting >= props.crowdThresholds.medium) return 'MEDIUM';
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
      <span>{{ text.crowdStatus }}</span>
      <div class="split-stat">
        <div>
          <strong>{{ highCrowdStations }}</strong>
          <small>{{ text.high }}</small>
        </div>
        <div>
          <strong>{{ busyStations }}</strong>
          <small>{{ text.medium }}</small>
        </div>
      </div>
    </article>
    <article class="stat-card">
      <span>{{ text.waitingNow }}</span>
      <strong>{{ totalWaiting }}</strong>
      <small>{{ text.passengersAcrossStations }}</small>
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
