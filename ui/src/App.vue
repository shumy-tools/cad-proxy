<template>
  <v-app>
    <v-dialog v-model="viewDialog">
      <v-card>
        <v-card-title class="headline grey lighten-2" primary-title>
          <span class="font-weight-bold">{{selected.edge}}</span>
        </v-card-title>

        <v-alert :value="inError" type="error">
          {{error}}
        </v-alert>

        <v-form ref="form" v-model="validForm">
          <v-container fluid grid-list-md>
            <v-layout row wrap>
                <!--ID/UDI-->
                <v-flex xs12 sm1>
                  <v-text-field disabled v-model="selected.id" label="ID"></v-text-field>
                </v-flex>
                <v-flex xs12 sm11>
                  <v-text-field v-if="selected.edge == 'Target'" :disabled="!selected.create" v-model="selected.udi" label="UDI"
                    :rules="rules.udi"></v-text-field>
                </v-flex>

                <!--ACTIVE-->
                <v-flex xs12 sm4>
                  <v-switch v-model="selected.active" label="Active"></v-switch>
                </v-flex>
                <v-flex xs12 sm8>
                  <v-text-field v-if="selected.active" disabled v-model="selected.aTime" label="Active-Since"></v-text-field>
                </v-flex>

                <!--Name-->
                <v-flex xs12 md4>
                  <v-text-field v-if="selected.edge == 'Source'" v-model="selected.aet" label="AET"
                    :rules="rules.name"></v-text-field>
                
                  <v-text-field v-if="selected.edge == 'Target'" v-model="selected.name" label="Name"
                    :rules="rules.name"></v-text-field>
                </v-flex>

                <!--Source-->
                <v-flex v-if="selected.edge == 'Source'" xs12 md4>
                  <v-text-field v-model="selected.host" label="Host"
                    :rules="rules.host"></v-text-field>
                </v-flex>
                <v-flex v-if="selected.edge == 'Source'" xs12 md4>
                  <v-text-field v-model="selected.port" label="Port"
                    :rules="rules.port"></v-text-field>
                </v-flex>

                <!--Target-->
                <v-flex v-if="selected.edge == 'Target'" xs12 md4>
                  <v-select :items="modalities" item-value="name" item-text="desc" v-model="selected.modalities" label="Modalities" multiple
                    :rules="rules.modalities">
                    <template slot="selection" slot-scope="{ item, index }">
                      <span v-if="index <= 3" class="mr-2">{{ item.name }}</span>
                      <span v-if="index === 4" class="grey--text caption">(+{{ selected.modalities.length - 4 }} more)</span>
                    </template>
                  </v-select>
                </v-flex>
            </v-layout>

            <v-toolbar flat dense color="white">
              <v-spacer></v-spacer>
              <v-btn v-if="!selected.create" flat @click="remove">remove</v-btn>
              <v-btn :disabled="!validForm" color="primary" @click="submit">submit</v-btn>
            </v-toolbar>
          </v-container>
        </v-form>
      </v-card>
    </v-dialog>

    <v-navigation-drawer fixed clipped class="grey lighten-4" app v-model="drawer">
      <v-list dense class="grey lighten-4">
        
        <!--DICOM Section-->
        <v-list-tile>
          <v-list-tile-action>
            <v-icon color="primary">fas fa-search</v-icon>
          </v-list-tile-action>
          <v-list-tile-content>
            <router-link tag="button" to="/dicom-find">DICOM Find</router-link>
          </v-list-tile-content>
        </v-list-tile>

        <v-divider dark class="my-2"></v-divider>

        <!--Sources Section-->
        <v-layout row align-center>
          <v-flex xs6>
            <v-subheader class="subheading">Sources</v-subheader>
          </v-flex>
        </v-layout>
        
          <!--Source List-->
          <v-list-tile v-for="(item, i) in items.sources" :key="`src-${i}`" class="ml-3">
            <v-list-tile-action>
              <v-icon small :color="item.active ? 'primary' : ''">fas fa-download</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <a @click="openEdge('Source', item)">{{ item.aet }}</a>
            </v-list-tile-content>
          </v-list-tile>

          <v-list-tile class="ml-3">
            <v-list-tile-action>
              <v-icon small color="primary">fas fa-plus</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <a @click="newEdge('Source')">New</a>
            </v-list-tile-content>
          </v-list-tile>

        <!--Targets Section-->
        <v-layout row align-center>
          <v-flex xs6>
            <v-subheader class="subheading">Targets</v-subheader>
          </v-flex>
        </v-layout>
        
          <!--Target List-->
          <v-list-tile v-for="(item, i) in items.targets" :key="`trg-${i}`" class="ml-3">
            <v-list-tile-action>
              <v-icon small :color="item.active ? 'primary' : ''">fas fa-upload</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <a @click="openEdge('Target', item)">{{ item.name }}</a>
            </v-list-tile-content>
          </v-list-tile>

          <v-list-tile class="ml-3">
            <v-list-tile-action>
              <v-icon small color="primary">fas fa-plus</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <a @click="newEdge('Target')">New</a>
            </v-list-tile-content>
          </v-list-tile>

        <v-divider dark class="my-2"></v-divider>
        
        <!--Settings Section-->
        <v-layout row align-center>
          <v-flex xs6>
            <v-subheader class="subheading">Settings</v-subheader>
          </v-flex>
        </v-layout>

          <v-list-tile>
            <v-list-tile-action>
              <v-icon color="primary">fas fa-cog</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <router-link tag="button" to="/keys">Keys</router-link>
            </v-list-tile-content>
          </v-list-tile>

          <v-list-tile>
            <v-list-tile-action>
              <v-icon color="primary">fas fa-user-circle</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <router-link tag="button" to="/users">Users</router-link>
            </v-list-tile-content>
          </v-list-tile>

      </v-list>
    </v-navigation-drawer>

    <v-toolbar app dense fixed clipped-left class="theme-bg-color">
      <v-toolbar-side-icon @click.native="drawer = !drawer"></v-toolbar-side-icon>
      <span class="title ml-2 mr-3">CAD-Proxy</span>
      
      <v-tooltip bottom>
        <v-btn icon slot="activator" to="/" class="no-border-radius">
          <v-icon>fas fa-user</v-icon>
        </v-btn>
        <span>Subject List</span>
      </v-tooltip>

      <v-tooltip bottom>
        <v-btn icon slot="activator" to="/pull-list" class="no-border-radius">
          <v-icon>fas fa-download</v-icon>
        </v-btn>
        <span>Pull List</span>
      </v-tooltip>

      <v-tooltip bottom>
        <v-btn icon slot="activator" to="/push-list" class="no-border-radius">
          <v-icon>fas fa-upload</v-icon>
        </v-btn>
        <span>Push List</span>
      </v-tooltip>
      
      <v-tooltip bottom>
        <v-btn icon slot="activator" to="/pending-data" class="no-border-radius">
          <v-icon>fas fa-clipboard-list</v-icon>
        </v-btn>
        <span>Pending Data</span>
      </v-tooltip>
      
      <v-tooltip bottom>
        <v-btn icon slot="activator" to="/schedulers" class="no-border-radius">
          <v-icon>fas fa-clock</v-icon>
        </v-btn>
        <span>Schedulers</span>
      </v-tooltip>

      <!--<v-text-field solo-inverted flat class="mt-2" label="Search" prepend-icon="fas fa-search"></v-text-field>-->
      
      <v-spacer></v-spacer>

      <v-toolbar-items>
        <v-menu offset-y content-class="no-border-radius elevation-4">
          <v-btn flat slot="activator" class="no-border-radius text-capitalize">
            <v-avatar size="36">
              <img src="https://randomuser.me/api/portraits/men/1.jpg">
            </v-avatar>
            <span class="ml-2">User Name</span>
          </v-btn>
          <v-list dense class="theme-bg-color">
            <v-list-tile @click="">
              <v-list-tile-action>
                <v-icon>fas fa-sign-out-alt</v-icon>
              </v-list-tile-action>
              <v-list-tile-title>Sign-Out</v-list-tile-title>
            </v-list-tile>
          </v-list>
        </v-menu>
      </v-toolbar-items>
    </v-toolbar>

    <v-content>
      <v-container fluid>
        <router-view></router-view>
      </v-container>
    </v-content>
    
    <v-footer app class="theme-bg-color">
      <span class="white--text ml-4">Bioinformatics &copy; 2018</span>
    </v-footer>
  </v-app>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import axios from 'axios';

