import Vue from 'vue'
import Router from 'vue-router'

import SubjectList from './views/SubjectList.vue'
import PullList from './views/PullList.vue'
import PushList from './views/PushList.vue'
import PendingData from './views/PendingData.vue'
import DicomFind from './views/DicomFind.vue'
import Keys from './views/Keys.vue'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/',
      name: 'subject-list',
      component: SubjectList
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
      path: '/pending-data',
      name: 'pending-data',
      component: PendingData
    },
    {
      path: '/dicom-find',
      name: 'dicom-find',
      component: DicomFind
    },
    {
      path: '/keys',
      name: 'keys',
      component: Keys
    },

    {
      path: '/about',
      name: 'about',
      component: () => import('./views/About.vue')
    }
  ]
})
