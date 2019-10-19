<template>
  <div>
    <b-navbar toggleable="lg" type="dark" variant="primary">
      <div class="container mx-auto my-1 d-flex">
        <div class="position-relative flex-grow-1">
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
            @keydown.esc="handleEscapeKeyPress()"
            @keydown.down="keyboard.focusedRowIndex = 0; keyboard.focusedColumnIndex = 0"
            @focus="keyboard.focusedRowIndex = null; keyboard.focusedColumnIndex = 0"
            autocomplete="off"
            v-model="searchQuery"
            autofocus
            ref="search"
            placeholder="Search for a user"
            size="lg"
          ></b-form-input>
        </div>
        <span class="navbar-text">
          <button
            class="btn btn-link text-white"
            v-b-tooltip="'Keyboard Shortcuts'"
            v-b-modal.helpPopover
          >
            <i class="fas fa-keyboard fa-2x"></i>
          </button>
        </span>
      </div>
    </b-navbar>
    <div class="bg-light">
      <div class="container" v-if="results.length">
        <div class="row font-weight-bold small">
          <div class="col-2 col-lg-1">ID</div>
          <div class="col-3">Name</div>
          <div class="col-2">Email</div>
          <div class="col-3">Deptartment</div>
          <div class="col-2">Phone</div>
        </div>
      </div>
    </div>
    <div
      v-for="(result, index) in results"
      :key="result.id"
      :ref="'resultRow' + index"
      tabindex="0"
      :class="keyboard.focusedRowIndex === index ? 'bg-highlighted-lighter text-black' : 'text-muted'"
    >
      <div class="container">
        <div class="row">
          <div
            class="col-2 col-lg-1"
            :id="'result-' + index + '-0'"
            tabindex="0"
            @click="keyboard.focusedRowIndex = index; keyboard.focusedColumnIndex = 0"
            @keydown.18.prevent
            @keydown.enter="copyText(result.id); flashTooltip('result-' + index + '-0')"
            :class="keyboard.focusedRowIndex === index && keyboard.focusedColumnIndex === 0 ? 'bg-highlighted' : 'text-truncated'"
            v-b-tooltip.manual.nofade.v-warning="'Copied!'"
          >{{result.id}}</div>
          <div
            class="col-3"
            :id="'result-' + index + '-1'"
            tabindex="0"
            @click="keyboard.focusedRowIndex = index; keyboard.focusedColumnIndex = 1"
            @keydown.18.prevent
            @keydown.enter="copyText(result.name); flashTooltip('result-' + index + '-1')"
            :class="keyboard.focusedRowIndex === index && keyboard.focusedColumnIndex === 1 ? 'bg-highlighted' : 'text-truncated'"
            v-b-tooltip.manual.nofade.v-warning="'Copied!'"
          >{{result.name}}</div>
          <div
            class="col-2"
            :id="'result-' + index + '-2'"
            tabindex="0"
            @click="keyboard.focusedRowIndex = index; keyboard.focusedColumnIndex = 2"
            @keydown.18.prevent="toggleEmailFormat = true"
            @keyup.18.prevent="toggleEmailFormat = false"
            @keydown.alt.enter.exact="copyText(result.email); flashTooltip('result-' + index + '-2')"
            @keydown.enter.exact="copyText(result.emailAlias); flashTooltip('result-' + index + '-2')"
            :class="keyboard.focusedRowIndex === index && keyboard.focusedColumnIndex === 2 ? 'bg-highlighted' : 'text-truncated'"
            v-b-tooltip.manual.nofade.v-warning="'Copied!'"
          >{{toggleEmailFormat ? result.email : result.emailAlias}}</div>
          <div
            class="col-3"
            :id="'result-' + index + '-3'"
            tabindex="0"
            @click="keyboard.focusedRowIndex = index; keyboard.focusedColumnIndex = 3"
            @keydown.18.prevent
            @keydown.enter="copyText(result.department); flashTooltip('result-' + index + '-3')"
            :class="keyboard.focusedRowIndex === index && keyboard.focusedColumnIndex === 3 ? 'bg-highlighted' : 'text-truncated'"
            v-b-tooltip.manual.nofade.v-warning="'Copied!'"
          >{{result.department}}</div>
          <div
            class="col-2"
            :id="'result-' + index + '-4'"
            tabindex="0"
            @click="keyboard.focusedRowIndex = index; keyboard.focusedColumnIndex = 4"
            @keydown.18.prevent
            @keydown.enter="copyText(result.phone); flashTooltip('result-' + index + '-4')"
            :class="keyboard.focusedRowIndex === index && keyboard.focusedColumnIndex === 4 ? 'bg-highlighted' : 'text-truncated'"
            v-b-tooltip.manual.nofade.v-warning="'Copied!'"
          >{{result.phone}}</div>
        </div>
      </div>
      <hr class="m-0" />
    </div>

    <b-modal id="helpPopover" title="Keyboard Shortcuts" centered no-fade ok-only>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>
            <i class="fas fa-arrow-up"></i>
          </kbd>
          <kbd>
            <i class="fas fa-arrow-down"></i>
          </kbd>
        </div>
        <div class="col-8">Navigate search results</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>/</kbd>
        </div>
        <div class="col-8">Focus search</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>esc</kbd> x2
        </div>
        <div class="col-8">Exit</div>
      </div>
      <hr />
      <div class="row mb-2 text-muted small font-weight-bold">
        <div class="col-8 ml-auto">When a row is selected</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>
            <i class="fas fa-arrow-left"></i>
          </kbd>
          <kbd>
            <i class="fas fa-arrow-right"></i>
          </kbd>
        </div>
        <div class="col-8">Navigate columns</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>enter</kbd>
        </div>
        <div class="col-8">Copy selection to clipboard</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>alt</kbd>
        </div>
        <div class="col-8">Toggle email address alias (when email is selected)</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>e</kbd>
        </div>
        <div class="col-8">Start new email for current user</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>t</kbd>
        </div>
        <div class="col-8">Open Microsoft Teams conversation for current user</div>
      </div>
      <div class="row mb-2">
        <div class="col-4 text-right">
          <kbd>a</kbd>
        </div>
        <div class="col-8">Open availability in Outlook for current user</div>
      </div>
    </b-modal>
  </div>
