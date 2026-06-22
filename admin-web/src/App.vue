<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue';
import { api } from './services/api';
import BusesPage from './page/Buses.vue';
import DashboardPage from './page/Dashboard.vue';
import ReportsPage from './page/Reports.vue';
import RouteEditorPage from './page/RouteEditor.vue';
import StationCCTVPage from './page/StationCCTV.vue';
import StationsPage from './page/Stations.vue';
import UsersPage from './page/Users.vue';
import type { Bus, DetectorStatus, Report, Station, User } from './types';

type Lang = 'en' | 'th';
type TabKey = 'dashboard' | 'stations' | 'routes' | 'cctv' | 'buses' | 'reports' | 'users';
type LatLng = { lat: number; lng: number };
type CameraPreviewKind = 'none' | 'rtsp' | 'image' | 'video' | 'link';
type RouteLine = 'line1' | 'line2';

type GoogleLatLngValue = {
  lat: () => number;
  lng: () => number;
};

type GoogleMapMouseEvent = {
  latLng?: GoogleLatLngValue;
};

type GoogleMapEventListener = {
  remove: () => void;
};

type GooglePolylineMouseEvent = GoogleMapMouseEvent & {
  vertex?: number;
};

type GoogleMap = {
  addListener: (eventName: string, handler: (event: GoogleMapMouseEvent) => void) => GoogleMapEventListener;
  setCenter: (position: LatLng) => void;
  fitBounds: (bounds: GoogleLatLngBounds) => void;
};

type GoogleMarker = {
  addListener: (eventName: string, handler: () => void) => void;
  getPosition: () => GoogleLatLngValue | undefined;
  setPosition: (position: LatLng) => void;
};

type GoogleMapPath = {
  addListener: (eventName: string, handler: () => void) => GoogleMapEventListener;
  clear: () => void;
  getArray: () => GoogleLatLngValue[];
  getLength: () => number;
  push: (position: LatLng) => number;
  removeAt: (index: number) => GoogleLatLngValue;
};

type GooglePolyline = {
  addListener: (eventName: string, handler: (event: GooglePolylineMouseEvent) => void) => GoogleMapEventListener;
  getPath: () => GoogleMapPath;
  setMap: (map: GoogleMap | null) => void;
  setPath: (path: LatLng[]) => void;
};

type GoogleLatLngBounds = {
  extend: (position: LatLng) => void;
};

type GoogleMapsApi = {
  Map: new (element: HTMLElement, options: Record<string, unknown>) => GoogleMap;
  Marker: new (options: Record<string, unknown>) => GoogleMarker;
  Polyline: new (options: Record<string, unknown>) => GooglePolyline;
  LatLngBounds: new () => GoogleLatLngBounds;
};

declare global {
  interface Window {
    google?: {
      maps: GoogleMapsApi;
    };
    initMfuStationMap?: () => void;
  }
}

const LANGUAGE_KEY = 'mfu_admin_language';
const ROUTE_EDITOR_STORAGE_PREFIX = 'mfu_route_editor_';
const savedLanguage = localStorage.getItem(LANGUAGE_KEY);
const GOOGLE_MAPS_API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '';
const MFU_CENTER: LatLng = { lat: 20.0446, lng: 99.8957 };
let googleMapsPromise: Promise<void> | null = null;

const lang = ref<Lang>(savedLanguage === 'th' ? 'th' : 'en');
const tabs: Array<{ key: TabKey }> = [
  { key: 'dashboard' },
  { key: 'stations' },
  { key: 'routes' },
  { key: 'cctv' },
  { key: 'buses' },
  { key: 'reports' },
  { key: 'users' },
];
const activeTab = ref<TabKey>('dashboard');

