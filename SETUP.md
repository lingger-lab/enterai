# EnterLab 설치 가이드

## 프로젝트 개요

EnterLab은 AI 1:1 코칭 예약 및 자동 알림 웹서비스입니다.  
AI에 대한 이해가 부족한 초보자도, 개인 맞춤형 코칭을 통해 AI 수익화 기술을 빠르게 익히고 실행할 수 있도록 돕는 **국내망 기반 플랫폼**입니다.

### 🇰🇷 국내망 기술 조합

이 프로젝트는 **100% 국내망 기반**으로 구성되어 있으며, 해외 API(Twilio 등)를 사용하지 않습니다:

| 구성요소 | 기술 / 서비스          | 설명                   |
| ---- | ----------------- | -------------------- |
| 전화   | KT 050 / 콜패스      | 가상번호 착신, 번호 노출 방지    |
| 문자   | Naver Cloud SENS  | API 기반 예약확인 / 알림 SMS |
| 이메일  | SendGrid          | 예약완료 메일 자동 발송        |
| 웹    | Rails 8 + Hotwire | 예약 폼 / DB / 자동화 중심   |
| 배포   | Vercel + Render   | 프론트·백 분리형 배포         |

## 주요 기능

1. **브랜딩 랜딩 페이지** - 서비스 소개 및 예약 유도
2. **1:1 코칭 예약 폼** - 이름, 연락처, 이메일, 날짜/시간, 코칭형태, 선택과목, 요청사항, 개인정보동의
3. **자동 안내 시스템** - 예약 제출 시 자동으로 이메일 및 SMS 발송 (국내망 기반)
   - 사용자: 예약완료 메일 (SendGrid) 및 문자 (Naver Cloud SENS)
   - 관리자: 신규예약 알림 메일 (SendGrid)
4. **비동기 처리** - ActionMailer와 ActiveJob을 사용한 비동기 발송
5. **현대적인 UI** - Tailwind CSS 기반, Hotwire 폼 제출 애니메이션, jeongdami.vercel.app와 유사한 스타일
6. **개인정보 보호** - 개인정보 보호법 준수, DB에 고객정보 암호화 저장

## 사전 요구사항

### 1. Ruby 설치 (Windows)

Windows에서 Ruby를 설치하는 방법:

1. **RubyInstaller 다운로드**
   - https://rubyinstaller.org/downloads/ 에서 Ruby 3.3.0 다운로드
   - **"Ruby+Devkit 3.3.0 (x64)"** 버전 선택 (64비트 시스템용, 개발 도구 포함)

2. **설치**
   - 다운로드한 설치 파일 실행
   - "Add Ruby executables to your PATH" 옵션 체크
   - 설치 완료 후 MSYS2 개발 도구 설치 창이 자동으로 실행됨
   
3. **MSYS2 개발 도구 설치**
   - 설치 창에서 다음 옵션 선택:
     - **1 - MSYS2 base installation** (필수)
     - **2 - MSYS2 system update** (선택사항, 권장)
     - **3 - MSYS2 and MINGW development toolchain** (필수)
   - **권장**: `1,2,3` 입력 후 Enter (모두 선택)
   - **최소**: `1,3` 입력 후 Enter (필수만 선택)
   - 설치가 완료될 때까지 기다림 (시간이 다소 걸릴 수 있음)

3. **설치 확인**
   ```powershell
   ruby --version
   # Ruby 3.3.0이 출력되어야 함
   ```

### 2. Rails 설치

```powershell
gem install rails -v 8.0.0
rails --version
# Rails 8.0.0이 출력되어야 함
```

### 3. PostgreSQL 설치

1. **PostgreSQL 다운로드**
   - https://www.postgresql.org/download/windows/ 에서 다운로드
   - 설치 시 비밀번호 설정 (나중에 .env 파일에 사용)

2. **설치 확인**
   ```powershell
   psql --version
   ```

### 4. Node.js 설치

1. **Node.js 다운로드**
   - https://nodejs.org/ 에서 LTS 버전 다운로드
   - 설치 시 "Add to PATH" 옵션 체크

2. **설치 확인**
   ```powershell
   node --version
   npm --version
   ```

## 프로젝트 설정

### 1. 의존성 설치

