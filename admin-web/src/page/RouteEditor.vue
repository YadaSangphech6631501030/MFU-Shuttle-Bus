<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue';

type LatLng = { lat: number; lng: number };
type RouteLine = 'line1' | 'line2';

defineProps<{
  routeDraft: LatLng[];
  routeEditorLine: RouteLine;
  routeEditorLineLabel: string;
  routeEditorMessage: string;
  routeGeoJsonText: string;
  routeMapError: string;
  routeMapLoading: boolean;
  routePointCount: number;
  text: Record<string, any>;
}>();

const emit = defineEmits<{
  clearRouteDraft: [];
  clearTemporaryRouteDraft: [];
  copyRouteGeoJson: [];
  downloadRouteGeoJson: [];
  importRouteFile: [event: Event];
  loadRouteFromGeoJsonText: [];
  loadRouteFromStations: [];
  routeMapReady: [element: HTMLElement | null];
  saveRouteDraftTemporary: [];
  setRouteEditorLine: [line: RouteLine];
  undoRoutePoint: [];
  updateRouteGeoJsonText: [value: string];
}>();

const routeMapEl = ref<HTMLElement | null>(null);

function updateRouteGeoJsonText(event: Event) {
  emit('updateRouteGeoJsonText', (event.target as HTMLTextAreaElement).value);
}

onMounted(() => {
  emit('routeMapReady', routeMapEl.value);
});

onUnmounted(() => {
  emit('routeMapReady', null);
});
</script>

<template>
  <section class="route-editor-layout">
    <article class="panel route-map-panel">
      <div class="panel-heading">
        <div>
          <h2>{{ routeEditorLineLabel }} temporary polyline</h2>
          <span>Click map to add points. Drag line vertices to adjust. Right-click a vertex to remove it.</span>
        </div>
        <span>{{ routePointCount }} points</span>
      </div>
      <div class="route-line-switcher" aria-label="Route line selector">
        <button
          type="button"
          :class="{ active: routeEditorLine === 'line1' }"
          @click="$emit('setRouteEditorLine', 'line1')"
        >
          Line 1
        </button>
        <button
          type="button"
          :class="{ active: routeEditorLine === 'line2' }"
          @click="$emit('setRouteEditorLine', 'line2')"
        >
          Line 2
        </button>
      </div>
      <div class="route-map-shell">
        <div ref="routeMapEl" class="route-map"></div>
        <div v-if="routeMapLoading" class="map-overlay">{{ text.mapLoading }}</div>
      </div>
      <p v-if="routeMapError" class="map-error">{{ routeMapError }}</p>
      <p v-if="routeEditorMessage" class="route-editor-message">{{ routeEditorMessage }}</p>
    </article>

    <article class="panel route-tools-panel">
      <div class="panel-heading">
        <h2>Tools</h2>
        <span>Temporary</span>
      </div>

      <div class="route-tool-group">
        <button class="secondary-btn compact-btn" type="button" @click="$emit('loadRouteFromStations')">
          Start from {{ routeEditorLineLabel }} stations
        </button>
        <label class="file-btn">
          Import GeoJSON
          <input accept=".geojson,.json,application/geo+json,application/json" type="file" @change="$emit('importRouteFile', $event)" />
        </label>
        <button class="secondary-btn compact-btn" type="button" @click="$emit('undoRoutePoint')">
          Undo last point
        </button>
        <button class="secondary-btn compact-btn" type="button" @click="$emit('clearRouteDraft')">
          Clear map
        </button>
      </div>

      <div class="route-tool-group">
        <button class="primary-btn compact-btn" type="button" @click="$emit('saveRouteDraftTemporary')">
          Save temporary
        </button>
        <button class="secondary-btn compact-btn" type="button" @click="$emit('clearTemporaryRouteDraft')">
          Clear saved draft
        </button>
      </div>

      <label>
        GeoJSON
        <textarea
          :value="routeGeoJsonText"
          class="route-geojson-textarea"
          spellcheck="false"
          @input="updateRouteGeoJsonText"
        ></textarea>
      </label>

      <div class="route-tool-group">
        <button class="secondary-btn compact-btn" type="button" @click="$emit('loadRouteFromGeoJsonText')">
          Load text
        </button>
        <button class="secondary-btn compact-btn" type="button" @click="$emit('copyRouteGeoJson')">
          Copy GeoJSON
        </button>
        <button class="secondary-btn compact-btn" type="button" @click="$emit('downloadRouteGeoJson')">
          Download
        </button>
      </div>
    </article>
  </section>
</template>
