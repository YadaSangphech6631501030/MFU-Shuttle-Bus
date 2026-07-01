<script setup lang="ts">
import { computed, ref } from 'vue';
import type { Report } from '../types';

type ReportView = 'active' | 'feedback' | 'history';

const props = defineProps<{
  reports: Report[];
  text: Record<string, any>;
}>();

defineEmits<{
  updateReportStatus: [report: Report, status: string];
  deleteReport: [report: Report];
}>();

function selectValue(event: Event) {
  return (event.target as HTMLSelectElement).value;
}

function cleanText(value: unknown) {
  if (value === null || value === undefined) return '';
  return String(value).trim();
}

function firstText(...values: unknown[]) {
  return values.map(cleanText).find(Boolean) || '';
}

function reportTitle(report: Report) {
  return firstText(report.title, report.category, report.type, props.text.issueReport);
}

function reportCategory(report: Report) {
  return firstText(report.type, report.category, props.text.issueReport);
}

function reportDetail(report: Report) {
  return firstText(report.description, report.detail, props.text.noReportDetail);
}

function reportLocation(report: Report) {
  return firstText(report.location, props.text.noReportLocation);
}

function reporterName() {
  return props.text.guestUser;
}

function reporterMeta() {
  return props.text.guestReportMeta || props.text.reportUserUnknown;
}

function normalizedStatus(report: Report) {
  const status = cleanText(report.status);
  return status || 'pending';
}

function statusLabel(status: string) {
  if (status === 'resolved') return props.text.resolvedStatus;
  if (status === 'in_progress') return props.text.inProgressStatus;
  return props.text.pendingStatus;
}

function statusClass(report: Report) {
  return `report-status-${normalizedStatus(report).replace(/_/g, '-')}`;
}

function reportTimestamp(report: Report) {
  return firstText(report.createdAt, report.time);
}

function reportDate(report: Report) {
  const timestamp = reportTimestamp(report);
  if (!timestamp) return null;

  const date = new Date(timestamp);
  return Number.isNaN(date.getTime()) ? null : date;
}

function reportDateValue(report: Report) {
  const date = reportDate(report);
  if (!date) return '';

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function reportLocale() {
  return props.text.language === 'TH' ? 'th-TH-u-ca-gregory' : 'en-US';
}

function formatReportDateTime(report: Report) {
  const date = reportDate(report);
  if (!date) return reportTimestamp(report) || props.text.unknownTime;

  return new Intl.DateTimeFormat(reportLocale(), {
    weekday: 'short',
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).format(date);
}

function setReportView(view: ReportView) {
  activeReportView.value = view;
  categoryFilter.value = 'all';
  statusFilter.value = 'all';
}

function reportDetailLines(report: Report) {
  return reportDetail(report).split(/\n+/).map((line) => line.trim()).filter(Boolean);
}

function ratingDetail(line: string) {
  const match = line.match(/^(.*?):\s*(\d+)\/5\s*(?:\((.*?)\))?$/);
  if (!match) return null;

  return {
    label: match[1].trim(),
    score: match[2],
    note: (match[3] || '').trim(),
  };
}

function structuredFeedbackRatings(report: Report) {
  return (report.feedbackRatings || [])
    .map((item) => ({
      label: firstText(item.label, item.key),
      score: Number(item.score),
      note: firstText(item.description),
    }))
    .filter((item) => item.label && Number.isFinite(item.score));
}

function hasStructuredFeedbackRatings(report: Report) {
  return structuredFeedbackRatings(report).length > 0;
}

function isFeedbackReport(report: Report) {
  return reportCategory(report).toLowerCase() === 'feedback';
}

function matchesSearch(report: Report, query: string) {
  if (!query) return true;

  const haystack = [
    reportTitle(report),
    reportCategory(report),
    reportDetail(report),
    reportLocation(report),
    reporterName(),
    statusLabel(normalizedStatus(report)),
    formatReportDateTime(report),
  ].join(' ').toLowerCase();

  return haystack.includes(query);
}

function matchesDateRange(report: Report) {
  const reportDateText = reportDateValue(report);
  if (!reportDateText) return !dateFromFilter.value && !dateToFilter.value;
  if (dateFromFilter.value && reportDateText < dateFromFilter.value) return false;
  if (dateToFilter.value && reportDateText > dateToFilter.value) return false;
  return true;
}

const activeReportView = ref<ReportView>('active');
const searchQuery = ref('');
const categoryFilter = ref('all');
const statusFilter = ref('all');
const dateFromFilter = ref('');
const dateToFilter = ref('');

const feedbackReports = computed(() => props.reports.filter((report) => isFeedbackReport(report)));
const activeReports = computed(() => props.reports
  .filter((report) => !isFeedbackReport(report))
  .filter((report) => normalizedStatus(report) !== 'resolved'));
const historyReports = computed(() => props.reports
  .filter((report) => !isFeedbackReport(report))
  .filter((report) => normalizedStatus(report) === 'resolved'));
const visibleReports = computed(() => {
  if (activeReportView.value === 'feedback') return feedbackReports.value;
  if (activeReportView.value === 'history') return historyReports.value;
  return activeReports.value;
});

const categoryOptions = computed(() => {
  const categories = new Set(visibleReports.value.map((report) => reportCategory(report)));
  return Array.from(categories).sort((a, b) => a.localeCompare(b));
});

const statusFilterOptions = computed(() => {
  if (activeReportView.value === 'history') {
    return [{ value: 'resolved', label: props.text.resolvedStatus }];
  }

  const options = [
    { value: 'pending', label: props.text.pendingStatus },
    { value: 'in_progress', label: props.text.inProgressStatus },
  ];

  if (activeReportView.value === 'feedback') {
    options.push({ value: 'resolved', label: props.text.resolvedStatus });
  }

  return options;
});

const filteredReports = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();

  return visibleReports.value.filter((report) => {
    if (categoryFilter.value !== 'all' && reportCategory(report) !== categoryFilter.value) return false;
    if (statusFilter.value !== 'all' && normalizedStatus(report) !== statusFilter.value) return false;
    if (!matchesDateRange(report)) return false;
    return matchesSearch(report, query);
  });
});

