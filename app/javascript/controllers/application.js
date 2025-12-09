import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true  // 디버그 모드 활성화
window.Stimulus = application

export { application }

