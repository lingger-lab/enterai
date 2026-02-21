import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.isHovered = false
    this.animationId = null
    this.time = 0
    this.bouncePhase = 0 // 0=idle, 1=squash, 2=stretch, 3=settle

    // Save original transform
    this.baseScale = 1
    this.baseRotate = 0
    this.baseY = 0

    // Animation state
    this.currentScale = 1
    this.currentScaleX = 1
    this.currentScaleY = 1
    this.currentRotate = 0
    this.currentY = 0
    this.glowOpacity = 0
    this.bounceTime = 0

    this._onEnter = () => this.onEnter()
    this._onLeave = () => this.onLeave()

    this.element.addEventListener("mouseenter", this._onEnter)
    this.element.addEventListener("mouseleave", this._onLeave)
    this.element.style.willChange = "transform"
  }

  disconnect() {
    this.element.removeEventListener("mouseenter", this._onEnter)
    this.element.removeEventListener("mouseleave", this._onLeave)
    if (this.animationId) cancelAnimationFrame(this.animationId)
    this.element.style.transform = ""
    this.element.style.boxShadow = ""
    this.element.style.willChange = ""
  }

  onEnter() {
    this.isHovered = true
    this.time = 0
    this.bouncePhase = 1
    this.bounceTime = 0
    this.ensureAnimating()
  }

  onLeave() {
    this.isHovered = false
    this.bouncePhase = 0
  }

  ensureAnimating() {
    if (!this.animationId) {
      this.lastTime = performance.now()
      this.animate()
    }
  }

  animate() {
    const now = performance.now()
    const dt = Math.min((now - this.lastTime) / 1000, 0.05) // cap at 50ms
    this.lastTime = now

    const shouldContinue = this.update(dt)
    if (shouldContinue) {
      this.animationId = requestAnimationFrame(() => this.animate())
    } else {
      this.animationId = null
    }
  }

  update(dt) {
    this.time += dt
    this.bounceTime += dt

    let targetY = 0
    let targetScaleX = 1
    let targetScaleY = 1
    let targetRotate = 0
    let targetGlow = 0

    if (this.isHovered) {
      // === Bounce/Jelly entrance (first 0.6s) ===
      if (this.bouncePhase > 0 && this.bounceTime < 0.6) {
        const t = this.bounceTime

        if (t < 0.1) {
          // Phase 1: Squash down
          const p = t / 0.1
          targetScaleX = 1 + 0.15 * p
          targetScaleY = 1 - 0.12 * p
          targetY = 2 * p
        } else if (t < 0.25) {
          // Phase 2: Stretch up (bounce)
          const p = (t - 0.1) / 0.15
          targetScaleX = 1.15 - 0.25 * p
          targetScaleY = 0.88 + 0.27 * p
          targetY = 2 - 10 * p
        } else if (t < 0.4) {
          // Phase 3: Settle back with overshoot
          const p = (t - 0.25) / 0.15
          targetScaleX = 0.9 + 0.15 * p
          targetScaleY = 1.15 - 0.08 * p
          targetY = -8 + 5 * p
        } else {
          // Phase 4: Final settle
          const p = (t - 0.4) / 0.2
          targetScaleX = 1.05 - 0.05 * p
          targetScaleY = 1.07 - 0.07 * p
          targetY = -3 + 3 * p
        }

        // Jelly rotation wiggle
        targetRotate = Math.sin(t * 25) * 6 * (1 - t / 0.6)
      } else {
        this.bouncePhase = 0

        // === Continuous hover: floating + pulse ===
        // Gentle floating up/down
        targetY = Math.sin(this.time * 2.5) * 3
        // Subtle breathing scale
        targetScaleX = 1 + Math.sin(this.time * 3) * 0.04
        targetScaleY = 1 + Math.sin(this.time * 3) * 0.04
        // Subtle rotation sway
        targetRotate = Math.sin(this.time * 2) * 3
      }

      // Pulsing glow
      targetGlow = 0.5 + Math.sin(this.time * 4) * 0.3
    }

    // Lerp all values
    const ease = this.isHovered ? 0.15 : 0.08
    this.currentScaleX += (targetScaleX - this.currentScaleX) * ease
    this.currentScaleY += (targetScaleY - this.currentScaleY) * ease
    this.currentRotate += (targetRotate - this.currentRotate) * ease
    this.currentY += (targetY - this.currentY) * ease
    this.glowOpacity += (targetGlow - this.glowOpacity) * ease

    // Check if still animating
    const isMoving =
      Math.abs(this.currentScaleX - targetScaleX) > 0.001 ||
      Math.abs(this.currentScaleY - targetScaleY) > 0.001 ||
      Math.abs(this.currentRotate - targetRotate) > 0.01 ||
      Math.abs(this.currentY - targetY) > 0.05 ||
      Math.abs(this.glowOpacity - targetGlow) > 0.005

    if (isMoving || this.isHovered) {
      // Apply transform
      this.element.style.transform =
        `translateY(${this.currentY.toFixed(1)}px) ` +
        `scale(${this.currentScaleX.toFixed(3)}, ${this.currentScaleY.toFixed(3)}) ` +
        `rotate(${this.currentRotate.toFixed(1)}deg)`

      // Apply glow shadow
      if (this.glowOpacity > 0.01) {
        const glowSize = 12 + Math.sin(this.time * 4) * 6
        this.element.style.boxShadow =
          `0 0 ${glowSize.toFixed(0)}px rgba(99, 102, 241, ${this.glowOpacity.toFixed(2)}), ` +
          `0 4px 15px rgba(99, 102, 241, ${(this.glowOpacity * 0.5).toFixed(2)})`
      }

      return true
    } else {
      // Reset to clean state
      if (!this.isHovered) {
        this.currentScaleX = 1
        this.currentScaleY = 1
        this.currentRotate = 0
        this.currentY = 0
        this.glowOpacity = 0
        this.element.style.transform = ""
        this.element.style.boxShadow = ""
      }
      return this.isHovered
    }
  }
}
