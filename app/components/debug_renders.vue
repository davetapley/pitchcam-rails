<template>
  <div class="container">
    <div class="col-xs-6" v-for="render in renders">
      <h2>{{ render.id }}</h2>
      <table>
        <tr>
          <td>At:</td>
          <td>{{ render.image.createdAt | seconds }}</td>
        </tr>
        <tr>
          <td>Lag: </td>
          <td>{{ render.lag }}ms</td>
        </tr>
        <tr v-for="(debugValue, debugKey) in render.debug">
          <td>{{debugKey}}:</td>
          <td>{{debugValue}}</td>
        </tr>
      </table>
      <img :src="render.image.uri">
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
      renders: []
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
        const id = data.id
        const image = JSON.parse(data.image)
        const lag = Date.now() - new Date(image.createdAt)
        const debug = JSON.parse(data.debug)

        const render = that.renders.find((r) => {
          const match = r.id === id
          return match
        })

        if (render === undefined) {
          that.renders.push({ id, lag, image, debug })
        } else {
          render.image = image
          render.lag = lag
          render.debug = debug
        }
      }
    })
  }
}
</script>
