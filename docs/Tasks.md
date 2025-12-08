# [Enter.ai] AI 코딩 착수용 프롬프트 (Tasks)

너는 Ruby on Rails 8.0 (Hotwire 포함)의 수석 개발자야.
첨부한 [PRD]와 [TRD] 문서를 기반으로, 100% 국내망 환경에서 작동하도록 구현해.


아래 사양을 반드시 준수해야 해.
1️⃣ 예약 폼 구현 (이름, 연락처, 이메일, 날짜/시간, 코칭형태, 선택과목, 요청사항, 개인정보동의)
2️⃣ 제출 시 DB에 저장 후 이메일 및 문자 자동 발송
- 이메일: SendGrid API 사용
- 문자: Naver Cloud SENS API 사용
3️⃣ 전화 문의는 KT 050 가상번호로 연결되어 내 실제 번호를 숨김
4️⃣ ActionMailer + REST API 방식으로 비동기 처리
5️⃣ Tailwind 기반 UI와 Hotwire 폼 애니메이션 적용
6️⃣ jeongdami.vercel.app와 유사한 레이아웃 및 신뢰감 있는 디자인 구현
7️⃣ 개인정보 보호법을 준수해 DB에 고객정보를 암호화 저장


💡 중요: Twilio, 해외 API는 절대 사용하지 않는다.
# [Enter.ai] AI 코딩 착수용 프롬프트 (Tasks)

너는 Ruby on Rails 8.0 (Hotwire 포함)의 수석 개발자야.  
첨부한 [PRD]와 [TRD] 문서를 기반으로 다음 규칙을 따라 구현해.

1️⃣ 예약 폼 (이름, 연락처, 이메일, 날짜/시간, 코칭형태, 선택과목, 요청사항, 개인정보동의)  
2️⃣ 제출 시 DB에 저장 후 이메일/문자 자동발송  
   - 사용자: 예약완료 메일 및 문자  
   - 관리자: 신규예약 알림 메일  
3️⃣ SendGrid API, Twilio Ruby SDK 사용  
4️⃣ ActionMailer, ActiveJob 비동기 발송  
5️⃣ Tailwind 기반 UI, Hotwire 폼 제출 애니메이션 적용  
6️⃣ jeongdami.vercel.app와 유사한 UI 구성  
