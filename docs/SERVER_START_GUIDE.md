# 서버 실행 가이드

## 현재 상태

✅ CSS 파일 빌드 완료
- `app/assets/builds/application.css` (4897 bytes)
- `app/assets/stylesheets/application.css` (4897 bytes)
- Tailwind CSS 내용 포함됨

❌ 서버 미실행
- 포트 3000이 열려있지 않음
- 서버를 다시 실행해야 함

## 서버 실행 방법

### 방법 1: bundle exec 사용 (권장)

```powershell
# Ruby 경로 추가 (필요한 경우)
$env:Path += ";C:\Ruby33-x64\bin"

# 서버 실행
bundle exec rails s
```

### 방법 2: bin/rails 사용

```powershell
# Ruby 경로 추가 (필요한 경우)
$env:Path += ";C:\Ruby33-x64\bin"

# 서버 실행
bin/rails s
```

## 예상 출력

정상적으로 실행되면 다음과 같은 메시지가 표시됩니다:

```
=> Booting Puma
=> Rails 8.0.4 application starting in development
=> Run `bin/rails server --help` for more startup options
*** SIGUSR2 not implemented, signal based restart unavailable!
*** SIGUSR1 not implemented, signal based restart unavailable!
*** SIGHUP not implemented, signal based logs reopening unavailable!
Puma starting in single mode...
* Puma version: 6.6.1 ("Return to Forever")
* Ruby version: ruby 3.3.10 (2025-10-23 revision 343ea05002) [x64-mingw-ucrt]
*  Min threads: 5
*  Max threads: 5
*  Environment: development
*          PID: [프로세스 ID]
* Listening on http://[::1]:3000
* Listening on http://127.0.0.1:3000
Use Ctrl-C to stop
```

## 서버 실행 후 확인 사항

### 1. 브라우저에서 접속

1. `http://localhost:3000` 접속
2. 페이지가 정상적으로 로드되는지 확인

### 2. 페이지 소스 확인

1. 우클릭 → "페이지 소스 보기" (`Ctrl+U`)
2. `<head>` 섹션에서 다음 태그 확인:
   ```html
   <link rel="stylesheet" href="/assets/application-[hash].css" data-turbo-track="reload">
   ```

### 3. Network 탭 확인

1. 개발자 도구 (`F12`) → Network 탭
2. 페이지 새로고침 (`Ctrl+R`)
3. 필터에서 "CSS" 선택
4. `application*.css` 파일이 로드되는지 확인

### 4. CSS 파일 직접 접근

브라우저에서 직접 접근:
```
http://localhost:3000/assets/application-[hash].css
```

**예상 결과**:
- Tailwind CSS 내용이 정상적으로 표시됨
- 서버 로그에 `Started GET "/assets/application-[hash].css"`가 표시됨

## 문제 해결

### 서버가 시작되지 않는 경우

1. **포트 확인**
   ```powershell
   netstat -ano | findstr :3000
   ```
   - 포트가 사용 중이면 다른 포트 사용: `bundle exec rails s -p 3001`

2. **에러 로그 확인**
   ```powershell
   Get-Content log/development.log -Tail 50
   ```

3. **Ruby 경로 확인**
   ```powershell
   ruby --version
   rails --version
   ```

### CSS가 로드되지 않는 경우

1. **CSS 파일 확인**
   ```powershell
   Get-Item "app/assets/stylesheets/application.css" | Select-Object Length
   ```

2. **빌드 재실행**
   ```powershell
   npm run build:css
   ```

3. **서버 재시작** (필수!)

## 참고

- 서버는 포그라운드에서 실행되므로, 서버가 실행 중이면 프롬프트가 반환되지 않습니다
- 서버를 중지하려면 `Ctrl+C`를 누르세요
- CSS 파일 변경 후에는 서버를 재시작해야 합니다


