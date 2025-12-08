# Propshaft 완전 호환 템플릿 설정 완료 ✅

## 완료된 수정 사항

### 1. ✅ config/application.rb
- Propshaft는 Bundler가 자동으로 로드하므로 별도 require 불필요
- `config.assets.enabled = true` 추가 완료
- `config.assets.debug = true` 추가 완료

### 2. ✅ config/tailwind.config.js
- `output: "app/assets/builds/application.css"` 추가 완료

### 3. ✅ 기존 설정 확인
- `app/assets/config/manifest.js` - 올바르게 설정됨
- `app/assets/stylesheets/application.tailwind.css` - 올바르게 설정됨
- `app/layouts/application.html.erb` - `stylesheet_link_tag` 포함됨
- `Gemfile` - Propshaft 포함, Sprockets 없음 ✅

## 빌드 및 실행 절차

### 1️⃣ 의존성 설치 (이미 완료된 경우 생략 가능)

```powershell
bundle install
npm install
```

### 2️⃣ Tailwind Propshaft 설치 (이미 설치되어 있더라도 재실행)

```powershell
bundle exec rails tailwindcss:install:propshaft
```

### 3️⃣ 캐시 및 에셋 정리

```powershell
bin/rails assets:clobber
```

### 4️⃣ Tailwind 빌드

```powershell
bin/rails tailwindcss:build
```

또는 npm 스크립트 사용:

```powershell
npm run build:css
```

### 5️⃣ 에셋 프리컴파일 (개발 환경에서는 선택 사항)

```powershell
bin/rails assets:precompile
```

### 6️⃣ 서버 실행

```powershell
# Ruby 경로 추가 (필요한 경우)
$env:Path += ";C:\Ruby33-x64\bin"

# 서버 실행
bundle exec rails s
```

## 정상 작동 체크리스트

| 체크 항목 | 기대 결과 |
|---------|---------|
| `app/assets/builds/application.css` | ✅ 존재해야 함 |
| 서버 실행 시 콘솔 로그 | Propshaft 관련 메시지 확인 |
| 브라우저 `<head>` (페이지 소스 보기 `Ctrl+U`) | ✅ `<link rel="stylesheet" href="/assets/application-[hash].css">` 표시 |
| 페이지 표시 | Tailwind 스타일 적용 (bg-white, text-indigo-600 등) |
| 직접 CSS 파일 접근 | `http://localhost:3000/assets/application-[hash].css` 정상 표시 |

## 문제 해결

### CSS 링크 태그가 보이지 않는 경우

1. **서버 완전 재시작** (가장 중요!)
   ```powershell
   # 서버 중지 (Ctrl+C를 여러 번 눌러 완전히 종료)
   # 서버 재시작
   $env:Path += ";C:\Ruby33-x64\bin"
   bundle exec rails s
   ```

2. **브라우저 캐시 완전 삭제**
   - `Ctrl+Shift+Delete` → "캐시된 이미지 및 파일" 삭제
   - 또는 시크릿 모드에서 테스트 (`Ctrl+Shift+N`)

3. **페이지 소스 확인**
   - 브라우저에서 `Ctrl+U`로 페이지 소스 보기
   - `<head>` 섹션에서 `<link rel="stylesheet">` 태그 확인

4. **CSS 파일 직접 접근 테스트**
   ```
   http://localhost:3000/assets/application-[hash].css
   ```
   - 해시는 서버 로그나 페이지 소스에서 확인 가능

## 참고 사항

- Propshaft는 서버 시작 시 에셋을 로드합니다
- 파일을 변경한 후에는 서버를 재시작해야 합니다
- 개발 환경에서는 Propshaft가 에셋을 직접 서빙합니다
- `stylesheet_link_tag`는 Propshaft가 에셋을 찾으면 정상적으로 작동합니다

