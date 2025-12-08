# CSS 파일 수정 완료

## 문제
CSS 파일에 Sprockets 지시문(`*= require_tree ../builds`)이 보였습니다.

## 해결 완료
✅ `app/assets/stylesheets/application.css` 파일을 빌드된 Tailwind CSS로 교체 완료
✅ Sprockets 지시문 제거 완료

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

브라우저가 이전 버전의 CSS를 캐시하고 있을 수 있습니다:

1. 브라우저에서 `Ctrl+Shift+Delete` 누르기
2. "캐시된 이미지 및 파일" 선택
3. "전체 기간" 선택
4. 삭제

또는 시크릿 모드에서 테스트:
- `Ctrl+Shift+N` (Chrome)
- `Ctrl+Shift+P` (Firefox)

### 3. CSS 파일 직접 접근 테스트

서버 재시작 후 브라우저에서 직접 접근:
```
http://localhost:3000/assets/application-[새로운해시].css
```

**예상 결과:**
- Tailwind CSS 내용이 정상적으로 표시되어야 함
- Sprockets 지시문(`*= require_tree`)이 보이지 않아야 함
- 서버 로그에 `Started GET "/assets/application-[해시].css"`가 표시되어야 함

### 4. 페이지 소스 확인

1. 브라우저에서 `http://localhost:3000` 접속
2. **우클릭 → "페이지 소스 보기"** (또는 `Ctrl+U`)
3. `<head>` 섹션에서 다음 태그 확인:
   ```html
   <link rel="stylesheet" href="/assets/application-[해시].css" />
   ```

### 5. Network 탭 확인

1. 브라우저에서 `F12` 또는 `Ctrl+Shift+I`로 개발자 도구 열기
2. **Network 탭** 선택
3. 페이지 새로고침 (`Ctrl+R`)
4. 필터에서 "CSS" 선택
5. `application*.css` 파일이 로드되는지 확인

## 중요 사항

- Propshaft는 서버 시작 시 에셋을 로드합니다
- 파일을 변경한 후에는 **반드시 서버를 재시작**해야 합니다
- Propshaft는 Sprockets 지시문(`*= require`, `*= require_tree` 등)을 처리하지 않습니다
- 빌드된 CSS 파일을 직접 `app/assets/stylesheets/application.css`에 복사해야 합니다

## 참고

`package.json`의 `build:css` 스크립트가 자동으로 `app/assets/stylesheets/application.css`를 업데이트하도록 설정되어 있습니다:
```json
"build:css": "tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css --minify && node -e \"require('fs').copyFileSync('app/assets/builds/application.css', 'app/assets/stylesheets/application.css')\""
```