@Component
export default class App extends Vue {
  drawer = false
  
  inError = false
  error = "none"

  viewDialog = false
  
  validForm = false
  rules = {
    udi: [
      v => !!v || 'Required field'
      //TODO: validate with CRC!
    ],
    name: [
      v => !!v || 'Required field'
    ],
    host: [
      v => !!v || 'Required field'
    ],
    port: [
      v => !!v || 'Required field',
      v => /^([1-9][0-9]*)$/.test(v) || 'Only numeric values'
    ],
    modalities: [
      v => v.length != 0 || 'Required at least one'
    ]
  }

  original: any = null
  selected: any = {
    create: false,
    edge: 'None'
  }

  modalities = [ { name: '', desc: '' } ]
  items = { sources: [], targets: [] }
 
  created() {
    axios.get(`/api/edges`)
      .then(res => {
        this.items = res.data
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })

    axios.get(`/api/keys/dicom/modalities`)
      .then(res => {
        this.modalities = res.data.map(it => {
          let splitIndex = it.indexOf("-")
          let name = it.substring(0, splitIndex)
          let desc = it.substring(splitIndex + 1, it.length)
          return { "name": name, "desc": `(${name}) ${desc}` }
        })
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  openEdge(edge: string, item: any) {
    this.original = item
    
    this.selected = JSON.parse(JSON.stringify(item))
    this.selected.create = false
    this.selected.edge = edge

    this.viewDialog = true
    this.inError = false
  }

  newEdge(edge: string) {
    this.original = null
    
    this.selected = { create: true, edge: edge, active: true, aTime: null, modalities: [] }
    
    this.viewDialog = true
    this.inError = false
  }

  remove() {
    axios.delete(`/api/edges/${this.selected.edge}/${this.selected.id}`)
      .then(res => {
        this.removeSelected()
        this.viewDialog = false
      }).catch(e => {
        this.error = e.message
        this.inError = true
      })
  }

  submit() {
    delete this.selected.aTime
    delete this.selected.create

    if ((this.$refs.form as HTMLFormElement).validate())
      axios.post(`/api/edges`, this.selected)
        .then(res => {
          this.updateSelected(res.data)
          this.viewDialog = false
        }).catch(e => {
          this.error = e.message
          this.inError = true
        })
  }

  private updateSelected(data: any) {
    let list
    if (this.selected.edge == 'Source')
      list = 'sources'
    else
      list = 'targets'

    this.selected.id = data.id
    this.selected.aTime = data.aTime
    
    if (this.original !== null) {
      let index = this.items[list].indexOf(this.original)
      this.items[list][index] = this.selected
    } else {
      this.items[list].push(this.selected)
    }
  }

  private removeSelected() {
    let list
    if (this.selected.edge == 'Source')
      list = 'sources'
    else
      list = 'targets'
    
    let index = this.items[list].indexOf(this.original)
    this.items[list].splice(index, 1)
  }
}
</script>
