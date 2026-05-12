class Users::SessionsController < Devise::SessionsController
  layout "application"

  # 로그인 후 이동 경로
  def after_sign_in_path_for(resource)
    account_path
  end

  # 로그아웃 후 이동 경로
  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
end
