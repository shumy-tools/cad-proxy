<template>
  <div>
    <v-dialog v-model="viewDialog">
      <v-card>
        <v-card-title class="headline grey lighten-2" primary-title>
          <span>
            <span class="font-weight-bold">Target:</span>
            {{selected.udi}}
          </span>
        </v-card-title>

        <v-card-text>
          <v-list class="list-border">
              <v-list-tile>
                <v-list-tile-content>
                  <v-list-tile-title class="title" style="height: 100%">
                    <v-toolbar flat color="white" class="toolbar-p-0">
                      <v-toolbar-title class="title">Series</v-toolbar-title>
                      <v-spacer></v-spacer>
                      <v-btn color="primary" @click="pushItem">push</v-btn>
                    </v-toolbar>
                  </v-list-tile-title>
                </v-list-tile-content>
              </v-list-tile>

              <v-data-table hide-actions :headers="eHeaders" :items="selected.series">
                <template slot="items" slot-scope="props">
                  <td v-for="h in eHeaders" :key="h.value">{{ props.item[h.value] }}</td>
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
        Pending Data (by Target)
        <v-spacer></v-spacer>
      </v-card-title>

      <v-data-table hide-actions :headers="headers" :items="items" :loading="onLoading">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
          <td>
            <v-icon small @click="viewItem(props.item)">far fa-eye</v-icon>
          </td>
          <td v-for="h in headers" v-if="h.value != 'view' && h.value != 'modalities'" :key="h.value">{{ props.item[h.value] }}</td>
          <td>
            <span v-for="name in props.item.modalities" :key="name" class="mr-2">({{name}})</span>
          </td>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class PendingData extends Vue {
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
    { text: 'Modalities', sortable: false, value: 'modalities' }
  ]

  eHeaders = [
    { text: 'ID', sortable: false, value: 'id' },
    { text: 'Subject', sortable: false, value: 'subject' },
    { text: 'Study-Date', sortable: false, value: 'date' },
    { text: 'Modality', sortable: false, value: 'modality' },
    { text: 'Size', sortable: false, value: 'size' },

    { text: 'Status', sortable: false, value: 'status' },
    { text: 'Status-Time', sortable: false, value: 'sTime' },
    { text: 'Error', sortable: false, value: 'error' }
  ]

  items = []
  selected: any = {}

  created() { this.load() }

  load() {
    this.onLoading = true
    axios.get(`/api/pending`)
      .then(res => {
        this.items = res.data
        this.onLoading = false
        this.viewDialog = false
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  viewItem(item: any) {
    this.onLoading = true
    axios.get(`/api/pending/${item.id}`)
      .then(res => {
        this.selected = res.data
        this.viewDialog = true
        this.onLoading = false
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  pushItem() {
    this.onLoading = true
    axios.post(`/api/pending/push`, { "id": this.selected.id, "series": this.selected.series.map(e => e.id) })
      .then(_ => this.load()).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }
}
</script>