import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progressBar", "stepNumber", "progressPercent", "form"]
  static values = {
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 10 }
  }

  connect() {
    this.showStep(this.currentStepValue)
    this.updateProgress()
    this.setupSubmitGuard()
    this.setupAutoSave()
  }

  setupSubmitGuard() {
    const form = this.element.querySelector('#reservation-form')
    if (!form) return
    form.addEventListener('submit', (e) => {
      const submitBtn = form.querySelector('button[type="submit"], input[type="submit"]')
      if (!submitBtn) return
      if (submitBtn.dataset.submitting === "true") {
        e.preventDefault()
        return
      }
      submitBtn.dataset.submitting = "true"
      submitBtn.disabled = true
      const originalText = submitBtn.textContent || submitBtn.value
      submitBtn.dataset.originalText = originalText
      if (submitBtn.tagName === "BUTTON") {
        submitBtn.innerHTML = '<span class="inline-flex items-center gap-2"><svg class="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"></path></svg>처리 중...</span>'
      } else {
        submitBtn.value = "처리 중..."
      }
      // 안전장치: 30초 후 다시 활성화 (네트워크 오류 등 대비)
      setTimeout(() => {
        if (submitBtn.dataset.submitting === "true") {
          submitBtn.disabled = false
          submitBtn.dataset.submitting = "false"
          if (submitBtn.tagName === "BUTTON") {
            submitBtn.textContent = submitBtn.dataset.originalText
          } else {
            submitBtn.value = submitBtn.dataset.originalText
          }
        }
      }, 30000)
    })
  }

  // localStorage 자동 저장/복구
  storageKey() {
    const serviceType = this.element.querySelector('#reservation_service_type')?.value || 'coaching'
    return `enterlab_reservation_${serviceType}`
  }

  setupAutoSave() {
    const form = this.element.querySelector('#reservation-form')
    if (!form) return
    this.restoreFromStorage()
    form.addEventListener('input', () => this.saveToStorage())
    form.addEventListener('change', () => this.saveToStorage())
    form.addEventListener('submit', () => this.clearStorage())
  }

  saveToStorage() {
    try {
      const form = this.element.querySelector('#reservation-form')
      if (!form) return
      const data = {}
      const inputs = form.querySelectorAll('input:not([type="hidden"]):not([name="authenticity_token"]):not([type="submit"]), textarea, select')
      inputs.forEach(input => {
        const name = input.name
        if (!name) return
        if (input.type === 'checkbox') {
          if (name.endsWith('[]')) {
            if (!data[name]) data[name] = []
            if (input.checked) data[name].push(input.value)
          } else {
            data[name] = input.checked
          }
        } else if (input.type === 'radio') {
          if (input.checked) data[name] = input.value
        } else {
          data[name] = input.value
        }
      })
      data._step = this.currentStepValue
      localStorage.setItem(this.storageKey(), JSON.stringify(data))
    } catch (e) {
      // localStorage 비활성/시크릿 모드 무시
    }
  }

  restoreFromStorage() {
    try {
      const raw = localStorage.getItem(this.storageKey())
      if (!raw) return
      const data = JSON.parse(raw)
      const form = this.element.querySelector('#reservation-form')
      if (!form) return
      Object.entries(data).forEach(([name, value]) => {
        if (name === '_step') return
        if (Array.isArray(value)) {
          value.forEach(v => {
            const input = form.querySelector(`input[name="${name}"][value="${v}"]`)
            if (input) input.checked = true
          })
        } else if (typeof value === 'boolean') {
          const input = form.querySelector(`input[name="${name}"]`)
          if (input && input.type === 'checkbox') input.checked = value
        } else {
          const radio = form.querySelector(`input[name="${name}"][value="${value}"]`)
          if (radio && radio.type === 'radio') {
            radio.checked = true
          } else {
            const input = form.querySelector(`[name="${name}"]`)
            if (input && input.type !== 'hidden') input.value = value
          }
        }
      })
    } catch (e) {
      // 복구 실패 무시
    }
  }

  clearStorage() {
    try {
      localStorage.removeItem(this.storageKey())
    } catch (e) {
      // 무시
    }
  }

  next(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.clearErrors()

    if (this.validateCurrentStep()) {
      if (this.currentStepValue < this.totalStepsValue) {
        this.currentStepValue++
        this.showStep(this.currentStepValue)
        this.updateProgress()
      }
    }
  }

  previous(event) {
    event.preventDefault()
    event.stopPropagation()

    this.clearErrors()

    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showStep(this.currentStepValue)
      this.updateProgress()
    }
  }

  showStep(step) {
    this.stepTargets.forEach((stepElement, index) => {
      if (index + 1 === step) {
        stepElement.classList.remove("hidden")
        if (step === 10) {
          this.updateReview()
        }
      } else {
        stepElement.classList.add("hidden")
      }
    })
  }

  updateReview() {
    const form = this.element.querySelector('#reservation-form')
    if (!form) return

    const packageInput = form.querySelector('input[name="reservation[package]"]:checked')
    const nameInput = form.querySelector('#reservation_name')
    const phoneInput = form.querySelector('#reservation_phone')
    const emailInput = form.querySelector('#reservation_email')
    const datetimeInput = form.querySelector('#reservation_reservation_datetime')
    const coachingRadio = form.querySelector('input[name="reservation[coaching_type]"]:checked')

    const selectedSubjects = []
    const subjectCheckboxes = form.querySelectorAll('input[name="reservation[selected_subjects][]"]:checked')
    subjectCheckboxes.forEach(checkbox => {
      selectedSubjects.push(checkbox.value)
    })

    const requestsInput = form.querySelector('#reservation_requests')

    const updateElement = (id, value) => {
      const element = document.getElementById(id)
      if (element) {
        element.textContent = value || '-'
      }
    }

    const packageLabels = { starter: "STARTER (98만원)", standard: "STANDARD (148만원)", premium: "PREMIUM (249만원)", basic: "BASIC (290만원~)", standard_dev: "STANDARD (500만원~)", premium_dev: "PREMIUM (1,000만원~)" }
    updateElement('review-package', packageInput ? (packageLabels[packageInput.value] || packageInput.value) : '-')
    updateElement('review-name', nameInput?.value)
    updateElement('review-phone', phoneInput?.value)
    updateElement('review-email', emailInput?.value)

    if (datetimeInput?.value) {
      try {
        const date = new Date(datetimeInput.value)
        const formattedDate = date.toLocaleString('ko-KR', {
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        })
        updateElement('review-datetime', formattedDate)
      } catch (e) {
        updateElement('review-datetime', datetimeInput.value)
      }
    } else {
      updateElement('review-datetime', '-')
    }

    updateElement('review-coaching', coachingRadio?.value)

    const subjectsContainer = document.getElementById('review-subjects-container')
    const subjectsElement = document.getElementById('review-subjects')
    if (selectedSubjects.length > 0) {
      if (subjectsContainer) subjectsContainer.style.display = 'flex'
      if (subjectsElement) subjectsElement.textContent = selectedSubjects.join(', ')
    } else {
      if (subjectsContainer) subjectsContainer.style.display = 'none'
    }

    const requestsContainer = document.getElementById('review-requests-container')
    const requestsElement = document.getElementById('review-requests')
    if (requestsInput?.value) {
      if (requestsContainer) requestsContainer.style.display = 'flex'
      if (requestsElement) requestsElement.textContent = requestsInput.value
    } else {
      if (requestsContainer) requestsContainer.style.display = 'none'
    }
  }

  updateProgress() {
    const percent = Math.round((this.currentStepValue / this.totalStepsValue) * 100)

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percent}%`
    }

    if (this.hasStepNumberTarget) {
      this.stepNumberTarget.textContent = `${this.currentStepValue} / ${this.totalStepsValue} 단계`
    }

    if (this.hasProgressPercentTarget) {
      this.progressPercentTarget.textContent = `${percent}%`
    }
  }

  validateCurrentStep() {
    const currentStepElement = this.stepTargets[this.currentStepValue - 1]
    if (!currentStepElement) return false

    const requiredInput = currentStepElement.querySelector("[required]")

    if (requiredInput) {
      const value = requiredInput.value ? requiredInput.value.trim() : ""
      if (!value) {
        requiredInput.focus()
        this.showError(requiredInput, "필수 입력 필드를 채워주세요.")
        return false
      }

      if (requiredInput.type === "email") {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        if (!emailRegex.test(requiredInput.value)) {
          this.showError(requiredInput, "올바른 이메일 형식을 입력해주세요.")
          requiredInput.focus()
          return false
        }
      }

      if (requiredInput.type === "tel") {
        const phoneRegex = /^\d{10,11}$/
        if (!phoneRegex.test(requiredInput.value.replace(/[-\s]/g, ""))) {
          this.showError(requiredInput, "올바른 전화번호 형식을 입력해주세요. (10-11자리 숫자)")
          requiredInput.focus()
          return false
        }
      }
    }

    // Step 4: 슬롯 선택 확인
    if (this.currentStepValue === 4) {
      const slotInput = currentStepElement.querySelector('input[name="reservation[time_slot_id]"]')
      if (slotInput && !slotInput.value) {
        this.showError(currentStepElement.querySelector("[data-slot-picker-target='slots']") || currentStepElement, "날짜와 시간을 선택해주세요.")
        return false
      }
    }

    // Step 5: 코칭 형태 선택 확인
    if (this.currentStepValue === 5) {
      const coachingRadio = currentStepElement.querySelector('input[name="reservation[coaching_type]"]:checked')
      if (!coachingRadio) {
        this.showError(currentStepElement.querySelector(".space-y-3") || currentStepElement, "코칭 형태를 선택해주세요.")
        return false
      }
    }

    if (this.currentStepValue === 9) {
      const checkbox = currentStepElement.querySelector('input[type="checkbox"]')
      if (checkbox && !checkbox.checked) {
        this.showError(checkbox, "개인정보 수집 및 이용에 동의해주세요.")
        checkbox.focus()
        return false
      }
    }

    return true
  }

  showError(input, message) {
    input.classList.add("border-red-500")
    const errorSpan = document.createElement("span")
    errorSpan.className = "step-form-error text-red-500 text-sm mt-1 block"
    errorSpan.textContent = message
    input.parentElement.appendChild(errorSpan)

    setTimeout(() => {
      input.classList.remove("border-red-500")
    }, 3000)
  }

  clearErrors() {
    this.element.querySelectorAll(".step-form-error").forEach(el => el.remove())
    this.element.querySelectorAll(".border-red-500").forEach(el => {
      el.classList.remove("border-red-500")
    })
  }
}
