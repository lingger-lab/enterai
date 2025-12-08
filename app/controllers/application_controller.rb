class ApplicationController < ActionController::Base
  # CSRF 보호 활성화
  protect_from_forgery with: :exception
  
  # Turbo Stream 요청 처리
  before_action :set_turbo_frame_header
  before_action :set_variant
  
  private
  
  def set_turbo_frame_header
    @turbo_frame = request.headers["Turbo-Frame"]
  end
  
  def set_variant
    request.variant = :mobile if request.user_agent =~ /Mobile|Android/
  end
end

