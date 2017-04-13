<template>
  <div>
    <vue-webcam ref='webcam' v-bind:width="800" v-bind:height="600"></vue-webcam>
    <br>
    <button type="submit" @click="snap">Start</button>
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
      videoChannel: null,
      configChannel: null
    }
  },
  methods: {
    snap: function snap () {
      const webcam = this.$refs.webcam
      const imageUri = webcam.getPhoto()
      const createdAt = Date.now()
      this.videoChannel.perform('frame', { image_uri: imageUri, created_at: createdAt })
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
