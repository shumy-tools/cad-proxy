<template>
  <div>
    <v-dialog v-model="viewDialog" max-width="800px">
      <!--<v-btn slot="activator" color="primary" dark class="mb-2">New Item</v-btn>-->
      <v-card>
        <v-card-title>
          <span class="headline">Subject Details</span>
        </v-card-title>

        <v-card-text>
          <v-container grid-list-md>
            <v-layout wrap>
              <v-flex xs12 sm6 md4>
                <v-text-field readonly v-model="selected.id" label="ID"></v-text-field>
              </v-flex>
              <v-flex xs12 sm6 md4>
                <v-text-field readonly v-model="selected.udi" label="UDI"></v-text-field>
              </v-flex>
              <!--<v-flex xs12 sm6 md4>
                <v-text-field v-model="selected.fat" label="Fat (g)"></v-text-field>
              </v-flex>
              <v-flex xs12 sm6 md4>
                <v-text-field v-model="selected.carbs" label="Carbs (g)"></v-text-field>
              </v-flex>
              <v-flex xs12 sm6 md4>
                <v-text-field v-model="selected.protein" label="Protein (g)"></v-text-field>
              </v-flex>-->
            </v-layout>
          </v-container>
        </v-card-text>

        <!--<v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="blue darken-1" flat @click.native="close">Close</v-btn>
        </v-card-actions>-->
      </v-card>
    </v-dialog>

    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>

    <v-data-table :total-items="pagination.totalItems" :pagination.sync="pagination" :headers="headers" :items="items" :loading="onLoading" class="elevation-1">
      <v-progress-linear slot="progress" indeterminate></v-progress-linear>
      <template slot="items" slot-scope="props">
        <td>{{ props.item.id }}</td>
        <td>{{ props.item.udi }}</td>
        <td>{{ props.item.active }}</td>
        <td>{{ props.item.atime }}</td>
        <td>{{ props.item.refs }}</td>
        <td class="justify-center layout px-0">
          <v-icon small class="mr-2" @click="viewItem(props.item)">far fa-eye</v-icon>
        </td>
      </template>
    </v-data-table>
  </div>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class SubjectList extends Vue {
  inError = false
  error = "none"

  onLoading = true
  viewDialog = false

  pagination = {
    page: 1,
    rowsPerPage: 10,
    totalItems: 0
  }

  headers = [
    { text: 'ID', sortable: false, value: 'id' },
    { text: 'UDI', sortable: false, value: 'udi' },
    { text: 'Active', sortable: false, value: 'active' },
    { text: 'Active-Time', sortable: false, value: 'atime' },
    { text: 'Patient-Refs', sortable: false, value: 'refs' },
    { text: 'View', sortable: false, value: 'view' }
  ]

  items = []
  selected = {
    id: '',
    udi: ''
  }

  @Watch('pagination')
  onPaginationChanged() {
    let page = this.pagination.page
    let pageSize = this.pagination.rowsPerPage

    this.onLoading = true
    axios.get(`/api/subject/page/${page}?pageSize=${pageSize}`)
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
    this.selected = item
    this.viewDialog = true

    /*axios.get(`/api/subject/${item.id}`)
      .then(res => {
        this.selected = res.data
        this.viewDialog = true
      }).catch(e => {
        this.error = e.message
      })
    */
  }
}
</script>