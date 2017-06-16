<template>
  <div class="container">
    <div class="col-xs-6" v-for="(render, id) in renders">
      <h2>{{ id }}</h2>
      <table>
        <tr>
          <td>Lag: </td>
          <td>{{ render.lag }}ms</td>
        </tr>
        <tr v-for="(metaValue, metaKey) in render.meta">
          <td>{{metaKey}}:</td>
          <td>{{metaValue}}</td>
        </tr>
      </table>
      <span v-for="uri in render.uris">
        <img :src="uri">
      </span>
    </div>
  </div>
</template>

<style scoped>
</style>

<script>

export default {
  data () {
    return {
      channel: null,
      renders: {}
    }
  },
  created: function created () {
    const that = this
    this.channel = this.$cable.subscriptions.create({ channel: 'DebugRenderChannel' }, {
      received (data) {
        const id = data.id
        const uris = Array.isArray(data.uri) ? data.uri : [data.uri]
        const lag = Date.now() - new Date(data.at)
        const meta = JSON.parse(data.meta || '{}')

        const render = that.renders[id]

        if (render === undefined) {
          that.$set(that.renders, id, { lag, uris, meta })
        } else {
          render.lag = lag
          render.uris = uris
          render.meta = meta
        }
      }
    })
  }
}
</script>
