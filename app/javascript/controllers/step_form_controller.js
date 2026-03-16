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
    const coachingSelect = form.querySelector('#reservation_coaching_type')

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

    const packageLabels = { starter: "STARTER (49만원)", standard: "STANDARD (80만원)", premium: "PREMIUM (120만원)" }
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

    updateElement('review-coaching', coachingSelect?.value)

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
