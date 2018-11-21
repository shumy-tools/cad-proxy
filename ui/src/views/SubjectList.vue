<template>
  <div>
    <v-dialog v-model="viewDialog">
      <v-card>
        <v-card-title class="headline grey lighten-2" primary-title>
          <span>
            <span class="font-weight-bold">Subject:</span>
            {{selected.udi}}
          </span>
        </v-card-title>

        <v-card-text>
          <v-list class="list-border">
              <v-list-tile>
                <v-list-tile-content>
                  <v-list-tile-title class="title">Sources</v-list-tile-title>
                </v-list-tile-content>
              </v-list-tile>

              <v-data-table hide-actions :headers="pHeaders" :items="selected.sources">
                <template slot="items" slot-scope="props">
                  <td v-for="h in pHeaders" :key="h.value">{{ props.item[h.value] }}</td>
                </template>
              </v-data-table>
          </v-list>

          <v-list>
            <v-list-group no-action class="list-border">
              <v-list-tile slot="activator">
                <v-list-tile-content>
                  <v-list-tile-title class="title">Series</v-list-tile-title>
                </v-list-tile-content>
              </v-list-tile>

              <v-data-table hide-actions :headers="eHeaders" :items="selected.series">
                <template slot="items" slot-scope="props">
                  <td v-for="h in eHeaders" :key="h.value">{{ props.item[h.value] }}</td>
                </template>
              </v-data-table>
            </v-list-group>
          </v-list>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="addDialog">
      <v-card>
        <v-card-title class="headline grey lighten-2" primary-title>
          <span class="font-weight-bold">Add Subject</span>
        </v-card-title>

        <v-form ref="form" v-model="validForm">
          <v-container fluid grid-list-md>
            <v-layout row wrap>
              <!--ID/UDI-->
              <v-flex xs12 sm1>
                <v-text-field disabled v-model="selected.id" label="ID"></v-text-field>
              </v-flex>
              <v-flex xs12 sm11>
                <v-text-field v-model="selected.udi" label="UDI"
                  :rules="rules.udi"></v-text-field>
              </v-flex>

              <!--Sex/Birthday-->
              <v-flex xs12 md4>
                <v-select :items="sexList" item-value="name" item-text="desc" v-model="selected.sex" label="Sex"
                  :rules="rules.sex">
                  <template slot="selection" slot-scope="{ item, index }">
                    <span>{{ item.name }}</span>
                  </template>
                </v-select>
              </v-flex>
              <v-flex xs12 md8>
                <v-menu full-width v-model="dpMenu" :close-on-content-click="false" transition="scale-transition" min-width="290px">
                  <v-text-field readonly slot="activator" v-model="selected.birthday" label="Birthday"
                    :rules="rules.birthday"></v-text-field>
                  <v-date-picker v-model="selected.birthday" no-title @input="dpMenu = false"></v-date-picker>
                </v-menu>
              </v-flex>
            </v-layout>

            <v-toolbar flat dense color="white">
              <v-spacer></v-spacer>
              <v-btn :disabled="!validForm" color="primary" @click="submit">submit</v-btn>
            </v-toolbar>
          </v-container>
        </v-form>
      </v-card>
    </v-dialog>

    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>

    <v-card class="elevation-1">
      <v-card-title class="title">
        Subject List
        <v-spacer></v-spacer>
        <v-btn color="primary" @click="addSubject">add</v-btn>
      </v-card-title>
      
      <v-data-table :total-items="pagination.totalItems" :pagination.sync="pagination" :headers="headers" :items="items" :loading="onLoading" class="elevation-1">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
          <td>
            <v-icon small @click="viewItem(props.item)">far fa-eye</v-icon>
          </td>
          <td>
            <router-link tag="a" :to="`/subject?udi=${props.item.udi}`">{{ props.item.udi }}</router-link>
          </td>
          <td v-for="h in headers" v-if="h.value != 'view' && h.value != 'udi'" :key="h.value">{{ props.item[h.value] }}</td>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class SubjectList extends Vue {
  inError = false
  error = ''

  onLoading = true

  viewDialog = false
  addDialog = false
  dpMenu = false

  sexList = [
    { name: 'M', desc: 'Male' },
    { name: 'F', desc: 'Female' },
    { name: 'O', desc: 'Other' }
  ]

  validForm = false
  rules = {
    udi: [
      v => !!v || 'Required field'
      //TODO: validate with CRC!
    ],
    sex: [
      v => !!v || 'Required selection'
    ],
    birthday: [
      v => !!v || 'Required field'
    ]
  }

  pagination = {
    page: 1,
    rowsPerPage: 10,
    totalItems: 0
  }

  headers = [
    { text: 'View', sortable: false, width: '5px', value: 'view' },
    { text: 'UDI', sortable: false, value: 'udi' },
    { text: 'Sex', sortable: false, value: 'sex' },
    { text: 'Birthday', sortable: false, value: 'birthday' },
    { text: 'Sources', sortable: false, value: 'sources' },
    { text: 'Active', sortable: false, value: 'active' },
    { text: 'Active-Since', sortable: false, value: 'aTime' }
  ]

  pHeaders = [
    { text: 'ID', sortable: false, value: 'id' },
    { text: 'Source', sortable: false, value: 'source' },
    { text: 'PatientID', sortable: false, value: 'pid' }
  ]

  eHeaders = [
    { text: 'ID', sortable: false, value: 'id' },
    { text: 'UID', sortable: false, value: 'uid' },
    { text: 'Modality', sortable: false, value: 'modality' },
    { text: 'Eligible', sortable: false, value: 'eligible' },
    { text: 'Size', sortable: false, value: 'size' },
    { text: 'Status', sortable: false, value: 'status' }
  ]

  items = []
  selected: any = {}

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
    this.onLoading = true
    axios.get(`/api/subject/${item.id}`)
      .then(res => {
        this.selected = res.data
        this.viewDialog = true
        this.onLoading = false
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  addSubject() {
    this.selected = { udi: null, sex: '', birthday: '' }
    
    this.addDialog = true
    this.inError = false
  }

  submit() {
    if ((this.$refs.form as HTMLFormElement).validate())
      axios.post(`/api/subject`, this.selected)
        .then(res => {
          this.onPaginationChanged()
          this.addDialog = false
        }).catch(e => {
          this.addDialog = false
          this.error = e.message
          this.inError = true
        })
  }
}
</script>