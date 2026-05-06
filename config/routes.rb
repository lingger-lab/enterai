Rails.application.routes.draw do
  devise_for :admin_users, path: "admin", controllers: { sessions: "admin_users/sessions" }

  namespace :admin do
    root "reservations#index"
    resources :reservations, only: [:index, :show, :edit, :update] do
      member do
        patch :update_status
        post :send_sms
      end
    end
    resources :time_slots, only: [:index, :new, :create, :destroy] do
      collection do
        get :bulk_new
        post :bulk_create
      end
      member do
        patch :toggle_block
      end
    end
    resources :reviews, only: [:index] do
      member do
        patch :toggle_publish
      end
    end
  end

  # 후기 작성 (공개, 토큰 인증)
  get "reviews/:token/write", to: "reviews#write", as: :write_review
  resources :reviews, only: [:create, :show]

  # 헬스체크 (UptimeRobot/HetrixTools 등 외부 모니터링용 — DB 쿼리 없음)
  get '/health', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['ok']] }

  # 개발환경 헬스체크 무시
  get '/_stcore/*path', to: proc { [200, {}, ['']] }

  # Favicon 요청 처리 (404 방지)
  get '/favicon.ico', to: proc { [204, {}, []] }

  # Chrome DevTools 자동 요청 경로 처리 (404 방지)
  get '/.well-known/*path', to: proc { [204, {}, []] }

  get "privacy_policy", to: "home#privacy_policy", as: :privacy_policy

  root "home#index"

  resources :reservations, only: [:new, :create, :show] do
    collection do
      get :available_dates
      get :available_slots
      get :lookup
      post :lookup, action: :lookup_results
    end
    member do
      patch :cancel
    end
  end
end

