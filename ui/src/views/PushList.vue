<template>
  <div>
    <v-dialog v-model="viewDialog">
      <v-card>
        <v-card-title class="headline grey lighten-2" primary-title>
          <span>
            <span class="font-weight-bold">Push-Request:</span>
            {{selected.id}}
          </span>
        </v-card-title>

        <v-card-text>
          <v-list class="list-border">
              <v-list-tile>
                <v-list-tile-content>
                  <v-list-tile-title class="title">Series</v-list-tile-title>
                </v-list-tile-content>
              </v-list-tile>

              <v-data-table hide-actions :headers="eHeaders" :items="selected.series">
                <template slot="items" slot-scope="props">
                  <td>{{ props.item.id }}</td>
                  <td>{{ props.item.subject }}</td>
                  <td>{{ props.item.date }}</td>
                  <td>{{ props.item.modality }}</td>
                  <td>{{ props.item.size }}</td>
                </template>
              </v-data-table>
          </v-list>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>

    <v-card class="elevation-1">
      <v-card-title class="title">
        Push List
        <v-spacer></v-spacer>
      </v-card-title>

      <v-data-table :total-items="pagination.totalItems" :pagination.sync="pagination" :headers="headers" :items="items" :loading="onLoading" class="elevation-1">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
          <td>
            <v-icon small @click="viewItem(props.item)">far fa-eye</v-icon>
          </td>
          <td>{{ props.item.id }}</td>
          <td>{{ props.item.target }}</td>
          <td>{{ props.item.subjects }}</td>
          <td>{{ props.item.series }}</td>
          <td>{{ props.item.started }}</td>
          <td>{{ props.item.status }}</td>
          <td>{{ props.item.sTime }}</td>
          <td>{{ props.item.error }}</td>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class PushList extends Vue {
  inError = false
  error = ''

  onLoading = true
  viewDialog = false

  pagination = {
    page: 1,
    rowsPerPage: 10,
    totalItems: 0
  }

  headers = [
    { text: 'View', sortable: false, width: '5px', value: 'view' },
    { text: 'ID', sortable: false, value: 'id' },
    { text: 'Target', sortable: false, value: 'target' },
    { text: 'Subjects', sortable: false, value: 'subjects' },
    { text: 'Series', sortable: false, value: 'series' },

    { text: 'Started', sortable: false, value: 'started' },
    { text: 'Status', sortable: false, value: 'status' },
    { text: 'Status-Time', sortable: false, value: 'sTime' },
    { text: 'Error', sortable: false, value: 'error' }
  ]

  eHeaders = [
    { text: 'ID', sortable: false, value: 'id' },
    { text: 'Subject', sortable: false, value: 'subject' },
    { text: 'Study-Date', sortable: false, value: 'date' },
    { text: 'Modality', sortable: false, value: 'modality' },
    { text: 'Size', sortable: false, value: 'size' }
  ]

  items = []
  selected = {}

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
        this.error = e.message
        this.inError = true
      })
  }

  viewItem(item: any) {
    this.onLoading = true
    axios.get(`/api/push/${item.id}`)
      .then(res => {
        this.selected = res.data
        this.viewDialog = true
        this.onLoading = false
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }
}
</script>