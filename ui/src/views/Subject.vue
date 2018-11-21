<template>
  <div>
    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>
    
    <v-container fluid grid-list-md>
      <v-layout row wrap>
        <!--ID/UDI-->
        <v-flex xs12 sm1>
          <v-text-field disabled v-model="selected.id" label="ID"></v-text-field>
        </v-flex>
        <v-flex xs12 sm11>
          <v-text-field disabled v-model="selected.udi" label="UDI"></v-text-field>
        </v-flex>

        <!--ACTIVE-->
        <v-flex xs12 sm4>
          <v-switch readonly v-model="selected.active" label="Active"></v-switch>
        </v-flex>
        <v-flex xs12 sm8>
          <v-text-field v-if="selected.active" disabled v-model="selected.aTime" label="Active-Since"></v-text-field>
        </v-flex>

        <!--Sex/Birthday-->
        <v-flex xs12 md4>
          <v-text-field disabled v-model="selected.sex" label="Sex"></v-text-field>
        </v-flex>
        <v-flex xs12 md8>
          <v-text-field disabled v-model="selected.birthday" label="Birthday"></v-text-field>
        </v-flex>
      </v-layout>
    </v-container>

    <v-card class="mb-2">
      <v-card-title class="title">
        Consents
      </v-card-title>
      
      <v-data-table hide-actions :headers="cHeaders" :items="selected.consents">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
          <td v-for="h in cHeaders" :key="h.value">{{ props.item[h.value] }}</td>
        </template>
      </v-data-table>
    </v-card>

    <v-card class="mb-2">
      <v-card-title class="title">
        Associations
      </v-card-title>
      
      <v-data-table hide-actions :headers="headers" :items="selected.associations">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
          <td>{{ props.item.source }}</td>
          <td>
            <a @click="viewPatient(props.item)">{{ props.item.pid }}</a>
          </td>
          <td>
            <v-icon v-if="!props.item.contains" small color="primary" @click="deAssociate(props.item)">far fa-minus-circle</v-icon>
          </td>
        </template>
      </v-data-table>
    </v-card>

    <v-card>
      <v-card-title class="title">
        <v-textarea auto-grow clearable clear-icon="fas fa-times" rows="1" label="Find"
          v-model="query" :error-messages="queryError" @keydown.tab="tab($event)" @keydown.shift.enter.exact.prevent @keyup.shift.enter="find"></v-textarea>
        <v-tooltip bottom>
          <v-btn slot="activator" color="primary" @click="find">go</v-btn>
          <span>Shift+Enter to submit</span>
        </v-tooltip>
      </v-card-title>
      
      <v-data-table hide-actions :headers="sHeaders" :items="queryResults" :loading="onLoading">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
          <tr :class="props.item.contains ? 'green lighten-3 simple-tr' : 'simple-tr'">
            <td>{{ props.item.head ? props.item.source : '-'}}</td>
            <td v-for="h in sHeaders" v-if="h.value != 'source' && h.value != 'add'" :key="h.value">{{ props.item[h.value] }}</td>
            <td>
              <v-icon v-if="!props.item.contains" small color="primary" @click="associate(props.item)">far fa-plus</v-icon>
            </td>
          </tr>
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
  selected = { id: 0, udi: '', active: false, aTime: '', sex: '', birthday: '', consents: [], associations: [] }

  inError = false
  error = ''

  onLoading = false
  
  query = ''
  queryError = ''
  queryResults = []

  cHeaders = [
    { text: 'Purpose', sortable: false, value: 'purpose' },
    { text: 'Targets', sortable: false, value: 'targets' },
    { text: 'Modalities', sortable: false, value: 'modalities' },
    { text: 'Active', sortable: false, value: 'active' },
    { text: 'Active-Since', sortable: false, value: 'aTime' }
  ]

  sHeaders = [
    { text: 'Source', sortable: false, value: 'source' },
    { text: 'PID', sortable: false, value: 'pid' },
    { text: 'Name', sortable: false, value: 'name' },
    { text: 'Sex', sortable: false, value: 'sex' },
    { text: 'Birthday', sortable: false, value: 'birthday' },
    { text: 'Add', sortable: false, value: 'add' }
  ]

  headers = [
    { text: 'Source', sortable: false, value: 'source' },
    { text: 'PID', sortable: false, value: 'pid' },
    { text: 'Remove', sortable: false, value: 'remove' }
  ]

  beforeCreate() {
    axios.get(`/api/subject/udi/${this.$route.query.udi}`)
      .then(res => {
        this.selected = res.data
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  find() {
    this.queryError = ''
    this.onLoading = true
    axios.post(`/api/pfind`, { "query": this.query })
      .then(res => {
        this.queryResults = this.transform(res.data)
        this.onLoading = false
      }).catch(e => {
        this.onLoading = false
        let eo = JSON.parse(JSON.stringify(e))
        if (eo.response.status == 400) {
          this.queryError = eo.response.data
        } else {
          this.error = e.message
          this.inError = true
        }
      })
  }

  associate(patient: any) {
    axios.post(`/api/subject/associate`, { "udi": this.selected.udi, "source": patient.source, "pid": patient.pid })
      .then(res => {
        patient.contains = true
        this.selected.associations.push({ "source": patient.source, "pid": patient.pid })
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  deAssociate(patient: any) {
    axios.delete(`/api/subject/associate/${this.selected.udi}/${patient.source}/${patient.pid}`)
      .then(res => {
        this.queryResults
          .filter(it => it.source == patient.source && it.pid == patient.pid)
          .forEach(it => it.contains = false)

        let index = this.selected.associations.indexOf(patient)
        this.$delete(this.selected.associations, index)
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  viewPatient(patient: any) {
    this.query = "PID : " + patient.pid
    this.find()
  }

  tab(e: KeyboardEvent) {
    e.preventDefault()
    let trg = e.target as HTMLTextAreaElement

    let sel = trg.selectionStart
    this.query = this.query.substring(0, sel) + "  " + this.query.substring(sel, this.query.length)
    setTimeout(_ => trg.selectionStart = trg.selectionEnd = sel + 2, 1)
  }

  private contains(source: string, pid: string) {
    return this.selected.associations
      .filter(it => it.source == source && it.pid == pid)
      .length !== 0
  }

  private transform(results: { source: string, pid: string, name: string, sex: string, birthday: string }[]) {
    let lastSource = ''
    return results.map(it => {
      let item = {
        "head": it.source != lastSource,
        "contains": this.contains(it.source, it.pid),
        "source": it.source,
        "pid": it.pid,
        "name": it.name,
        "sex": it.sex,
        "birthday": it.birthday
      }

      lastSource = it.source
      return item
    })
  }
}
</script>