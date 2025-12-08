# CSS 로딩 문제 디버깅 가이드

## 현재 상태

`stylesheet_link_tag "application"`은 정상적으로 HTML을 생성하고 있습니다:
```html
<link rel="stylesheet" href="/assets/application.debug-[hash].css" />
```

## 브라우저에서 확인 방법

### 1. 페이지 소스 보기 (가장 중요!)

**개발자 도구의 Elements 탭이 아닌 실제 HTML 소스를 확인해야 합니다:**

1. 브라우저에서 `http://localhost:3000` 접속
2. **우클릭 → "페이지 소스 보기"** (또는 `Ctrl+U`)
3. `<head>` 섹션에서 `<link rel="stylesheet">` 태그 확인

**중요**: 개발자 도구의 Elements 탭은 JavaScript에 의해 수정된 DOM을 보여줍니다. 실제 서버에서 전송된 HTML은 다를 수 있습니다.

### 2. 개발자 도구에서 확인

1. `F12` 또는 `Ctrl+Shift+I`로 개발자 도구 열기
2. **Network 탭** 선택
3. 페이지 새로고침 (`Ctrl+R`)
4. 필터에서 "CSS" 선택
5. `application*.css` 파일이 로드되는지 확인

### 3. 강력 새로고침

브라우저 캐시 문제일 수 있으므로:
- `Ctrl+Shift+R` (Windows/Linux)
- `Cmd+Shift+R` (Mac)

### 4. 서버 로그 확인

서버 로그에서 CSS 파일에 대한 GET 요청이 있는지 확인:
```
Started GET "/assets/application.debug-[hash].css" for ::1
```

## 문제 해결 단계

### Step 1: 페이지 소스 확인
실제 HTML 소스에 `<link>` 태그가 있는지 확인합니다.

### Step 2: Network 탭 확인
CSS 파일이 요청되고 있는지, 404 에러가 발생하는지 확인합니다.

### Step 3: 서버 재시작
변경사항이 반영되지 않았을 수 있으므로:
```powershell
# 서버 중지 (Ctrl+C)
# 서버 재시작
$env:Path += ";C:\Ruby33-x64\bin"
bundle exec rails s
```

### Step 4: assets:precompile 재실행
```powershell
bundle exec rails assets:clobber
npm run build:css
bundle exec rails assets:precompile
```

## 현재 설정 확인

- ✅ `app/assets/config/manifest.js`에 `//= link application.css` 추가됨
- ✅ `app/assets/stylesheets/application.css` 존재
- ✅ `app/assets/builds/application.css` 존재 (4,897 bytes)
- ✅ `app/layouts/application.html.erb`에 `stylesheet_link_tag "application"` 있음
- ✅ `config/environments/development.rb`에 `config.assets.compile = true` 설정됨

## 다음 단계

1. **페이지 소스 보기**로 실제 HTML 확인
2. **Network 탭**에서 CSS 파일 요청 확인
3. 결과를 알려주시면 추가 진단 진행


