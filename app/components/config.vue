<template>
  <div class="container">
    <button @click=saveConfig>Save</button>
    <div class="row" v-for="colorRow in colorRows">
      <div class="col-sm-3" v-for="color in colorRow">
        <h2>{{ color.name }}</h2>
        <table>
          <tr><td>&nbsp;</td><td>low</td><td>high</td></tr>
          <tr v-for="key in hsv">
            <td>{{ key }}</td>
            <td><input v-model="color[key][0]" @change="sendConfig" type="number" min="0" max="255"/></td>
            <td><input v-model="color[key][1]" @change="sendConfig" type="number" min="0" max="255"/></td>
          </tr>
        </table>
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
      this.channel.perform('update', { new_config: { colors: this.colors } })
    },
    saveConfig: function sendConfig () {
      this.channel.perform('save')
    }
  },
  mounted: function created () {
    const that = this
    this.channel = this.$cable.subscriptions.create({ channel: 'ConfigChannel' }, {
      connected: function connected () {
        that.channel.perform('get')
      },
      received: function received (data) {
        const config = data.config
        that.colors.push(...config.colors)
      }
    })
  }
}
</script>
