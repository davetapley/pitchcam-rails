<template>
  <div>
    <input type="file" @change="onFileChange" />
    <table class="roi">
      <tr>
        <td>ROI: </td>
        <td>{{roi.x}}</td>
        <td>{{roi.y}}</td>
        <td>{{roi.width}}</td>
        <td>{{roi.height}}</td>
      </tr>
    </table>
    <p>Set start segment transform: {{nextPoint}}</p>
    <video id="training-video" controls ref="video" @click="setStartLine" @play="snap"></video>
  </div>
</template>

<style scoped>
  th, td {
    border: 1px solid black;
    padding: 0 10px;
  }
</style>

<script>
export default {
  data () {
    return {
      nextClickIsLeft: true,
      prevClickPoint: { x: undefined, y: undefined },
      roi: { x: undefined, y: undefined, width: undefined, height: undefined },
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

    setStartLine: function setStartLine (event) {
      const rect = this.$refs.video.getBoundingClientRect()
      this.nextClickIsLeft = !this.nextClickIsLeft

      const clickedPoint = { x: event.clientX - rect.left, y: event.clientY - rect.top }

      if (this.nextClickIsLeft) {
        const left = this.prevClickPoint
        const right = clickedPoint

        const videoElement = this.$refs.video
        const frameWidth = videoElement.videoWidth
        const frameHeight = videoElement.videoHeight

        this.configChannel.perform('start_line', { left, right, frameWidth, frameHeight })
      }

      Object.assign(this.prevClickPoint, clickedPoint)
    },

    snap: function snap () {
      const videoElement = this.$refs.video
      const roi = this.roi

      if (videoElement.readyState > 0 && roi.x) {
        const canvas = document.createElement('CANVAS')
        canvas.width = roi.width
        canvas.height = roi.height

        canvas.getContext('2d').drawImage(videoElement, roi.x, roi.y, canvas.width, canvas.height, 0, 0, canvas.width, canvas.height)

        const imageUri = canvas.toDataURL('img/jpeg')
        const createdAt = Date.now()
        this.videoChannel.perform('frame', { image_uri: imageUri, created_at: createdAt, roi })
      }
    }
  },
  computed: {
    nextPoint: function nextPoint () {
      const where = this.nextClickIsLeft ? 'left' : 'right'
      return `Click ${where}`
    }
  },
  created: function created () {
    const that = this
    this.configChannel = this.$cable.subscriptions.create({ channel: 'ConfigChannel' }, {
      received (data) {
        if (data.roi) {
          Object.assign(that.roi, data.roi)
        }
      }
    })
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
  }
}
</script>
