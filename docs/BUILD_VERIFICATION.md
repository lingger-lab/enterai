# 빌드 및 서버 실행 검증 가이드

## 실행한 명령어

```powershell
bin/rails assets:clobber
bin/rails tailwindcss:build
bin/rails s
```

## 확인 사항

### 1. CSS 파일 빌드 확인

**확인할 파일**:
- `app/assets/builds/application.css` - Tailwind 빌드 결과
- `app/assets/stylesheets/application.css` - Propshaft용 파일

**예상 결과**:
- 두 파일 모두 최근에 수정되었어야 함
- 파일 크기가 4897 bytes 이상이어야 함
- Tailwind CSS 내용이 포함되어 있어야 함

### 2. 서버 실행 확인

**확인 방법**:
1. **포트 확인**: `localhost:3000`이 열려있는지 확인
2. **프로세스 확인**: Ruby/Rails/Puma 프로세스가 실행 중인지 확인
3. **서버 로그 확인**: 서버가 정상적으로 시작되었는지 확인

### 3. 서버가 실행되지 않은 경우

**가능한 원인**:
- 서버가 백그라운드로 실행되지 않음
- 포트 3000이 이미 사용 중
- 에러가 발생하여 서버가 종료됨

**해결 방법**:
```powershell
# 서버를 포그라운드에서 실행
bundle exec rails s

# 또는 특정 포트 지정
bundle exec rails s -p 3001
```

## 다음 단계

### 1. CSS 재빌드 (필요한 경우)

```powershell
npm run build:css
```

### 2. 서버 실행

```powershell
# Ruby 경로 추가 (필요한 경우)
$env:Path += ";C:\Ruby33-x64\bin"

# 서버 실행
bundle exec rails s
```

**예상 출력**:
```
=> Booting Puma
=> Rails 8.0.4 application starting in development
* Listening on http://127.0.0.1:3000
```

### 3. 브라우저에서 확인

1. `http://localhost:3000` 접속
2. 페이지 소스 보기 (`Ctrl+U`)
3. `<head>` 섹션에서 CSS 링크 태그 확인
4. Network 탭에서 CSS 파일 요청 확인

## 문제 해결

### 서버가 시작되지 않는 경우

1. **포트 확인**
   ```powershell
   netstat -ano | findstr :3000
   ```

2. **에러 로그 확인**
   ```powershell
   Get-Content log/development.log -Tail 50
   ```

3. **서버 재시작**
   ```powershell
   # 기존 프로세스 종료 후
   bundle exec rails s
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

- `bin/rails s`는 포그라운드에서 실행되므로, 서버가 실행 중이면 프롬프트가 반환되지 않습니다
- 서버를 중지하려면 `Ctrl+C`를 누르세요
- CSS 파일 변경 후에는 서버를 재시작해야 합니다


