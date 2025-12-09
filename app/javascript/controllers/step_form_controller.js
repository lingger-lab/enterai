import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progressBar", "stepNumber", "progressPercent", "form"]
  static values = { 
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 9 }
  }

  connect() {
    console.log("Step form controller connected", {
      currentStep: this.currentStepValue,
      totalSteps: this.totalStepsValue,
      steps: this.stepTargets.length
    })
    this.showStep(this.currentStepValue)
    this.updateProgress()
  }

  next(event) {
    event.preventDefault()
    event.stopPropagation()
    
    console.log("Next button clicked", {
      currentStep: this.currentStepValue,
      totalSteps: this.totalStepsValue
    })
    
    if (this.validateCurrentStep()) {
      if (this.currentStepValue < this.totalStepsValue) {
        this.currentStepValue++
        this.showStep(this.currentStepValue)
        this.updateProgress()
        console.log("Moved to step", this.currentStepValue)
      }
    } else {
      console.log("Validation failed")
    }
  }

  previous(event) {
    event.preventDefault()
    event.stopPropagation()
    
    console.log("Previous button clicked", {
      currentStep: this.currentStepValue
    })
    
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showStep(this.currentStepValue)
      this.updateProgress()
      console.log("Moved to step", this.currentStepValue)
    }
  }

  showStep(step) {
    console.log("Showing step", step, "out of", this.stepTargets.length)
    this.stepTargets.forEach((stepElement, index) => {
      if (index + 1 === step) {
        stepElement.classList.remove("hidden")
        console.log("Step", index + 1, "shown")
      } else {
        stepElement.classList.add("hidden")
      }
    })
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
      if (!requiredInput.value.trim()) {
        requiredInput.focus()
        requiredInput.classList.add("border-red-500")
        setTimeout(() => {
          requiredInput.classList.remove("border-red-500")
        }, 2000)
        return false
      }
      
      // 이메일 형식 검증
      if (requiredInput.type === "email") {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        if (!emailRegex.test(requiredInput.value)) {
          alert("올바른 이메일 형식을 입력해주세요.")
          requiredInput.focus()
          return false
        }
      }
      
      // 전화번호 형식 검증
      if (requiredInput.type === "tel") {
        const phoneRegex = /^\d{10,11}$/
        if (!phoneRegex.test(requiredInput.value.replace(/[-\s]/g, ""))) {
          alert("올바른 전화번호 형식을 입력해주세요. (10-11자리 숫자)")
          requiredInput.focus()
          return false
        }
      }
    }
    
    // 체크박스 검증 (개인정보 동의)
    if (this.currentStepValue === 8) {
      const checkbox = currentStepElement.querySelector('input[type="checkbox"]')
      if (checkbox && !checkbox.checked) {
        alert("개인정보 수집 및 이용에 동의해주세요.")
        checkbox.focus()
        return false
      }
    }
    
    return true
  }
}

