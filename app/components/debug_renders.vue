<template>
  <div class="container">
    <div class="col-xs-6" v-for="render in renders">
      <h2>{{ render.id }}</h2>
      <table>
        <tr>
          <td>Lag: </td>
          <td>{{ render.lag }}ms</td>
        </tr>
        <tr v-for="(debugValue, debugKey) in render.debug">
          <td>{{debugKey}}:</td>
          <td>{{debugValue}}</td>
        </tr>
      </table>
      <img :src="render.uri">
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
      renders: []
    }
  },
  created: function created () {
    const that = this
    this.channel = this.$cable.subscriptions.create({ channel: 'DebugRenderChannel' }, {
      received (data) {
        const id = data.id
        const uri = data.uri
        const lag = Date.now() - new Date(data.at)
        const debug = JSON.parse(data.debug || '{}')

        const render = that.renders.find((r) => {
          const match = r.id === id
          return match
        })

        if (render === undefined) {
          that.renders.push({ id, lag, uri, debug })
        } else {
          render.lag = lag
          render.uri = uri
          render.debug = debug
        }
      }
    })
  }
}
</script>
