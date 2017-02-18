<template>
  <div>
    <input type="file" accept="video/*" @change="onFileChange" />
    <p>{{fileMessage}}</p>
    <p>{{nextPoint}}</p>
    <video id="training-video" controls ref="video" @loadedmetadata="setDefaultTrackBoundary" @click="setTrackBoundary" @play="snap"></video>
  </div>
</template>

<style scoped>
</style>

<script>
export default {
  data () {
    return {
      fileMessage: '',
      nextClickIsTopLeft: true,
      topLeft: { x: undefined, y: undefined },
      bottomRight: { x: undefined, y: undefined },
      videoChannel: null,
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

    setDefaultTrackBoundary: function setDefaultTrackBoundary () {
      const videoElement = this.$refs.video
      this.topLeft = { x: 0, y: 0 }
      this.bottomRight = { x: videoElement.videoWidth, y: videoElement.videoHeight }
    },

    setTrackBoundary: function setTrackBoundary (event) {
      const rect = this.$refs.video.getBoundingClientRect()
      const point = this.nextClickIsTopLeft ? this.topLeft : this.bottomRight
      this.nextClickIsTopLeft = !this.nextClickIsTopLeft
      point.x = event.clientX - rect.left
      point.y = event.clientY - rect.top
    },

    snap: function snap () {
      const canvas = document.createElement('CANVAS')
      canvas.width = this.bottomRight.x - this.topLeft.x
      canvas.height = this.bottomRight.y - this.topLeft.y

      const videoElement = this.$refs.video
      canvas.getContext('2d').drawImage(videoElement, this.topLeft.x, this.topLeft.y, canvas.width, canvas.height, 0, 0, canvas.width, canvas.height)

      const imageUri = canvas.toDataURL('img/jpeg')
      const createdAt = Date.now()
      this.videoChannel.perform('frame', { image_uri: imageUri, created_at: createdAt })
    }
  },
  computed: {
    nextPoint: function nextPoint () {
      const where = this.nextClickIsTopLeft ? 'top left' : 'bottom right'
      return `Click ${where}`
    }
  },
  created: function created () {
    const that = this
    this.videoChannel = this.$cable.subscriptions.create({ channel: 'VideoChannel' }, {
      received (data) {
        if (data.action === 'snap') {
          that.snap()
        }
      }
    })
  }
}
</script>

