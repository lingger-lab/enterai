import { Controller } from "@hotwired/stimulus"

// Privacy policy modal controller
// Usage: data-controller="privacy-modal"
//        data-action="click->privacy-modal#open" on trigger link
//        data-privacy-modal-target="modal" on modal container
export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  backdropClose(event) {
    if (event.target === this.modalTarget) {
      this.close(event)
    }
  }

  connect() {
    this._escHandler = (e) => {
      if (e.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
        this.close()
      }
    }
    document.addEventListener("keydown", this._escHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this._escHandler)
    document.body.style.overflow = ""
  }
}
