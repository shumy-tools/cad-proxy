<template>
    <v-card>
      <v-card-title class="headline grey lighten-2" primary-title>
        <span class="font-weight-bold">Keys</span>
      </v-card-title>

      <v-card-text>
        <v-alert :value="inError" type="error">
          {{error}}
        </v-alert>

        <v-snackbar v-model="snack" :timeout="3000" :color="snackColor">
          {{ snackText }}
          <v-btn flat @click="snack = false">Close</v-btn>
        </v-snackbar>

        <v-data-table hide-actions :headers="headers" :items="items">
          <template slot="items" slot-scope="props">
            <tr :class="props.item.header ? 'grey lighten-2' : ''">
              <td>
                <span class="subheading">{{ props.item.header }}</span>
              </td>
              <td>{{ props.item.key }}</td>
              <td>
                <v-icon v-if="props.item.type && props.item.type.startsWith('Set')" @click="">fas fa-list-ul</v-icon>

                <v-edit-dialog v-if="props.item.type == 'String' || props.item.type == 'Integer'" :return-value.sync="props.item.value" lazy @save="save">
                  {{ props.item.value }}
                  <v-text-field slot="input" v-model="props.item.value" label="Edit" single-line></v-text-field>
                </v-edit-dialog>
              </td>
            </tr>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class Keys extends Vue {
  inError = false
  error = "none"

  snack = false
  snackColor = ''
  snackText = ''

  headers = [
    { text: 'Group', sortable: false, value: 'group' },
    { text: 'Key', sortable: false, value: 'key' },
    { text: 'Value', sortable: false, value: 'value' }
  ]

  items = []

  created() {
    axios.get(`/api/keys`)
      .then(res => {
        let lastGroup: string = null
        res.data.forEach(it => {
          if (it.group != lastGroup) {
            lastGroup = it.group
            this.items.push({ header: lastGroup })
          }

          this.items.push(it)
        })
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  save () {
    this.snack = true
    this.snackColor = 'success'
    this.snackText = 'Data saved'
  }
}
</script>