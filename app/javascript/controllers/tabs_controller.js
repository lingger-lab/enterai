import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["btn", "panel"]

  switch(event) {
    const index = parseInt(event.currentTarget.dataset.index)

    this.btnTargets.forEach((btn, i) => {
      if (i === index) {
        btn.classList.add("bg-indigo-600", "text-white", "border-indigo-600")
        btn.classList.remove("text-gray-600", "border-gray-300")
      } else {
        btn.classList.remove("bg-indigo-600", "text-white", "border-indigo-600")
        btn.classList.add("text-gray-600", "border-gray-300")
      }
    })

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
