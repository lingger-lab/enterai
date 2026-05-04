import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["btn", "panel"]
  static values = {
    interval: { type: Number, default: 16000 },
    current: { type: Number, default: 0 }
  }

  connect() {
    this.isHovered = false
    this.setupObserver()
  }

  disconnect() {
    this.stopAutoRotation()
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupObserver() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.startAutoRotation()
          } else {
            this.stopAutoRotation()
          }
        })
      },
      { threshold: 0.3 }
    )
    this.observer.observe(this.element)
  }

  startAutoRotation() {
    if (this.timer) return
    this.timer = setInterval(() => {
      if (!this.isHovered) {
        const next = (this.currentValue + 1) % this.panelTargets.length
        this.switchTo(next)
      }
    }, this.intervalValue)
  }

  stopAutoRotation() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  resetAutoRotation() {
    this.stopAutoRotation()
    this.startAutoRotation()
  }

  switch(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.switchTo(index)
    this.resetAutoRotation()
  }

  switchTo(index) {
    const currentPanel = this.panelTargets[this.currentValue]
    const nextPanel = this.panelTargets[index]

    if (currentPanel === nextPanel) return

    // fade out current
    currentPanel.style.opacity = "0"
    currentPanel.style.transform = "translateY(0.5rem)"

    setTimeout(() => {
      // hide current, show next
      this.panelTargets.forEach((panel, i) => {
        panel.classList.toggle("hidden", i !== index)
      })

      // prepare next for fade in
      nextPanel.style.opacity = "0"
      nextPanel.style.transform = "translateY(0.5rem)"

      // trigger reflow then fade in
      void nextPanel.offsetHeight
      nextPanel.style.opacity = "1"
      nextPanel.style.transform = "translateY(0)"
    }, 300)

    // update buttons
    this.btnTargets.forEach((btn, i) => {
      if (i === index) {
        btn.classList.add("bg-indigo-600", "text-white", "border-indigo-600")
        btn.classList.remove("text-gray-600", "border-gray-300")
      } else {
        btn.classList.remove("bg-indigo-600", "text-white", "border-indigo-600")
        btn.classList.add("text-gray-600", "border-gray-300")
      }
    })

    this.currentValue = index
  }

  panelEnter() {
    this.isHovered = true
    // 안전장치: 8초 후 자동 해제 (모바일 touchend 누락 대비)
    if (this.hoverTimeout) clearTimeout(this.hoverTimeout)
    this.hoverTimeout = setTimeout(() => {
      this.isHovered = false
    }, 8000)
  }

  panelLeave() {
    this.isHovered = false
    if (this.hoverTimeout) {
      clearTimeout(this.hoverTimeout)
      this.hoverTimeout = null
    }
  }
}
