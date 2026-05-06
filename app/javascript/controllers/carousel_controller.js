import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "dot", "counter"]
  static values = {
    interval: { type: Number, default: 7000 },
    current: { type: Number, default: 0 },
    auto: { type: Boolean, default: true }
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
    if (!this.autoValue) return
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
    // 안전장치: 8초 후 자동 재개 (모바일 mouseleave/touchend 누락 대비)
    if (this.pauseTimeout) clearTimeout(this.pauseTimeout)
    this.pauseTimeout = setTimeout(() => this.startAuto(), 8000)
  }

  resume() {
    if (this.pauseTimeout) {
      clearTimeout(this.pauseTimeout)
      this.pauseTimeout = null
    }
    this.startAuto()
  }

  // 슬라이드 클릭 시 전체화면 확대
  zoom(event) {
    const img = event.currentTarget
    if (!img || !img.src) return

    const overlay = document.createElement('div')
    overlay.className = 'fixed inset-0 z-[100] bg-black/95 flex items-center justify-center cursor-zoom-out p-4'
    overlay.setAttribute('role', 'dialog')
    overlay.setAttribute('aria-label', '슬라이드 확대 보기')
    overlay.innerHTML = `
      <img src="${img.src}" alt="${img.alt || ''}" class="max-w-full max-h-full object-contain pointer-events-none">
      <button type="button" aria-label="닫기" class="absolute top-3 right-3 w-11 h-11 bg-white/10 hover:bg-white/20 active:bg-white/30 text-white rounded-full flex items-center justify-center transition-colors text-2xl backdrop-blur-sm">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
      </button>
      <p class="absolute bottom-4 left-1/2 -translate-x-1/2 text-xs text-white/70 bg-black/30 px-3 py-1.5 rounded-full backdrop-blur-sm pointer-events-none">탭하면 닫힙니다 · 모바일은 손가락으로 확대 가능</p>
    `

    const close = () => {
      overlay.remove()
      document.removeEventListener('keydown', escHandler)
      document.body.style.overflow = ''
    }
    const escHandler = (e) => { if (e.key === 'Escape') close() }
    overlay.addEventListener('click', close)
    document.addEventListener('keydown', escHandler)
    document.body.style.overflow = 'hidden'
    document.body.appendChild(overlay)
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
