<template>
  <div class="container">
    <div class="row" v-for="renderRow in renderRows">
      <div class="col-sm-3" v-for="render in renderRow">
        <h2>{{ render.description }}</h2>
        <ul>
          <li>Rendered at: {{ render.createdAt }}</li>
          <li>Lag: {{ render.lag }}ms</li>
        </ul>
        <img :src="render.imageUri">
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
      renders: []
    }
  },
  computed: {
    renderRows: function renderRows () {
      return _.chunk(this.renders, 4)
    }
  },
  created: function created () {
    const that = this
    this.channel = this.$cable.subscriptions.create({ channel: 'DebugRenderChannel' }, {
      received (data) {
        const render = that.renders.find((r) => {
          const match = r.description === data.description
          return match
        })

        const lag = Date.now() - Date.parse(data.createdAt)

        if (render === undefined) {
          that.renders.push(Object.assign(data, { lag }))
        } else if (data.createdAt > render.createdAt) {
          render.createdAt = data.createdAt
          render.lag = lag
          render.imageUri = data.imageUri
        }
      }
    })
  }
}
</script>
