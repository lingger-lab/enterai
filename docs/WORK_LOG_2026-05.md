# EnterLab 종합 개선 작업 기록 (2026년 5월)

> 본 문서는 2026-05-06 ~ 2026-05-07에 진행한 종합 개선 작업의 상세 기록입니다.
> 향후 참고/회고/유지보수용으로 보관됩니다.

---

## 📊 전체 요약

| 항목 | 수치 |
|------|------|
| 작업 기간 | 2026-05-06 ~ 2026-05-07 |
| 커밋 수 | 약 15+ |
| 변경 파일 | 약 80+ |
| 코드 라인 변경 | +1,500 / -300 |
| 비용 절감 | LB 제거 ₩322,140/년 + Artifact 정책 ₩10k/년 |
| 신규 테스트 | 33 → 59개 (+26개) |
| 신규 페이지 | 4개 (FAQ, 이용약관, 환불정책, 404/500) |
| 보안 키 회전 | DATABASE_PASSWORD, SECRET_KEY_BASE |

---

## ✅ 완료한 작업 (카테고리별)

### 🛡 1. 보안 (Security)

#### 1.1 긴급 키 회전 (Critical)
- **문제**: cloudbuild.yaml에 DB 비밀번호/SECRET_KEY_BASE/ENCRYPTION_KEY가 평문으로 노출되어 있었고, GitHub repo가 public이라 누구나 볼 수 있는 상태였음
- **조치**:
  - DATABASE_PASSWORD 회전 (Cloud SQL + Cloud Run 적용)
  - SECRET_KEY_BASE 회전 (Cloud Run 적용)
  - ENCRYPTION_KEY는 유지 (회전 시 기존 PII 복호화 불가)
  - cloudbuild.yaml에서 평문 비밀 제거
  - `--set-env-vars` → `--update-env-vars`로 변경 (기존 비밀 env var 유지)
  - DB 마이그레이션 단계 cloudbuild.yaml에서 제거 (비밀 노출 방지, 향후 수동 실행)
- **결과 파일**: `CREDENTIALS.local.md` (git 무시됨, 로컬 보관)

#### 1.2 CSP (Content Security Policy)
- nonce를 SecureRandom 기반으로 변경 (이전: 빈 세션 ID 시 nonce 빈값으로 importmap 차단)
- script-src: ga.jspm.io + googletagmanager.com 허용
- connect-src: ga.jspm.io + cdn.jsdelivr.net + google-analytics.com 외 허용
- font-src/style-src: cdn.jsdelivr.net 허용 (Pretendard)
- style-src에서 nonce 제외 (CSP3 spec: nonce 시 unsafe-inline 무시 → inline style 차단 회피)

#### 1.3 보안 헤더
- HSTS (max-age 2년, includeSubDomains) ✓
- X-Content-Type-Options: nosniff ✓
- X-Frame-Options: SAMEORIGIN ✓
- Referrer-Policy: strict-origin-when-cross-origin ✓
- Cookie: HttpOnly + Secure + SameSite=Lax ✓
- force_ssl=true ✓

#### 1.4 Rate Limiting (이미 적용)
- rack-attack: 예약 생성, 관리자 로그인, 슬롯 조회 등

#### 1.5 PII 암호화 (이미 적용)
- attr_encrypted: 이름/연락처/이메일 컬럼 단위 암호화

---

### 💰 2. 인프라 비용 절감

#### 2.1 Cloud Load Balancer 제거 (₩322,140/년 절감)
- **이전**: HTTPS Forwarding Rule + HTTP Forwarding Rule (₩26,845/월)
- **조치**: Firebase Hosting으로 마이그레이션
  - Firebase Hosting 활성화 + 도메인 매핑
  - DNS 변경 (가비아: A @ → 199.36.158.100)
  - SSL 인증서 자동 발급
  - LB 리소스 모두 삭제 (Forwarding Rules, Target Proxies, URL Maps, Backend Service, NEG, SSL Certs, Static IP)
- **결과**: 월 ₩26,845 → ₩0 + Firebase CDN 인천 PoP (한국 사용자 빠름)

