<template>
  <div>
    <input type="file" accept="video/*" @change="onFileChange" />
    <input type="radio" id="boundary" value="boundary" v-model="clickMode" @change="resetClickMode">
    <label for="boundary">Set boundary</label>
    <input type="radio" id="origin" value="origin" v-model="clickMode" @change="resetClickMode">
    <label for="origin">Set origin</label>
    <p>{{nextClick}}</p>
    <p>{{boundaryStatus}}</p>
    <video id="training-video" controls loop muted ref="video" @loadedmetadata="setDefaultTrackBoundary" @click="click" @play="snap"></video>
  </div>
</template>

<style scoped>
</style>

<script>
export default {
  data () {
    return {
      clickMode: 'boundary',
      prevClick: undefined,
      boundary: { topLeft: undefined, bottomRight: undefined },
      filePath: undefined,
      videoChannel: null,
      configChannel: null,
      trainingRenderUri: 'data:image/png;base64,'
    }
  },
  localStorage: {
    boundary: { type: Object }
  },
  methods: {
    onFileChange: function onFileChange (event) {
      const file = event.target.files[0]
      const type = file.type
      const canPlay = this.$refs.video.canPlayType(type) !== 'no'

      if (!canPlay) {
        return
      }

      this.fileName = file.name
      const URL = window.URL || window.webkitURL
      const fileURL = URL.createObjectURL(file)
      const videoElement = this.$refs.video
      videoElement.src = fileURL
    },

    resetClickMode: function resetClickMode () {
      this.prevClick = undefined
    },

    setDefaultTrackBoundary: function setDefaultTrackBoundary () {
      const prevBoundary = this.$localStorage.get('boundary')
      if (prevBoundary) {
        this.boundary = prevBoundary
      } else {
        const videoElement = this.$refs.video
        this.boundary.topLeft = { x: 0, y: 0 }
        this.boundary.bottomRight = { x: videoElement.videoWidth, y: videoElement.videoHeight }
      }
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
          this.$localStorage.set('boundary', this.boundary)
        }
      } else if (this.clickMode === 'origin') {
        const topLeft = this.boundary.topLeft
        const boundedOrigin = { origin_x: point.x - topLeft.x, origin_y: point.y - topLeft.y }
        this.configChannel.perform('update', { new_config: { world_transform: boundedOrigin } })
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
