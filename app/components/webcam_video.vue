<template>
  <div>
    <input type="radio" id="boundary" value="boundary" v-model="clickMode" @change="resetClickMode">
    <label for="boundary">Set boundary</label>
    <input type="radio" id="origin" value="origin" v-model="clickMode" @change="resetClickMode">
    <label for="origin">Set origin</label>
    <button type="submit" @click="snap">snap</button>
    <p>{{nextClick}}</p>
    <p>{{boundaryStatus}}</p>
    <vue-webcam ref='webcam' v-bind:width="800" v-bind:height="600"></vue-webcam>
  </div>
</template>

<style scoped>
</style>

<script>
import VueWebcam from 'vue-webcam'

export default {
  components: { VueWebcam },
  data () {
    return {
      clickMode: 'boundary',
      prevClick: undefined,
      boundary: { topLeft: undefined, bottomRight: undefined },
      videoChannel: null,
      configChannel: null,
      trainingRenderUri: 'data:image/png;base64,'
    }
  },
  methods: {
    resetClickMode: function resetClickMode () {
      this.prevClick = undefined
    },

    setDefaultTrackBoundary: function setDefaultTrackBoundary () {
      const videoElement = this.$refs.video
      this.boundary.topLeft = { x: 0, y: 0 }
      this.boundary.bottomRight = { x: videoElement.videoWidth, y: videoElement.videoHeight }
    },

    click: function click (event) {
      const rect = this.$refs.video.getBoundingClientRect()
      const point = { x: event.clientX - rect.left, y: event.clientY - rect.top }

      if (this.clickMode === 'boundary') {
        if (this.prevClick === undefined) {
          this.prevClick = point
        } else {
          this.boundary.topLeft = this.prevClick
          this.boundary.bottomRight = point
          this.prevClick = undefined
        }
      } else if (this.clickMode === 'origin') {
        const topLeft = this.boundary.topLeft
        const boundedOrigin = { origin_x: point.x - topLeft.x, origin_y: point.y - topLeft.y }
        this.configChannel.perform('update', { new_config: { world_transform: boundedOrigin } })
      }
    },

    snap: function snap () {
      const webcam = this.$refs.webcam
      if (webcam.hasUserMedia) {
        const imageUri = webcam.getPhoto()
        const createdAt = Date.now()
        this.videoChannel.perform('frame', { image_uri: imageUri, created_at: createdAt })
      }
    }
  },
  computed: {
    nextClick: function nextClick () {
      if (this.clickMode === 'boundary') {
        const where = this.prevClick === undefined ? 'top left' : 'bottom right'
        return `Click ${where}`
      }
      return 'Click origin'
    },

    boundaryStatus: function boundaryStatus () {
      if (this.boundary.topLeft === undefined) {
        return 'Boundary undefined'
      }

      return `Boundary from ${this.boundary.topLeft.x}, ${this.boundary.topLeft.y} to ${this.boundary.bottomRight.x}, ${this.boundary.bottomRight.y}`
    }
  },
  created: function created () {
    const that = this
    this.videoChannel = this.$cable.subscriptions.create({ channel: 'VideoChannel' }, {
      connected () {
        that.snap()
      },
      received (data) {
        if (data.action === 'snap') {
          that.snap()
        }
      }
    })
    this.configChannel = this.$cable.subscriptions.create({ channel: 'ConfigChannel' }, {})
  }
}
</script>
