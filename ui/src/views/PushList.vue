<template>
  <div>
    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>

    <v-data-table :total-items="pagination.totalItems" :pagination.sync="pagination" :headers="headers" :items="items" :loading="onLoading" class="elevation-1">
      <v-progress-linear slot="progress" indeterminate></v-progress-linear>
      <template slot="items" slot-scope="props">
        <td>{{ props.item.target }}</td>
        <td>{{ props.item.started }}</td>
        <td>{{ props.item.status }}</td>
        <td>{{ props.item.stime }}</td>
        <td>{{ props.item.error }}</td>
      </template>
    </v-data-table>
  </div>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class PushList extends Vue {
  inError = false
  error = "none"

  onLoading = true

  pagination = {
    page: 1,
    rowsPerPage: 10,
    totalItems: 0
  }

  headers = [
    { text: 'Target', align: 'left', sortable: false, value: 'target' },
    { text: 'Started', sortable: false, value: 'started' },
    { text: 'Status', sortable: false, value: 'status' },
    { text: 'Status-Time', sortable: false, value: 'stime' },
    { text: 'Error', sortable: false, value: 'error' }
  ]

  items = []

  @Watch('pagination')
  onPaginationChanged() {
    let page = this.pagination.page
    let pageSize = this.pagination.rowsPerPage

    this.onLoading = true
    axios.get(`/api/push/page/${page}?pageSize=${pageSize}`)
      .then(res => {
        this.items = res.data.data
        this.pagination.totalItems = res.data.total
        this.onLoading = false
      }).catch(e => {
        this.error = `Server request error => ${e.message}`
        this.inError = true
      })
  }
}
</script>