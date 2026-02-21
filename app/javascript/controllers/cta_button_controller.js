import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.time = 0
    this.lastTime = performance.now()
    this.isHovered = false

    // Create shimmer overlay
    this.shimmer = document.createElement("span")
    this.shimmer.style.cssText = `
      position: absolute; inset: 0; overflow: hidden;
      border-radius: inherit; pointer-events: none;
    `
    const sheen = document.createElement("span")
    sheen.style.cssText = `
      position: absolute; top: -50%; left: -100%; width: 60%; height: 200%;
      background: linear-gradient(
        105deg,
        transparent 30%,
        rgba(255,255,255,0.35) 45%,
        rgba(255,255,255,0.5) 50%,
        rgba(255,255,255,0.35) 55%,
        transparent 70%
      );
      transform: skewX(-20deg);
    `
    this.sheen = sheen
    this.shimmer.appendChild(sheen)

    // Ensure button is positioned
    const pos = getComputedStyle(this.element).position
    if (pos === "static") this.element.style.position = "relative"
    this.element.style.overflow = "hidden"
    this.element.appendChild(this.shimmer)

    // Pulse glow state
    this.glowOpacity = 0
    this.glowSize = 0

    // Shimmer timing
    this.shimmerCycle = 4    // seconds between shimmers
    this.shimmerDuration = 0.8 // how long the sweep takes
    this.shimmerTimer = 1     // start first shimmer soon

    this._onEnter = () => { this.isHovered = true }
    this._onLeave = () => { this.isHovered = false }
    this.element.addEventListener("mouseenter", this._onEnter)
    this.element.addEventListener("mouseleave", this._onLeave)

    this.animationId = requestAnimationFrame(() => this.animate())
  }

  disconnect() {
    if (this.animationId) cancelAnimationFrame(this.animationId)
    this.element.removeEventListener("mouseenter", this._onEnter)
    this.element.removeEventListener("mouseleave", this._onLeave)
    if (this.shimmer.parentNode) this.shimmer.remove()
    this.element.style.boxShadow = ""
  }

  animate() {
    const now = performance.now()
    const dt = Math.min((now - this.lastTime) / 1000, 0.05)
    this.lastTime = now
    this.time += dt

    this.updateShimmer(dt)
    this.updateGlow(dt)

    this.animationId = requestAnimationFrame(() => this.animate())
  }

  updateShimmer(dt) {
    this.shimmerTimer += dt

    if (this.shimmerTimer >= this.shimmerCycle) {
      this.shimmerTimer = 0
    }

    if (this.shimmerTimer <= this.shimmerDuration) {
      // Sweep from -100% to +200%
      const progress = this.shimmerTimer / this.shimmerDuration
      // Ease-in-out
      const eased = progress < 0.5
        ? 2 * progress * progress
        : 1 - Math.pow(-2 * progress + 2, 2) / 2
      const leftPos = -100 + eased * 300
      this.sheen.style.left = `${leftPos}%`
      this.sheen.style.opacity = "1"
    } else {
      this.sheen.style.opacity = "0"
    }
  }

  updateGlow(dt) {
    // Continuous subtle pulse glow
    const basePulse = 0.15 + Math.sin(this.time * 2.5) * 0.1
    const targetOpacity = this.isHovered ? 0.6 : basePulse
    const targetSize = this.isHovered ? 25 : 10 + Math.sin(this.time * 2.5) * 5

    this.glowOpacity += (targetOpacity - this.glowOpacity) * 0.08
    this.glowSize += (targetSize - this.glowSize) * 0.08

    this.element.style.boxShadow =
      `0 0 ${this.glowSize.toFixed(0)}px rgba(99, 102, 241, ${this.glowOpacity.toFixed(2)}), ` +
      `0 4px ${(this.glowSize * 0.8).toFixed(0)}px rgba(99, 102, 241, ${(this.glowOpacity * 0.4).toFixed(2)})`
  }
}