const dictionary = {
  en: {
    tabs: {
      dashboard: 'Dashboard',
      stations: 'Stations',
      routes: 'Route Editor',
      cctv: 'Station CCTV',
      buses: 'Buses',
      reports: 'Reports',
      users: 'Users',
    },
    language: 'TH',
    loginSubtitle: '',
    username: 'Username',
    password: 'Password',
    usernamePlaceholder: 'admin username',
    passwordPlaceholder: 'password',
    signIn: 'Sign in',
    signingIn: 'Signing in...',
    logout: 'Log out',
    refresh: 'Refresh data',
    loading: 'Loading...',
    genericError: 'Something went wrong',
    adminOnlyError: 'This account is not an administrator.',
    totalStations: 'Total stations',
    activeStops: 'Active pickup points',
    onlineBuses: 'Online buses',
    fromTotalBuses: 'from {count} buses',
    pendingReports: 'Pending reports',
    unresolvedItems: 'Items not resolved yet',
    usersCount: 'Users',
    systemAccounts: 'System accounts',
    stationList: 'Station list',
    stationName: 'Station name',
    line: 'Line',
    coordinates: 'Coordinates',
    status: 'Status',
    edit: 'Edit',
    delete: 'Delete',
    editStation: 'Edit station',
    addStation: 'Add station',
    cancel: 'Cancel',
    stationIdPlaceholder: 'Example: S01',
    stationNamePlaceholder: 'Pickup point name',
    mapPicker: 'Map location picker',
    mapHint: 'Click the map or drag the marker to update latitude and longitude.',
    mapMissingKey: 'Add VITE_GOOGLE_MAPS_API_KEY in admin-web/.env to enable Google Map picker.',
    mapLoadFailed: 'Google Map could not be loaded.',
    mapLoading: 'Loading map...',
    useCurrentLocation: 'Use current location',
    locateFailed: 'Could not get your current location.',
    saveChanges: 'Save changes',
    allBuses: 'All buses',
    unknownBus: 'Unknown bus',
    noDriver: 'No driver name',
    noLine: 'No line',
    issueReports: 'Issue reports',
    issueReport: 'Issue report',
    anonymous: 'anonymous',
    systemUsers: 'System users',
    changeRole: 'Change role',
    deleteStationConfirm: 'Delete station "{name}"?',
    deleteUserConfirm: 'Delete user "{name}"?',
  },
  th: {
    tabs: {
      dashboard: 'ภาพรวม',
      stations: 'สถานี',
      routes: 'แก้เส้นทาง',
      cctv: 'Station CCTV',
      buses: 'รถทั้งหมด',
      reports: 'รายงาน',
      users: 'ผู้ใช้',
    },
    language: 'EN',
    loginSubtitle: '',
    username: 'ชื่อผู้ใช้',
    password: 'รหัสผ่าน',
    usernamePlaceholder: 'ชื่อผู้ใช้แอดมิน',
    passwordPlaceholder: 'รหัสผ่าน',
    signIn: 'เข้าสู่ระบบ',
    signingIn: 'กำลังเข้าสู่ระบบ...',
    logout: 'ออกจากระบบ',
    refresh: 'รีเฟรชข้อมูล',
    loading: 'กำลังโหลด...',
    genericError: 'เกิดข้อผิดพลาด',
    adminOnlyError: 'บัญชีนี้ไม่ใช่ผู้ดูแลระบบ',
    totalStations: 'สถานีทั้งหมด',
    activeStops: 'จุดจอดที่เปิดให้บริการ',
    onlineBuses: 'รถออนไลน์',
    fromTotalBuses: 'จากทั้งหมด {count} คัน',
    pendingReports: 'รายงานรอดำเนินการ',
    unresolvedItems: 'รายการที่ยังไม่ปิดงาน',
    usersCount: 'ผู้ใช้',
    systemAccounts: 'บัญชีในระบบ',
    stationList: 'รายการสถานี',
    stationName: 'ชื่อสถานี',
    line: 'สาย',
    coordinates: 'พิกัด',
    status: 'สถานะ',
    edit: 'แก้ไข',
    delete: 'ลบ',
    editStation: 'แก้ไขสถานี',
    addStation: 'เพิ่มสถานี',
    cancel: 'ยกเลิก',
    stationIdPlaceholder: 'เช่น S01',
    stationNamePlaceholder: 'ชื่อจุดจอด',
    mapPicker: 'เลือกตำแหน่งจากแผนที่',
    mapHint: 'คลิกบนแผนที่หรือลากหมุดเพื่ออัปเดต latitude และ longitude',
    mapMissingKey: 'เพิ่ม VITE_GOOGLE_MAPS_API_KEY ใน admin-web/.env เพื่อเปิดใช้ Google Map',
    mapLoadFailed: 'โหลด Google Map ไม่สำเร็จ',
    mapLoading: 'กำลังโหลดแผนที่...',
    useCurrentLocation: 'ใช้ตำแหน่งปัจจุบัน',
    locateFailed: 'ไม่สามารถอ่านตำแหน่งปัจจุบันได้',
    saveChanges: 'บันทึกการแก้ไข',
    allBuses: 'รถทั้งหมด',
    unknownBus: 'ไม่ระบุรถ',
    noDriver: 'ไม่มีชื่อคนขับ',
    noLine: 'ไม่ระบุสาย',
    issueReports: 'รายงานปัญหา',
    issueReport: 'รายงานปัญหา',
    anonymous: 'ไม่ระบุชื่อ',
    systemUsers: 'ผู้ใช้ในระบบ',
    changeRole: 'เปลี่ยนสิทธิ์',
    deleteStationConfirm: 'ลบสถานี "{name}" ใช่ไหม?',
    deleteUserConfirm: 'ลบผู้ใช้ "{name}" ใช่ไหม?',
  },
} as const;

const text = computed(() => dictionary[lang.value]);
const activeTitle = computed(() => text.value.tabs[activeTab.value]);

const loading = ref(false);
const error = ref('');
const isLoggedIn = ref(Boolean(api.token));

const loginForm = reactive({
  username: '',
  password: '',
});

const stations = ref<Station[]>([]);
const buses = ref<Bus[]>([]);
const reports = ref<Report[]>([]);
const users = ref<User[]>([]);

const emptyStation = (): Station => ({
  id: '',
  name: '',
  lat: 0,
  lng: 0,
  lines: ['line1'],
  waiting: 0,
  status: 'LOW',
  cameraUrl: '',
  detectionRoi: [],
});

