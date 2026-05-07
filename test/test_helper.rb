ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # 병렬 처리 비활성 (Windows에서 fork 미지원, threads는 일부 테스트 비안전)
  fixtures :all
end
