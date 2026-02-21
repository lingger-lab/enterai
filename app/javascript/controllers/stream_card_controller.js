import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.played = false
    this.isAnimating = false
    this._timeouts = []

    // Collect streamable text elements in DOM order
    this.items = []
    this.element.querySelectorAll("h3, p, li").forEach(node => {
      if (node.tagName === "LI") {
        // For <li>, stream only the last <span> (skip the bullet)
        const textSpan = node.querySelector("span:last-child")
        if (textSpan && textSpan.previousElementSibling) {
          this.items.push({ el: textSpan, original: textSpan.textContent, speed: 18 })
        }
      } else {
        this.items.push({ el: node, original: node.textContent, speed: node.tagName === "H3" ? 30 : 20 })
      }
    })

    this._onEnter = () => this.play()
    this.element.addEventListener("mouseenter", this._onEnter)
  }

  disconnect() {
    this.element.removeEventListener("mouseenter", this._onEnter)
    this.cancelAnimation()
    this.items.forEach(item => {
      item.el.textContent = item.original
      item.el.style.borderRight = ""
    })
  }

  cancelAnimation() {
    this._timeouts.forEach(t => clearTimeout(t))
    this._timeouts = []
  }

  play() {
    if (this.played || this.isAnimating) return
    this.isAnimating = true

    // Hide all text instantly
    this.items.forEach(item => {
      item.el.textContent = ""
      item.el.style.minHeight = "1em"
    })

    this.streamSequential(0)
  }

  streamSequential(index) {
    if (index >= this.items.length) {
      this.isAnimating = false
      this.played = true
      return
    }

    const item = this.items[index]
    const chars = [...item.original]

    // Show typing cursor on current element
    item.el.style.borderRight = "2px solid #6366f1"

    chars.forEach((char, i) => {
      const t = setTimeout(() => {
        item.el.textContent += char
      }, i * item.speed)
      this._timeouts.push(t)
    })

    // After this element finishes, move to next
    const finishDelay = chars.length * item.speed
    const t = setTimeout(() => {
      item.el.style.borderRight = ""
      item.el.style.minHeight = ""
      this.streamSequential(index + 1)
    }, finishDelay)
    this._timeouts.push(t)
  }
}