```powershell
# Gem 설치
bundle install

# Node.js 패키지 설치
npm install
```

### 2. 환경 변수 설정

`.env` 파일을 프로젝트 루트에 생성하고 다음 내용을 추가:

```env
# 데이터베이스 설정
DATABASE_USER=postgres
DATABASE_PASSWORD=설치_시_설정한_비밀번호
DATABASE_HOST=localhost

# SendGrid 설정 (https://sendgrid.com 에서 API 키 발급)
SENDGRID_API_KEY=your_sendgrid_api_key
SENDGRID_FROM_EMAIL=noreply@enterlab.com
SENDGRID_DOMAIN=enterlab.com

# Naver Cloud SENS 설정 (https://www.ncloud.com 에서 서비스 신청)
SENS_ACCESS_KEY=your_sens_access_key
SENS_SECRET_KEY=your_sens_secret_key
SENS_SERVICE_ID=your_sens_service_id
SENS_SENDER_NUMBER=01012345678

# 관리자 설정
ADMIN_EMAIL=admin@enterlab.com
CONTACT_PHONE=050-0000-0000

# 개인정보 암호화 키 (32자리 문자열, 보안을 위해 반드시 변경하세요)
ENCRYPTION_KEY=your_32_character_encryption_key_here

# 호스트 설정 (프로덕션)
HOST=enterlab.com
```

### 3. 데이터베이스 생성 및 마이그레이션

```powershell
# 데이터베이스 생성
rails db:create

# 마이그레이션 실행
rails db:migrate

# 마이그레이션 확인
rails db:migrate:status
```

**참고**: 마이그레이션은 `reservations` 테이블을 생성하며, 다음 필드를 포함합니다:
- 이름, 연락처, 이메일 (암호화 저장)
- 예약 날짜/시간
- 코칭 형태
- 선택 과목 (배열)
- 요청사항
- 개인정보 동의
- 암호화 필드: name_encrypted, phone_encrypted, email_encrypted (개인정보 보호법 준수)

### 4. Tailwind CSS 빌드

```powershell
npm run build:css
```

## 서버 실행

### 개발 서버 시작

**Windows PowerShell에서 실행:**

```powershell
# Ruby 경로를 현재 세션에 추가 (한 번만 실행)
$env:Path += ";C:\Ruby33-x64\bin"

# 서버 실행
bundle exec rails s
```

또는 Ruby 전체 경로 사용:

```powershell
C:\Ruby33-x64\bin\ruby.exe bin/rails s
```

또는 간단하게 (PATH에 Ruby가 있는 경우):

```powershell
bundle exec rails server
```

**참고**: 
- `.env` 파일에 `DATABASE_PASSWORD`가 설정되어 있으면 자동으로 사용됩니다
- 서버가 시작되면 `http://127.0.0.1:3000` 또는 `http://localhost:3000`에서 접속 가능합니다
- 서버를 중지하려면 `Ctrl + C`를 누르세요

브라우저에서 `http://localhost:3000` 접속

**참고**: 
- 루트 경로(`/`)는 랜딩 페이지를 표시합니다
- 예약 폼은 `/reservations/new` 경로에서 접근 가능합니다
- 랜딩 페이지의 "코칭 예약하기" 버튼을 클릭하면 예약 폼으로 이동합니다

### Sidekiq 실행 (비동기 작업 처리)

**중요**: 이메일 및 SMS 발송은 비동기로 처리되므로 Sidekiq이 실행 중이어야 합니다.

새 터미널 창에서:

```powershell
bundle exec sidekiq
```

## API 키 발급 가이드

### SendGrid API 키 발급

1. https://sendgrid.com 에서 계정 생성
2. Settings > API Keys 메뉴로 이동
3. "Create API Key" 클릭
4. API Key 이름 입력 및 권한 선택 (Full Access 권장)
5. 생성된 API Key를 `.env` 파일의 `SENDGRID_API_KEY`에 입력

### Naver Cloud SENS 계정 설정

**Naver Cloud SENS**는 국내망 기반 SMS 발송 서비스로, 한국 통신사 기반으로 문자 발송 지연이 거의 없습니다.  
**💡 중요: Twilio, 해외 API는 사용하지 않습니다. 100% 국내망 기반으로 운영됩니다.**

