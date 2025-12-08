# CSS 파일 직접 접근 에러 해결

## 문제
브라우저에서 `http://localhost:3000/assets/application.debug-[hash].css` 접근 시 Error Code: -102 발생

## 원인
1. 개발 환경에서 `.debug` 버전의 파일은 런타임에 생성됩니다
2. 프리컴파일된 파일(`public/assets/`)은 프로덕션용입니다
3. 개발 환경에서는 Sprockets가 런타임에 컴파일해야 합니다

## 해결 방법

### 1. 개발 환경 설정 확인

`config/environments/development.rb`에 다음 설정이 있어야 합니다:
```ruby
config.assets.compile = true
config.assets.debug = true
config.assets.check_precompiled_asset = false  # 추가됨
```

### 2. 올바른 URL 사용

개발 환경에서는 실제 해시값을 사용해야 합니다:
```
http://localhost:3000/assets/application-be233f39ddbae0e152a7284f2291f997273473b3d0d4789158e54af8c460101c.css
```

또는 Sprockets가 자동으로 생성하는 URL:
```
http://localhost:3000/assets/application.css
```

### 3. 서버 재시작

설정 변경 후 서버를 재시작해야 합니다:
```powershell
# 서버 중지 (Ctrl+C)
# 서버 재시작
$env:Path += ";C:\Ruby33-x64\bin"
bundle exec rails s
```

### 4. 페이지에서 자동 생성된 링크 사용

직접 URL을 입력하는 대신, 페이지 소스에서 생성된 링크를 사용하세요:
1. `http://localhost:3000` 접속
2. 페이지 소스 보기 (`Ctrl+U`)
3. `<head>`에서 실제 생성된 `<link>` 태그의 `href` 값 확인
4. 그 URL을 사용

## 참고

- 개발 환경: Sprockets가 런타임에 컴파일 (`.debug` 버전 생성 가능)
- 프로덕션 환경: 프리컴파일된 파일 사용 (`public/assets/`)

현재 설정으로는 개발 환경에서 런타임 컴파일이 활성화되어 있으므로, 서버가 실행 중일 때 CSS 파일이 자동으로 생성됩니다.


