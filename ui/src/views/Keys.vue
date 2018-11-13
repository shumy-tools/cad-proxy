<template>
  <div>
    <v-dialog v-model="viewDialog">
      <v-card>
        <v-card-title class="headline grey lighten-2" primary-title>
          <span>
            <span class="font-weight-bold">Key:</span>
            {{selected.group}} - {{selected.key}}
          </span>
        </v-card-title>

        <v-card-text>
          <v-list class="list-border">
              <v-list-tile>
                <v-list-tile-content>
                  <v-list-tile-title style="height: 100%">
                    <v-toolbar flat color="white" class="toolbar-p-0">
                      <v-toolbar-title class="title">Items</v-toolbar-title>
                      <v-spacer></v-spacer>
                      <v-edit-dialog lazy @open="newItem = ''" @save="addItem" style="width: auto">
                        <v-btn color="primary">add</v-btn>
                        <v-text-field slot="input" v-model="newItem" label="Edit" single-line></v-text-field>
                      </v-edit-dialog>
                    </v-toolbar>
                  </v-list-tile-title>
                </v-list-tile-content>
              </v-list-tile>

              <v-data-table hide-actions :headers="iHeaders" :items="selected.value">
                <template slot="items" slot-scope="props">
                  <td>
                    <v-edit-dialog lazy @open="newItem = props.item" @save="changeItem(props.item)">
                      {{ props.item }}
                      <v-text-field slot="input" v-model="newItem" label="Edit" single-line></v-text-field>
                    </v-edit-dialog>
                  </td>
                  <td>
                    <v-icon small @click="removeItem(props.item)">fas fa-trash</v-icon>
                  </td>
                </template>
              </v-data-table>
          </v-list>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-card>
      <v-card-title class="headline grey lighten-2" primary-title>
        <span class="font-weight-bold">Keys</span>
      </v-card-title>

      <v-card-text>
        <v-alert :value="inError" type="error">
          {{error}}
        </v-alert>
        
        <v-data-table hide-actions :headers="headers" :items="items">
          <template slot="items" slot-scope="props">
            <tr :class="props.item.header ? 'grey lighten-2 simple-tr' : 'simple-tr'">
              <td>
                <span class="subheading">{{ props.item.header }}</span>
              </td>
              <td>{{ props.item.key }}</td>
              <td>
                <v-icon v-if="props.item.type == 'set'" @click="viewKey(props.item)">fas fa-list-ul</v-icon>

                <v-edit-dialog v-if="props.item.type == 'nat'" lazy @open="newValue = props.item.value" @save="save(props.item, true)">
                  {{ props.item.value }}
                  <v-text-field slot="input" v-model="newValue" label="Edit" single-line></v-text-field>
                </v-edit-dialog>
              </td>
            </tr>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
  </div>
</template>

<script lang="ts">
import { Component, Watch, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class Keys extends Vue {
  inError = false
  error = "none"

  newValue = null
  newItem = null

  viewDialog = false

  headers = [
    { text: 'Group', sortable: false, value: 'group' },
    { text: 'Key', sortable: false, value: 'key' },
    { text: 'Value', sortable: false, value: 'value' }
  ]

  iHeaders = [
    { text: 'Value', sortable: false, value: 'value' },
    { text: 'Remove', sortable: false, value: 'remove' }
  ]

  items = []
  selected: any = {}

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

  viewKey(key: any) {
    this.viewDialog = true
    this.selected = key
  }

  removeItem(item: any) {
    let index = this.selected.value.indexOf(item)

    this.newValue = JSON.parse(JSON.stringify(this.selected.value))
    this.newValue.splice(index, 1)

    this.save(this.selected, false)
  }

  addItem() {
    this.newValue = JSON.parse(JSON.stringify(this.selected.value))
    this.newValue.push(this.newItem)
    
    this.save(this.selected, false)
  }

  changeItem(item: any) {
    let index = this.selected.value.indexOf(item)

    this.newValue = JSON.parse(JSON.stringify(this.selected.value))
    this.newValue[index] = this.newItem

    this.save(this.selected, false)
  }

  save(key: any, close: boolean) {
    axios.post(`/api/keys`, { "group": key.group, "key": key.key, "value": this.newValue })
      .then(_ => {
        key.value = this.newValue
        this.viewDialog = !close
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }
}
</script>