#### 2.2 Cloud SQL 비용 검토 (유지 결정)
- 현재 db-f1-micro (최저 등급), ENTERPRISE Edition
- shared-core라 Edition 다운그레이드 무의미
- Neon/Supabase 검토 → 한국 검증 사례 부족 + auto-pause/cold-start 위험 + PIPA 처리방침 추가 부담
- **결정**: Cloud SQL 유지 (₩192k/년이 안정성 가치 대비 합리적)

#### 2.3 Artifact Registry 정리 정책
- 누적 9.5GB / 43개 이미지
- 정책 적용: 최신 5개 유지 + 30일 이상 자동 삭제
- 자동 정리 24~48시간 내 실행 (~₩10k/년 절감)

#### 2.4 Cloud SQL 자동 백업 활성
- 03:00 매일, 7일 보관

---

### 🎨 3. UI/UX 개선

#### 3.1 디자인 시스템 (Supanova)
- Pretendard 폰트 적용 (한국어 프리미엄)
- `lang="ko"`, `word-break: keep-all`, font-smoothing
- 헤드라인 `tracking-tight` + `text-wrap: balance`
- 가격 숫자 `tabular-nums`
- 섹션 패딩 확대 (py-6 → py-10/24)
- 그라디언트 톤다운 (indigo-purple → indigo only)

#### 3.2 인터랙션
- 슬라이드 클릭 시 전체화면 라이트박스 (cursor-zoom-in)
- 모바일 핀치 줌 가능
- 자동 슬라이드/탭 회전 비활성 (사용자 요청)
- 자동 회전 안전장치 8초 (mobile touchend 누락 대비)
- WebP 변환 (44MB → 2MB, 95% 감소)
- img width/height + decoding="async" (CLS 개선)

#### 3.3 폼 안정성
- 제출 시 버튼 비활성화 + 로딩 스피너 (중복 제출 방지)
- 30초 안전장치 (네트워크 오류 시 재시도 가능)
- localStorage 자동 저장/복구 (페이지 이탈 시 입력 보존)
- 제출 성공 시 자동 정리

#### 3.4 카드 정렬
- 패키지 카드: `flex flex-col` + `mt-auto` (버튼 하단 정렬)
- 웹 개발 카드: 설명문도 하단 정렬

#### 3.5 색상 대비
- 흰 배경 위 text-gray-400 → text-gray-500 (WCAG AA 준수)

#### 3.6 파비콘
- 이모지 🤖 → indigo 배경의 대문자 E

#### 3.7 격자 배경 애니메이션
- 히어로 격자 4초 대각선 이동 (시각적 효과)

---

### 📞 4. 콘텐츠 + 비즈니스 정보

#### 4.1 코칭 패키지
- 가격: STARTER 98만원, STANDARD 148만원, PREMIUM 249만원
- Q&A 지원 → "온라인 1:1 코칭 지원(30분/일, 2.5시간/주, 10시간/월)"
- 커뮤니티 → "카톡 채팅 커뮤니티"

#### 4.2 웹 개발 의뢰 (앱 개발 → 웹 개발 변경)
- BASIC 290만원~, STANDARD 500만원~, PREMIUM 1,000만원~
- 난이도 표시 (하/중/상)

#### 4.3 코치 소개 보강
- 부산대학교 미생물학과 졸업
- 7년 기획실, 7년 PM, 7년 나노소재 벤처
- 20개+ 웹 개발

#### 4.4 사업자 정보 (푸터)
- ENTERLABS (엔터랩스)
- 대표자: 김동현
- 사업자번호: 405-02-46113
- 주소: 경남 김해시 대청로26번안길 25-8, 202호(관동동)
- 연락처: 0502-1927-1910 (tel: 링크)
- 이메일: iamblackwhite86@gmail.com (mailto: 링크)
- 협업: 부산대학교 생명자원과학대학 생명산업융합연구원

#### 4.5 후기 진정성 표시
- "각색된 시나리오" 명시 (표시광고법 대응)

---

### ⚖️ 5. 법적 컴플라이언스 페이지

