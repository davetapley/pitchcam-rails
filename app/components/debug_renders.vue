<template>
  <div class="container">
    <div class="row" v-if="track.image">
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
        <tr v-for="(debugValue, debugKey) in track.debug">
          <td>{{debugKey}}:</td>
          <td>{{debugValue}}</td>
        </tr>
      </table>
        <img :src="track.image.uri">
    </div>
    <div class="row" v-for="color in colors">
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
        <tr>
          <td>World:</td>
          <td>{{ color.positions.world | coords('x', 'y', 0) }}</td>
        </tr>
        <tr>
          <td>Track:</td>
          <td>{{ color.positions.track | coords('p', 'd', 2) }}</td>
        </tr>
        <tr v-for="(debugValue, debugKey) in color.debug">
          <td>{{debugKey}}:</td>
          <td>{{debugValue}}</td>
        </tr>
      </table>
      <img :src="color.image.uri">
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
      track: { lag: undefined, image: undefined, debug: undefined },
      colors: []
    }
  },
  filters: {
    seconds: function time (ms) {
      const date = new Date(ms)
      return `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`
    },
    coords: function coords (obj, axis1, axis2, round) {
      if (obj === null) {
        return 'none'
      }

      return `(${_.round(obj[axis1], round)}, ${_.round(obj[axis2], round)})`
    }
  },
  created: function created () {
    const that = this
    this.channel = this.$cable.subscriptions.create({ channel: 'DebugRenderChannel' }, {
      received (data) {
        if (data.image) {
          const image = JSON.parse(data.image)
          const lag = Date.now() - new Date(image.createdAt)
          const debug = JSON.parse(data.debug)

          if (data.color) {
            const name = data.name

            const color = that.colors.find((c) => {
              const match = c.name === name
              return match
            })

            const positions = JSON.parse(data.positions)

            if (color === undefined) {
              that.colors.push({ name, lag, image, positions, debug })
            } else {
              color.lag = lag
              color.image = image
              color.positions = positions
              color.debug = debug
            }
          } else {
            that.track.lag = lag
            that.track.image = image
            that.track.debug = debug
          }
        }
      }
    })
  }
}
</script>
