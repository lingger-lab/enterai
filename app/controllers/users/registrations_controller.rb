class Users::RegistrationsController < Devise::RegistrationsController
  layout "application"

  # 회원가입 후 이동 경로
  def after_sign_up_path_for(resource)
    account_path
  end

  protected

  # 회원가입 폼 추가 파라미터 (이름, 마케팅 동의)
  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :marketing_agreed)
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :name)
  end
end
