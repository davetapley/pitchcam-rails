<template>
  <div>
    <input type="file" accept="video/*" @change="onFileChange" />
    <video id="training-video" controls ref="video" @loadedmetadata="setDefaultTrackBoundary" @click="click" @play="snap"></video>
    <br>

    <span>Click for:</span>

    <input type="radio" id="boundary" value="boundary" v-model="clickMode" @change="resetClickMode">
    <label for="boundary">boundary</label>

    <input type="radio" id="origin" value="origin" v-model="clickMode" @change="resetClickMode">
    <label for="origin">origin</label>

    <input type="radio" id="perspective" value="perspective" v-model="clickMode" @change="resetClickMode">
    <label for="perspective">perspective</label>
    <p>{{nextClick}}</p>
    <p>{{boundaryStatus}}</p>
  </div>
</template>

<style scoped>
</style>

<script>
import _ from 'lodash'

export default {
  data () {
    return {
      clickMode: 'boundary',
      prevClicks: [],
      boundary: { topLeft: undefined, bottomRight: undefined },
      videoChannel: null,
      configChannel: null,
      trainingRenderUri: 'data:image/png;base64,'
    }
  },
  methods: {
    onFileChange: function onFileChange (event) {
      const file = event.target.files[0]
      const type = file.type
      const canPlay = this.$refs.video.canPlayType(type) !== 'no'
      this.message = `Can play type "${type}" ${canPlay}`

      if (!canPlay) {
        return
      }

      const URL = window.URL || window.webkitURL
      const fileURL = URL.createObjectURL(file)
      const videoElement = this.$refs.video
      videoElement.src = fileURL
    },

    resetClickMode: function resetClickMode () {
      this.prevClicks.splice(0)
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
        if (this.prevClicks.length === 0) {
          this.prevClicks.push(point)
        } else {
          this.boundary.topLeft = this.prevClicks[0]
          this.boundary.bottomRight = point
          this.prevClicks.splice(0)
        }
      } else if (this.clickMode === 'origin') {
        const topLeft = this.boundary.topLeft
        const boundedOrigin = { origin_x: point.x - topLeft.x, origin_y: point.y - topLeft.y }
        this.configChannel.perform('update', { new_config: { world_transform: boundedOrigin } })
      } else if (this.clickMode === 'perspective') {
        if (this.prevClicks.length < 3) {
          this.prevClicks.push(point)
        } else {
          const topLeft = this.boundary.topLeft
          const boundedPoint = function boundedPoint (canvasPoint) {
            return { x: canvasPoint.x - topLeft.x, y: canvasPoint.y - topLeft.y }
          }
          const boundedPoints = _.map(this.prevClicks, boundedPoint)
          this.configChannel.perform('update', { new_config: { perspective: boundedPoints } })
          this.prevClicks.splice(0)
        }
      }
    },

    snap: function snap () {
      const videoElement = this.$refs.video
      if (videoElement && videoElement.readyState > 0) {
        const width = this.boundary.bottomRight.x - this.boundary.topLeft.x
        const height = this.boundary.bottomRight.y - this.boundary.topLeft.y

        const canvas = document.createElement('CANVAS')
        canvas.width = width
        canvas.height = height

        const srcX = this.boundary.topLeft.x
        const srcY = this.boundary.topLeft.y
        canvas.getContext('2d').drawImage(videoElement, srcX, srcY, width, height, 0, 0, width, height)

        const imageUri = canvas.toDataURL('img/jpeg')
        const createdAt = Date.now()
        this.videoChannel.perform('frame', { image_uri: imageUri, created_at: createdAt })
      }
    }
  },
  computed: {
    nextClick: function nextClick () {
      if (this.clickMode === 'boundary') {
        const where = this.prevClicks.length === 0 ? 'top left' : 'bottom right'
        return `Click ${where}`
      } else if (this.clickMode === 'perspective') {
        switch (this.prevClicks.length) {
          case 0: return 'Click top left'
          case 1: return 'Click top right'
          case 2: return 'Click bottom left'
          default:return 'Click bottom right'

        }
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