#### 5.1 개인정보 처리방침 대폭 보강
- ✅ 처리위탁 명시 (Google Cloud, SendGrid, SENS, 카카오, GA)
- ✅ 정보주체 권리 (열람/정정/삭제/처리정지)
- ✅ 자동수집장치(쿠키) + Google Analytics 옵트아웃 안내
- ✅ 만 14세 미만 정책
- ✅ 권익침해 구제 기관 안내 (개인정보분쟁조정위원회 등)
- ✅ 보유기간 구체화 (취소 90일/완료 1년)

#### 5.2 이용약관 페이지 신규
- 10개 조항 (목적, 정의, 약관 효력, 서비스 제공, 이용자/회사 의무, 결제/환불, 지적재산권, 책임 제한, 분쟁 해결, 부칙)

#### 5.3 환불 정책 페이지 신규
- 코칭 패키지 단계별 환불 비율 (학원법 시행령 제18조 준용)
- 웹 개발 의뢰 단계별 환불 비율
- 회사 귀책 사유 100% 환불
- 환불 절차 및 분쟁 해결 안내

#### 5.4 FAQ 페이지 신규
- 11개 질문 (코딩 무경험자, 코칭 형태, 정원, 결제, 환불, 일정 변경 등)
- FAQ JSON-LD Structured Data

---

### ♿ 6. 접근성

- Skip navigation 링크 (포커스 시 표시)
- `<main id="main-content">` 시맨틱 랜드마크
- focus-visible 포커스 강화
- 햄버거 메뉴 aria-expanded/aria-controls/aria-label
- 폼 aria-invalid + aria-describedby + role="alert"
- autocomplete (name/tel/email) + inputmode="numeric"
- 슬라이드 이미지 alt 다양화 (페이지별 제목)
- tel:/mailto: 링크화

---

### 🌐 7. SEO

- robots.txt 수정 (잘못된 sitemap URL → enterlab.cloud)
- /admin disallow
- sitemap.xml 신규 생성 (홈, 예약폼, 조회, FAQ, 약관, 환불정책, 처리방침)
- canonical URL 메타 태그
- 페이지별 고유 title (홈/예약폼/조회/FAQ/약관/환불/처리방침)
- og:locale=ko_KR
- noindex 메타 (예약 상세, 관리자 페이지)
- JSON-LD: LocalBusiness + Service Offers
- JSON-LD: FAQPage (FAQ 페이지)

---

### 🧪 8. 테스트 (33 → 59개)

#### 신규 추가 (26개)
- Review 모델 8개 테스트 (관계, 검증, scope, submitted?)
- TimeSlot 모델 10개 테스트 (검증, scope, book/release, bulk_create)
- SmsNotificationJob 2개 테스트
- EmailNotificationJob 2개 테스트
- ReservationMailer 4개 테스트 (created/admin/confirmed/cancelled)

#### 기존 (33개) — 유지
- Reservation 모델 18개
- ReservationsController 통합 15개

#### 인프라
- test/test_helper.rb 신규 (Rails 표준)
- Windows fork 미지원으로 parallelize 비활성

---

### 🤖 9. CI/CD 자동화

#### 9.1 GitHub Actions
- `.github/workflows/ci.yml`: PR/push 시 PostgreSQL + 테스트 + bundler-audit
- `.github/workflows/deploy.yml`: 수동 트리거 전용 (workflow_dispatch)

#### 9.2 Dependabot
- `.github/dependabot.yml`: 주간 Ruby gem + 월간 GitHub Actions 자동 PR

---

### 📊 10. 분석/관측

- Google Analytics 4 통합 (`G-RJ1JTWX6S5`)
- production 환경에서만 추적
- CSP nonce 적용
- Enhanced Measurement (페이지뷰/스크롤/외부링크/파일다운로드/검색)

---

### 🐛 11. Bug Fixes

- 자동 슬라이드 멈춤 (모바일 touchend 누락) — 8초 안전장치
- DB 마이그레이션 후 Stimulus 미동작 — CSP nonce 수정
- coaching_type NOT NULL 위반 (앱 개발 예약 시 500 에러 가능) — 마이그레이션으로 NULL 허용
- Step 10 예약 버튼 미동작 — turbo_frame 제거
- 모바일 예약 버튼 — form novalidate 추가
- 격자 배경 애니메이션 + 버튼 비동작 → 통합 수정

