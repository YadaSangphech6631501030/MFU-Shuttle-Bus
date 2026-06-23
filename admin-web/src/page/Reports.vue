<script setup lang="ts">
import type { Report } from '../types';

defineProps<{
  reports: Report[];
  text: Record<string, any>;
}>();

defineEmits<{
  updateReportStatus: [report: Report, status: string];
}>();

function selectValue(event: Event) {
  return (event.target as HTMLSelectElement).value;
}
</script>

<template>
  <section class="panel">
    <div class="panel-heading">
      <h2>{{ text.issueReports }}</h2>
      <span>{{ reports.length }} {{ text.reportsUnit }}</span>
    </div>
    <div class="card-list">
      <article v-for="report in reports" :key="report._id" class="list-card report-card">
        <div>
          <strong>{{ report.title || report.category || report.type || text.issueReport }}</strong>
          <p>{{ report.description || report.detail || report.location || '-' }}</p>
          <small>
            {{ report.username || report.user?.username || report.userId || report.UserId || text.anonymous }}
            &middot;
            {{ report.createdAt || report.time || '-' }}
          </small>
        </div>
        <select :value="report.status || 'pending'" @change="$emit('updateReportStatus', report, selectValue($event))">
          <option value="pending">{{ text.pendingStatus }}</option>
          <option value="in_progress">{{ text.inProgressStatus }}</option>
          <option value="resolved">{{ text.resolvedStatus }}</option>
        </select>
      </article>
    </div>
  </section>
</template>
