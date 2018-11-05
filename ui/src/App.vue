<template>
  <v-app>
    <v-navigation-drawer fixed clipped class="grey lighten-4" app v-model="drawer">
      <v-list dense class="grey lighten-4">
        <template v-for="(item, i) in items">
          <v-layout row v-if="item.heading" align-center :key="i">
            <v-flex xs6>
              <v-subheader v-if="item.heading" class="title">
                {{ item.heading }}
              </v-subheader>
            </v-flex>
          </v-layout>
          <v-divider dark v-else-if="item.divider" class="my-3" :key="i"></v-divider>
          <v-list-tile :key="i" v-else>
            <v-list-tile-action>
              <v-icon>{{ item.icon }}</v-icon>
            </v-list-tile-action>
            <v-list-tile-content>
              <router-link tag="button" :to="item.to">{{ item.text }}</router-link>
            </v-list-tile-content>
          </v-list-tile>
        </template>
      </v-list>
    </v-navigation-drawer>

    <v-toolbar app dense fixed clipped-left class="theme-bg-color">
      <v-toolbar-side-icon @click.native="drawer = !drawer"></v-toolbar-side-icon>
      <span class="title ml-3 mr-5">CAD-<span class="text">Proxy</span></span>
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
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class App extends Vue {
  drawer = null
  items = [
    //{ icon: 'fas fa-bell', text: 'Reminders', to: '/reminders' },
    
    { divider: true },
    { heading: 'Sources' },
    { icon: 'fas fa-plus', text: 'New Source', to: '/new-source' },

    //{ divider: true },
    { heading: 'Targets' },
    { icon: 'fas fa-plus', text: 'New Target', to: '/new-target' },
    
    { divider: true },
    { icon: 'fas fa-cog', text: 'Settings', to: '/settings' }
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