---

### 🏢 12. 운영

- /health 헤lthcheck 엔드포인트 (DB 쿼리 없는 단순 200 응답)
- ApplicationController#set_variant 제거 (미사용 mobile 변형, 매 요청 파싱 낭비)
- admin/reservations N+1 수정 (`includes :time_slot, :review`)
- icon_hover_controller.js 데드코드 제거
- Review.submitted scope 정확화 (rating + content 둘 다 체크)

---

### 📋 13. 컴플라이언스 잡

- `PurgeOldReservationsJob`: PIPA 자동 삭제/익명화
  - 취소 후 90일 → 완전 삭제
  - 완료 후 1년 → PII 익명화 (통계 보존)

---

### 🇰🇷 14. 한국 상용 사이트 추가 보완 (2026-05-08)

#### 14.1 법적 표시 보강
- 푸터에 사업자등록 진위확인 링크 추가 (`bizCommPop.do?wrkr_no=405-02-46113`)
- 호스팅 서비스 제공자(Google Cloud) 처리방침에 명시
- 청소년 보호 정책 처리방침에 추가
- 광고성 정보 발송 정책 처리방침에 추가 ([광고] 표시, 야간 발송 제한)
- 약관/처리방침 변경 이력 섹션 추가

#### 14.2 추가 에러 페이지
- 422 (Unprocessable) 페이지
- 429 (Too Many Requests) 페이지
- 503 (Service Unavailable / Maintenance) 페이지

#### 14.3 시니어 친화 (선택 기능)
- 글자 크기 조절 버튼 (작게/보통/크게)
- localStorage로 사용자 선택 저장

#### 14.4 폼 동의 분리
- 광고성 정보 수신 동의 (선택, 별도 체크박스)
- 정보통신망법 §50 준수

---

## 🚧 미처리 / 사용자 결정 필요

### 🔴 사용자 직접 작업 필요

| # | 항목 | 사용자 작업 |
|---|------|-----------|
| U1 | **GitHub `GCP_SA_KEY` Secret 등록** | 자동 배포 활성화 시 필요 (현재는 수동 트리거) |
| U2 | **Branch protection 규칙** | GitHub Settings > Branches > main에서 설정 |
| U3 | **HetrixTools / UptimeRobot Pro 가입** | 외부 모니터링 (UptimeRobot 무료는 상업용 금지) |
| U4 | **Sentry 가입 + DSN 받기** | 에러 모니터링 |
| U5 | **네이버 서치어드바이저 등록** | 검색 등록 (한국 점유율 30%+) |
| U6 | **Google Search Console 등록** | 검색 등록 |
| U7 | **카카오 검색(Daum) 등록** | 검색 등록 |
| U8 | **카카오톡 채널 개설** | 시니어/소상공인 1차 소통 채널 |

### 🟡 사용자 결정/정보 필요

| # | 항목 | 결정/정보 |
|---|------|---------|
| D1 | **통신판매업 신고번호** | 신고 했는지? 했다면 번호 |
| D2 | **영업 시간 / 응답 시간** | 명시할 시간대 |
| D3 | **결제 시스템** | 토스페이먼츠/포트원 등 도입 여부 |
| D4 | **2FA (관리자 계정)** | 도입 여부 |
| D5 | **세션 만료 시간** | 자동 로그아웃 시간 (예: 8시간) |
| D6 | **관리자 비밀번호 8자 이상** | 새 비밀번호 (현재 6자 정책) |
| D7 | **소셜 채널 링크** | 인스타/유튜브/블로그 URL |
| D8 | **OG 이미지 디자인** | 카톡/페북 공유 시 미리보기 이미지 |
| D9 | **실제 수강생 후기 수집** | 현재 "각색" 후기 → 실제 후기로 교체 시점 |

### 🟢 미처리 (선택사항)

