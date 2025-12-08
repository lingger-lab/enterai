# Propshaft CSS 문제 최종 해결

## 문제 상황
- CSS 파일에 Sprockets 지시문(`*= require_tree ../builds`)이 보임
- 서버 로그에 `Started GET "/assets/application-54e30363.css"`가 보이지 않음
- Propshaft는 Sprockets 지시문을 처리하지 않음

## 해결 완료
✅ `app/assets/stylesheets/application.css` 파일을 빌드된 Tailwind CSS로 교체 완료
✅ `package.json`의 `build:css` 스크립트가 자동으로 복사하도록 설정됨

## 다음 단계 (필수!)

### 1. 서버 완전 재시작

**Propshaft는 서버 시작 시 에셋을 로드하므로, 서버를 완전히 재시작해야 합니다:**

```powershell
# 1. 서버 중지 (Ctrl+C를 여러 번 눌러 완전히 종료)
# 2. PowerShell 창을 닫고 새로 열기 (선택 사항이지만 권장)
# 3. 프로젝트 디렉토리로 이동
cd C:\Users\USER\Desktop\Enter-ai

# 4. Ruby 경로 추가
$env:Path += ";C:\Ruby33-x64\bin"

# 5. 서버 재시작
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
http://localhost:3000/assets/application-54e30363.css
```

**예상 결과:**
- Tailwind CSS 내용이 정상적으로 표시되어야 함
- Sprockets 지시문(`*= require_tree`)이 보이지 않아야 함
- 서버 로그에 `Started GET "/assets/application-54e30363.css"`가 표시되어야 함

### 4. 페이지 소스 확인

1. 브라우저에서 `http://localhost:3000` 접속
2. **우클릭 → "페이지 소스 보기"** (또는 `Ctrl+U`)
3. `<head>` 섹션에서 다음 태그 확인:
   ```html
   <link rel="stylesheet" href="/assets/application-54e30363.css" />
   ```

### 5. 서버 로그 확인

서버 재시작 후 페이지를 새로고침하면 다음 로그가 보여야 합니다:
```
Started GET "/assets/application-54e30363.css" for ::1
Completed 200 OK in XXms
```

## 문제가 계속되면

만약 위의 모든 단계를 수행했는데도 문제가 있다면:

1. **파일 내용 확인**: `app/assets/stylesheets/application.css` 파일이 실제 Tailwind CSS 내용을 포함하는지 확인
2. **해시 변경 확인**: 서버 재시작 후 `asset_path`가 새로운 해시를 반환하는지 확인
3. **Propshaft 초기화**: 서버 시작 시 Propshaft 관련 에러가 있는지 확인

## 참고

- Propshaft는 `app/assets` 디렉토리를 자동으로 스캔합니다
- Sprockets 지시문(`*= require`, `*= require_tree` 등)은 사용할 수 없습니다
- 빌드된 CSS 파일을 직접 `app/assets/stylesheets/application.css`에 복사해야 합니다


