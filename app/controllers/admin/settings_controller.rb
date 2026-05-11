class Admin::SettingsController < Admin::BaseController
  def index
    @settings = Setting.all_with_defaults
  end

  def update
    Setting::DEFAULTS.each_key do |key|
      next unless params[:settings].is_a?(ActionController::Parameters)

      value = params.dig(:settings, key)
      next if value.nil?

      Setting.set(key, value.to_s)
    end

    redirect_to admin_settings_path, notice: "운영 설정이 저장되었습니다."
  end
end