| # | 항목 | 설명 |
|---|------|------|
| O1 | **Sidekiq cron gem 추가** | PurgeOldReservationsJob 자동 실행 (현재는 수동) |
| O2 | **APM (New Relic/Datadog 무료)** | 응답 시간/쿼리 분석 |
| O3 | **Lighthouse CI** | 성능 회귀 자동 감지 |
| O4 | **Pre-commit hooks (overcommit/lefthook)** | 커밋 전 lint 자동 |
| O5 | **PWA 지원** | 모바일 홈 화면 추가 |
| O6 | **이미지 srcset 반응형** | 디바이스별 최적 크기 |
| O7 | **Cloud Secret Manager** | 환경변수 → Secret Manager로 보안 강화 |
| O8 | **다국어 지원** | 영어 등 추가 |
| O9 | **추천인 코드 시스템** | 마케팅 기능 |
| O10 | **실시간 채팅** | 카카오톡 외 |
| O11 | **이용약관/처리방침 변호사 검토** | 법적 안전성 강화 |
| O12 | **개인정보 처리책임자 명함/직책** | 법령 권장 |

---

## 🔑 자격 증명 위치

- **`CREDENTIALS.local.md`**: 신규 자격증명 (DB 비밀번호, SECRET_KEY_BASE 등). git 무시됨.
- **Cloud Run 환경변수**: DATABASE_PASSWORD, SECRET_KEY_BASE, ENCRYPTION_KEY (production 운영)
- **`.env`** (로컬): 개발 환경변수
- **GitHub Secrets**: (미설정) GCP_SA_KEY 추가 시 자동 배포 활성화

---

## 📦 신규 파일 목록

### 페이지
- `app/views/home/faq.html.erb` (FAQ + JSON-LD)
- `app/views/home/terms.html.erb` (이용약관)
- `app/views/home/refund_policy.html.erb` (환불 정책)
- `public/404.html` (커스텀 404)
- `public/500.html` (커스텀 500)
- `public/sitemap.xml` (사이트맵)
- `public/og-image.png` (OG 이미지)

### 인프라/설정
- `firebase.json` (Firebase Hosting 설정)
- `.firebaserc` (Firebase 프로젝트 연결)
- `.github/workflows/ci.yml` (테스트 자동화)
- `.github/workflows/deploy.yml` (수동 배포)
- `.github/dependabot.yml` (의존성 자동 PR)
- `artifact-cleanup-policy.json` (Artifact Registry 정책)
- `CREDENTIALS.local.md` (로컬 자격증명, git 무시됨)

### 모델/잡/마이그레이션
- `app/jobs/purge_old_reservations_job.rb` (PIPA 자동 삭제)
- `db/migrate/20260506031600_allow_null_coaching_type_on_reservations.rb`

### 테스트
- `test/test_helper.rb` (Rails 표준)
- `test/models/reservation_test.rb` (18개)
- `test/models/review_test.rb` (8개)
- `test/models/time_slot_test.rb` (10개)
- `test/controllers/reservations_controller_test.rb` (15개)
- `test/jobs/sms_notification_job_test.rb` (2개)
- `test/jobs/email_notification_job_test.rb` (2개)
- `test/mailers/reservation_mailer_test.rb` (4개)

### WebP 이미지
- `public/slide/senior_predominance/Senior1~11.webp`
- `public/slide/vip_curiculum/VIP_Curriculum1~12.webp`
- 기존 PNG 파일 모두 삭제됨

---

## 🔄 라우팅 변경 (config/routes.rb)

추가:
- `GET /health` (헬스체크)
- `GET /terms` (이용약관)
- `GET /refund_policy` (환불 정책)
- `GET /faq` (FAQ)

---

## 📝 git 커밋 이력 (요약)