#### 1. 네이버 클라우드 플랫폼 가입

1. https://www.ncloud.com 에서 계정 생성
2. 본인인증 및 결제 수단 등록 (무료 크레딧 제공)
3. 콘솔 로그인

#### 2. SENS 서비스 신청

1. 콘솔에서 **"Services"** > **"AI·NAVER API"** > **"SENS"** 선택
2. **"서비스 신청"** 클릭
3. 서비스 이름 입력 및 약관 동의
4. 서비스 신청 완료 대기 (보통 즉시 승인)

#### 3. API 인증키 발급

1. 콘솔 상단 **"Management"** > **"API 인증키 관리"** 메뉴로 이동
2. **"API 인증키 생성"** 클릭
3. 인증키 이름 입력 (예: "EnterLab SMS")
4. **Access Key ID**와 **Secret Key** 확인 및 안전하게 저장
   - ⚠️ Secret Key는 한 번만 표시되므로 반드시 저장하세요

#### 4. SMS 서비스 ID 확인

1. SENS 콘솔에서 **"SMS"** 메뉴 선택
2. **"서비스 관리"**에서 서비스 ID 확인
   - 형식: `ncp:sms:kr:123456789012:service_name`
   - 또는 숫자만 있는 경우: `123456789012`

#### 5. 발신번호 등록 및 인증

1. **"발신번호 관리"** 메뉴로 이동
2. **"발신번호 등록"** 클릭
3. 발신번호 입력 (예: 010-1234-5678)
4. 인증 서류 업로드:
   - **개인**: 통신사 이용증명서 또는 신분증
   - **사업자**: 사업자등록증
5. 인증 승인 대기 (1-2일 소요)
6. 인증 완료 후 발신번호 확인

#### 6. 환경 변수 설정

`.env` 파일에 다음 정보 입력:

```env
# Naver Cloud SENS 설정
SENS_ACCESS_KEY=your_access_key_id          # API 인증키 관리에서 발급받은 Access Key ID
SENS_SECRET_KEY=your_secret_key             # API 인증키 관리에서 발급받은 Secret Key
SENS_SERVICE_ID=your_service_id             # SMS 서비스 관리에서 확인한 서비스 ID
SENS_SENDER_NUMBER=01012345678              # 인증 완료된 발신번호 (하이픈 제외)
```

#### 참고사항

- ✅ **국내망 기반**: 한국 통신사 기반으로 문자 발송 지연이 거의 없음
- ✅ **무료 크레딧**: 신규 가입 시 무료 크레딧 제공 (테스트 가능)
- ✅ **발신번호 인증**: 1-2일 소요, 인증 완료 후 사용 가능
- ✅ **월 무료 제공**: 프로모션에 따라 월 50건 무료 제공
- ⚠️ **국내 전화번호만**: 국가코드 82 (한국) 전화번호만 발송 가능
- ⚠️ **Secret Key 보안**: Secret Key는 한 번만 표시되므로 반드시 안전하게 보관

#### 테스트 방법

1. Naver Cloud SENS 콘솔에서 **"SMS"** > **"발송 내역"** 메뉴 확인
2. 예약 제출 후 발송 내역에서 문자 발송 상태 확인
3. 사용자 휴대폰에서 문자 수신 확인

## 문제 해결

### PostgreSQL 연결 오류

```powershell
# PostgreSQL 서비스 시작 확인
# Windows 서비스 관리자에서 "postgresql-x64-XX" 서비스가 실행 중인지 확인
```

### Gem 설치 오류

```powershell
# 개발 도구 재설치
ridk install
```

### Tailwind CSS 빌드 오류

```powershell
# Node.js 버전 확인 (18.0.0 이상 필요)
node --version

# 패키지 재설치
rm -rf node_modules
npm install

# Tailwind CSS 재빌드
npm run build:css
```

### PATH 설정 문제

Ruby와 PostgreSQL이 설치되었지만 명령어를 찾을 수 없는 경우:

```powershell
# 현재 세션에만 PATH 추가 (임시)
$env:Path += ";C:\Ruby33-x64\bin"
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"

# 영구적으로 추가하려면 시스템 환경 변수에 추가
# 제어판 > 시스템 > 고급 시스템 설정 > 환경 변수
```

### 예약 폼이 표시되지 않는 경우

