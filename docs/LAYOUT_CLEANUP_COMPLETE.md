# 레이아웃 파일 정리 완료 ✅

## 문제 상황
동일한 레이아웃 파일이 두 경로에 존재했습니다:
- ❌ `app/layouts/application.html.erb` (잘못된 경로)
- ✅ `app/views/layouts/application.html.erb` (올바른 경로)

## 해결 완료

✅ `app/layouts/application.html.erb` 삭제 완료
✅ `app/views/layouts/application.html.erb` 유지 (올바른 경로)

## Rails 레이아웃 파일 경로 규칙

Rails는 기본적으로 다음 경로에서 레이아웃 파일을 찾습니다:
- ✅ `app/views/layouts/application.html.erb` (표준 경로)
- ❌ `app/layouts/application.html.erb` (비표준 경로, 인식되지 않음)

## 다음 단계

### 1. 서버 재시작 (필수!)

파일 삭제 후 서버를 재시작해야 합니다:

```powershell
# 서버 중지 (Ctrl+C를 여러 번 눌러 완전히 종료)
# 서버 재시작
$env:Path += ";C:\Ruby33-x64\bin"
bundle exec rails s
```

### 2. 브라우저에서 확인

1. 브라우저에서 `http://localhost:3000` 접속
2. **우클릭 → "페이지 소스 보기"** (`Ctrl+U`)
3. `<head>` 섹션 확인:
   ```html
   <head>
     <title>Enter.ai - AI 코칭 예약</title>
     <meta name="viewport" content="width=device-width,initial-scale=1">
     ...
     <link rel="stylesheet" href="/assets/application-3bc0b26f.css" />
     ...
   </head>
   ```

### 3. Network 탭 확인

1. `F12` 또는 `Ctrl+Shift+I`로 개발자 도구 열기
2. **Network 탭** 선택
3. 페이지 새로고침 (`Ctrl+R`)
4. 필터에서 "CSS" 선택
5. `application*.css` 파일이 로드되는지 확인

## 정상 작동 체크리스트

| 체크 항목 | 기대 결과 |
|---------|---------|
| 레이아웃 파일 위치 | ✅ `app/views/layouts/application.html.erb`만 존재 |
| 잘못된 경로 파일 | ✅ `app/layouts/application.html.erb` 삭제됨 |
| 브라우저 `<head>` (페이지 소스) | ✅ `<head>` 섹션 표시 |
| CSS 링크 태그 | ✅ `<link rel="stylesheet" href="/assets/application-[hash].css">` |
| Network 탭 | ✅ CSS 파일 요청 표시 |
| 페이지 표시 | ✅ Tailwind 스타일 적용 |

## 참고

- Rails는 `app/views/layouts/` 경로에서만 레이아웃 파일을 찾습니다
- 다른 경로에 레이아웃 파일이 있어도 Rails가 인식하지 않습니다
- 레이아웃 파일 위치 변경 후 서버를 재시작하지 않으면 변경사항이 적용되지 않습니다


