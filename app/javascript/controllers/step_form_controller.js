import { Controller } from "@hotwired/stimulus"

// Stimulus는 파일명에서 _controller.js를 제거하고 나머지를 컨트롤러 이름으로 사용
// step_form_controller.js → step-form
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
      steps: this.stepTargets.length,
      controller: this.identifier
    })
    
    // 초기 단계 표시
    this.showStep(this.currentStepValue)
    this.updateProgress()
    
    // 디버깅: 모든 step target 확인
    console.log("Step targets:", this.stepTargets.map((el, i) => ({
      index: i + 1,
      element: el,
      hidden: el.classList.contains("hidden")
    })))
  }

  next(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    console.log("Next button clicked", {
      currentStep: this.currentStepValue,
      totalSteps: this.totalStepsValue,
      stepTargetsCount: this.stepTargets.length
    })
    
    // 검증 없이 바로 이동 (테스트용 - 나중에 검증 활성화)
    if (this.currentStepValue < this.totalStepsValue) {
      this.currentStepValue++
      this.showStep(this.currentStepValue)
      this.updateProgress()
      console.log("Moved to step", this.currentStepValue)
    } else {
      console.log("Already at last step")
    }
    
    // 검증 로직 (나중에 활성화)
    /*
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
    */
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
        
        // 9단계(최종 확인)로 이동할 때 입력값 업데이트
        if (step === 9) {
          this.updateReview()
        }
      } else {
        stepElement.classList.add("hidden")
      }
    })
  }
  
  updateReview() {
    const form = this.element.querySelector('#reservation-form')
    if (!form) {
      console.log("Form not found")
      return
    }
    
    // 입력 필드에서 값 가져오기
    const nameInput = form.querySelector('#reservation_name')
    const phoneInput = form.querySelector('#reservation_phone')
    const emailInput = form.querySelector('#reservation_email')
    const datetimeInput = form.querySelector('#reservation_reservation_datetime')
    const coachingSelect = form.querySelector('#reservation_coaching_type')
    
    // 선택된 과목 가져오기
    const selectedSubjects = []
    const subjectCheckboxes = form.querySelectorAll('input[name="reservation[selected_subjects][]"]:checked')
    subjectCheckboxes.forEach(checkbox => {
      selectedSubjects.push(checkbox.value)
    })
    
    // 요청사항 가져오기
    const requestsInput = form.querySelector('#reservation_requests')
    
    // 리뷰 영역 업데이트
    const updateElement = (id, value) => {
      const element = document.getElementById(id)
      if (element) {
        element.textContent = value || '-'
      }
    }
    
    updateElement('review-name', nameInput?.value)
    updateElement('review-phone', phoneInput?.value)
    updateElement('review-email', emailInput?.value)
    
    // 날짜 포맷팅
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
    
    // 선택 과목 표시
    const subjectsContainer = document.getElementById('review-subjects-container')
    const subjectsElement = document.getElementById('review-subjects')
    if (selectedSubjects.length > 0) {
      if (subjectsContainer) subjectsContainer.style.display = 'flex'
      if (subjectsElement) subjectsElement.textContent = selectedSubjects.join(', ')
    } else {
      if (subjectsContainer) subjectsContainer.style.display = 'none'
    }
    
    // 요청사항 표시
    const requestsContainer = document.getElementById('review-requests-container')
    const requestsElement = document.getElementById('review-requests')
    if (requestsInput?.value) {
      if (requestsContainer) requestsContainer.style.display = 'flex'
      if (requestsElement) requestsElement.textContent = requestsInput.value
    } else {
      if (requestsContainer) requestsContainer.style.display = 'none'
    }
    
    console.log("Review updated", {
      name: nameInput?.value,
      phone: phoneInput?.value,
      email: emailInput?.value,
      datetime: datetimeInput?.value,
      coaching: coachingSelect?.value,
      subjects: selectedSubjects,
      requests: requestsInput?.value
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
    if (!currentStepElement) {
      console.log("Current step element not found", this.currentStepValue)
      return false
    }
    
    const requiredInput = currentStepElement.querySelector("[required]")
    
    if (requiredInput) {
      const value = requiredInput.value ? requiredInput.value.trim() : ""
      if (!value) {
        console.log("Required input is empty", requiredInput)
        requiredInput.focus()
        requiredInput.classList.add("border-red-500")
        setTimeout(() => {
          requiredInput.classList.remove("border-red-500")
        }, 2000)
        alert("필수 입력 필드를 채워주세요.")
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