const stationForm = reactive<Station>(emptyStation());
const stationRoiText = ref('');
const editingStationKey = ref<string | null>(null);
const stationMapEl = ref<HTMLElement | null>(null);
const stationMap = ref<GoogleMap | null>(null);
const stationMarker = ref<GoogleMarker | null>(null);
const stationMapLoading = ref(false);
const stationMapError = ref('');
const routeMapEl = ref<HTMLElement | null>(null);
const routeMap = ref<GoogleMap | null>(null);
const routePolyline = ref<GooglePolyline | null>(null);
const routeEditorLine = ref<RouteLine>('line1');
const routeDraft = ref<LatLng[]>([]);
const routeGeoJsonText = ref('');
const routeMapLoading = ref(false);
const routeMapError = ref('');
const routeEditorMessage = ref('');
const openRoleMenu = ref<string | null>(null);
const selectedCameraStationId = ref<string | null>(null);
const detectorStatus = ref<DetectorStatus | null>(null);
const detectorBusy = ref(false);
const roiDraft = ref<Array<[number, number]>>([]);
const isEditingRoi = ref(false);
const draggingRoiPointIndex = ref<number | null>(null);
let detectorFrameTimer: number | undefined;

function setStationMapElement(element: HTMLElement | null) {
  if (stationMapEl.value !== element) {
    stationMap.value = null;
    stationMarker.value = null;
  }
  stationMapEl.value = element;
  if (element) {
    void nextTick(initStationMap);
  }
}

function setRouteMapElement(element: HTMLElement | null) {
  if (routeMapEl.value !== element) {
    routeMap.value = null;
    routePolyline.value = null;
  }
  routeMapEl.value = element;
  if (element) {
    void nextTick(initRouteMap);
  }
}

const onlineBuses = computed(() => buses.value.filter((bus) => bus.status?.toLowerCase() !== 'offline').length);
const pendingReports = computed(() => reports.value.filter((report) => report.status !== 'resolved').length);
const selectedCameraStation = computed(() => {
  if (stations.value.length === 0) return null;
  return stations.value.find((station) => station.id === selectedCameraStationId.value) ?? stations.value[0];
});
const selectedCameraUrl = computed(() => normalizeCameraUrl(selectedCameraStation.value?.cameraUrl));
const selectedCameraPreviewKind = computed(() => getCameraPreviewKind(selectedCameraUrl.value));
const detectorStreamUrl = computed(() => (
  selectedCameraStation.value && detectorStatus.value?.running
    ? api.getDetectorStreamUrl(selectedCameraStation.value.id)
    : ''
));
const routePointCount = computed(() => routeDraft.value.length);
const routeEditorLineLabel = computed(() => (routeEditorLine.value === 'line1' ? 'Line 1' : 'Line 2'));

function fillTemplate(template: string, values: Record<string, string | number>) {
  return template.replace(/\{(\w+)\}/g, (_, key) => String(values[key] ?? ''));
}

function googleLatLngToLiteral(value: GoogleLatLngValue): LatLng {
  return {
    lat: Number(value.lat().toFixed(6)),
    lng: Number(value.lng().toFixed(6)),
  };
}

function routeEditorStorageKey() {
  return `${ROUTE_EDITOR_STORAGE_PREFIX}${routeEditorLine.value}`;
}

function buildRouteGeoJson(points: LatLng[], line: RouteLine = routeEditorLine.value) {
  return {
    type: 'FeatureCollection',
    features: [
      {
        type: 'Feature',
        properties: {
          routeId: line,
          source: 'admin-web-route-editor',
        },
        geometry: {
          type: 'LineString',
          coordinates: points.map((point) => [
            Number(point.lng.toFixed(6)),
            Number(point.lat.toFixed(6)),
          ]),
        },
      },
    ],
  };
}

function extractGeoJsonLineCoordinates(value: unknown): unknown[] {
  if (!value || typeof value !== 'object') return [];

  const geoJson = value as Record<string, unknown>;
  if (geoJson.type === 'FeatureCollection') {
    const features = Array.isArray(geoJson.features) ? geoJson.features : [];
    return features.length ? extractGeoJsonLineCoordinates(features[0]) : [];
  }

  if (geoJson.type === 'Feature') {
    return extractGeoJsonLineCoordinates(geoJson.geometry);
  }

  if (geoJson.type === 'LineString') {
    return Array.isArray(geoJson.coordinates) ? geoJson.coordinates : [];
  }

  return [];
}

function parseGeoJsonRoute(raw: string) {
  const parsed = JSON.parse(raw);
  const coordinates = extractGeoJsonLineCoordinates(parsed);
  const points = coordinates
    .filter((point): point is unknown[] => Array.isArray(point) && point.length >= 2)
    .map((point) => ({
      lat: Number(point[1]),
      lng: Number(point[0]),
    }))
    .filter((point) => Number.isFinite(point.lat) && Number.isFinite(point.lng));

  if (points.length < 2) {
    throw new Error('GeoJSON route must contain at least 2 coordinates.');
  }

  return points;
}

function syncRouteGeoJsonText() {
  routeGeoJsonText.value = JSON.stringify(buildRouteGeoJson(routeDraft.value), null, 2);
}

function syncRouteDraftFromPolyline() {
  const path = routePolyline.value?.getPath();
  if (!path) return;

  routeDraft.value = path.getArray().map(googleLatLngToLiteral);
  syncRouteGeoJsonText();
}

