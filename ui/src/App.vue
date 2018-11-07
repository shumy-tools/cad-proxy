<template>
  <v-app>
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
            <v-subheader class="title">Sources</v-subheader>
          </v-flex>
        </v-layout>
        
          <!--Source List-->
          <v-list-tile v-for="(item, i) in sources" :key="`src-${i}`" class="ml-3">
            <v-list-tile-action>
              <v-icon small>fas fa-download</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <router-link tag="button" :to="item.to">{{ item.label }}</router-link>
            </v-list-tile-content>
          </v-list-tile>

          <v-list-tile>
            <v-list-tile-action>
              <v-icon color="primary">fas fa-plus</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <router-link tag="button" to="/new-source">New</router-link>
            </v-list-tile-content>
          </v-list-tile>

        <!--Targets Section-->
        <v-layout row align-center>
          <v-flex xs6>
            <v-subheader class="title">Targets</v-subheader>
          </v-flex>
        </v-layout>
        
          <!--Target List-->
          <v-list-tile v-for="(item, i) in targets" :key="`trg-${i}`" class="ml-3">
            <v-list-tile-action>
              <v-icon small>fas fa-upload</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <router-link tag="button" :to="item.to">{{ item.label }}</router-link>
            </v-list-tile-content>
          </v-list-tile>

          <v-list-tile>
            <v-list-tile-action>
              <v-icon color="primary">fas fa-plus</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <router-link tag="button" to="/new-target">New</router-link>
            </v-list-tile-content>
          </v-list-tile>

        <v-divider dark class="my-2"></v-divider>
        
        <!--Settings Section-->
        <v-layout row align-center>
          <v-flex xs6>
            <v-subheader class="title">Settings</v-subheader>
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
      <span class="title ml-2 mr-3">CAD-<span class="text">Proxy</span></span>
      
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
      <v-container>
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

@Component
export default class App extends Vue {
  drawer = false

  sources = [
    { label: 'Source-X', to: '/source-x' },
    { label: 'Source-Y', to: '/source-y' }
  ]

  targets = [
    { label: 'Target-X', to: '/target-x' },
    { label: 'Target-Y', to: '/target-y' }
  ]
}
</script>

<style lang="scss">
.text {
  font-weight: 400;
}

.no-border-radius {
  border-radius: 0px;
}
</style>
