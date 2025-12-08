Rails.application.routes.draw do
  # 개발환경 헬스체크 무시
  get '/_stcore/*path', to: proc { [200, {}, ['']] }
  
  # Favicon 요청 처리 (404 방지)
  get '/favicon.ico', to: proc { [204, {}, []] }
  
  # Chrome DevTools 자동 요청 경로 처리 (404 방지)
  get '/.well-known/*path', to: proc { [204, {}, []] }
  
  root "home#index"
  resources :reservations, only: [:new, :create, :show]
end

