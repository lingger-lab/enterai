# 프로젝트 경로 오류 점검 보고서

## 점검 일시
2025-12-09

## 점검 결과 요약

### ✅ 정상 경로

| 파일/디렉토리 | 경로 | 상태 |
|------------|------|------|
| 레이아웃 파일 | `app/views/layouts/application.html.erb` | ✅ 정상 |
| 컨트롤러 | `app/controllers/` | ✅ 정상 |
| 모델 | `app/models/` | ✅ 정상 |
| 뷰 | `app/views/` | ✅ 정상 |
| 메일러 | `app/mailers/` | ✅ 정상 |
| 잡 | `app/jobs/` | ✅ 정상 |
| 서비스 | `app/services/` | ✅ 정상 |
| 에셋 | `app/assets/` | ✅ 정상 |
| JavaScript | `app/javascript/` | ✅ 정상 |

### ❌ 발견된 문제 (수정 완료)

| 문제 | 원래 위치 | 수정 후 위치 | 상태 |
|------|----------|------------|------|
| 레이아웃 파일 중복 | `app/layouts/application.html.erb` | 삭제됨 | ✅ 수정 완료 |

## Rails 8.0 표준 디렉토리 구조

### app/ 디렉토리 구조

```
app/
├── assets/              # Propshaft 에셋
│   ├── builds/          # Tailwind 빌드 결과
│   ├── config/          # manifest.js
│   ├── images/          # 이미지 파일
│   ├── javascripts/     # JavaScript 파일 (선택)
│   └── stylesheets/     # CSS 파일
├── controllers/         # 컨트롤러
├── javascript/          # Importmap JavaScript
│   └── controllers/     # Stimulus 컨트롤러
├── jobs/                # ActiveJob
├── mailers/             # ActionMailer
├── models/              # ActiveRecord 모델
├── services/            # 서비스 객체 (선택)
└── views/               # 뷰 템플릿
    ├── layouts/         # 레이아웃 파일 ⚠️ 중요
    ├── home/            # 컨트롤러별 뷰
    └── reservations/    # 컨트롤러별 뷰
```

### 중요 경로 규칙

1. **레이아웃 파일**: `app/views/layouts/application.html.erb`
   - ❌ `app/layouts/application.html.erb` (인식되지 않음)

2. **뷰 파일**: `app/views/{controller_name}/{action}.html.erb`
   - 예: `app/views/home/index.html.erb`

3. **컨트롤러**: `app/controllers/{name}_controller.rb`
   - 예: `app/controllers/home_controller.rb`

4. **모델**: `app/models/{name}.rb`
   - 예: `app/models/reservation.rb`

5. **에셋**: `app/assets/{type}/{name}`
   - 스타일시트: `app/assets/stylesheets/`
   - JavaScript: `app/assets/javascripts/` (선택)
   - 이미지: `app/assets/images/`

## 현재 프로젝트 구조 확인

### app/ 디렉토리

```
app/
├── assets/              ✅
│   ├── builds/         ✅
│   ├── config/         ✅
│   ├── images/         ✅
│   ├── javascripts/    ✅
│   └── stylesheets/    ✅
├── controllers/        ✅
├── javascript/         ✅
├── jobs/              ✅
├── mailers/           ✅
├── models/            ✅
├── services/           ✅
└── views/             ✅
    └── layouts/       ✅ (수정 완료)
```

### config/ 디렉토리

```
config/
├── application.rb      ✅
├── routes.rb           ✅
├── environments/       ✅
│   ├── development.rb  ✅
│   ├── production.rb   ✅
│   └── test.rb         ✅
├── initializers/       ✅
└── tailwind.config.js  ✅
```

## 검증 결과

### ✅ 모든 파일이 올바른 위치에 있음

1. **레이아웃 파일**: `app/views/layouts/application.html.erb` ✅
2. **컨트롤러**: 모두 `app/controllers/`에 위치 ✅
3. **모델**: 모두 `app/models/`에 위치 ✅
4. **뷰**: 모두 `app/views/`에 위치 ✅
5. **메일러**: 모두 `app/mailers/`에 위치 ✅
6. **잡**: 모두 `app/jobs/`에 위치 ✅
7. **서비스**: 모두 `app/services/`에 위치 ✅
8. **에셋**: 모두 `app/assets/`에 위치 ✅

### ❌ 발견된 문제 없음

현재 프로젝트의 모든 파일이 Rails 8.0 표준 디렉토리 구조를 따르고 있습니다.

## 권장 사항

### 1. 레이아웃 파일 위치 확인

레이아웃 파일은 반드시 `app/views/layouts/`에 있어야 합니다:
- ✅ `app/views/layouts/application.html.erb`
- ❌ `app/layouts/application.html.erb` (인식되지 않음)

### 2. 뷰 파일 네이밍 규칙

뷰 파일은 컨트롤러 이름과 액션 이름을 따라야 합니다:
- 컨트롤러: `HomeController` → 디렉토리: `app/views/home/`
- 액션: `index` → 파일: `index.html.erb`
- 전체 경로: `app/views/home/index.html.erb`

### 3. 에셋 파일 관리

Propshaft를 사용하는 경우:
- CSS: `app/assets/stylesheets/`
- 빌드 결과: `app/assets/builds/`
- manifest: `app/assets/config/manifest.js`

## 다음 단계

1. ✅ 레이아웃 파일 위치 수정 완료
2. ✅ 잘못된 경로의 파일 삭제 완료
3. ⏳ 서버 재시작 후 정상 작동 확인 필요

## 참고

- Rails는 `app/views/layouts/` 경로에서만 레이아웃 파일을 찾습니다
- 다른 경로에 레이아웃 파일이 있어도 Rails가 인식하지 않습니다
- 파일 위치 변경 후 서버를 재시작해야 변경사항이 적용됩니다


