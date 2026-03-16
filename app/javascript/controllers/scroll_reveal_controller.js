import { Controller } from "@hotwired/stimulus"

// Scroll-triggered reveal animations using IntersectionObserver
// Usage: data-controller="scroll-reveal"
//        data-scroll-reveal-stagger-value="150"  (ms stagger delay between items)
//        data-scroll-reveal-target="item" on each child to animate
// Re-triggers animation each time elements scroll back into view
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 0 },
    threshold: { type: Number, default: 0.15 },
    stagger: { type: Number, default: 100 }
  }

  static targets = ["item"]

  connect() {
    const elements = this.hasItemTarget ? this.itemTargets : [this.element]
    elements.forEach(el => {
      el.style.opacity = "0"
      el.style.transform = "translateY(1rem)"
      el.style.transition = "opacity 0.6s ease-out, transform 0.6s ease-out"
    })

    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      {
        threshold: this.thresholdValue,
        rootMargin: "0px 0px -50px 0px"
      }
    )

    if (this.hasItemTarget) {
      this.itemTargets.forEach(el => this.observer.observe(el))
    } else {
      this.observer.observe(this.element)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.revealElement(entry.target)
      } else {
        this.hideElement(entry.target)
      }
    })
  }

  revealElement(el) {
    if (this.hasItemTarget) {
      const index = this.itemTargets.indexOf(el)
      const staggerDelay = this.delayValue + (Math.max(0, index) * this.staggerValue)
      setTimeout(() => {
        el.style.opacity = "1"
        el.style.transform = "translateY(0)"
      }, staggerDelay)
    } else {
      setTimeout(() => {
        el.style.opacity = "1"
        el.style.transform = "translateY(0)"
      }, this.delayValue)
    }
  }

  hideElement(el) {
    el.style.opacity = "0"
    el.style.transform = "translateY(1rem)"
  }
}
