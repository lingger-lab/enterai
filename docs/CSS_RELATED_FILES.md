# CSS 문제 관련 파일 리스트

## 핵심 파일 (수정/확인 필요)

### 1. 레이아웃 파일 (가장 중요!)
**경로**: `app/views/layouts/application.html.erb`
- `stylesheet_link_tag "application"` 포함 여부 확인
- 레이아웃이 올바른 위치에 있는지 확인 (`app/views/layouts/`)

### 2. CSS 소스 파일
**경로**: `app/assets/stylesheets/application.tailwind.css`
- Tailwind CSS 지시문 포함 (`@tailwind base;`, `@tailwind components;`, `@tailwind utilities;`)
- 커스텀 스타일 정의

### 3. 빌드된 CSS 파일
**경로**: `app/assets/builds/application.css`
- Tailwind가 빌드한 최종 CSS 파일
- `npm run build:css` 실행 시 생성됨

### 4. Propshaft용 CSS 파일
**경로**: `app/assets/stylesheets/application.css`
- Propshaft가 서빙하는 실제 CSS 파일
- `app/assets/builds/application.css`의 내용이 복사되어야 함

## 설정 파일

### 5. Tailwind 설정
**경로**: `config/tailwind.config.js`
- `content` 경로 설정
- `output` 경로 설정 (`app/assets/builds/application.css`)

### 6. Propshaft Manifest
**경로**: `app/assets/config/manifest.js`
- Propshaft가 인식하는 에셋 목록
- `//= link_tree ../builds` 포함 여부 확인

### 7. Rails 애플리케이션 설정
**경로**: `config/application.rb`
- `config.assets.enabled = true`
- `config.assets.debug = true`

### 8. 개발 환경 설정
**경로**: `config/environments/development.rb`
- `config.assets.enabled = true`
- `config.assets.debug = true`
- `config.public_file_server.enabled = true`

### 9. 빌드 스크립트
**경로**: `package.json`
- `build:css` 스크립트 확인
- Tailwind 빌드 및 복사 로직

## 파일 상세 정보

### 레이아웃 파일
```
app/views/layouts/application.html.erb
├── <head> 섹션
│   ├── stylesheet_link_tag "application"  ← CSS 링크 태그
│   └── javascript_importmap_tags
└── <body> 섹션
```

### CSS 파일 구조
```
app/assets/
├── stylesheets/
│   ├── application.tailwind.css  ← 소스 파일 (Tailwind 지시문)
│   └── application.css           ← Propshaft용 파일 (빌드된 CSS)
├── builds/
│   └── application.css           ← Tailwind 빌드 결과
└── config/
    └── manifest.js               ← Propshaft manifest
```

## 파일별 역할

| 파일 | 역할 | 중요도 |
|------|------|--------|
| `app/views/layouts/application.html.erb` | CSS 링크 태그 포함 | ⭐⭐⭐ |
| `app/assets/stylesheets/application.css` | Propshaft가 서빙하는 CSS | ⭐⭐⭐ |
| `app/assets/builds/application.css` | Tailwind 빌드 결과 | ⭐⭐⭐ |
| `app/assets/stylesheets/application.tailwind.css` | Tailwind 소스 파일 | ⭐⭐ |
| `app/assets/config/manifest.js` | Propshaft 에셋 목록 | ⭐⭐ |
| `config/tailwind.config.js` | Tailwind 설정 | ⭐⭐ |
| `config/application.rb` | Rails 에셋 설정 | ⭐ |
| `config/environments/development.rb` | 개발 환경 에셋 설정 | ⭐ |
| `package.json` | 빌드 스크립트 | ⭐ |

## 문제 해결 체크리스트

### 1. 레이아웃 파일 확인
- [ ] `app/views/layouts/application.html.erb` 존재
- [ ] `stylesheet_link_tag "application"` 포함
- [ ] 잘못된 경로 (`app/layouts/`)에 파일 없음

### 2. CSS 파일 확인
- [ ] `app/assets/stylesheets/application.css` 존재
- [ ] `app/assets/builds/application.css` 존재
- [ ] `app/assets/stylesheets/application.tailwind.css` 존재

### 3. 설정 파일 확인
- [ ] `config/tailwind.config.js`에 `output` 경로 설정
- [ ] `app/assets/config/manifest.js`에 `//= link_tree ../builds` 포함
- [ ] `config/application.rb`에 `config.assets.enabled = true`
- [ ] `config/environments/development.rb`에 에셋 설정

### 4. 빌드 확인
- [ ] `npm run build:css` 실행
- [ ] `app/assets/builds/application.css` 생성됨
- [ ] `app/assets/stylesheets/application.css` 업데이트됨

## 빌드 및 실행 순서

1. **CSS 빌드**
   ```powershell
   npm run build:css
   ```

2. **에셋 정리** (선택 사항)
   ```powershell
   bin/rails assets:clobber
   ```

3. **서버 재시작** (필수!)
   ```powershell
   bundle exec rails s
   ```

## 문제 발생 시 확인 사항

1. **CSS 링크 태그가 보이지 않는 경우**
   - 레이아웃 파일 위치 확인 (`app/views/layouts/`)
   - `stylesheet_link_tag` 포함 여부 확인

2. **CSS 파일이 로드되지 않는 경우**
   - `app/assets/stylesheets/application.css` 존재 확인
   - Propshaft manifest 확인
   - 서버 재시작 확인

3. **Tailwind 스타일이 적용되지 않는 경우**
   - `app/assets/builds/application.css` 빌드 확인
   - `app/assets/stylesheets/application.css` 내용 확인
   - `tailwind.config.js`의 `content` 경로 확인

## 관련 문서

- `docs/PROPSHAFT_UPDATE_SUMMARY.md` - Propshaft 설정 요약
- `docs/LAYOUT_FIX_COMPLETE.md` - 레이아웃 파일 수정 완료
- `docs/PATH_VALIDATION_REPORT.md` - 경로 점검 보고서


