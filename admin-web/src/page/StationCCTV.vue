<script setup lang="ts">
import type { DetectorStatus, Station } from '../types';

type CameraPreviewKind = 'none' | 'rtsp' | 'image' | 'video' | 'link';

defineProps<{
  detectorBusy: boolean;
  detectorStatus: DetectorStatus | null;
  detectorStreamUrl: string;
  hasCamera: (station?: Station | null) => boolean;
  isEditingRoi: boolean;
  roiDraft: Array<[number, number]>;
  selectedCameraPreviewKind: CameraPreviewKind;
  selectedCameraStation: Station | null;
  selectedCameraUrl: string;
  stations: Station[];
}>();

defineEmits<{
  cancelRoiEditor: [];
  clearRoiDraft: [];
  copyCameraUrl: [];
  dragRoiPoint: [event: PointerEvent];
  handleRoiCanvasPointerDown: [event: PointerEvent];
  saveSelectedRoi: [];
  selectCameraStation: [station: Station];
  setRoiPreset: [preset: 'full' | 'right' | 'left' | 'bottom' | 'center'];
  startDragRoiPoint: [index: number, event: PointerEvent];
  startRoiEditor: [];
  startSelectedDetector: [];
  stopDragRoiPoint: [];
  stopSelectedDetector: [];
}>();
</script>

<template>
  <section class="cctv-layout">
    <article class="panel cctv-list-panel">
      <div class="panel-heading">
        <h2>Station CCTV</h2>
        <span>{{ stations.filter(hasCamera).length }} cameras</span>
      </div>
      <div class="cctv-station-list">
        <button
          v-for="station in stations"
          :key="station._id || station.id"
          class="cctv-station-item"
          :class="{ active: selectedCameraStation?.id === station.id }"
          type="button"
          @click="$emit('selectCameraStation', station)"
        >
          <span>
            <strong>{{ station.name }}</strong>
            <small>{{ station.id }} &middot; {{ station.lines.join(', ') }}</small>
          </span>
          <span class="chip" :class="{ 'chip-muted': !hasCamera(station) }">
            {{ hasCamera(station) ? 'Ready' : 'No camera' }}
          </span>
        </button>
      </div>
    </article>

    <article class="panel cctv-view-panel">
      <section class="camera-panel camera-panel-standalone">
        <div class="camera-panel-header">
          <div>
            <h3>Station camera</h3>
            <p v-if="selectedCameraStation">{{ selectedCameraStation.name }} &middot; {{ selectedCameraStation.id }}</p>
          </div>
          <span class="chip" :class="{ 'chip-muted': !hasCamera(selectedCameraStation) }">
            {{ hasCamera(selectedCameraStation) ? 'Configured' : 'No camera' }}
          </span>
        </div>

        <div
          class="camera-preview-shell cctv-preview"
          :class="{ 'roi-editing': isEditingRoi }"
          @pointerdown="$emit('handleRoiCanvasPointerDown', $event)"
          @pointermove="$emit('dragRoiPoint', $event)"
          @pointerup="$emit('stopDragRoiPoint')"
          @pointerleave="$emit('stopDragRoiPoint')"
        >
          <img
            v-if="detectorStreamUrl"
            class="camera-preview-media"
            :src="detectorStreamUrl"
            :alt="selectedCameraStation?.name || 'YOLO detector frame'"
          />
          <img
            v-else-if="selectedCameraPreviewKind === 'image' && selectedCameraUrl"
            class="camera-preview-media"
            :src="selectedCameraUrl"
            :alt="selectedCameraStation?.name || 'Station camera'"
          />
          <video
            v-else-if="selectedCameraPreviewKind === 'video' && selectedCameraUrl"
            class="camera-preview-media"
            :src="selectedCameraUrl"
            controls
            muted
            playsinline
          ></video>
          <div v-else class="camera-preview-empty">
            <strong v-if="selectedCameraPreviewKind === 'rtsp'">
              {{ detectorStatus?.running ? 'YOLO is starting' : 'RTSP camera saved' }}
            </strong>
            <strong v-else-if="selectedCameraPreviewKind === 'none'">No camera source</strong>
            <strong v-else>Preview unavailable</strong>
            <p v-if="selectedCameraPreviewKind === 'rtsp'">
              {{ detectorStatus?.running ? 'Waiting for the first detected frame...' : 'Press Start YOLO to read RTSP on the backend and show detected frames here.' }}
            </p>
            <p v-else-if="selectedCameraPreviewKind === 'none'">
              Edit this station and save a Camera URL first.
            </p>
            <p v-else>
              This link is saved, but it is not a browser-playable stream.
            </p>
          </div>
          <svg
            v-if="roiDraft.length"
            class="roi-overlay"
            viewBox="0 0 1 1"
            preserveAspectRatio="none"
            aria-hidden="true"
          >
            <polygon class="roi-polygon" :points="roiDraft.map((point) => point.join(',')).join(' ')" />
            <circle
              v-for="(point, index) in roiDraft"
              :key="index"
              class="roi-handle"
              :cx="point[0]"
              :cy="point[1]"
              r="0.018"
              @pointerdown="$emit('startDragRoiPoint', index, $event)"
            />
          </svg>
        </div>

        <label v-if="selectedCameraStation">
          Camera source
          <input :value="selectedCameraUrl" readonly />
        </label>

        <div class="roi-toolbar">
          <button v-if="!isEditingRoi" class="secondary-btn compact-btn" type="button" @click="$emit('startRoiEditor')">
            Draw Detection Area
          </button>
          <template v-else>
            <button class="primary-btn compact-btn" type="button" @click="$emit('saveSelectedRoi')">Save Area</button>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('cancelRoiEditor')">Cancel</button>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('clearRoiDraft')">Clear</button>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('setRoiPreset', 'full')">Full</button>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('setRoiPreset', 'right')">Right half</button>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('setRoiPreset', 'left')">Left half</button>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('setRoiPreset', 'bottom')">Bottom</button>
            <button class="secondary-btn compact-btn" type="button" @click="$emit('setRoiPreset', 'center')">Center</button>
          </template>
        </div>

        <div v-if="selectedCameraUrl" class="camera-actions">
          <button
            v-if="!detectorStatus?.running"
            class="primary-btn compact-btn"
            type="button"
            :disabled="detectorBusy"
            @click="$emit('startSelectedDetector')"
          >
            {{ detectorBusy ? 'Starting...' : 'Start YOLO' }}
          </button>
          <button
            v-else
            class="secondary-btn compact-btn"
            type="button"
            :disabled="detectorBusy"
            @click="$emit('stopSelectedDetector')"
          >
            {{ detectorBusy ? 'Stopping...' : 'Stop YOLO' }}
          </button>
          <button class="secondary-btn compact-btn" type="button" @click="$emit('copyCameraUrl')">
            Copy URL
          </button>
          <a
            v-if="selectedCameraPreviewKind !== 'rtsp'"
            class="secondary-btn compact-btn camera-link"
            :href="selectedCameraUrl"
            target="_blank"
            rel="noreferrer"
          >
            Open
          </a>
        </div>

        <div v-if="detectorStatus" class="detector-status">
          <span :class="{ live: detectorStatus.running }"></span>
          {{ detectorStatus.running ? 'Detector running' : 'Detector stopped' }}
          <small v-if="detectorStatus.lastError">{{ detectorStatus.lastError }}</small>
          <small v-else-if="detectorStatus.lastLog">{{ detectorStatus.lastLog }}</small>
        </div>
      </section>
    </article>
  </section>
</template>
