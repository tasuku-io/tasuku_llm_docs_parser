// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Import CodeMirror
import {EditorView, basicSetup} from "codemirror"
import {EditorState} from "@codemirror/state"
import {markdown} from "@codemirror/lang-markdown"
import {json} from "@codemirror/lang-json"
import {oneDark} from "@codemirror/theme-one-dark"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Define hooks for LiveView
let Hooks = {}

Hooks.CodeMirror = {
  mounted() {
    // Find the textarea within this hook element
    const textarea = this.el.querySelector('textarea')
    if (!textarea) return
    
    // Create a hidden textarea for form submission
    this.hiddenTextarea = document.createElement('textarea')
    this.hiddenTextarea.name = textarea.name
    this.hiddenTextarea.style.display = 'none'
    this.hiddenTextarea.value = textarea.value
    this.el.appendChild(this.hiddenTextarea)
    
    // Create CodeMirror editor
    this.editor = new EditorView({
      state: EditorState.create({
        doc: textarea.value,
        extensions: [
          basicSetup,
          markdown(),
          oneDark,
          EditorView.updateListener.of((update) => {
            if (update.docChanged) {
              // Update the hidden textarea when content changes
              this.hiddenTextarea.value = this.editor.state.doc.toString()
              // Dispatch input event to notify LiveView
              this.hiddenTextarea.dispatchEvent(new Event('input', { bubbles: true }))
            }
          }),
          EditorView.theme({
            "&": {
              height: "40vh"
            },
            ".cm-scroller": {
              fontFamily: "'Monaco', 'Menlo', 'Ubuntu Mono', monospace"
            }
          })
        ]
      }),
      parent: this.el
    })
    
    // Remove the original textarea
    textarea.remove()
    
    // Store the current content to prevent unnecessary updates
    this.lastValue = this.hiddenTextarea.value
  },
  
  updated() {
    // Only update if the external value actually changed and differs from editor content
    const currentEditorContent = this.editor ? this.editor.state.doc.toString() : ''
    const newValue = this.hiddenTextarea ? this.hiddenTextarea.value : ''
    
    if (this.editor && newValue !== this.lastValue && newValue !== currentEditorContent) {
      this.editor.dispatch({
        changes: {
          from: 0,
          to: this.editor.state.doc.length,
          insert: newValue
        }
      })
      this.lastValue = newValue
    }
  },
  
  destroyed() {
    if (this.editor) {
      this.editor.destroy()
    }
  }
}

Hooks.CodeMirrorOutput = {
  mounted() {
    this.createEditor()
  },
  
  updated() {
    this.createEditor()
  },
  
  createEditor() {
    // Destroy existing editor if it exists
    if (this.editor) {
      this.editor.destroy()
    }
    
    // Get the content from the data attribute
    const content = this.el.dataset.content || ""
    
    if (content) {
      // Create read-only CodeMirror editor for JSON output
      this.editor = new EditorView({
        state: EditorState.create({
          doc: content,
          extensions: [
            basicSetup,
            json(),
            oneDark,
            EditorView.editable.of(false), // Make it read-only
            EditorView.theme({
              "&": {
                height: "60vh"
              },
              ".cm-scroller": {
                fontFamily: "'Monaco', 'Menlo', 'Ubuntu Mono', monospace"
              },
              ".cm-content": {
                padding: "12px"
              }
            })
          ]
        }),
        parent: this.el
      })
    }
  },
  
  destroyed() {
    if (this.editor) {
      this.editor.destroy()
    }
  }
}

Hooks.CopyToClipboard = {
  mounted() {
    // This hook is now on the copy button, not the output area
    this.handleEvent("copy_to_clipboard", ({text}) => {
      navigator.clipboard.writeText(text).then(() => {
        // Show temporary success feedback
        this.pushEventTo(this.el, "clipboard_copied", {})
      }).catch(err => {
        console.error('Failed to copy text: ', err)
      })
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

