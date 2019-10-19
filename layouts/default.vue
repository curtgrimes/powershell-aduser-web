<template>
  <div>
    <nuxt />
  </div>
</template>

<script>
export default {
  data() {
    return {
      items: [
        {
          title: 'Home',
          icon: 'home',
          to: { name: 'index' }
        }
      ]
    }
  }
}
</script>

<style>
@import 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.11.2/css/fontawesome.min.css';
@import 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.11.2/css/solid.min.css';

body {
  overflow-y: scroll;
}
</style>