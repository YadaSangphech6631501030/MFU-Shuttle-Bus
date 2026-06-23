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
  openCameraStation: [station: Station];
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

function hasCamera(station: Station) {
  return Boolean(String(station.cameraUrl ?? '').trim());
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
  <section class="crowd-monitor">
    <div class="crowd-header">
      <div>
        <p class="eyebrow">{{ text.tabs.crowd }}</p>
        <h1>{{ text.tabs.crowd }}</h1>
      </div>
      <button class="secondary-btn compact-btn" type="button" :disabled="loading" @click="$emit('refresh')">
        {{ loading ? text.loading : text.refresh }}
      </button>
    </div>

    <section class="grid crowd-stat-grid">
      <article class="stat-card">
        <span>{{ text.waitingNow }}</span>
        <strong>{{ totalWaiting }}</strong>
        <small>{{ text.passengersAcrossStations }}</small>
      </article>
      <article class="stat-card split-stat-card crowd-status-card">
        <span>{{ text.crowdStatus }}</span>
        <div class="split-stat">
          <div>
            <strong>{{ highStations.length }}</strong>
            <small>{{ text.high }}</small>
          </div>
          <div>
            <strong>{{ mediumStations.length }}</strong>
            <small>{{ text.medium }}</small>
          </div>
        </div>
      </article>
      <article class="stat-card">
        <span>{{ text.onlineBuses }}</span>
        <strong>{{ onlineBuses }}</strong>
        <small>{{ buses.length }} {{ text.busesUnit }}</small>
      </article>
    </section>

    <section class="crowd-layout">
      <article class="panel crowd-map-panel">
        <div class="panel-heading">
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
        <article class="panel station-load-panel">
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
              <button
                v-if="hasCamera(item.station)"
                class="link-btn compact-inline"
                type="button"
                @click="$emit('openCameraStation', item.station)"
              >
                CCTV
              </button>
            </div>
          </div>
        </article>

        <article class="panel crowd-guide-panel">
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
