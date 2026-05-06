class ApplicationController < ActionController::Base
  # CSRF 보호 활성화
  protect_from_forgery with: :exception

  before_action :set_turbo_frame_header

  private

  def set_turbo_frame_header
    @turbo_frame = request.headers["Turbo-Frame"]
  end
end