| 커밋 | 내용 |
|------|------|
| infra: Cloud Load Balancer를 Firebase Hosting으로 대체 | LB 제거 + Firebase 도입 |
| feat: Supanova 디자인 개선 | 디자인 시스템 |
| fix: 패키지 카드 버튼 정렬 + 네비 링크 미작동 | UX 버그 |
| fix: CSP에 ga.jspm.io + cdn.jsdelivr.net 허용 | Stimulus 미동작 수정 |
| fix: CSP nonce 생성기를 SecureRandom으로 변경 | 근본 수정 |
| fix: 자동 전환 전체 비활성화 + 웹 개발 카드 설명문 하단 정렬 | UX |
| feat: Google Analytics 4 통합 | 분석 |
| security: cloudbuild.yaml에서 평문 비밀 제거 + 키 회전 | 보안 사고 대응 |
| chore: SEO + 보안 개선 (sitemap, robots.txt, Dependabot) | SEO/보안 |
| feat: UI/UX 개선 5종 (이미지 WebP, 접근성, 폼 안정성) | 종합 개선 |
| feat: 슬라이드 클릭 확대 + CSP 인라인 style/sourcemap 수정 | UX/보안 |
| test: 예약 프로세스 종합 테스트 + coaching_type NOT NULL 수정 | 테스트 |
| feat: 운영/품질/UX/SEO/접근성 종합 개선 (1차) | 종합 |
| feat: 테스트 확장 + CI/CD + 컴플라이언스 + 폼 접근성 (2차) | 종합 |
| feat: 상용 사이트 법적/UX 보완 (3차) | 컴플라이언스 |

---

## 🎯 향후 권장 우선순위

### Phase 1 — 외부 서비스 가입 (사용자 30분~1시간)
1. **Sentry 가입** + DSN 받아서 알려주면 즉시 통합 (5분)
2. **HetrixTools 가입** + 모니터 1개 추가 (10분, 직접 작업)
3. **네이버 서치어드바이저** 사이트 등록 + sitemap 제출 (10분)
4. **Google Search Console** 등록 + sitemap 제출 (10분)

### Phase 2 — 비즈니스 정보 채우기 (사용자 결정)
1. 영업시간 명시
2. 통신판매업 신고 번호 (해당 시)
3. 카카오톡 채널 개설 + URL 추가
4. 실제 수강생 후기 수집

### Phase 3 — 결제/유료 기능 (별도 프로젝트급)
1. 토스페이먼츠/포트원 통합
2. 영수증/계산서 발급
3. 자동 입금 확인

### Phase 4 — 운영 고도화
1. 2FA 관리자 인증
2. Sidekiq cron gem (PurgeJob 자동 실행)
3. Cloud Secret Manager 도입
4. 이용약관/처리방침 변호사 검토

---

## 📖 핵심 학습 사항 (회고)

### 잘 한 것
- 보안 이슈 (cloudbuild.yaml 평문 비밀) 즉시 발견 + 신속 회전
- 단계별 검증 (Rails 로드 → 테스트 → curl 검증 → 배포)
- 사용자 의도 재확인 (Cloud SQL 마이그레이션 시 보수적 권장)
- 각 변경 후 Cloud Run + Firebase Hosting 분리 배포

### 개선 여지
- 초기 분석 시 Network 비용 원인 추측 잘못 (실제는 LB 고정 비용)
- 일부 추천에서 트래픽 적은 사이트 특성을 늦게 반영
- 외부 서비스(UptimeRobot 무료 → 상업용 금지) 정책 변경 미리 확인 필요

### 의외의 발견
- Networking ₩26,796의 정체 = LB Forwarding Rule 고정비
- UptimeRobot 무료가 2024-10부터 비상업용 한정
- Render/Fly.io 무료 PostgreSQL 폐지 (2025-2026)
- Neon 인수 (Databricks $1B, 2025-05)

---

## 📞 비상 연락처 / 문서

- **사이트**: https://enterlab.cloud
- **GitHub**: https://github.com/lingger-lab/enterai
- **Cloud Run**: https://console.cloud.google.com/run?project=enterlabs-489809
- **Firebase Hosting**: https://console.firebase.google.com/project/enterlabs-489809/hosting
- **GA4**: https://analytics.google.com (속성: enterlabs-489809)
- **Cloud SQL**: enterlab (asia-northeast3)

---

작성: 2026-05-07
다음 검토 권장: 2026-08-07 (3개월 후)
