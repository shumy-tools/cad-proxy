import 'vuetify/src/stylus/app.styl'

import Vue from 'vue'
import Vuetify from 'vuetify/lib'

//import Vuetify, { VApp, VGrid, VToolbar, VFooter, transitions } from 'vuetify/lib'
//import { Ripple } from 'vuetify/lib/directives'

//import { VNavigationDrawer } from 'vuetify/lib'

Vue.use(Vuetify, {
  /*components: {
    VApp, VGrid, VToolbar, VFooter, transitions,
    VNavigationDrawer
  },
  directives: {
    Ripple
  },*/
  iconfont: 'fa' //'md' || 'mdi' || 'fa' || 'fa4'
})
