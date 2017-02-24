<template>
  <div class="container">
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
        const config = JSON.parse(data.config)
        const name = config.name

        const color = that.colors.find((c) => {
          const match = c.name === name
          return match
        })

        const image = JSON.parse(data.image)
        const lag = Date.now() - new Date(image.createdAt)

        if (color === undefined) {
          that.colors.push({ name, lag, image })
        } else {
          color.lag = lag
          color.image = image
        }
      }
    })
  }
}
</script>
