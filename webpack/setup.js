import Vue from 'vue'
import ActionCable from 'actioncable'
import axios from 'axios'
import VueLocalStorage from 'vue-localstorage'

import config from 'components/config'
import debugRenders from 'components/debug_renders'
import trainingVideo from 'components/training_video'
import webcamVideo from 'components/webcam_video'

const cable = ActionCable.createConsumer('ws://localhost:28080/cable')

Vue.prototype.$http = axios
Vue.prototype.$cable = cable
Vue.use(VueLocalStorage)

export default function (template) {
  return new Vue({
    template,
    computed: {
      // This is a utitly to add classes to your container
      wrapperClass () { return '' }
    },
    // Then include them here:
    components: {
      config,
      debugRenders,
      trainingVideo,
      webcamVideo
    }
  })
}
