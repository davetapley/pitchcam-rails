<template>
  <div class="container">
    <img v-if="imageUri" :src="imageUri">
    <div class="col-xs-4" v-for="(carData, carName) in cars">
      <h3>{{carName}}</h3>
      <tr v-for="(dataValue, dataKey) in carData">
        <td>{{dataKey}}:</td>
        <td>{{dataValue}}</td>
      </tr>
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
      imageUri: undefined,
      cars: {}
    }
  },
  created: function created () {
    const that = this
    this.channel = this.$cable.subscriptions.create({ channel: 'CarTrackerChannel' }, {
      received (data) {
        const action = data.action
        if (action === 'addCar') {
          const name = data.name
          that.$set(that.cars, name, { waiting: true, onTrack: false })
        } else if (action === 'frame') {
          that.imageUri = data.uri
        } else if (action === 'info') {
          const name = data.name
          const info = data.info
          that.cars[name].waiting = info.waiting
          that.cars[name].onTrack = info.onTrack
        }
      }
    })
  }
}
</script>

