import Vue from 'vue'
import Router from 'vue-router'

import Home from './views/Home.vue'
import PullList from './views/PullList.vue'
import PushList from './views/PushList.vue'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home
    },
    {
      path: '/pull-list',
      name: 'pull-list',
      component: PullList
    },
    {
      path: '/push-list',
      name: 'push-list',
      component: PushList
    },

    {
      path: '/about',
      name: 'about',
      component: () => import('./views/About.vue')
    }
  ]
})
