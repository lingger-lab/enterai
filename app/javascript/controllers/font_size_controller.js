import { Controller } from "@hotwired/stimulus"

// 시니어 친화: 글자 크기 조절 (작게/보통/크게)
// HTML 루트에 클래스를 적용하여 Tailwind/CSS에서 활용
export default class extends Controller {
  static targets = ["smallBtn", "normalBtn", "largeBtn"]

  connect() {
    const saved = this.read()
    this.applySize(saved || "normal")
  }

  small() { this.applySize("small") }
  normal() { this.applySize("normal") }
  large() { this.applySize("large") }

  applySize(size) {
    const root = document.documentElement
    root.classList.remove("font-size-small", "font-size-normal", "font-size-large")
    root.classList.add(`font-size-${size}`)
    this.save(size)
    this.updateButtonStates(size)
  }

  updateButtonStates(active) {
    const map = { small: this.smallBtnTarget?.dataset, normal: this.normalBtnTarget?.dataset, large: this.largeBtnTarget?.dataset }
    if (this.hasSmallBtnTarget) this.toggleActive(this.smallBtnTarget, active === "small")
    if (this.hasNormalBtnTarget) this.toggleActive(this.normalBtnTarget, active === "normal")
    if (this.hasLargeBtnTarget) this.toggleActive(this.largeBtnTarget, active === "large")
  }

  toggleActive(el, isActive) {
    if (!el) return
    el.setAttribute("aria-pressed", isActive ? "true" : "false")
    if (isActive) {
      el.classList.add("bg-indigo-600", "text-white")
      el.classList.remove("bg-gray-100", "text-gray-700")
    } else {
      el.classList.remove("bg-indigo-600", "text-white")
      el.classList.add("bg-gray-100", "text-gray-700")
    }
  }

  read() {
    try { return localStorage.getItem("enterlab_font_size") } catch (e) { return null }
  }

  save(size) {
    try { localStorage.setItem("enterlab_font_size", size) } catch (e) {}
  }
}
