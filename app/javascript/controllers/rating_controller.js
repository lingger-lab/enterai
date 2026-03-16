import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input"]

  select(event) {
    const value = parseInt(event.currentTarget.dataset.value)
    this.inputTarget.value = value
    this.updateStars(value)
  }

  updateStars(value) {
    this.starTargets.forEach((star, index) => {
      if (index < value) {
        star.classList.remove("text-gray-300")
        star.classList.add("text-yellow-400")
      } else {
        star.classList.remove("text-yellow-400")
        star.classList.add("text-gray-300")
      }
    })
  }
}
