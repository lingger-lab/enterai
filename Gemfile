# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.3.10"

# Rails 8.0
gem "rails", "~> 8.0.0"

# 웹 서버
gem "puma", "~> 6.0"

# 데이터베이스
gem "pg", "~> 1.5"

# UI 스타일링
gem "tailwindcss-rails", "~> 2.0"
gem "propshaft", "~> 1.3"

# JavaScript 모듈 관리 (Importmap)
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# 이메일 발송
gem "sendgrid-ruby", "~> 6.7"

# SMS 발송 (Naver Cloud SENS)
gem "rest-client", "~> 2.1"

# 개인정보 암호화
gem "attr_encrypted", "~> 4.0"

# 인증 (관리자용)
gem "devise", "~> 4.9"

# 비동기 작업 처리
gem "sidekiq", "~> 7.0"

# 환경 변수 관리
gem "dotenv-rails"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "ffi", "~> 1.15", platforms: [:mingw, :mswin, :x64_mingw]
  gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
end

group :development do
  gem "web-console"
end
