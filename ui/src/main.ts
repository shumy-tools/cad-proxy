import './plugins/vuetify'
import './base.scss'

import Vue from 'vue'
import App from './App.vue'
import router from './router'
import axios from 'axios'

Vue.config.productionTip = false

//axios.defaults.headers.common['Authorization'] = 'Bearer <JWT-HERE>'

new Vue({
  router,
  render: h => h(App)
}).$mount('#app')
