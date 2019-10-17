<template>
  <div>
    <b-navbar toggleable="lg" type="dark" variant="primary">
      <div class="position-relative mx-auto my-1" style="width:40rem;max-width:100%">
        <div
          class="position-absolute d-flex align-items-center pr-3"
          style="right:0;top:0;bottom:0"
        >
          <span
            v-if="showKeepTypingMessage"
            class="small text-muted d-inline-block mr-3 font-weight-bold"
          >Keep typing to see results.</span>
          <b-spinner v-if="loading" variant="primary" />
        </div>
        <b-form-input
          @input="focusedElementRef = null; getResults()"
          @keydown.esc="resetSearchInput()"
          @keydown.down="focus('0-name')"
          v-model="searchQuery"
          autofocus
          ref="search"
          placeholder="Search for a user"
          size="lg"
        ></b-form-input>
      </div>
    </b-navbar>
    <b-container class="py-3">
      <div v-for="(result, index) in results" :key="result.id">
        <div class="mx-auto" style="max-width:40rem">
          <div class="row mx-auto">
            <div class="col-5 pl-0">
              <h4>
                <span
                  tabindex="0"
                  class="d-block"
                  :id="index + '-name'"
                  :ref="index + '-name'"
                  v-b-tooltip.manual.v-warning="'Copied!'"
                  @keydown.esc.exact="resetSearchInput()"
                  @keydown.down.exact="focus(index + '-id')"
                  @keydown.up.exact="index === 0 ? resetSearchInput() : focus((index - 1) + '-id')"
                  @keydown.enter.exact="copyText(result.name)"
                  @keydown.ctrl.67="copyText(result.name)"
                  @click="copyText(result.id)"
                  @keydown.enter.ctrl="copyTextAndClose(result.id)"
                  :class="highlightIfFocused(index + '-name')"
                >{{result.name}}</span>
                <small
                  tabindex="0"
                  :id="index + '-id'"
                  :ref="index + '-id'"
                  v-b-tooltip.manual.v-warning="'Copied!'"
                  @keydown.up.exact="focus(index + '-name')"
                  @keydown.down.exact="focus((index < results.length - 1) ? ((index + 1) + '-name') : (index + '-id'))"
                  @keydown.esc.exact="resetSearchInput()"
                  @keydown.enter.exact="copyText(result.id)"
                  @keydown.ctrl.67="copyText(result.id)"
                  @click="copyText(result.id)"
                  @keydown.enter.ctrl="copyTextAndClose(result.id)"
                  :class="highlightIfFocused(index + '-id')"
                >{{result.id}}</small>
              </h4>
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
        </div>
        <hr />
      </div>
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
      loading: false,
      showKeepTypingMessage: false,
      focusedElementRef: null,
      showCopiedTooltip: false,
      results: []
    }
  },

  mounted() {
    this.centerWindow()

    window.addEventListener(
      'unload',
      () => {
        navigator.sendBeacon('/api/quit')
      },
      false
    )
  },

  created() {
    this.abortSearchControllers = []
  },

  methods: {
    getResults: throttle(function() {
      this.loading = true
      this.showKeepTypingMessage = false

      // Abort any existing searches before starting a new search
      this.abortAnyInProgressSearches()

      const abortController = new AbortController()
      const signal = abortController.signal
      this.abortSearchControllers.push(abortController)

      fetch('/api/search?q=' + this.searchQuery, {
        signal
      })
        .then((response) => {
          if (!response.ok) {
            throw response
          } else {
            return response
          }
        })
        .then((response) => response.json())
        .then((json) => {
          this.results = json
          this.loading = false
        })
        .catch((errorResponse) => {
          if (errorResponse.status === 422) {
            // Need to type more to see results
            this.showKeepTypingMessage = true
            this.loading = false

            if (!this.searchQuery) {
              // If they cleared the search field, hide this message completely
              this.showKeepTypingMessage = false
            }
          }
        })
    }, 300),

    abortAnyInProgressSearches() {
      this.abortSearchControllers.forEach((signal) => signal.abort())

      this.abortSearchControllers = []
    },

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
      this.focusedElementRef = refName
    },

    copyText: function(text, { closeAfterCopy = false } = {}) {
      navigator.clipboard
        .writeText(text)
        .then(() => {
          if (closeAfterCopy) {
            fetch('/api/quit')

            setTimeout(() => {
              window.close()
            }, 200)
          } else {
            this.$root.$emit('bv::show::tooltip', this.focusedElementRef)
            setTimeout(() => {
              this.$root.$emit('bv::hide::tooltip')
            }, 500)
          }
        })
        .catch((e) => {
          console.log(e)
          alert('Something went wrong')
        })
    },

    copyTextAndClose: function(text) {
      this.copyText(text, { closeAfterCopy: true })
    },

    centerWindow() {
      setTimeout(() => {
        const windowWidth = screen.width / 2
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
/* Bootstrap focus outline tweak */
:focus {
  outline: none;
}
</style>