```powershell
# 라우팅 확인
rails routes

# 서버 재시작
rails server
```

## 프로젝트 구조

```
/app
  /controllers
    - home_controller.rb          # 랜딩 페이지
    - reservations_controller.rb  # 예약 폼 및 처리
  /models
    - reservation.rb             # 예약 모델 (자동 알림 발송 포함)
  /views
    /home
      - index.html.erb             # 랜딩 페이지
    /reservations
      - new.html.erb               # 예약 폼
      - show.html.erb              # 예약 완료 페이지
      - create.turbo_stream.erb    # Hotwire 애니메이션
    /reservation_mailer
      - confirmation.html.erb      # 사용자 예약 확인 이메일
      - admin_notification.html.erb # 관리자 알림 이메일
  /mailers
    - reservation_mailer.rb       # 이메일 발송 로직
  /jobs
    - sms_notification_job.rb     # SMS 발송 Job (비동기, Naver Cloud SENS 사용)
  /services
    - sens_sms_service.rb          # Naver Cloud SENS API 연동 서비스
```

## 주요 기능 설명

### 1. 랜딩 페이지 (`/`)
- 서비스 소개 및 주요 기능 안내
- 신뢰 요소 및 프로세스 설명
- "코칭 예약하기" 버튼으로 예약 폼 이동
- jeongdami.vercel.app와 유사한 깔끔한 UI 디자인

### 2. 예약 폼 (`/reservations/new`)
- **필수 필드**: 이름, 연락처, 이메일, 예약 날짜/시간, 코칭 형태, 개인정보 동의
- **선택 필드**: 선택 과목 (복수 선택 가능), 요청사항
- Tailwind CSS 기반 반응형 디자인
- Hotwire (Turbo) 기반 폼 제출 애니메이션

### 3. 자동 알림 시스템
- **예약 생성 시 자동 발송**:
  - 사용자 이메일: 예약 확인 메일 (SendGrid)
  - 사용자 SMS: 예약 확인 문자 (Naver Cloud SENS)
  - 관리자 이메일: 신규 예약 알림 메일 (SendGrid)
- **비동기 처리**: ActionMailer `deliver_later` 및 ActiveJob 사용
- Sidekiq을 통한 백그라운드 작업 처리

### 4. 예약 완료 페이지 (`/reservations/:id`)
- 예약 정보 요약 표시
- 안내 메시지 및 다음 단계 안내

## 사용자 흐름

1. 접속 → 랜딩 페이지 표시
2. "코칭 예약하기" 버튼 클릭 → 예약 폼으로 이동
3. 신청서 작성 (이름, 연락처, 이메일, 날짜/시간, 코칭형태, 선택과목, 요청사항, 개인정보동의)
4. 개인정보 동의 및 제출
5. DB 저장 → 이메일 및 문자 자동발송 (비동기)
6. 완료 안내 페이지 표시

## 다음 단계

### 개발 환경 테스트

1. **랜딩 페이지 확인**
   ```powershell
   # 서버 실행 후 브라우저에서 확인
   http://localhost:3000
   ```

2. **예약 폼 테스트**
   - 랜딩 페이지에서 "코칭 예약하기" 클릭
   - 모든 필드 입력 후 제출
   - 예약 완료 페이지 확인

3. **이메일 발송 테스트** (SendGrid 설정 확인)
   - 예약 제출 후 사용자 이메일 확인
   - 관리자 이메일 확인 (ADMIN_EMAIL 환경 변수 설정 필요)

4. **SMS 발송 테스트** (Naver Cloud SENS 설정 확인)
   - 예약 제출 후 사용자 휴대폰 문자 확인
   - Sidekiq이 실행 중이어야 함
   - Naver Cloud SENS 콘솔에서 발송 내역 확인 가능

5. **비동기 작업 확인**
   ```powershell
   # Sidekiq 대시보드에서 작업 상태 확인
   # 또는 로그에서 확인
   ```

### 프로덕션 배포 준비

1. 환경 변수 설정 (프로덕션)
2. 데이터베이스 마이그레이션
3. Tailwind CSS 빌드
4. SendGrid 및 Naver Cloud SENS 프로덕션 계정 설정
5. 배포 플랫폼 설정 (Vercel + Render)

