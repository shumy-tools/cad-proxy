import Vue from 'vue'
import Router from 'vue-router'

import Subject from './views/Subject.vue'
import SubjectList from './views/SubjectList.vue'
import PullList from './views/PullList.vue'
import PushList from './views/PushList.vue'
import PendingData from './views/PendingData.vue'
import DicomFind from './views/DicomFind.vue'
import Settings from './views/Settings.vue'
import Model from './views/Model.vue'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/',
      name: 'subject-list',
      component: SubjectList
    },
    {
      path: '/subject',
      name: 'subject',
      component: Subject
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
      path: '/settings',
      name: 'settings',
      component: Settings
    },
    {
      path: '/model',
      name: 'model',
      component: Model
    },

    {
      path: '/about',
      name: 'about',
      component: () => import('./views/About.vue')
    }
  ]
})
