# 서버 실행 및 문제 해결 가이드

## 서버 실행

```powershell
# Ruby 경로 추가 (한 번만)
$env:Path += ";C:\Ruby33-x64\bin"

# 서버 실행
bundle exec rails s
```

## 일반적인 문제 해결

### 1. 라우팅 에러

#### Chrome DevTools 자동 요청 경로
- **에러**: `ActionController::RoutingError (No route matches [GET] "/.well-known/appspecific/com.chrome.devtools.json")`
- **원인**: Chrome 브라우저가 자동으로 요청하는 경로입니다.
- **해결**: `config/routes.rb`에 이미 처리 라우트가 추가되어 있습니다.
- **상태**: ✅ 해결됨

#### Favicon 요청
- **에러**: `GET /favicon.ico 404 (Not Found)`
- **원인**: 브라우저가 자동으로 요청하는 favicon 파일입니다.
- **해결**: `config/routes.rb`에 이미 처리 라우트가 추가되어 있습니다.
- **상태**: ✅ 해결됨

### 2. 서버 종료 시 중복 메시지

#### Windows 배치 작업 종료 프롬프트
- **현상**: 서버 종료 시 "Terminate batch job (Y/N)?" 메시지가 2번 표시됩니다.
- **원인**: Windows PowerShell에서 `Ctrl+C`를 누르면 배치 작업 종료 프롬프트가 표시됩니다. 이는 Windows의 정상적인 동작입니다.
- **해결 방법**:
  1. **한 번만 Y 입력**: 첫 번째 프롬프트에 `Y`를 입력하면 서버가 종료됩니다.
  2. **Ctrl+C 한 번만 누르기**: 여러 번 누르지 마세요.
  3. **강제 종료**: `Ctrl+Break`를 사용하면 프롬프트 없이 즉시 종료됩니다.

#### 정상적인 종료 과정
```
Gracefully stopping, waiting for requests to finish
=== puma shutdown: 2025-12-08 20:04:51 +0900 ===
- Goodbye!
Exiting
```
이 메시지는 정상적인 종료 과정입니다.

### 3. SIGUSR2 경고 메시지

#### Windows에서 지원되지 않는 시그널
- **경고**: 
  ```
  *** SIGUSR2 not implemented, signal based restart unavailable!
  *** SIGUSR1 not implemented, signal based restart unavailable!
  *** SIGHUP not implemented, signal based logs reopening unavailable!
  ```
- **원인**: Windows는 Unix 시그널(SIGUSR1, SIGUSR2, SIGHUP)을 지원하지 않습니다.
- **해결**: 이 경고는 무시해도 됩니다. 애플리케이션 기능에는 영향을 주지 않습니다.
- **상태**: ✅ 정상 (Windows에서 예상되는 동작)

### 4. 서버가 시작되지 않을 때

#### Ruby 경로 문제
- **에러**: `rails : The term 'rails' is not recognized...`
- **해결**: 
  ```powershell
  $env:Path += ";C:\Ruby33-x64\bin"
  bundle exec rails s
  ```

#### 포트가 이미 사용 중일 때
- **에러**: `Address already in use - bind(2) for "127.0.0.1" port 3000`
- **해결**: 
  ```powershell
  # 다른 포트로 실행
  bundle exec rails s -p 3001
  ```

### 5. 데이터베이스 연결 문제

#### PostgreSQL 연결 실패
- **에러**: `could not connect to server`
- **해결**: 
  1. PostgreSQL 서비스가 실행 중인지 확인
  2. `.env` 파일에 올바른 데이터베이스 정보가 있는지 확인
  3. 데이터베이스가 생성되었는지 확인: `bundle exec rails db:create`

## 로그 레벨 조정

개발 환경에서 불필요한 로그를 줄이려면 `config/environments/development.rb`에서 다음 설정을 조정할 수 있습니다:

```ruby
# 라우팅 에러를 로그에 표시하지 않음 (선택사항)
config.consider_all_requests_local = false
```

하지만 개발 중에는 `true`로 유지하는 것이 디버깅에 도움이 됩니다.

## 서버 재시작

코드 변경 후 서버를 재시작하려면:

1. `Ctrl+C`로 서버 중지
2. `bundle exec rails s`로 다시 시작

또는 Rails의 자동 리로드 기능을 사용하면 대부분의 변경사항은 서버 재시작 없이 반영됩니다.


