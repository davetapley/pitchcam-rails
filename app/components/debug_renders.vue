<template>
  <div class="container">
    <div class="row" v-for="colorRow in colorRows">
      <div class="col-sm-3" v-for="color in colorRow">
        <h2>{{ color.name }}</h2>
        <table>
          <tr>
            <td>Config</td>
            <td>{{ color.config.updated_at }}</td>
          </tr>
          <tr><td>&nbsp;</td><td>low</td><td>high</td></tr>
          <tr v-for="key in hsv">
            <td>{{ key }}</td>
            <td><input v-model="color.config[key][0]" @change="sendConfig" type="number" min="0" max="255"/></td>
            <td><input v-model="color.config[key][1]" @change="sendConfig" type="number" min="0" max="255"/></td>
          </tr>

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
    },
    hsv: function hsv () {
      return ['hue', 'saturation', 'value']
    }
  },
  methods: {
    sendConfig: function sendConfig () {
      const colors = _.map(this.colors, color => color.config)
      this.channel.perform('config', { new_config: { colors } })
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
          that.colors.push({ name, lag, config, image })
        } else {
          color.lag = lag
          color.image = image
        }
      }
    })
  }
}
</script>
