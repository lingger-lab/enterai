# Importmap 서버 재시작 가이드

## 현재 상태

✅ `importmap-rails` gem 설치 완료
✅ Importmap 엔진 로드됨 (`Importmap loaded`)
❌ `javascript_importmap_tags` 헬퍼 메서드가 인식되지 않음

## 문제 원인

서버가 `importmap-rails` gem 설치 **전**에 시작되어서, 헬퍼 메서드가 로드되지 않았습니다.

## 해결 방법

### 1. 서버 완전 종료 (중요!)

현재 실행 중인 서버를 완전히 종료해야 합니다:

1. 서버가 실행 중인 PowerShell 창에서 `Ctrl+C`를 여러 번 누르기
2. "Terminate batch job (Y/N)?" 메시지가 나오면 `Y` 입력
3. PowerShell 창이 프롬프트로 돌아올 때까지 대기

### 2. 서버 재시작

**새로운 PowerShell 창**에서 실행하거나, 기존 창에서:

```powershell
# Ruby 경로 추가 (필요한 경우)
$env:Path += ";C:\Ruby33-x64\bin"

# 서버 재시작
bundle exec rails s
```

### 3. 예상 출력

정상적으로 실행되면 다음과 같은 메시지가 표시됩니다:

```
=> Booting Puma
=> Rails 8.0.4 application starting in development
* Listening on http://127.0.0.1:3000
Use Ctrl-C to stop
```

**에러 없이** 서버가 시작되어야 합니다.

### 4. 브라우저에서 확인

1. `http://localhost:3000` 접속
2. **500 에러가 사라지고** 페이지가 정상적으로 로드되는지 확인
3. 페이지 소스 보기 (`Ctrl+U`)에서 `<head>` 섹션 확인:
   ```html
   <script type="importmap">...</script>
   <script type="module">...</script>
   ```

## 문제가 계속되면

### 대안 1: 레이아웃 파일에서 임시 제거

만약 서버 재시작 후에도 문제가 계속되면, 레이아웃 파일에서 임시로 제거할 수 있습니다:

```erb
<!-- 임시로 주석 처리 -->
<%#= javascript_importmap_tags %>
```

하지만 이렇게 하면 Turbo와 Stimulus가 작동하지 않을 수 있습니다.

### 대안 2: 수동으로 JavaScript 태그 추가

```erb
<%= javascript_include_tag "application", type: "module" %>
```

하지만 이 방법은 importmap의 장점을 활용할 수 없습니다.

## 권장 사항

**반드시 서버를 완전히 종료하고 재시작하세요.** 이렇게 하면 새로 설치된 gem이 제대로 로드됩니다.

## 참고

- Rails는 서버 시작 시 gem을 로드합니다
- gem 설치 후 서버를 재시작하지 않으면 변경사항이 적용되지 않습니다
- `importmap-rails` gem이 로드되면 `javascript_importmap_tags` 헬퍼가 자동으로 사용 가능해집니다