</template>

<script>
import throttle from 'lodash.throttle'
import hotkeys from 'hotkeys-js'

export default {
  name: 'HomePage',

  data() {
    return {
      searchQuery: null,
      loading: false,
      keyboard: {
        focusedRowIndex: null,
        focusedColumnIndex: 0
      },
      toggleEmailFormat: false, // swithc between showing email formats
      showKeepTypingMessage: false,
      focusedElementRef: null,
      showCopiedTooltip: false,
      receivedESCAgainToCloseWarning: false,
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

    // Focus the search if we're returning back to this window
    window.addEventListener(
      'focus',
      () => {
        this.focusHighlightSearchInput()
      },
      false
    )

    hotkeys('/', (event, handler) => {
      if (event.target !== this.$refs['search']) {
        // Focus search
        event.preventDefault()
        this.focusHighlightSearchInput()
      }
    })

    hotkeys('backspace', (event, handler) => {
      if (event.target !== this.$refs['search']) {
        // We're not in the search field. Focus the search.
        event.preventDefault()
        this.focusHighlightSearchInput()
      }
    })

    // Microsoft Teams shortcut - open deep link
    // to Teams conversation for person when row is highlighted
    hotkeys('t', (event, handler) => {
      event.preventDefault()
      if (parseInt(this.keyboard.focusedRowIndex) >= 0) {
        // A row is selected
        window.open(
          'https://teams.microsoft.com/l/chat/0/0?users=' +
            this.results[this.keyboard.focusedRowIndex].email
        )
        // window.close()
      }
    })

    // Open email shortcut
    hotkeys('e', (event, handler) => {
      event.preventDefault()
      if (parseInt(this.keyboard.focusedRowIndex) >= 0) {
        // A row is selected
        window.open(
          'mailto:' + this.results[this.keyboard.focusedRowIndex].emailAlias
        )
        // window.close()
      }
    })

    // Open user availability shortcut
    hotkeys('a', (event, handler) => {
      event.preventDefault()
      if (parseInt(this.keyboard.focusedRowIndex) >= 0) {
        // A row is selected
        fetch(
          '/api/get-availability?email=' +
            this.results[this.keyboard.focusedRowIndex].emailAlias
        ).then(() => {
          // window.close()
        })
      }
    })

    hotkeys('escape', (event, handler) => {
      event.preventDefault()
      this.handleEscapeKeyPress()
    })

    hotkeys('down', (event, handler) => {
      event.preventDefault()

      if (
        parseInt(this.keyboard.focusedRowIndex) >= 0 &&
        this.keyboard.focusedRowIndex < this.results.length - 1 // We haven't reached the end of the list yet
      ) {
        this.keyboard.focusedRowIndex++
      } else if (this.keyboard.focusedRowIndex === null) {
        this.keyboard.focusedRowIndex = 0
        this.keyboard.focusedColumnIndex = 0
      }
    })

    hotkeys('up', (event, handler) => {
      event.preventDefault()

      if (this.keyboard.focusedRowIndex > 0) {
        this.keyboard.focusedRowIndex--
      } else if (this.keyboard.focusedRowIndex === 0) {
        this.$refs['search'].focus()
        this.$refs['search'].select()
        this.keyboard.focusedRowIndex = null
      }
    })
    hotkeys('right', (event, handler) => {
      event.preventDefault()

      const COLUMN_COUNT = 5
      if (this.keyboard.focusedRowIndex >= 0) {
        this.keyboard.focusedColumnIndex =
          (this.keyboard.focusedColumnIndex + 1) % COLUMN_COUNT
      }
    })

    hotkeys('left', (event, handler) => {
      event.preventDefault()

      const COLUMN_COUNT = 5
      if (this.keyboard.focusedColumnIndex === 0) {
        this.keyboard.focusedColumnIndex = COLUMN_COUNT - 1
      } else if (this.keyboard.focusedRowIndex >= 0) {
        this.keyboard.focusedColumnIndex =
          (this.keyboard.focusedColumnIndex - 1) % COLUMN_COUNT
      }
    })
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
            .filter((result) => {
              // Ignore some entries
              return !result.id.includes('wt_user')
            })
            .sort((a, b) => {
              // Sort students last
              if (
                a.id[0].toUpperCase() !== 'Z' &&
                b.id[0].toUpperCase() === 'Z'
              ) {
                return -1
              }
              if (
                a.id[0].toUpperCase() === 'Z' &&
                b.id[0].toUpperCase() !== 'Z'
              ) {
                return 1
              }
              // a must be equal to b
              return ((a, b) => {
                // Sort people with departments first
                if (a.department && !b.department) {
                  return -1
                }
                if (!a.department && b.department) {
                  return 1
                }
                // a must be equal to b
                return 0
              })(a, b)
            })
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

    flashTooltip(id) {
      // Show tooltip
      this.$root.$emit('bv::show::tooltip', id)
      setTimeout(() => {
        this.$root.$emit('bv::hide::tooltip')
      }, 500)
    },

    abortAnyInProgressSearches() {
      this.abortSearchControllers.forEach((signal) => signal.abort())

      this.abortSearchControllers = []
    },

    highlightIfFocused(refName) {
      if (this.focusedElementRef == refName) {
        return 'bg-warning p-1 m-n1'
      }
    },

    focusHighlightSearchInput() {
      this.$refs['search'].focus()
      this.$refs['search'].select()
      this.keyboard.focusedRowIndex = null
    },

    focusCurrentRow() {
      let elementToFocus = document.querySelector(
        '#result-' +
          this.keyboard.focusedRowIndex +
          '-' +
          this.keyboard.focusedColumnIndex
      )
      if (elementToFocus) {
        elementToFocus.focus()
      }
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

    handleEscapeKeyPress: function() {
      if (document.activeElement !== this.$refs['search']) {
        // We're not in the search field. Focus the search.
        this.focusHighlightSearchInput()
      }

      if (this.receivedESCAgainToCloseWarning) {
        window.close()
      } else {
        this.receivedESCAgainToCloseWarning = true
        // Show a message saying the next ESC will close the window.
        this.$bvToast.toast(`Press ESC again to close.`, {
          title: '',
          toaster: 'b-toaster-top-center',
          autoHideDelay: 1500,
          variant: 'secondary'
        })

        // Clear the warning after a time period
        setTimeout(() => {
          this.receivedESCAgainToCloseWarning = false
        }, 1500)
      }
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
    'keyboard.focusedRowIndex': function() {
      this.focusCurrentRow()
    },
    'keyboard.focusedColumnIndex': function() {
      this.focusCurrentRow()
    }
  }
}
</script>

<style>
:focus {
  outline: none;
}

.text-truncated {
  text-overflow: ellipsis;
  overflow: hidden;
  white-space: nowrap;
}

.bg-highlighted-lighter {
  background-color: #f0e1bf !important;
}
.bg-highlighted {
  background-color: #fdc33c !important;
}
</style>