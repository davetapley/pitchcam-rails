import Vue from 'vue'
import ActionCable from 'actioncable'
import axios from 'axios'

import debugRenders from 'components/debug_renders'
import trainingVideo from 'components/training_video'

const cable = ActionCable.createConsumer('ws://localhost:28080/cable')

Vue.prototype.$http = axios
Vue.prototype.$cable = cable

export default function (template) {
  return new Vue({
    template,
    computed: {
      // This is a utitly to add classes to your container
      wrapperClass () { return '' }
    },
    // Then include them here:
    components: {
      debugRenders,
      trainingVideo
    }
  })
}
