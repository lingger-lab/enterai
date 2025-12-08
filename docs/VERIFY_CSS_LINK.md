# CSS 링크 태그 확인 가이드

## 현재 상태
- ✅ `stylesheet_link_tag "application"` 정상 작동 (`<link rel="stylesheet" href="/assets/application-54e30363.css" />`)
- ✅ `app/assets/stylesheets/application.css` 파일 존재 (Tailwind CSS 내용 포함)
- ❌ 서버 로그에 CSS 파일 요청이 없음

## 확인 방법

### 1. 브라우저에서 페이지 소스 확인 (가장 중요!)

**개발자 도구의 Elements 탭이 아닌 실제 HTML 소스를 확인해야 합니다:**

1. 브라우저에서 `http://localhost:3000` 접속
2. **우클릭 → "페이지 소스 보기"** (또는 `Ctrl+U`)
3. `<head>` 섹션에서 다음 태그를 찾아보세요:
   ```html
   <link rel="stylesheet" href="/assets/application-54e30363.css" />
   ```

**중요**: 
- 개발자 도구의 Elements 탭은 JavaScript에 의해 수정된 DOM을 보여줍니다
- 실제 서버에서 전송된 HTML은 다를 수 있습니다
- **반드시 페이지 소스 보기(`Ctrl+U`)를 사용해야 합니다**

### 2. 브라우저 개발자 도구 Network 탭 확인

1. 브라우저에서 `F12` 또는 `Ctrl+Shift+I`로 개발자 도구 열기
2. **Network 탭** 선택
3. 페이지 새로고침 (`Ctrl+R`)
4. 필터에서 "CSS" 선택
5. `application*.css` 파일이 로드되는지 확인

### 3. 직접 CSS 파일 접근 테스트

브라우저에서 직접 접근:
```
http://localhost:3000/assets/application-54e30363.css
```

**예상 결과:**
- Tailwind CSS 내용이 정상적으로 표시되어야 함
- 서버 로그에 `Started GET "/assets/application-54e30363.css"`가 표시되어야 함

### 4. 브라우저 캐시 완전 삭제

브라우저가 이전 버전의 HTML을 캐시하고 있을 수 있습니다:

1. 브라우저에서 `Ctrl+Shift+Delete` 누르기
2. "캐시된 이미지 및 파일" 선택
3. "전체 기간" 선택
4. 삭제

또는 시크릿 모드에서 테스트:
- `Ctrl+Shift+N` (Chrome)
- `Ctrl+Shift+P` (Firefox)

### 5. 서버 재시작 후 확인

서버를 재시작하고 다시 확인:

```powershell
# 서버 중지 (Ctrl+C)
# 서버 재시작
$env:Path += ";C:\Ruby33-x64\bin"
bundle exec rails s
```

그 다음:
1. 브라우저에서 `http://localhost:3000` 접속
2. 페이지 소스 보기 (`Ctrl+U`)
3. `<head>`에서 `<link>` 태그 확인
4. 페이지 새로고침 (`Ctrl+R`)
5. 서버 로그에서 `Started GET "/assets/application-54e30363.css"` 확인

## 문제 해결

### 만약 페이지 소스에 `<link>` 태그가 없다면:

1. **레이아웃 파일 확인**: `app/layouts/application.html.erb`에 `stylesheet_link_tag "application"`이 있는지 확인 ✅
2. **에러 확인**: 서버 로그에 에러 메시지가 있는지 확인
3. **Propshaft 초기화**: 서버 시작 시 Propshaft 관련 에러가 있는지 확인

### 만약 `<link>` 태그는 있지만 CSS가 로드되지 않는다면:

1. **CSS 파일 직접 접근**: `http://localhost:3000/assets/application-54e30363.css` 접근 테스트
2. **서버 로그 확인**: CSS 파일 요청이 있는지 확인
3. **브라우저 콘솔 확인**: 개발자 도구의 Console 탭에서 에러 메시지 확인

## 참고

- Propshaft는 `app/assets` 디렉토리를 자동으로 스캔합니다
- 서버 시작 시 에셋을 로드하므로, 파일 변경 후 서버를 재시작해야 할 수 있습니다
- 개발 환경에서는 Propshaft가 에셋을 직접 서빙합니다


