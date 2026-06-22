<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue';
import type { Station } from '../types';

defineProps<{
  editingStationKey: string | null;
  hasCamera: (station?: Station | null) => boolean;
  loading: boolean;
  stationForm: Station;
  stationMapError: string;
  stationMapLoading: boolean;
  stationRoiText: string;
  stations: Station[];
  text: Record<string, any>;
}>();

const emit = defineEmits<{
  deleteStation: [station: Station];
  editStation: [station: Station];
  openCameraStation: [station: Station];
  resetStationForm: [];
  saveStation: [];
  stationMapReady: [element: HTMLElement | null];
  updateStationRoiText: [value: string];
  useCurrentLocation: [];
}>();

const stationMapEl = ref<HTMLElement | null>(null);

function updateStationRoiText(event: Event) {
  emit('updateStationRoiText', (event.target as HTMLTextAreaElement).value);
}

onMounted(() => {
  emit('stationMapReady', stationMapEl.value);
});

onUnmounted(() => {
  emit('stationMapReady', null);
});
</script>

<template>
  <section class="two-column">
    <article class="panel">
      <div class="panel-heading">
        <h2>{{ text.stationList }}</h2>
        <span>{{ stations.length }} stations</span>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>{{ text.stationName }}</th>
              <th>{{ text.line }}</th>
              <th>{{ text.coordinates }}</th>
              <th>{{ text.status }}</th>
              <th>Camera</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="station in stations" :key="station._id || station.id">
              <td>{{ station.id }}</td>
              <td>{{ station.name }}</td>
              <td>{{ station.lines.join(', ') }}</td>
              <td>{{ station.lat }}, {{ station.lng }}</td>
              <td><span class="chip">{{ station.status || 'LOW' }}</span></td>
              <td>
                <span class="chip" :class="{ 'chip-muted': !hasCamera(station) }">
                  {{ hasCamera(station) ? 'Configured' : 'Empty' }}
                </span>
              </td>
              <td class="actions">
                <button class="link-btn" @click="$emit('openCameraStation', station)">Camera</button>
                <button class="link-btn" @click="$emit('editStation', station)">{{ text.edit }}</button>
                <button class="danger-link" @click="$emit('deleteStation', station)">{{ text.delete }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </article>

    <article class="panel form-panel">
      <div class="panel-heading">
        <h2>{{ editingStationKey ? text.editStation : text.addStation }}</h2>
        <button v-if="editingStationKey" class="link-btn" @click="$emit('resetStationForm')">{{ text.cancel }}</button>
      </div>
      <form class="station-form" @submit.prevent="$emit('saveStation')">
        <label>ID <input v-model="stationForm.id" required :placeholder="text.stationIdPlaceholder" /></label>
        <label>{{ text.stationName }} <input v-model="stationForm.name" required :placeholder="text.stationNamePlaceholder" /></label>
        <div class="split">
          <label>Latitude <input v-model.number="stationForm.lat" required type="number" step="any" /></label>
          <label>Longitude <input v-model.number="stationForm.lng" required type="number" step="any" /></label>
        </div>
        <div class="map-picker">
          <div class="map-picker-header">
            <div>
              <strong>{{ text.mapPicker }}</strong>
              <p>{{ text.mapHint }}</p>
            </div>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('useCurrentLocation')">
              {{ text.useCurrentLocation }}
            </button>
          </div>
          <div ref="stationMapEl" class="station-map"></div>
          <div v-if="stationMapLoading" class="map-overlay">{{ text.mapLoading }}</div>
          <p v-if="stationMapError" class="map-error">{{ stationMapError }}</p>
        </div>
        <div class="checkbox-row">
          <label><input v-model="stationForm.lines" type="checkbox" value="line1" /> Line 1</label>
          <label><input v-model="stationForm.lines" type="checkbox" value="line2" /> Line 2</label>
        </div>
        <label>Camera URL <input v-model="stationForm.cameraUrl" placeholder="rtsp://... or https://..." /></label>
        <label>
          Detection ROI
          <textarea
            :value="stationRoiText"
            placeholder="[[0.1,0.2],[0.9,0.2],[0.9,0.8],[0.1,0.8]]"
            rows="3"
            @input="updateStationRoiText"
          ></textarea>
        </label>
        <button class="primary-btn" type="submit" :disabled="loading">
          {{ editingStationKey ? text.saveChanges : text.addStation }}
        </button>
      </form>
    </article>
  </section>
</template>