function setRouteDraft(points: LatLng[], message = '') {
  routeDraft.value = points.map((point) => ({
    lat: Number(point.lat.toFixed(6)),
    lng: Number(point.lng.toFixed(6)),
  }));
  routePolyline.value?.setPath(routeDraft.value);
  attachRoutePathListeners();
  syncRouteGeoJsonText();
  focusRouteDraft();
  routeEditorMessage.value = message;
}

function attachRoutePathListeners() {
  const path = routePolyline.value?.getPath();
  if (!path) return;

  path.addListener('set_at', syncRouteDraftFromPolyline);
  path.addListener('insert_at', syncRouteDraftFromPolyline);
  path.addListener('remove_at', syncRouteDraftFromPolyline);
}

function focusRouteDraft() {
  const maps = window.google?.maps;
  const map = routeMap.value;
  if (!maps || !map || routeDraft.value.length === 0) return;

  if (routeDraft.value.length === 1) {
    map.setCenter(routeDraft.value[0]);
    return;
  }

  const bounds = new maps.LatLngBounds();
  routeDraft.value.forEach((point) => bounds.extend(point));
  map.fitBounds(bounds);
}

function toggleLanguage() {
  lang.value = lang.value === 'en' ? 'th' : 'en';
  localStorage.setItem(LANGUAGE_KEY, lang.value);
}

function setActiveTab(tab: TabKey) {
  activeTab.value = tab;
}

function setRouteEditorLine(line: RouteLine) {
  routeEditorLine.value = line;
}

function selectValue(event: Event) {
  return (event.target as HTMLSelectElement).value;
}

function normalizeCameraUrl(value?: string) {
  return String(value ?? '').trim();
}

function hasCamera(station?: Station | null) {
  return normalizeCameraUrl(station?.cameraUrl).length > 0;
}

