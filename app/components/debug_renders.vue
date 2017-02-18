<template>
  <div class="container">
  <div class="row" v-for="render in renders">
    <h2>{{ render.description }}</h2>
    <div class="col-sm-8">
      <img :src="render.imageUri">
    </div>
    <div class="col-sm-4">
      <ul>
        <li>Rendered at: {{ render.createdAt }}</li>
        <li>Lag: {{ render.lag }}ms</li>
      </ul>
    </div>
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
  methods: {
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
