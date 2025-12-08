# Propshaft 설정 완료

## 완료된 작업

### 1. Gemfile 정리
✅ `sprockets` 및 `sprockets-rails` 제거 완료
✅ `propshaft` gem 추가 완료 (중복 제거 완료)
✅ `bundle install` 완료

### 2. config/application.rb
✅ `require "rails/all"` 확인
✅ Propshaft는 Bundler가 자동으로 로드하므로 별도 require 불필요

### 3. app/assets/config/manifest.js
✅ Propshaft용으로 수정 완료:
```javascript
//= link_tree ../images
//= link_directory ../stylesheets .css
//= link_tree ../builds
```

### 4. app/layouts/application.html.erb
✅ `<head>`에 다음 태그 포함 확인:
```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= javascript_importmap_tags %>
```

### 5. 에셋 재빌드
✅ `rails assets:clobber` 완료
✅ `rails tailwindcss:build` 완료
✅ `npm run build:css` 완료 (자동으로 `app/assets/stylesheets/application.css` 복사)
✅ `rails assets:precompile` 완료
✅ `public/assets/.manifest.json` 삭제 (개발 환경에서는 불필요)

### 6. 확인
✅ `stylesheet_link_tag "application"` 정상 작동
✅ 새로운 해시 생성: `/assets/application-3bc0b26f.css`

## 다음 단계 (필수!)

### 1. 서버 완전 재시작

**Propshaft는 서버 시작 시 에셋을 로드하므로, 반드시 서버를 재시작해야 합니다:**

```powershell
# 1. 서버 중지 (Ctrl+C를 여러 번 눌러 완전히 종료)
# 2. 서버 재시작
$env:Path += ";C:\Ruby33-x64\bin"
bundle exec rails s
```

### 2. 브라우저 캐시 완전 삭제

브라우저가 이전 버전의 HTML/CSS를 캐시하고 있을 수 있습니다:

1. 브라우저에서 `Ctrl+Shift+Delete` 누르기
2. "캐시된 이미지 및 파일" 선택
3. "전체 기간" 선택
4. 삭제

또는 시크릿 모드에서 테스트:
- `Ctrl+Shift+N` (Chrome)
- `Ctrl+Shift+P` (Firefox)

### 3. 페이지 소스 확인

1. 브라우저에서 `http://localhost:3000` 접속
2. **우클릭 → "페이지 소스 보기"** (또는 `Ctrl+U`)
3. `<head>` 섹션에서 다음 태그 확인:
   ```html
   <link rel="stylesheet" href="/assets/application-3bc0b26f.css" />
   ```

### 4. Network 탭 확인

1. 브라우저에서 `F12` 또는 `Ctrl+Shift+I`로 개발자 도구 열기
2. **Network 탭** 선택
3. 페이지 새로고침 (`Ctrl+R`)
4. 필터에서 "CSS" 선택
5. `application*.css` 파일이 로드되는지 확인
6. 상태 코드가 `200 OK`인지 확인

### 5. 서버 로그 확인

서버 재시작 후 페이지를 새로고침하면 다음 로그가 보여야 합니다:
```
Started GET "/assets/application-3bc0b26f.css" for ::1
Completed 200 OK in XXms
```

## Propshaft 작동 방식

- Propshaft는 `app/assets` 디렉토리를 자동으로 스캔합니다
- 서버 시작 시 에셋을 로드하고 해시를 생성합니다
- 개발 환경에서는 에셋을 직접 서빙합니다
- Sprockets 지시문(`*= require`, `*= require_tree` 등)을 사용하지 않습니다
- 빌드된 CSS 파일을 직접 `app/assets/stylesheets/application.css`에 복사해야 합니다

## 참고

- `package.json`의 `build:css` 스크립트가 자동으로 `app/assets/stylesheets/application.css`를 업데이트합니다
- 파일을 변경한 후에는 서버를 재시작해야 Propshaft가 새로운 파일을 인식합니다
- 개발 환경에서는 `public/assets/.manifest.json`을 삭제하는 것이 좋습니다


