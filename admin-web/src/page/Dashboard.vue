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
  id: station._id || station.id,
  name: station.name,
  line: station.lines.join(', ') || props.text.noLine,
  waiting: stationWaiting(station),
  level: stationDensityLevel(station),
})));

const totalWaiting = computed(() => stationSummaries.value.reduce((sum, item) => sum + item.waiting, 0));
const crowdStations = computed(() => [...stationSummaries.value]
  .sort((a, b) => b.waiting - a.waiting));
const highCrowdCount = computed(() => crowdStations.value.filter((item) => item.level === 'HIGH').length);
const mediumCrowdCount = computed(() => crowdStations.value.filter((item) => item.level === 'MEDIUM').length);
const lowCrowdCount = computed(() => crowdStations.value.filter((item) => item.level === 'LOW').length);
const totalStationsCount = computed(() => props.stations.length);
const highCrowdPercent = computed(() => {
  if (!totalStationsCount.value) return 0;
  return Math.round((highCrowdCount.value / totalStationsCount.value) * 100);
});
const mediumCrowdPercent = computed(() => {
  if (!totalStationsCount.value) return 0;
  return Math.round((mediumCrowdCount.value / totalStationsCount.value) * 100);
});
const lowCrowdPercent = computed(() => Math.max(0, 100 - highCrowdPercent.value - mediumCrowdPercent.value));
const alertStations = computed(() => crowdStations.value
  .filter((item) => item.level === 'HIGH' || item.level === 'MEDIUM')
  .slice(0, 5));

function densityLabel(level: string) {
  if (level === 'HIGH') return props.text.high;
  if (level === 'MEDIUM') return props.text.medium;
  return props.text.low;
}
</script>

<template>
  <section class="dashboard-page">
    <header class="dashboard-page-header">
      <div>
        <p class="eyebrow">{{ text.adminDashboard }}</p>
        <h1>Dashboard</h1>
      </div>
    </header>

    <section class="dashboard-metric-grid">
      <article class="dashboard-metric-card metric-rose">
        <div>
          <span>{{ text.waitingNow }}</span>
          <strong>{{ totalWaiting }}</strong>
          <small>{{ text.passengersAcrossStations }}</small>
        </div>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M4 19V5" />
          <path d="M4 19h16" />
          <path d="m7 15 4-4 3 3 5-7" />
        </svg>
      </article>

      <article class="dashboard-metric-card metric-blue">
        <div>
          <span>{{ text.onlineBuses }}</span>
          <strong>{{ onlineBuses }}</strong>
          <small>{{ fillTemplate(text.fromTotalBuses, { count: buses.length }) }}</small>
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

      <article class="dashboard-metric-card metric-teal">
        <div>
          <span>{{ text.pendingReports }}</span>
          <strong>{{ pendingReports }}</strong>
          <small>{{ text.unresolvedItems }}</small>
        </div>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M9 12h6" />
          <path d="M9 16h6" />
          <path d="M9 8h2" />
          <path d="M9 3h6l1 2h3v16H5V5h3l1-2Z" />
        </svg>
      </article>
    </section>

    <section class="dashboard-chart-grid crowd-dashboard-grid">
      <article class="dashboard-chart-panel crowd-pie-panel">
        <div class="dashboard-panel-heading">
          <div>
            <h2>{{ text.crowdStatus }}</h2>
            <span>Realtime station density</span>
          </div>
          <div class="crowd-status-summary">
            <span class="summary-high">{{ highCrowdCount }} {{ text.high }}</span>
            <span class="summary-medium">{{ mediumCrowdCount }} {{ text.medium }}</span>
            <span class="summary-low">{{ lowCrowdCount }} {{ text.low }}</span>
          </div>
        </div>

        <div class="crowd-pie-layout">
          <div
            class="crowd-donut"
            :class="{ empty: totalStationsCount === 0 }"
            :style="{
              '--high': `${highCrowdPercent}%`,
              '--medium': `${mediumCrowdPercent}%`,
            }"
            aria-hidden="true"
          >
            <span>{{ totalStationsCount }}</span>
            <small>{{ text.stationsUnit }}</small>
          </div>

          <div class="crowd-pie-legend">
            <p>
              <span class="overview-dot dot-rose"></span>
              {{ text.high }}
              <strong>{{ highCrowdCount }}</strong>
            </p>
            <p>
              <span class="overview-dot dot-gold"></span>
              {{ text.medium }}
              <strong>{{ mediumCrowdCount }}</strong>
            </p>
            <p>
              <span class="overview-dot dot-green"></span>
              {{ text.low }}
              <strong>{{ lowCrowdCount }}</strong>
            </p>
          </div>
        </div>
      </article>

      <article class="dashboard-chart-panel crowd-alert-panel">
        <div class="dashboard-panel-heading">
          <div>
            <h2>{{ text.crowdAlerts }}</h2>
            <span>
              {{
                alertStations.length
                  ? fillTemplate(text.stationsNeedAttention, { count: alertStations.length })
                  : text.noNotifications
              }}
            </span>
          </div>
        </div>

        <div v-if="alertStations.length" class="dashboard-alert-list">
          <div
            v-for="item in alertStations"
            :key="item.id"
            class="dashboard-alert-item"
            :class="`level-${item.level.toLowerCase()}`"
          >
            <span class="dashboard-alert-dot" aria-hidden="true"></span>
            <div>
              <strong>{{ item.name }}</strong>
              <p>
                {{
                  fillTemplate(text.passengersWaitingAt, {
                    level: densityLabel(item.level),
                    count: item.waiting,
                    line: item.line,
                  })
                }}
              </p>
            </div>
          </div>
        </div>

        <div v-else class="dashboard-alert-empty">
          <strong>{{ text.noNotifications }}</strong>
          <span>{{ text.lowAdvice }}</span>
        </div>
      </article>
    </section>
  </section>
</template>