const reportGroups = computed(() => {
  const groups = new Map<string, Report[]>();

  filteredReports.value.forEach((report) => {
    const category = reportCategory(report);
    const group = groups.get(category) || [];
    group.push(report);
    groups.set(category, group);
  });

  return Array.from(groups, ([category, items]) => ({ category, items }));
});
</script>

<template>
  <section class="panel report-panel">
    <div class="panel-heading report-heading">
      <div>
        <h2>{{ text.issueReports }}</h2>
        <p>{{ text.issueReportsHint }}</p>
      </div>
      <span class="report-total">{{ filteredReports.length }} / {{ reports.length }} {{ text.reportsUnit }}</span>
    </div>

    <div class="report-toolbar">
      <div class="report-view-toggle" role="tablist" :aria-label="text.reportViewLabel">
        <button
          type="button"
          :class="{ active: activeReportView === 'active' }"
          @click="setReportView('active')"
        >
          {{ text.activeReports }}
          <span>{{ activeReports.length }}</span>
        </button>
        <button
          type="button"
          :class="{ active: activeReportView === 'feedback' }"
          @click="setReportView('feedback')"
        >
          {{ text.feedbackReports }}
          <span>{{ feedbackReports.length }}</span>
        </button>
        <button
          type="button"
          :class="{ active: activeReportView === 'history' }"
          @click="setReportView('history')"
        >
          {{ text.historyReports }}
          <span>{{ historyReports.length }}</span>
        </button>
      </div>

      <div class="report-filters">
        <label>
          {{ text.reportSearch }}
          <input v-model="searchQuery" type="search" :placeholder="text.reportSearchPlaceholder" />
        </label>
        <label>
          {{ text.reportCategoryFilter }}
          <select v-model="categoryFilter">
            <option value="all">{{ text.allCategories }}</option>
            <option v-for="category in categoryOptions" :key="category" :value="category">
              {{ category }}
            </option>
          </select>
        </label>
        <label class="report-date-range-field">
          {{ text.reportDateRange }}
          <span class="report-date-range">
            <span class="report-date-input">
              <input
                v-model="dateFromFilter"
                type="date"
                :aria-label="text.reportDateFrom"
                :class="{ empty: !dateFromFilter }"
                :title="text.reportDateFrom"
              />
              <span v-if="!dateFromFilter">{{ text.reportDateFromShort }}</span>
            </span>
            <span class="report-date-input">
              <input
                v-model="dateToFilter"
                type="date"
                :aria-label="text.reportDateTo"
                :class="{ empty: !dateToFilter }"
                :title="text.reportDateTo"
              />
              <span v-if="!dateToFilter">{{ text.reportDateToShort }}</span>
            </span>
          </span>
        </label>
        <label v-if="activeReportView !== 'feedback'">
          {{ text.reportStatusFilter }}
          <select v-model="statusFilter">
            <option value="all">{{ text.allStatuses }}</option>
            <option v-for="option in statusFilterOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </option>
          </select>
        </label>
      </div>
    </div>

    <div v-if="filteredReports.length" class="report-category-list">
      <section v-for="group in reportGroups" :key="group.category" class="report-category-section">
        <header class="report-category-heading">
          <div>
            <span class="report-category-pill">{{ group.category }}</span>
            <strong>{{ group.category }}</strong>
          </div>
          <span>{{ group.items.length }} {{ text.reportsUnit }}</span>
        </header>

        <div class="report-table-wrap">
          <table class="report-table" :class="{ 'feedback-table': activeReportView === 'feedback' }">
            <thead>
              <tr>
                <th>#</th>
                <th>{{ text.reportTitleLabel }}</th>
                <th>{{ text.reportDetailLabel }}</th>
                <th v-if="activeReportView !== 'feedback'">{{ text.reportLocation }}</th>
                <th>{{ text.reportedBy }}</th>
                <th>{{ text.submittedAt }}</th>
                <th v-if="activeReportView !== 'feedback'">{{ text.reportStatus }}</th>
                <th>{{ text.reportActions }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(report, rowIndex) in group.items" :key="report._id">
                <td class="report-index">{{ rowIndex + 1 }}</td>
                <td>
                  <strong class="report-table-title">{{ reportTitle(report) }}</strong>
                  <span class="report-table-category">{{ group.category }}</span>
                </td>
                <td>
                  <div v-if="hasStructuredFeedbackRatings(report)" class="feedback-rating-list">
                    <div
                      v-for="rating in structuredFeedbackRatings(report)"
                      :key="rating.label"
                      class="feedback-rating-item"
                    >
                      <span>{{ rating.label }}</span>
                      <strong>{{ rating.score }}/5</strong>
                      <small v-if="rating.note">{{ rating.note }}</small>
                    </div>
                    <div v-if="report.feedbackAverage" class="feedback-rating-average">
                      <span>{{ text.feedbackAverage }}</span>
                      <strong>{{ report.feedbackAverage }}/5</strong>
                    </div>
                  </div>
                  <div v-else-if="isFeedbackReport(report)" class="feedback-rating-list">
                    <div v-for="line in reportDetailLines(report)" :key="line" class="feedback-rating-item">
                      <template v-if="ratingDetail(line)">
                        <span>{{ ratingDetail(line)?.label }}</span>
                        <strong>{{ ratingDetail(line)?.score }}/5</strong>
                        <small v-if="ratingDetail(line)?.note">{{ ratingDetail(line)?.note }}</small>
                      </template>
                      <span v-else>{{ line }}</span>
                    </div>
                  </div>
                  <span v-else class="report-table-detail">{{ reportDetail(report) }}</span>
                </td>
                <td v-if="activeReportView !== 'feedback'" class="report-table-location">{{ reportLocation(report) }}</td>
                <td>
                  <strong class="reporter-table-name">{{ reporterName() }}</strong>
                  <small>{{ reporterMeta() }}</small>
                </td>
                <td class="report-table-time">{{ formatReportDateTime(report) }}</td>
                <td v-if="activeReportView !== 'feedback'">
                  <div class="report-status-cell">
                    <span class="report-status-pill" :class="statusClass(report)">
                      {{ statusLabel(normalizedStatus(report)) }}
                    </span>
                    <select
                      class="report-status-select"
                      :value="normalizedStatus(report)"
                      @change="$emit('updateReportStatus', report, selectValue($event))"
                    >
                      <option value="pending">{{ text.pendingStatus }}</option>
                      <option value="in_progress">{{ text.inProgressStatus }}</option>
                      <option value="resolved">{{ text.resolvedStatus }}</option>
                    </select>
                  </div>
                </td>
                <td>
                  <button class="report-delete-btn" type="button" @click="$emit('deleteReport', report)">
                    -
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>

    <div v-else class="report-empty-state">
      <strong>{{ reports.length ? text.noFilteredReports : text.noReports }}</strong>
      <span>{{ reports.length ? text.noFilteredReportsHint : text.noReportsHint }}</span>
    </div>
  </section>
</template>
