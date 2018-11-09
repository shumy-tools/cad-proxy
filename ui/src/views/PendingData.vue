<template>
  <div>
    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>

    <v-data-table :total-items="pagination.totalItems" :pagination.sync="pagination" :headers="headers" :items="items" :loading="onLoading" class="elevation-1">
      <v-progress-linear slot="progress" indeterminate></v-progress-linear>
      <template slot="items" slot-scope="props">
        <td>{{ props.item.id }}</td>
        <td>{{ props.item.udi }}</td>
        <td>{{ props.item.name }}</td>
        <td>{{ props.item.subjects }}</td>
        <td>{{ props.item.series }}</td>
        <!--<td>{{ props.item.target }}</td>
        <td>{{ props.item.subject }}</td>
        <td>{{ props.item.modality }}</td>
        <td>{{ props.item.size }}</td>
        <td>{{ props.item.status }}</td>
        <td>{{ props.item.sTime }}</td>
        <td>{{ props.item.error }}</td>-->
      </template>
    </v-data-table>
  </div>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class PendingData extends Vue {
  inError = false
  error = "none"

  onLoading = true

  pagination = {
    page: 1,
    rowsPerPage: 10,
    totalItems: 0
  }

  headers = [
    { text: 'ID', sortable: false, value: 'id' },
    { text: 'UDI', sortable: false, value: 'udi' },
    { text: 'Name', sortable: false, value: 'name' },
    { text: 'Subjects', sortable: false, value: 'subjects' },
    { text: 'Series', sortable: false, value: 'series' }
    
    /*
    { text: 'Target', sortable: false, value: 'target' },
    { text: 'Subject', sortable: false, value: 'subject' },
    { text: 'Eligible', sortable: false, value: 'eligible' },
    { text: 'Size', sortable: false, value: 'size' },

    { text: 'Status', sortable: false, value: 'status' },
    { text: 'Status-Time', sortable: false, value: 'sTime' },
    { text: 'Error', sortable: false, value: 'error' }
    */
  ]

  items = []

  @Watch('pagination')
  onPaginationChanged() {
    let page = this.pagination.page
    let pageSize = this.pagination.rowsPerPage

    this.onLoading = true
    axios.get(`/api/pending/${page}?pageSize=${pageSize}`)
      .then(res => {
        this.items = res.data.data
        this.pagination.totalItems = res.data.total
        this.onLoading = false
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }
}
</script>