import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["node", "subgoalSelect", "completedCheckbox"]

  connect() {
    requestAnimationFrame(() => {
      this.element.classList.add("goal-map-page--ready")
    })
  }

  select(event) {
    this.element.querySelectorAll(".is-selected").forEach((element) => {
      element.classList.remove("is-selected")
    })

    const selectable = event.currentTarget
    selectable.classList.add("is-selected")

    if (selectable.classList.contains("goal-map-node")) {
      this.moveCurrentLocation(selectable)
    }
  }

  selectReward(event) {
    this.element.querySelectorAll(".is-selected").forEach((element) => {
      element.classList.remove("is-selected")
    })

    const rewardPoint = event.currentTarget.closest(".goal-map-reward-point")

    if (rewardPoint) {
      rewardPoint.classList.add("is-selected")
    }
  }

  openPanelSection(event) {
    const section = event.target.closest(".goal-map-panel__section--collapsible")

    if (section) {
      section.open = true
      section.setAttribute("open", "")
    }
  }

  moveCurrentLocation(node) {
    this.element.querySelectorAll(".goal-map-node.is-current").forEach((element) => {
      element.classList.remove("is-current")
    })

    node.classList.add("is-current")

    const nodeGroup = node.closest(".goal-map-node-group")
    let currentLabel = this.element.querySelector(".goal-map-current-label")

    if (!currentLabel) {
      currentLabel = document.createElement("span")
      currentLabel.className = "goal-map-current-label"
      currentLabel.textContent = "現在地"
    }

    if (nodeGroup && currentLabel.parentElement !== nodeGroup) {
      nodeGroup.prepend(currentLabel)
    }
  }

  changeTodoSubgoal(event) {
    const form = event.target.closest("form")

    if (form && event.target.value) {
      form.action = event.target.value
    }
  }

  setCompletedAt(event) {
    event.target.value = event.target.checked ? new Date().toISOString() : ""
  }
}
