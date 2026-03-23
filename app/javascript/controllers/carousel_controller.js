import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "dot", "counter"]
  static values = {
    interval: { type: Number, default: 14000 },
    current: { type: Number, default: 0 }
  }

  connect() {
    this.total = this.slideTargets.length
    this.touchStartX = 0
    this.touchDeltaX = 0
    this.isDragging = false
    this.updateUI()
    this.setupObserver()
    this.setupKeyboard()
  }

  disconnect() {
    this.stopAuto()
    if (this.observer) this.observer.disconnect()
    if (this.keyHandler) document.removeEventListener("keydown", this.keyHandler)
  }

  setupObserver() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.startAuto()
          } else {
            this.stopAuto()
          }
        })
      },
      { threshold: 0.3 }
    )
    this.observer.observe(this.element)
  }

  setupKeyboard() {
    this.keyHandler = (e) => {
      if (!this.isElementInViewport()) return
      if (e.key === "ArrowLeft") { this.prev(); this.resetAuto() }
      if (e.key === "ArrowRight") { this.next(); this.resetAuto() }
    }
    document.addEventListener("keydown", this.keyHandler)
  }

  isElementInViewport() {
    const rect = this.element.getBoundingClientRect()
    return rect.top < window.innerHeight && rect.bottom > 0
  }

  // Navigation
  next() {
    this.goTo((this.currentValue + 1) % this.total)
  }

  prev() {
    this.goTo((this.currentValue - 1 + this.total) % this.total)
  }

  goTo(index) {
    this.currentValue = index
    this.updateUI()
  }

  selectDot(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.goTo(index)
    this.resetAuto()
  }

  // UI Update
  updateUI() {
    // Move track
    const offset = -(this.currentValue * 100)
    this.trackTarget.style.transform = `translateX(${offset}%)`

    // Update dots
    this.dotTargets.forEach((dot, i) => {
      if (i === this.currentValue) {
        dot.classList.remove("bg-gray-300")
        dot.classList.add("bg-indigo-600", "scale-125")
      } else {
        dot.classList.remove("bg-indigo-600", "scale-125")
        dot.classList.add("bg-gray-300")
      }
    })

    // Update counter
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentValue + 1} / ${this.total}`
    }
  }

  // Auto rotation
  startAuto() {
    if (this.timer) return
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  stopAuto() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  resetAuto() {
    this.stopAuto()
    this.startAuto()
  }

  pause() {
    this.stopAuto()
  }

  resume() {
    this.startAuto()
  }

  // Touch swipe
  touchStart(event) {
    this.touchStartX = event.touches[0].clientX
    this.touchStartY = event.touches[0].clientY
    this.isDragging = true
    this.touchDeltaX = 0
    this.trackTarget.style.transition = "none"
    this.stopAuto()
  }

  touchMove(event) {
    if (!this.isDragging) return

    const currentX = event.touches[0].clientX
    const currentY = event.touches[0].clientY
    this.touchDeltaX = currentX - this.touchStartX
    const deltaY = Math.abs(currentY - this.touchStartY)

    // Horizontal swipe detected — prevent vertical scroll
    if (Math.abs(this.touchDeltaX) > deltaY && Math.abs(this.touchDeltaX) > 10) {
      event.preventDefault()
    }

    // Real-time drag feedback
    const baseOffset = -(this.currentValue * 100)
    const dragPercent = (this.touchDeltaX / this.element.offsetWidth) * 100
    this.trackTarget.style.transform = `translateX(${baseOffset + dragPercent}%)`
  }

  touchEnd() {
    if (!this.isDragging) return
    this.isDragging = false
    this.trackTarget.style.transition = "transform 0.4s ease-in-out"

    if (this.touchDeltaX > 50) {
      this.prev()
    } else if (this.touchDeltaX < -50) {
      this.next()
    } else {
      this.updateUI() // snap back
    }

    this.startAuto()
  }
}
