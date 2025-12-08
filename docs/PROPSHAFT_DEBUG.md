# Propshaft 디버깅 가이드

## 현재 상태
- ✅ Propshaft gem 설치됨
- ✅ `asset_path('application.css')` 정상 작동 (`/assets/application-54e30363.css`)
- ✅ `app/assets/stylesheets/application.css` 파일 존재 (4897 bytes)
- ❌ 브라우저에서 `<link>` 태그가 보이지 않음

## 확인 사항

### 1. 실제 HTML 출력 확인
브라우저에서 페이지 소스 보기 (`Ctrl+U`)를 통해 실제 HTML을 확인해야 합니다.

### 2. Propshaft 설정 확인
Propshaft는 `app/assets` 디렉토리를 자동으로 스캔합니다.
- `app/assets/stylesheets/application.css` 파일이 있어야 함 ✅
- Propshaft는 `stylesheet_link_tag "application"`을 통해 자동으로 링크 생성

### 3. 서버 재시작
Propshaft 설정 변경 후 서버를 완전히 재시작해야 합니다:
```powershell
# 서버 중지 (Ctrl+C)
# 서버 재시작
$env:Path += ";C:\Ruby33-x64\bin"
bundle exec rails s
```

### 4. 브라우저 캐시 삭제
브라우저 캐시를 완전히 삭제하거나 시크릿 모드에서 테스트:
- `Ctrl+Shift+Delete` (캐시 삭제)
- `Ctrl+Shift+N` (Chrome 시크릿 모드)

### 5. 직접 CSS 파일 접근 테스트
브라우저에서 직접 접근:
```
http://localhost:3000/assets/application-54e30363.css
```

이 URL이 작동하면 Propshaft가 정상적으로 에셋을 서빙하고 있는 것입니다.

## 문제 해결

만약 `<link>` 태그가 여전히 보이지 않는다면:

1. **레이아웃 파일 확인**: `app/layouts/application.html.erb`에 `stylesheet_link_tag "application"`이 있는지 확인
2. **에셋 파일 확인**: `app/assets/stylesheets/application.css` 파일이 존재하고 내용이 있는지 확인
3. **서버 로그 확인**: CSS 파일에 대한 GET 요청이 있는지 확인
4. **Propshaft 초기화 확인**: 서버 시작 시 Propshaft 관련 메시지가 있는지 확인


