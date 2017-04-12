<template>
  <div class="container">
    <button @click=saveConfig>Save</button>
    <div class="row">
      <h2>Track layout</h2>
      <td><input v-model="layout" size=50 @change="sendConfig"/>
      <h2>World transform</h2>
      <table>
        <tr >
          <td>Origin x</td>
          <td><input v-model="world_transform.origin_x" @change="sendConfig" type="number" min="0" max="600"/></td>
          <td>Origin y</td>
          <td><input v-model="world_transform.origin_y" @change="sendConfig" type="number" min="0" max="600"/></td>
        </tr>
        <tr >
          <td>Scale</td>
          <td><input v-model="world_transform.scale" @change="sendConfig" type="number" min="1"/></td>
          <td>Rotation</td>
          <td><input v-model="world_transform.rotation" @change="sendConfig" type="number" min="0" max="360"/></td>
        </tr>
        <tr >
          <td>Null image threshold</td>
          <table>
            <tr v-for="key in hsv">
              <td>{{ key }}</td>
              <td><input v-model="null_image_threshold[key]" @change="sendConfig" type="number" min="0" max="255"/></td>
            </tr>
          </table>
        <tr >
        </tr>
      </table>
    </div>
    <div class="row" v-for="colorRow in colorRows">
    <h2>Colors</h2>
      <div class="col-sm-3" v-for="color in colorRow">
        <h3>{{ color.name }}</h3>
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
      world_transform: { origin_x: 0, origin_y: 0 },
      null_image_threshold: { hue: 10, saturation: 10, value: 10 },
      layout: '',
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
      this.channel.perform('update', { new_config: { layout: this.layout, world_transform: this.world_transform, null_image_threshold: this.null_image_threshold, colors: this.colors } })
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
        that.world_transform = config.world_transform
        that.layout = config.layout
        that.colors.splice(0)
        that.colors.push(...config.colors)
      }
    })
  }
}
</script>
