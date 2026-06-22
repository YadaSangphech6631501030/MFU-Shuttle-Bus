<script setup lang="ts">
import type { Bus, Report, Station, User } from '../types';

defineProps<{
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
</script>

<template>
  <section class="grid dashboard-grid">
    <article class="stat-card">
      <span>{{ text.totalStations }}</span>
      <strong>{{ stations.length }}</strong>
      <small>{{ text.activeStops }}</small>
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
      <span>{{ text.usersCount }}</span>
      <strong>{{ users.length }}</strong>
      <small>{{ text.systemAccounts }}</small>
    </article>
  </section>
</template>
