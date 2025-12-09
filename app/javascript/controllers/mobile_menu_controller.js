import { Controller } from "@hotwired/stimulus"

// Stimulus는 파일명에서 _controller.js를 제거하고 나머지를 컨트롤러 이름으로 사용
// mobile_menu_controller.js → mobile-menu
export default class extends Controller {
  static targets = ["menu"]

  // 모바일 메뉴 토글 메서드
  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }
}

