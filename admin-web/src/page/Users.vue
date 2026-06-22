<script setup lang="ts">
import type { User } from '../types';

defineProps<{
  openRoleMenu: string | null;
  text: Record<string, any>;
  users: User[];
}>();

defineEmits<{
  deleteUser: [user: User];
  toggleRoleMenu: [user: User];
  updateUserRole: [user: User, role: 'admin' | 'user'];
}>();
</script>

<template>
  <section class="panel">
    <div class="panel-heading">
      <h2>{{ text.systemUsers }}</h2>
      <span>{{ users.length }} users</span>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Username</th>
            <th>Email</th>
            <th>Role</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in users" :key="user._id || user.username">
            <td>{{ user.username }}</td>
            <td>{{ user.email || '-' }}</td>
            <td>
              <div class="role-menu">
                <button
                  class="role-select"
                  type="button"
                  :aria-label="text.changeRole"
                  @click="$emit('toggleRoleMenu', user)"
                >
                  {{ user.role || 'user' }}
                  <span aria-hidden="true">⌄</span>
                </button>
                <div v-if="openRoleMenu === user.username" class="role-options">
                  <button type="button" @click="$emit('updateUserRole', user, 'user')">user</button>
                  <button type="button" @click="$emit('updateUserRole', user, 'admin')">admin</button>
                </div>
              </div>
            </td>
            <td class="actions">
              <button class="danger-link" @click="$emit('deleteUser', user)">{{ text.delete }}</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
