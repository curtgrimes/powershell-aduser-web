<template>
  <section class="section">
    <div class="columns is-mobile">
      <card title="Free" icon="github-circle">
        Open source on
        <a href="https://github.com/buefy/buefy">GitHub</a>
      </card>

      <card title="Responsive" icon="cellphone-link">
        <b class="has-text-grey">Every</b>
        component is responsive
      </card>

      <card title="Modern" icon="alert-decagram">
        Built with
        <a href="https://vuejs.org/">Vue.js</a>
        and
        <a href="http://bulma.io/">Bulma</a>
      </card>

      <card title="Lightweight" icon="arrange-bring-to-front">No other internal dependency</card>
    </div>
  </section>
</template>

<script>
import Card from '~/components/Card'

export default {
  name: 'HomePage',

  components: {
    Card
  },

  mounted() {
    this.centerWindow()
  },

  methods: {
    centerWindow() {
      const windowWidth = screen.width / 1.5
      const windowHeight = screen.height / 2
      const xPos = screen.width / 2 - windowWidth / 2
      const yPos = screen.height / 2 - windowHeight / 2
      window.moveTo(xPos, yPos)
      window.resizeTo(windowWidth, windowHeight)
    }
  }
}
</script>
