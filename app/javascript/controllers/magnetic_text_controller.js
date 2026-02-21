import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  connect() {
    const isMobile = "ontouchstart" in window || navigator.maxTouchPoints > 0

    this.radius = isMobile ? 150 : 280
    this.strength = 0.5
    this.maxDisplacement = 30
    this.ease = 0.12
    this.returnEase = 0.06
    this.maxRotation = 8      // degrees
    this.maxScale = 1.2

    this.pointerX = -9999
    this.pointerY = -9999
    this.isPointerActive = false

    // Save original HTML for restoration
    this.originalHTMLs = this.textTargets.map(el => el.innerHTML)

    // Split text into per-character spans
    this.charStates = []
    this.textTargets.forEach(el => {
      this.splitTextNodes(el)
    })

    // Cache positions after split
    this.cachePositions()

    // Event handlers
    this._onMouseMove = (e) => {
      this.pointerX = e.clientX
      this.pointerY = e.clientY
      this.isPointerActive = true
      this.ensureAnimating()
    }
    this._onMouseLeave = () => {
      this.pointerX = -9999
      this.pointerY = -9999
      this.isPointerActive = false
    }
    this._onTouchMove = (e) => {
      const touch = e.touches[0]
      if (touch) {
        this.pointerX = touch.clientX
        this.pointerY = touch.clientY
        this.isPointerActive = true
        this.ensureAnimating()
      }
    }
    this._onTouchEnd = () => {
      this.pointerX = -9999
      this.pointerY = -9999
      this.isPointerActive = false
    }

    this._onResize = () => {
      clearTimeout(this._resizeTimer)
      this._resizeTimer = setTimeout(() => this.cachePositions(), 150)
    }

    this.element.addEventListener("mousemove", this._onMouseMove)
    this.element.addEventListener("mouseleave", this._onMouseLeave)
    this.element.addEventListener("touchmove", this._onTouchMove, { passive: true })
    this.element.addEventListener("touchend", this._onTouchEnd, { passive: true })
    window.addEventListener("resize", this._onResize)

    this.animationId = null
    this.animate()
  }

  disconnect() {
    if (this.animationId) cancelAnimationFrame(this.animationId)
    clearTimeout(this._resizeTimer)

    this.element.removeEventListener("mousemove", this._onMouseMove)
    this.element.removeEventListener("mouseleave", this._onMouseLeave)
    this.element.removeEventListener("touchmove", this._onTouchMove)
    this.element.removeEventListener("touchend", this._onTouchEnd)
    window.removeEventListener("resize", this._onResize)

    // Restore original HTML
    this.textTargets.forEach((el, i) => {
      if (this.originalHTMLs[i] !== undefined) {
        el.innerHTML = this.originalHTMLs[i]
      }
    })
  }

  /**
   * Split all text inside an element into per-character <span> elements.
   * Handles nested elements (preserving classes), <br> tags, and whitespace.
   */
  splitTextNodes(element) {
    const fragment = document.createDocumentFragment()
    const childNodes = Array.from(element.childNodes)

    for (const node of childNodes) {
      if (node.nodeType === Node.TEXT_NODE) {
        this.splitText(node.textContent, null, fragment)
      } else if (node.nodeType === Node.ELEMENT_NODE) {
        if (node.tagName === "BR") {
          fragment.appendChild(node.cloneNode())
        } else {
          // Nested element (e.g., <span class="text-indigo-600">)
          // Split its text content but preserve the element's classes
          const classes = Array.from(node.classList)
          const innerNodes = Array.from(node.childNodes)
          for (const inner of innerNodes) {
            if (inner.nodeType === Node.TEXT_NODE) {
              this.splitText(inner.textContent, classes, fragment)
            } else if (inner.nodeType === Node.ELEMENT_NODE && inner.tagName === "BR") {
              fragment.appendChild(inner.cloneNode())
            }
          }
        }
      }
    }

    element.innerHTML = ""
    element.appendChild(fragment)
  }

  /**
   * Split a text string into individual character <span> elements.
   * @param {string} text - The text to split
   * @param {string[]|null} extraClasses - CSS classes to apply (for preserving nested element styles)
   * @param {DocumentFragment} fragment - Target fragment to append spans to
   */
  splitText(text, extraClasses, fragment) {
    for (const char of text) {
      const span = document.createElement("span")
      span.textContent = char
      span.style.display = "inline-block"
      span.style.whiteSpace = "pre"
      span.style.willChange = "transform"

      if (extraClasses && extraClasses.length > 0) {
        span.classList.add(...extraClasses)
      }

      span.style.transition = "opacity 0.3s"

      fragment.appendChild(span)
      this.charStates.push({
        el: span, currentX: 0, currentY: 0,
        currentRot: 0, currentScale: 1,
        baseX: 0, baseY: 0
      })
    }
  }

  /**
   * Cache the base position of each character span.
   * Called on connect and on window resize.
   */
  cachePositions() {
    const scrollX = window.scrollX
    const scrollY = window.scrollY
    for (const state of this.charStates) {
      const rect = state.el.getBoundingClientRect()
      state.baseX = rect.left + rect.width / 2 + scrollX
      state.baseY = rect.top + rect.height / 2 + scrollY
    }
  }

  ensureAnimating() {
    if (!this.animationId) {
      this.animate()
    }
  }

  animate() {
    const shouldContinue = this.update()
    if (shouldContinue) {
      this.animationId = requestAnimationFrame(() => this.animate())
    } else {
      this.animationId = null
    }
  }

  update() {
    const scrollX = window.scrollX
    const scrollY = window.scrollY
    let anyMoving = false

    for (const state of this.charStates) {
      const centerX = state.baseX - scrollX
      const centerY = state.baseY - scrollY

      const dx = this.pointerX - centerX
      const dy = this.pointerY - centerY
      const dist = Math.sqrt(dx * dx + dy * dy)

      let targetX = 0
      let targetY = 0
      let targetRot = 0
      let targetScale = 1

      if (dist < this.radius) {
        const proximity = 1 - dist / this.radius
        const force = this.strength * proximity
        targetX = dx * force
        targetY = dy * force

        const mag = Math.sqrt(targetX * targetX + targetY * targetY)
        if (mag > this.maxDisplacement) {
          targetX = (targetX / mag) * this.maxDisplacement
          targetY = (targetY / mag) * this.maxDisplacement
        }

        // Rotation: tilt toward cursor direction
        targetRot = (dx / this.radius) * this.maxRotation * proximity
        // Scale: grow when close
        targetScale = 1 + (this.maxScale - 1) * proximity * proximity
      }

      const easing = (targetX === 0 && targetY === 0) ? this.returnEase : this.ease
      state.currentX += (targetX - state.currentX) * easing
      state.currentY += (targetY - state.currentY) * easing
      state.currentRot += (targetRot - state.currentRot) * easing
      state.currentScale += (targetScale - state.currentScale) * easing

      const isMoving = Math.abs(state.currentX) > 0.05 ||
                        Math.abs(state.currentY) > 0.05 ||
                        Math.abs(state.currentScale - 1) > 0.001 ||
                        Math.abs(state.currentRot) > 0.05

      if (isMoving) {
        state.el.style.transform = `translate(${state.currentX.toFixed(1)}px, ${state.currentY.toFixed(1)}px) rotate(${state.currentRot.toFixed(1)}deg) scale(${state.currentScale.toFixed(3)})`
        anyMoving = true
      } else if (state.currentX !== 0 || state.currentY !== 0 || state.currentScale !== 1 || state.currentRot !== 0) {
        state.currentX = 0
        state.currentY = 0
        state.currentRot = 0
        state.currentScale = 1
        state.el.style.transform = ""
      }
    }

    return anyMoving || this.isPointerActive
  }
}
