<template>
  <div>
    <b-navbar toggleable="lg" type="dark" variant="primary">
      <b-form-input
        @input="getResults()"
        @keydown.esc="resetSearchInput()"
        @keydown.down="focus('0-name')"
        v-model="searchQuery"
        autofocus
        ref="search"
        placeholder="Search for a user"
        size="lg"
        class="mx-auto my-3"
        style="max-width:40rem"
      ></b-form-input>
    </b-navbar>
    <b-container class="py-3" style="max-width:40rem">
      <transition-group name="flip-list">
        <div v-for="(result, index) in results" :key="result.id">
          <div class="row">
            <div class="col-5">
              <h3>
                <span
                  tabindex="0"
                  class="d-inline-block"
                  :ref="index + '-name'"
                  @keydown.esc="resetSearchInput()"
                  @keydown.down="focus(index + '-id')"
                  @keydown.up="index === 0 ? resetSearchInput() : focus((index - 1) + '-name')"
                  @keydown.enter="copyText(result.name)"
                  :class="highlightIfFocused(index + '-name')"
                >{{result.name}}</span>
                <small
                  tabindex="0"
                  :ref="index + '-id'"
                  @keydown.up="focus(index + '-name')"
                  @keydown.down="focus((index < results.length - 1) ? ((index + 1) + '-name') : (index + '-id'))"
                  @keydown.esc="resetSearchInput()"
                  @keydown.enter="copyText(result.id)"
                  :class="highlightIfFocused(index + '-id')"
                >{{result.id}}</small>
              </h3>
            </div>
            <div class="col-7">
              <p class="mb-0 small">
                {{result.title}}
                <br />
                {{result.email}}
                <br />
                {{result.department}}
                <br />
                {{result.emailAlias}}
                <br />
                {{result.location}}
                <br />
                {{result.phone}}
              </p>
            </div>
          </div>
          <hr />
        </div>
      </transition-group>
    </b-container>
    <!-- {{focusedElementRef}}
    <b-button ref="testthing" id="tooltip-button-1" variant="primary">I have a tooltip</b-button>-->
    <!-- <b-tooltip
      :show="true"
      trigger="manual"
      :target="() => $refs['focusedElementRef']"
      title="Copied!"
    ></b-tooltip>-->
  </div>
</template>

<script>
import throttle from 'lodash.throttle'

export default {
  name: 'HomePage',

  data() {
    return {
      searchQuery: null,
      focusedElementRef: null,
      showCopiedTooltip: false,
      results: []
    }
  },

  mounted() {
    this.centerWindow()
  },

  methods: {
    getResults: throttle(function() {
      fetch('/api/search?q=' + this.searchQuery)
        .then((response) => response.json())
        .then((json) => {
          this.results = json
        })
    }, 750),

    highlightIfFocused(refName) {
      if (this.focusedElementRef == refName) {
        return 'bg-warning p-1 m-n1'
      }
    },

    resetSearchInput() {
      this.searchQuery = ''
      this.$refs['search'].focus()
      this.focusedElementRef = null
    },

    focus: function(refName) {
      console.log('focusing ' + refName)
      this.focusedElementRef = refName
      // this.keyboardNavigation.currentElement = newElementName
    },

    copyText: function(text) {
      navigator.clipboard
        .writeText(text)
        .then(() => {
          console.log('copied')
          this.showCopiedTooltip = true
        })
        .catch((e) => {
          console.log(e)
          alert('Something went wrong')
        })
    },

    centerWindow() {
      setTimeout(() => {
        const windowWidth = screen.width / 1.5
        const windowHeight = screen.height / 2
        const xPos = screen.width / 2 - windowWidth / 2
        const yPos = screen.height / 2 - windowHeight / 2
        window.moveTo(xPos, yPos)
        window.resizeTo(windowWidth, windowHeight)
      }, 300)
    }
  },

  watch: {
    focusedElementRef() {
      if (this.$refs[this.focusedElementRef]) {
        this.$refs[this.focusedElementRef][0].focus()
      }
    }
  }
}
</script>

<style>
.flip-list-move {
  transition: transform 1s;
}

/* Bootstrap focus outline tweak */
:focus {
  outline: none;
}
</style>