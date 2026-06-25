<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue';
import type { Bus, CrowdThresholds, Station } from '../types';

type DensityLevel = 'LOW' | 'MEDIUM' | 'HIGH';

const props = defineProps<{
  buses: Bus[];
  crowdMapError: string;
  crowdMapLoading: boolean;
  crowdThresholds: CrowdThresholds;
  loading: boolean;
  selectedStationId: string | null;
  stations: Station[];
  text: Record<string, any>;
}>();

const emit = defineEmits<{
  crowdMapReady: [element: HTMLElement | null];
  focusStation: [station: Station];
  refresh: [];
}>();

const crowdMapEl = ref<HTMLElement | null>(null);

function stationWaiting(station: Station) {
  const waiting = Number(station.waiting ?? 0);
  return Number.isFinite(waiting) ? waiting : 0;
}

function densityLevel(station: Station): DensityLevel {
  const waiting = stationWaiting(station);

  if (waiting >= props.crowdThresholds.high) return 'HIGH';
  if (waiting >= props.crowdThresholds.medium) return 'MEDIUM';
  return 'LOW';
}

function densityLabel(level: DensityLevel) {
  if (level === 'HIGH') return props.text.high;
  if (level === 'MEDIUM') return props.text.medium;
  return props.text.low;
}

function densityAdvice(level: DensityLevel) {
  if (level === 'HIGH') return props.text.highAdvice;
  if (level === 'MEDIUM') return props.text.mediumAdvice;
  return props.text.lowAdvice;
}

function stationLineLabel(station: Station) {
  return station.lines?.length ? station.lines.join(', ') : props.text.noLine;
}

const stationSummaries = computed(() => props.stations
  .map((station) => ({
    station,
    waiting: stationWaiting(station),
    level: densityLevel(station),
  }))
  .sort((a, b) => b.waiting - a.waiting));

const highStations = computed(() => stationSummaries.value.filter((item) => item.level === 'HIGH'));
const mediumStations = computed(() => stationSummaries.value.filter((item) => item.level === 'MEDIUM'));
const totalWaiting = computed(() => stationSummaries.value.reduce((sum, item) => sum + item.waiting, 0));
const onlineBuses = computed(() => props.buses.filter((bus) => bus.status?.toLowerCase() !== 'offline').length);
onMounted(() => {
  emit('crowdMapReady', crowdMapEl.value);
});

onUnmounted(() => {
  emit('crowdMapReady', null);
});
</script>

<template>
  <section class="crowd-monitor dashboard-page">
    <div class="crowd-header dashboard-page-header">
      <div>
        <p class="eyebrow">{{ text.tabs.crowd }}</p>
        <h1>{{ text.tabs.crowd }}</h1>
      </div>
      <button class="secondary-btn compact-btn refresh-data-btn" type="button" :disabled="loading" @click="$emit('refresh')">
        <svg class="refresh-btn-icon" :class="{ spinning: loading }" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M21 12a9 9 0 0 1-15.5 6.2" />
          <path d="M3 12A9 9 0 0 1 18.5 5.8" />
          <path d="M18 2v4h4" />
          <path d="M6 22v-4H2" />
        </svg>
        {{ loading ? text.loading : text.refresh }}
      </button>
    </div>

    <section class="dashboard-metric-grid crowd-stat-grid">
      <article class="dashboard-metric-card">
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
      <article class="dashboard-metric-card crowd-status-card">
        <div>
          <span>{{ text.crowdStatus }}</span>
          <strong>{{ highStations.length + mediumStations.length }}</strong>
          <div class="metric-status-pills">
            <small class="summary-high">{{ highStations.length }} {{ text.high }}</small>
            <small class="summary-medium">{{ mediumStations.length }} {{ text.medium }}</small>
          </div>
        </div>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M12 22s7-5.02 7-12a7 7 0 1 0-14 0c0 6.98 7 12 7 12" />
          <circle cx="12" cy="10" r="2.5" />
        </svg>
      </article>
      <article class="dashboard-metric-card">
        <div>
          <span>{{ text.onlineBuses }}</span>
          <strong>{{ onlineBuses }}</strong>
          <small>{{ buses.length }} {{ text.busesUnit }}</small>
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
    </section>

    <section class="crowd-layout">
      <article class="dashboard-chart-panel crowd-map-panel">
        <div class="dashboard-panel-heading">
          <div>
            <h2>{{ text.liveStationMap }}</h2>
            <span>{{ text.markerColorHint }}</span>
          </div>
        </div>
        <div class="crowd-map-shell">
          <div ref="crowdMapEl" class="crowd-map"></div>
          <div v-if="crowdMapLoading" class="map-overlay">{{ text.mapLoading }}</div>
        </div>
        <p v-if="crowdMapError" class="map-error">{{ crowdMapError }}</p>
      </article>

      <aside class="crowd-side">
        <article class="dashboard-chart-panel station-load-panel">
          <div class="dashboard-panel-heading">
            <div>
              <h2>{{ text.crowdAlerts }}</h2>
              <span>{{ text.dispatchGuide }}</span>
            </div>
          </div>
          <div class="station-load-list">
            <div
              v-for="item in stationSummaries"
              :key="item.station._id || item.station.id"
              class="station-load-item"
              :class="[
                `level-${item.level.toLowerCase()}`,
                { active: selectedStationId === item.station.id },
              ]"
            >
              <button class="station-load-main" type="button" @click="$emit('focusStation', item.station)">
                <span class="load-dot" aria-hidden="true"></span>
                <span class="station-load-name">
                  <strong>{{ item.station.name }}</strong>
                  <small>{{ stationLineLabel(item.station) }}</small>
                </span>
                <span class="station-load-count">
                  <strong>{{ item.waiting }}</strong>
                  <small>{{ densityLabel(item.level) }}</small>
                </span>
              </button>
            </div>
          </div>
        </article>

        <article class="dashboard-chart-panel crowd-guide-panel">
          <h2>{{ text.dispatchGuide }}</h2>
          <div class="crowd-guide-list">
            <p><span class="guide-dot high"></span><strong>{{ text.high }}</strong> {{ densityAdvice('HIGH') }}</p>
            <p><span class="guide-dot medium"></span><strong>{{ text.medium }}</strong> {{ densityAdvice('MEDIUM') }}</p>
            <p><span class="guide-dot low"></span><strong>{{ text.low }}</strong> {{ densityAdvice('LOW') }}</p>
          </div>
        </article>
      </aside>
    </section>
  </section>
</template>
