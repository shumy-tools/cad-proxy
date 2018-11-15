<template>
  <div>
    <v-expansion-panel class="mb-2">
      <v-expansion-panel-content>
        <div slot="header">
          <v-icon>far fa-question-circle</v-icon>
          <span class="subheading ml-2">Model Diagram</span>
        </div>
        <v-img :src="require('@/assets/pull-push.png')"></v-img>
      </v-expansion-panel-content>
    </v-expansion-panel>

    <v-alert :value="inError" type="error">
      {{error}}
    </v-alert>

    <v-card class="elevation-1">
      <v-card-title class="title">
        <span class="mr-5">Cypher Query</span>
        <v-textarea auto-grow autofocus clearable clear-icon="fas fa-eraser" rows="1" label="Query"
          v-model="query" :error-messages="queryError" @keydown.shift.enter.exact.prevent @keyup.shift.enter="doQuery"></v-textarea>
        <v-tooltip bottom>
          <v-btn slot="activator" color="primary" @click="doQuery">go</v-btn>
          <span>Shift+Enter to submit</span>
        </v-tooltip>
      </v-card-title>
      
      <v-data-table hide-actions :headers="data.headers" :items="data.results" :loading="onLoading">
        <v-progress-linear slot="progress" indeterminate></v-progress-linear>
        <template slot="items" slot-scope="props">
            <td v-for="h in data.headers" :key="h.value">{{ props.item[h.value] }}</td>
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

  data = {
    headers: [ { text: 'No Result Headers', sortable: false, value: 'no-headers' }  ],
    results: []
  }

  doQuery() {
    this.queryError = ''
    this.onLoading = true
    axios.post(`/api/cypher`, { "query": this.query })
      .then(res => {
        this.data = {
          headers: res.data.headers.map(it => {return { text: it, value: it, sortable: false }}),
          results: res.data.results
        }

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
}
</script>