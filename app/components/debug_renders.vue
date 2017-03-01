<template>
  <div class="container">
    <div class="row">
    <div class="col-sm-12" v-if="track.image">
          <h2>Track</h2>
          <table>
            <tr>
              <td>At:</td>
              <td>{{ track.image.createdAt | seconds }}</td>
            </tr>
            <tr>
              <td>Lag: </td>
              <td>{{ track.lag }}ms</td>
            </tr>
          </table>

          <img :src="track.image.uri">
      </div>
    </div>
    <div class="row" v-for="colorRow in colorRows">
      <div class="col-sm-3" v-for="color in colorRow">
        <h2>{{ color.name }}</h2>
        <table>
          <tr>
            <td>At:</td>
            <td>{{ color.image.createdAt | seconds }}</td>
          </tr>
          <tr>
            <td>Lag: </td>
            <td>{{ color.lag }}ms</td>
          </tr>
        </table>

        <img :src="color.image.uri">
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>

<script>
import _ from 'lodash'

export default {
  data () {
    return {
      channel: null,
      track: {},
      colors: []
    }
  },
  computed: {
    colorRows: function colorRows () {
      return _.chunk(this.colors, 4)
    }
  },
  filters: {
    seconds: function time (ms) {
      const date = new Date(ms)
      return `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`
    }
  },
  created: function created () {
    const that = this
    this.channel = this.$cable.subscriptions.create({ channel: 'DebugRenderChannel' }, {
      received (data) {
        const image = JSON.parse(data.image)
        const lag = Date.now() - new Date(image.createdAt)

        if (data.color) {
          const name = data.name

          const color = that.colors.find((c) => {
            const match = c.name === name
            return match
          })

          if (color === undefined) {
            that.colors.push({ name, lag, image })
          } else {
            color.lag = lag
            color.image = image
          }
        } else {
          that.track.lag = lag
          that.track.image = image
        }
      }
    })
  }
}
</script>
