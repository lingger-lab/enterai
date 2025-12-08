# Propshaft CSS 링크 태그 문제 해결

## 현재 상태
- ✅ Propshaft gem 설치됨
- ✅ `stylesheet_link_tag "application"` 정상 작동 (`<link rel="stylesheet" href="/assets/application-54e30363.css" />`)
- ✅ `app/assets/stylesheets/application.css` 파일 존재 (4897 bytes)
- ❌ 브라우저에서 `<link>` 태그가 보이지 않음

## 해결 방법

### 1. 서버 완전 재시작 (가장 중요!)

Propshaft는 서버 시작 시 에셋을 로드합니다. 서버를 완전히 재시작해야 합니다:

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

브라우저 캐시를 완전히 삭제하거나 시크릿 모드에서 테스트:

1. 브라우저에서 `Ctrl+Shift+Delete` 누르기
2. "캐시된 이미지 및 파일" 선택
3. "전체 기간" 선택
4. 삭제

또는 시크릿 모드에서 테스트:
- `Ctrl+Shift+N` (Chrome)
- `Ctrl+Shift+P` (Firefox)

### 3. 페이지 소스 확인 (중요!)

**개발자 도구의 Elements 탭이 아닌 실제 HTML 소스를 확인해야 합니다:**

1. 브라우저에서 `http://localhost:3000` 접속
2. **우클릭 → "페이지 소스 보기"** (또는 `Ctrl+U`)
3. `<head>` 섹션에서 다음 태그 확인:
   ```html
   <link rel="stylesheet" href="/assets/application-54e30363.css" />
   ```

**중요**: 개발자 도구의 Elements 탭은 JavaScript에 의해 수정된 DOM을 보여줍니다. 실제 서버에서 전송된 HTML은 다를 수 있습니다.

### 4. 직접 CSS 파일 접근 테스트

브라우저에서 직접 접근:
```
http://localhost:3000/assets/application-54e30363.css
```

이 URL이 작동하면 Propshaft가 정상적으로 에셋을 서빙하고 있는 것입니다.

### 5. 서버 로그 확인

서버 로그에서 CSS 파일에 대한 GET 요청이 있는지 확인:
```
Started GET "/assets/application-54e30363.css" for ::1
```

### 6. Propshaft 설정 확인

`config/environments/development.rb`에 다음 설정이 있어야 합니다:
```ruby
config.assets.enabled = true
config.assets.debug = true
```

## 추가 확인 사항

1. **레이아웃 파일 확인**: `app/layouts/application.html.erb`에 `stylesheet_link_tag "application"`이 있는지 확인 ✅
2. **에셋 파일 확인**: `app/assets/stylesheets/application.css` 파일이 존재하고 내용이 있는지 확인 ✅
3. **Propshaft 초기화**: 서버 시작 시 Propshaft 관련 메시지가 있는지 확인

## 문제가 계속되면

만약 위의 모든 단계를 수행했는데도 `<link>` 태그가 보이지 않는다면:

1. 브라우저 개발자 도구의 Network 탭에서 CSS 파일 요청이 있는지 확인
2. 서버 로그에서 에러 메시지가 있는지 확인
3. `app/assets/stylesheets/application.css` 파일의 내용이 올바른지 확인


