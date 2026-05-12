import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const SHORTCUT_PATHS = {
  "1": "/",
  "2": "/onboarding",
  "3": "/today",
  "4": "/rest",
}

export default class extends Controller {
  connect() {
    this.animations = []
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleTurboLoad = this.handleTurboLoad.bind(this)
    this.handleTurboBeforeVisit = this.handleTurboBeforeVisit.bind(this)

    document.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("turbo:load", this.handleTurboLoad)
    document.addEventListener("turbo:render", this.handleTurboLoad)
    document.addEventListener("turbo:before-visit", this.handleTurboBeforeVisit)

    this.preparePage()
  }

  disconnect() {
    this.cancelAnimations()
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("turbo:load", this.handleTurboLoad)
    document.removeEventListener("turbo:render", this.handleTurboLoad)
    document.removeEventListener("turbo:before-visit", this.handleTurboBeforeVisit)
  }

  handleTurboLoad() {
    this.preparePage()
  }

  handleTurboBeforeVisit() {
    const shell = this.prototypeShell

    if (shell) {
      shell.classList.remove("prototype-shell--visible")
    }
  }

  handleKeydown(event) {
    if (!this.prototypeShell || this.shouldIgnoreShortcut(event)) {
      return
    }

    const path = SHORTCUT_PATHS[event.key]

    if (!path || window.location.pathname === path) {
      return
    }

    event.preventDefault()
    Turbo.visit(path)
  }

  preparePage() {
    const shell = this.prototypeShell

    if (!shell) {
      return
    }

    shell.classList.remove("prototype-shell--visible")
    shell.classList.add("prototype-shell--animated")

    window.requestAnimationFrame(() => {
      shell.classList.add("prototype-shell--visible")
      this.animatePage(shell)
    })
  }

  animatePage(shell) {
    this.cancelAnimations()

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return
    }

    this.trackAnimation(shell.animate([
      { opacity: 0, transform: "translateY(8px)" },
      { opacity: 1, transform: "translateY(0)" },
    ], {
      duration: 420,
      easing: "cubic-bezier(0.22, 1, 0.36, 1)",
      fill: "both",
    }))

    // Keep persistent overlays invisible so the generated UI mockups remain visually faithful.
  }

  trackAnimation(animation) {
    this.animations.push(animation)
  }

  cancelAnimations() {
    this.animations?.forEach((animation) => animation.cancel())
    this.animations = []
  }

  shouldIgnoreShortcut(event) {
    if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
      return true
    }

    const tagName = event.target?.tagName

    return event.target?.isContentEditable || tagName === "INPUT" || tagName === "TEXTAREA" || tagName === "SELECT"
  }

  get prototypeShell() {
    return document.querySelector(".prototype-shell")
  }

  get prototypeImage() {
    return document.querySelector(".prototype-image")
  }

  get prototypeHotspots() {
    return document.querySelectorAll(".prototype-hotspot")
  }
}
