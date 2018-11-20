<template>
  <div>
    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>

    <v-card class="elevation-1">
      <v-card-title class="title">
        <span class="mr-5">DICOM</span>
        <v-textarea auto-grow autofocus clearable clear-icon="fas fa-times" rows="1" label="Find"
          v-model="query" :error-messages="queryError" @keydown.tab="tab($event)" @keydown.shift.enter.exact.prevent @keyup.shift.enter="find"></v-textarea>
        <v-tooltip bottom>
          <v-btn slot="activator" color="primary" @click="find">go</v-btn>
          <span>Shift+Enter to submit</span>
        </v-tooltip>
      </v-card-title>
      
      <v-data-table hide-actions item-key="index" :headers="headers" :items="items" :loading="onLoading">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
          <tr :class="props.item.header ? 'grey lighten-2 simple-tr' : 'simple-tr'">
            <td>{{ props.item.header ? props.item.source : '-'}}</td>
            <td v-for="h in headers" v-if="h.value != 'source'" :key="h.value">{{ props.item[h.value] }}</td>
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
export default class DicomFind extends Vue {
  inError = false
  error = ''
  queryError = ''

  onLoading = false
  query = ''

  headers = [
    { text: 'Source', sortable: false, value: 'source' },
    { text: 'PatientID', sortable: false, value: 'pid' },
    { text: 'Birthday', sortable: false, value: 'birthday' },
    { text: 'Sex', sortable: false, value: 'sex' },
    { text: 'Series', sortable: false, value: 'series' }
  ]

  items = []

  find() {
    this.queryError = ''
    this.onLoading = true
    axios.post(`/api/dfind`, { "query": this.query })
      .then(res => {
        this.items = this.transform(res.data.results)
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

  tab(e: KeyboardEvent) {
    e.preventDefault()
    let trg = e.target as HTMLTextAreaElement

    let sel = trg.selectionStart
    this.query = this.query.substring(0, sel) + "  " + this.query.substring(sel, this.query.length)
    setTimeout(_ => trg.selectionStart = trg.selectionEnd = sel + 2, 1)
  }

  private transform(results: {
    [sid:string]: {
      [pid:string]: {
        birthday: string,
        sex: string,
        studies: {
          [suid:string]: {
            date: string,
            series: {
              [euid:string]: {
                date: string,
                modality: string,
                number: number
              }
            }
          }
        }
      }
    }
  }) {
    let iRes = []

    let lastSource = ''
    let index = 0
    Object.keys(results).forEach(sid => {
      Object.keys(results[sid]).forEach(pid => {
        let patient = results[sid][pid]
        Object.keys(patient.studies).forEach(suid => {
          let study = patient.studies[suid]
          iRes.push({
            "index": index,
            "header": lastSource != sid,
            "source": sid,
            "pid": pid,
            "birthday": patient.birthday,
            "sex": patient.sex,
            "series": Object.keys(study.series).length
          })

          lastSource = sid
          index++
        })
      })
    })

    return iRes
  }
}
</script>