# CSS 링크 태그가 표시되지 않는 문제 - 최종 해결 가이드

## 문제 상황
- 페이지 소스에 `<link rel="stylesheet">` 태그가 없음
- 네트워크 탭에서 CSS 파일 요청이 없음
- `stylesheet_link_tag "application"`이 빈 문자열을 반환

## 확인된 사항
✅ `sprockets` gem 설치됨 (4.2.2)
✅ `sprockets-rails` gem 설치됨 (3.5.2)
✅ `app/assets/config/manifest.js`에 `//= link application.css` 있음
✅ `app/assets/stylesheets/application.css` 존재
✅ `app/assets/builds/application.css` 존재
✅ `config.assets.enabled = true`
✅ `config.assets.compile = true` (개발 환경)

## 해결 방법

### 1. 서버 완전 재시작 (가장 중요!)

**서버를 완전히 종료하고 재시작해야 합니다:**

```powershell
# 1. 서버 중지 (Ctrl+C를 여러 번 눌러 완전히 종료)
# 2. PowerShell 창을 닫고 새로 열기
# 3. 프로젝트 디렉토리로 이동
cd C:\Users\USER\Desktop\Enter-ai

# 4. Ruby 경로 추가
$env:Path += ";C:\Ruby33-x64\bin"

# 5. 서버 재시작
bundle exec rails s
```

### 2. 브라우저 캐시 완전 삭제

1. 브라우저에서 `Ctrl+Shift+Delete` 누르기
2. "캐시된 이미지 및 파일" 선택
3. "전체 기간" 선택
4. 삭제

또는 시크릿 모드에서 테스트:
- `Ctrl+Shift+N` (Chrome)
- `Ctrl+Shift+P` (Firefox)

### 3. assets:precompile 재실행

```powershell
# 기존 프리컴파일된 파일 삭제
bundle exec rails assets:clobber

# Tailwind CSS 빌드
npm run build:css

# 에셋 프리컴파일
bundle exec rails assets:precompile

# 서버 재시작
bundle exec rails s
```

### 4. 서버 로그 확인

서버 로그에서 다음을 확인:
- CSS 파일에 대한 GET 요청이 있는지
- 에러 메시지가 있는지

정상적인 경우:
```
Started GET "/assets/application.debug-[hash].css" for ::1
```

### 5. 직접 CSS 파일 접근 테스트

브라우저에서 직접 접근:
```
http://localhost:3000/assets/application.debug-[hash].css
```

이전에 확인한 해시값:
```
http://localhost:3000/assets/application.debug-c99a1969f1c8f97d393e90b9fb822cfc03e08ebaa09b6f3013e234e019dbac0f.css
```

### 6. 레이아웃 파일 확인

`app/layouts/application.html.erb` 파일이 올바르게 저장되었는지 확인:
```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```

## 디버깅 명령어

### Sprockets가 application.css를 찾는지 확인:
```powershell
bundle exec rails runner "puts ActionController::Base.helpers.stylesheet_link_tag('application')"
```

정상적인 출력:
```html
<link rel="stylesheet" href="/assets/application.debug-[hash].css" />
```

### Asset 경로 확인:
```powershell
bundle exec rails runner "puts Rails.application.config.assets.paths"
```

## 예상 원인

1. **서버가 변경사항을 인식하지 못함** - 가장 가능성 높음
2. **브라우저 캐시 문제**
3. **Turbo가 간섭** - `data-turbo-track="reload"`가 있지만 여전히 문제가 있을 수 있음

## 다음 단계

1. **서버를 완전히 종료하고 재시작**
2. **시크릿 모드에서 테스트**
3. **서버 로그 확인**
4. **결과를 알려주세요**


