import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle() {
    const willOpen = this.menuTarget.classList.contains("hidden")
    this.menuTarget.classList.toggle("hidden")
    this.updateAria(willOpen)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.updateAria(false)
  }

  updateAria(isOpen) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", isOpen.toString())
    }
  }
}

