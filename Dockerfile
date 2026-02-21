# syntax=docker/dockerfile:1
# Google Cloud Run 배포용 Dockerfile

# ── Stage 1: 빌드 ──
FROM ruby:3.3-slim AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential libpq-dev nodejs npm git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gem 설치
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && \
    bundle config set --local without "development test" && \
    bundle install --jobs 4

# Node 패키지 설치
COPY package.json package-lock.json* ./
RUN npm ci --production 2>/dev/null || npm install --production

# 소스 복사 및 에셋 빌드
COPY . .
RUN npm run build:css && \
    SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# ── Stage 2: 런타임 ──
FROM ruby:3.3-slim AS runtime

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libpq5 curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 빌드 결과물 복사
COPY --from=build /app /app
COPY --from=build /usr/local/bundle /usr/local/bundle

# 비root 사용자로 실행
RUN groupadd --system rails && \
    useradd rails --system --gid rails --create-home && \
    chown -R rails:rails /app
USER rails

# Cloud Run은 PORT 환경변수를 자동 주입 (기본 8080)
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    PORT=8080

EXPOSE 8080

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD curl -f http://localhost:${PORT}/ || exit 1

# Web 서버 실행 (CMD를 통해 Sidekiq worker로도 재사용 가능)
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