function getCameraPreviewKind(url?: string): CameraPreviewKind {
  const normalizedUrl = normalizeCameraUrl(url);
  if (!normalizedUrl) return 'none';
  if (/^rtsp:\/\//i.test(normalizedUrl)) return 'rtsp';
  if (/(\.jpg|\.jpeg|\.png|\.gif|\.webp|\.mjpg|\.mjpeg)(\?|$)/i.test(normalizedUrl)) return 'image';
  if (/(\.mp4|\.webm|\.ogg|\.m3u8)(\?|$)/i.test(normalizedUrl)) return 'video';
  return 'link';
}

function selectCameraStation(station: Station) {
  selectedCameraStationId.value = station.id;
}

function openCameraStation(station: Station) {
  selectCameraStation(station);
  activeTab.value = 'cctv';
}

function syncSelectedCameraStation(nextStations: Station[]) {
  if (nextStations.length === 0) {
    selectedCameraStationId.value = null;
    return;
  }

  if (selectedCameraStationId.value && nextStations.some((station) => station.id === selectedCameraStationId.value)) {
    return;
  }

  const station08 = nextStations.find((station) => station.id.toLowerCase() === 'station08');
  selectedCameraStationId.value = (station08 ?? nextStations.find(hasCamera) ?? nextStations[0]).id;
}

async function copyCameraUrl() {
  if (!selectedCameraUrl.value) return;
  await navigator.clipboard.writeText(selectedCameraUrl.value);
}

function syncRoiDraftFromStation() {
  roiDraft.value = selectedCameraStation.value?.detectionRoi?.length
    ? selectedCameraStation.value.detectionRoi.map((point) => [point[0], point[1]])
    : [];
}

async function loadDetectorStatus() {
  const station = selectedCameraStation.value;
  if (!station) return;

  try {
    detectorStatus.value = await api.getDetectorStatus(station.id);
  } catch {
    detectorStatus.value = null;
  }
}

async function startSelectedDetector() {
  const station = selectedCameraStation.value;
  if (!station) return;

  detectorBusy.value = true;
  try {
    detectorStatus.value = await api.startDetector(station.id);
    window.setTimeout(() => {
      void loadDetectorStatus();
    }, 2500);
  } finally {
    detectorBusy.value = false;
  }
}

async function stopSelectedDetector() {
  const station = selectedCameraStation.value;
  if (!station) return;

  detectorBusy.value = true;
  try {
    detectorStatus.value = await api.stopDetector(station.id);
  } finally {
    detectorBusy.value = false;
  }
}

function getPointerInRoi(event: PointerEvent) {
  const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
  const x = Math.min(1, Math.max(0, (event.clientX - rect.left) / rect.width));
  const y = Math.min(1, Math.max(0, (event.clientY - rect.top) / rect.height));
  return [Number(x.toFixed(4)), Number(y.toFixed(4))] as [number, number];
}

function startRoiEditor() {
  syncRoiDraftFromStation();
  isEditingRoi.value = true;
}

function cancelRoiEditor() {
  isEditingRoi.value = false;
  draggingRoiPointIndex.value = null;
  syncRoiDraftFromStation();
}

function setRoiPreset(preset: 'full' | 'right' | 'left' | 'bottom' | 'center') {
  const presets: Record<typeof preset, Array<[number, number]>> = {
    full: [[0, 0], [1, 0], [1, 1], [0, 1]],
    right: [[0.5, 0], [1, 0], [1, 1], [0.5, 1]],
    left: [[0, 0], [0.5, 0], [0.5, 1], [0, 1]],
    bottom: [[0, 0.5], [1, 0.5], [1, 1], [0, 1]],
    center: [[0.2, 0.2], [0.8, 0.2], [0.8, 0.8], [0.2, 0.8]],
  };
  roiDraft.value = presets[preset];
}

function clearRoiDraft() {
  roiDraft.value = [];
}

function handleRoiCanvasPointerDown(event: PointerEvent) {
  if (!isEditingRoi.value || roiDraft.value.length >= 8) return;
  roiDraft.value = [...roiDraft.value, getPointerInRoi(event)];
}

function startDragRoiPoint(index: number, event: PointerEvent) {
  event.stopPropagation();
  draggingRoiPointIndex.value = index;
}

function dragRoiPoint(event: PointerEvent) {
  if (draggingRoiPointIndex.value === null) return;

  const nextPoints = [...roiDraft.value];
  nextPoints[draggingRoiPointIndex.value] = getPointerInRoi(event);
  roiDraft.value = nextPoints;
}

function stopDragRoiPoint() {
  draggingRoiPointIndex.value = null;
}

async function saveSelectedRoi() {
  const station = selectedCameraStation.value;
  if (!station) return;

  const payload: Station = {
    ...station,
    detectionRoi: roiDraft.value,
  };

  await withLoading(async () => {
    await api.updateStation(station.id, payload);
    stations.value = await api.getStations();
    syncSelectedCameraStation(stations.value);
    isEditingRoi.value = false;
  });
}

function resetStationForm() {
  Object.assign(stationForm, emptyStation());
  stationRoiText.value = '';
  editingStationKey.value = null;
  void nextTick(initStationMap);
}

function formatRoi(roi?: Array<[number, number]>) {
  return roi && roi.length ? JSON.stringify(roi) : '';
}

function parseRoiText() {
  const raw = stationRoiText.value.trim();
  if (!raw) return [];

  const parsed = JSON.parse(raw);
  const isValid = Array.isArray(parsed) && parsed.every((point) => (
    Array.isArray(point) &&
    point.length === 2 &&
    Number.isFinite(Number(point[0])) &&
    Number.isFinite(Number(point[1])) &&
    Number(point[0]) >= 0 &&
    Number(point[0]) <= 1 &&
    Number(point[1]) >= 0 &&
    Number(point[1]) <= 1
  ));

  if (!isValid) {
    throw new Error('Detection ROI must be JSON like [[0.1,0.2],[0.9,0.2],[0.9,0.8],[0.1,0.8]]');
  }

  return parsed.map((point) => [Number(point[0]), Number(point[1])]) as Array<[number, number]>;
}

function getStationPosition() {
  const lat = Number(stationForm.lat);
  const lng = Number(stationForm.lng);

  if (Number.isFinite(lat) && Number.isFinite(lng) && (lat !== 0 || lng !== 0)) {
    return { lat, lng };
  }

  return MFU_CENTER;
}

function setStationPosition(position: LatLng) {
  stationForm.lat = Number(position.lat.toFixed(6));
  stationForm.lng = Number(position.lng.toFixed(6));
  stationMarker.value?.setPosition(position);
  stationMap.value?.setCenter(position);
}

function syncMarkerFromForm() {
  if (!stationMarker.value || !stationMap.value) return;

  const position = getStationPosition();
  stationMarker.value.setPosition(position);
  stationMap.value.setCenter(position);
}

function loadGoogleMaps() {
  if (window.google?.maps) return Promise.resolve();
  if (googleMapsPromise) return googleMapsPromise;

  googleMapsPromise = new Promise((resolve, reject) => {
    if (!GOOGLE_MAPS_API_KEY) {
      reject(new Error(text.value.mapMissingKey));
      return;
    }

    window.initMfuStationMap = () => resolve();

    const script = document.createElement('script');
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(GOOGLE_MAPS_API_KEY)}&callback=initMfuStationMap`;
    script.async = true;
    script.defer = true;
    script.onerror = () => reject(new Error(text.value.mapLoadFailed));
    document.head.appendChild(script);
  });

  return googleMapsPromise;
}

async function initStationMap() {
  if (activeTab.value !== 'stations' || !stationMapEl.value) return;

  if (stationMap.value && stationMarker.value) {
    syncMarkerFromForm();
    return;
  }

  stationMapLoading.value = true;
  stationMapError.value = '';

  try {
    await loadGoogleMaps();

    const maps = window.google?.maps;
    if (!maps || !stationMapEl.value) {
      throw new Error(text.value.mapLoadFailed);
    }

    const position = getStationPosition();
    stationMap.value = new maps.Map(stationMapEl.value, {
      center: position,
      zoom: 17,
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: true,
    });

    stationMarker.value = new maps.Marker({
      position,
      map: stationMap.value,
      draggable: true,
      title: 'Station location',
    });

    stationMap.value.addListener('click', (event: GoogleMapMouseEvent) => {
      if (!event.latLng) return;
      setStationPosition({ lat: event.latLng.lat(), lng: event.latLng.lng() });
    });

    stationMarker.value.addListener('dragend', () => {
      const markerPosition = stationMarker.value?.getPosition();
      if (!markerPosition) return;
      setStationPosition({ lat: markerPosition.lat(), lng: markerPosition.lng() });
    });
  } catch (err) {
    stationMapError.value = err instanceof Error ? err.message : text.value.mapLoadFailed;
  } finally {
    stationMapLoading.value = false;
  }
}

function loadSavedRouteDraft() {
  const savedRoute = localStorage.getItem(routeEditorStorageKey());
  if (!savedRoute) {
    setRouteDraft([], '');
    syncRouteGeoJsonText();
    return;
  }

  try {
    setRouteDraft(parseGeoJsonRoute(savedRoute), `Loaded temporary ${routeEditorLineLabel.value} draft.`);
  } catch {
    localStorage.removeItem(routeEditorStorageKey());
    setRouteDraft([], '');
    syncRouteGeoJsonText();
  }
}

async function initRouteMap() {
  if (activeTab.value !== 'routes' || !routeMapEl.value) return;

  if (routeMap.value && routePolyline.value) {
    focusRouteDraft();
    return;
  }

  routeMapLoading.value = true;
  routeMapError.value = '';

  try {
    await loadGoogleMaps();

    const maps = window.google?.maps;
    if (!maps || !routeMapEl.value) {
      throw new Error(text.value.mapLoadFailed);
    }

    routeMap.value = new maps.Map(routeMapEl.value, {
      center: MFU_CENTER,
      zoom: 16,
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: true,
    });

    routePolyline.value = new maps.Polyline({
      map: routeMap.value,
      path: routeDraft.value,
      strokeColor: '#bc9945',
      strokeOpacity: 0.95,
      strokeWeight: 5,
      editable: true,
      draggable: false,
      zIndex: 30,
    });

    attachRoutePathListeners();

    routeMap.value.addListener('click', (event) => {
      if (!event.latLng) return;
      routePolyline.value?.getPath().push(googleLatLngToLiteral(event.latLng));
      syncRouteDraftFromPolyline();
      routeEditorMessage.value = 'Point added.';
    });

    routePolyline.value.addListener('rightclick', (event) => {
      if (typeof event.vertex !== 'number') return;
      routePolyline.value?.getPath().removeAt(event.vertex);
      syncRouteDraftFromPolyline();
      routeEditorMessage.value = 'Point removed.';
    });

    loadSavedRouteDraft();
    focusRouteDraft();
  } catch (err) {
    routeMapError.value = err instanceof Error ? err.message : text.value.mapLoadFailed;
  } finally {
    routeMapLoading.value = false;
  }
}

function loadRouteFromStations() {
  const line1Stations = stations.value
    .filter((station) => station.lines.includes(routeEditorLine.value))
    .map((station) => ({ lat: Number(station.lat), lng: Number(station.lng) }))
    .filter((point) => Number.isFinite(point.lat) && Number.isFinite(point.lng));

  if (line1Stations.length < 2) {
    routeEditorMessage.value = `${routeEditorLineLabel.value} needs at least 2 stations.`;
    return;
  }

  setRouteDraft(line1Stations, `Loaded ${routeEditorLineLabel.value} station points.`);
}

function loadRouteFromGeoJsonText() {
  try {
    setRouteDraft(parseGeoJsonRoute(routeGeoJsonText.value), 'GeoJSON loaded.');
    routeMapError.value = '';
  } catch (err) {
    routeMapError.value = err instanceof Error ? err.message : 'Invalid GeoJSON.';
  }
}

async function importRouteFile(event: Event) {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  if (!file) return;

  routeGeoJsonText.value = await file.text();
  loadRouteFromGeoJsonText();
  input.value = '';
}

function undoRoutePoint() {
  const path = routePolyline.value?.getPath();
  if (!path || path.getLength() === 0) return;

  path.removeAt(path.getLength() - 1);
  syncRouteDraftFromPolyline();
  routeEditorMessage.value = 'Last point removed.';
}

function clearRouteDraft() {
  setRouteDraft([], 'Route cleared.');
}

function saveRouteDraftTemporary() {
  const geoJson = JSON.stringify(buildRouteGeoJson(routeDraft.value));
  localStorage.setItem(routeEditorStorageKey(), geoJson);
  routeEditorMessage.value = `Saved ${routeEditorLineLabel.value} temporarily in this browser.`;
}

function clearTemporaryRouteDraft() {
  localStorage.removeItem(routeEditorStorageKey());
  routeEditorMessage.value = `Temporary ${routeEditorLineLabel.value} draft cleared.`;
}

async function copyRouteGeoJson() {
  syncRouteGeoJsonText();
  await navigator.clipboard.writeText(routeGeoJsonText.value);
  routeEditorMessage.value = 'GeoJSON copied.';
}

function downloadRouteGeoJson() {
  syncRouteGeoJsonText();
  const blob = new Blob([routeGeoJsonText.value], { type: 'application/geo+json' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `polyline_${routeEditorLine.value}_mfu.geojson`;
  link.click();
  URL.revokeObjectURL(url);
  routeEditorMessage.value = 'GeoJSON downloaded.';
}

function useCurrentLocation() {
  if (!navigator.geolocation) {
    stationMapError.value = text.value.locateFailed;
    return;
  }

  stationMapLoading.value = true;
  stationMapError.value = '';

  navigator.geolocation.getCurrentPosition(
    (position) => {
      setStationPosition({
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      });
      stationMapLoading.value = false;
    },
    () => {
      stationMapError.value = text.value.locateFailed;
      stationMapLoading.value = false;
    },
    { enableHighAccuracy: true, timeout: 10000 },
  );
}

async function withLoading(task: () => Promise<void>) {
  loading.value = true;
  error.value = '';
  try {
    await task();
  } catch (err) {
    error.value = err instanceof Error ? err.message : text.value.genericError;
  } finally {
    loading.value = false;
  }
}

async function loadData() {
  await withLoading(async () => {
    const [stationData, busData, reportData, userData] = await Promise.all([
      api.getStations(),
      api.getBuses(),
      api.getReports(),
      api.getUsers(),
    ]);

    stations.value = stationData;
    syncSelectedCameraStation(stationData);
    buses.value = busData;
    reports.value = reportData;
    users.value = userData;
  });
}

async function login() {
  await withLoading(async () => {
    const result = await api.login(loginForm.username.trim(), loginForm.password);
    if (result.role !== 'admin') {
      api.clearSession();
      throw new Error(text.value.adminOnlyError);
    }
    isLoggedIn.value = true;
    await loadData();
  });
}

function logout() {
  api.clearSession();
  isLoggedIn.value = false;
  loginForm.password = '';
}

function editStation(station: Station) {
  Object.assign(stationForm, {
    ...station,
    lines: [...station.lines],
  });
  stationRoiText.value = formatRoi(station.detectionRoi);
  editingStationKey.value = station.id;
  selectCameraStation(station);
  void nextTick(initStationMap);
}

async function saveStation() {
  await withLoading(async () => {
    const payload: Station = {
      ...stationForm,
      id: stationForm.id.trim(),
      name: stationForm.name.trim(),
      lat: Number(stationForm.lat),
      lng: Number(stationForm.lng),
      waiting: 0,
      status: 'LOW',
      lines: stationForm.lines.length ? stationForm.lines : ['line1'],
      detectionRoi: parseRoiText(),
    };

    if (editingStationKey.value) {
      await api.updateStation(editingStationKey.value, payload);
    } else {
      await api.createStation(payload);
    }

    resetStationForm();
    stations.value = await api.getStations();
    syncSelectedCameraStation(stations.value);
  });
}

async function deleteStation(station: Station) {
  const stationKey = station.id;
  const message = fillTemplate(text.value.deleteStationConfirm, { name: station.name });
  if (!stationKey || !confirm(message)) return;

  await withLoading(async () => {
    await api.deleteStation(stationKey);
    stations.value = await api.getStations();
    syncSelectedCameraStation(stations.value);
  });
}

async function updateReportStatus(report: Report, status: string) {
  await withLoading(async () => {
    await api.updateReportStatus(report._id, status);
    reports.value = await api.getReports();
  });
}

async function updateUserRole(user: User, role: 'admin' | 'user') {
  openRoleMenu.value = null;
  await withLoading(async () => {
    await api.updateUserRole(user.username, role);
    users.value = await api.getUsers();
  });
}

function toggleRoleMenu(user: User) {
  openRoleMenu.value = openRoleMenu.value === user.username ? null : user.username;
}

async function deleteUser(user: User) {
  const message = fillTemplate(text.value.deleteUserConfirm, { name: user.username });
  if (!confirm(message)) return;

  await withLoading(async () => {
    await api.deleteUser(user.username);
    users.value = await api.getUsers();
  });
}

onMounted(() => {
  if (isLoggedIn.value) {
    void loadData();
  }

  detectorFrameTimer = window.setInterval(() => {
    void loadDetectorStatus();
  }, 2000);
});

onUnmounted(() => {
  if (detectorFrameTimer) {
    window.clearInterval(detectorFrameTimer);
  }
});

watch(activeTab, (tab) => {
  if (tab === 'stations') {
    void nextTick(initStationMap);
  }
  if (tab === 'routes') {
    void nextTick(initRouteMap);
  }
});

watch(routeEditorLine, () => {
  if (activeTab.value !== 'routes') {
    syncRouteGeoJsonText();
    return;
  }

  loadSavedRouteDraft();
});

watch(
  () => [stationForm.lat, stationForm.lng],
  () => {
    syncMarkerFromForm();
  },
);

watch(selectedCameraStationId, () => {
  detectorStatus.value = null;
  syncRoiDraftFromStation();
  void loadDetectorStatus();
});
</script>

<template>
  <main v-if="!isLoggedIn" class="login-page">
    <button class="language-toggle login-language" type="button" @click="toggleLanguage">
      {{ text.language }}
    </button>

    <section class="login-card">
      <div class="brand-mark">MFU</div>
      <p class="eyebrow">Admin Dashboard</p>
      <h1>MFU Shuttle Bus</h1>
      <p class="muted">{{ text.loginSubtitle }}</p>

      <form class="login-form" @submit.prevent="login">
        <label>
          {{ text.username }}
          <input v-model="loginForm.username" required autocomplete="username" :placeholder="text.usernamePlaceholder" />
        </label>
        <label>
          {{ text.password }}
          <input v-model="loginForm.password" required type="password" autocomplete="current-password" :placeholder="text.passwordPlaceholder" />
        </label>
        <button class="primary-btn" type="submit" :disabled="loading">
          {{ loading ? text.signingIn : text.signIn }}
        </button>
      </form>

      <p v-if="error" class="error-text">{{ error }}</p>
      <p class="api-note">API: {{ api.baseUrl }}</p>
    </section>
  </main>

  <div v-else class="shell">
    <aside class="sidebar">
      <div class="sidebar-brand">
        <div class="brand-mark small">MFU</div>
        <div>
          <strong>Shuttle Admin</strong>
          <span>Mae Fah Luang</span>
        </div>
      </div>

      <nav>
        <button
          v-for="tab in tabs"
          :key="tab.key"
          :class="{ active: activeTab === tab.key }"
          @click="setActiveTab(tab.key)"
        >
          {{ text.tabs[tab.key] }}
        </button>
      </nav>

      <button class="ghost-btn logout" @click="logout">{{ text.logout }}</button>
    </aside>

    <section class="content">
      <header class="topbar">
        <div>
          <p class="eyebrow">MFU Shuttle Bus</p>
          <h1>{{ activeTitle }}</h1>
        </div>
        <div class="topbar-actions">
          <button class="language-toggle" type="button" @click="toggleLanguage">
            {{ text.language }}
          </button>
          <button class="secondary-btn" :disabled="loading" @click="loadData">
            {{ loading ? text.loading : text.refresh }}
          </button>
        </div>
      </header>

      <p v-if="error" class="error-banner">{{ error }}</p>

      <DashboardPage
        v-if="activeTab === 'dashboard'"
        :buses="buses"
        :online-buses="onlineBuses"
        :pending-reports="pendingReports"
        :reports="reports"
        :stations="stations"
        :text="text"
        :users="users"
      />

      <StationsPage
        v-if="activeTab === 'stations'"
        :editing-station-key="editingStationKey"
        :has-camera="hasCamera"
        :loading="loading"
        :station-form="stationForm"
        :station-map-error="stationMapError"
        :station-map-loading="stationMapLoading"
        :station-roi-text="stationRoiText"
        :stations="stations"
        :text="text"
        @delete-station="deleteStation"
        @edit-station="editStation"
        @open-camera-station="openCameraStation"
        @reset-station-form="resetStationForm"
        @save-station="saveStation"
        @station-map-ready="setStationMapElement"
        @update-station-roi-text="stationRoiText = $event"
        @use-current-location="useCurrentLocation"
      />

      <RouteEditorPage
        v-if="activeTab === 'routes'"
        :route-draft="routeDraft"
        :route-editor-line="routeEditorLine"
        :route-editor-line-label="routeEditorLineLabel"
        :route-editor-message="routeEditorMessage"
        :route-geo-json-text="routeGeoJsonText"
        :route-map-error="routeMapError"
        :route-map-loading="routeMapLoading"
        :route-point-count="routePointCount"
        :text="text"
        @clear-route-draft="clearRouteDraft"
        @clear-temporary-route-draft="clearTemporaryRouteDraft"
        @copy-route-geo-json="copyRouteGeoJson"
        @download-route-geo-json="downloadRouteGeoJson"
        @import-route-file="importRouteFile"
        @load-route-from-geo-json-text="loadRouteFromGeoJsonText"
        @load-route-from-stations="loadRouteFromStations"
        @route-map-ready="setRouteMapElement"
        @save-route-draft-temporary="saveRouteDraftTemporary"
        @set-route-editor-line="setRouteEditorLine"
        @undo-route-point="undoRoutePoint"
        @update-route-geo-json-text="routeGeoJsonText = $event"
      />

      <StationCCTVPage
        v-if="activeTab === 'cctv'"
        :detector-busy="detectorBusy"
        :detector-status="detectorStatus"
        :detector-stream-url="detectorStreamUrl"
        :has-camera="hasCamera"
        :is-editing-roi="isEditingRoi"
        :roi-draft="roiDraft"
        :selected-camera-preview-kind="selectedCameraPreviewKind"
        :selected-camera-station="selectedCameraStation"
        :selected-camera-url="selectedCameraUrl"
        :stations="stations"
        @cancel-roi-editor="cancelRoiEditor"
        @clear-roi-draft="clearRoiDraft"
        @copy-camera-url="copyCameraUrl"
        @drag-roi-point="dragRoiPoint"
        @handle-roi-canvas-pointer-down="handleRoiCanvasPointerDown"
        @save-selected-roi="saveSelectedRoi"
        @select-camera-station="selectCameraStation"
        @set-roi-preset="setRoiPreset"
        @start-drag-roi-point="startDragRoiPoint"
        @start-roi-editor="startRoiEditor"
        @start-selected-detector="startSelectedDetector"
        @stop-drag-roi-point="stopDragRoiPoint"
        @stop-selected-detector="stopSelectedDetector"
      />
      <BusesPage
        v-if="activeTab === 'buses'"
        :buses="buses"
        :text="text"
      />

      <ReportsPage
        v-if="activeTab === 'reports'"
        :reports="reports"
        :text="text"
        @update-report-status="updateReportStatus"
      />

      <UsersPage
        v-if="activeTab === 'users'"
        :open-role-menu="openRoleMenu"
        :text="text"
        :users="users"
        @delete-user="deleteUser"
        @toggle-role-menu="toggleRoleMenu"
        @update-user-role="updateUserRole"
      />
    </section>
  </div>
</template>
