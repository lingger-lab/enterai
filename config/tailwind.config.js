/** @type {import('tailwindcss').Config} */
const path = require('path');

module.exports = {
  // 절대 경로 사용으로 빌드 환경에서도 안정적으로 작동
  content: [
    path.join(__dirname, '../app/views/**/*.{html,erb,html.erb}'),
    path.join(__dirname, '../app/helpers/**/*.rb'),
    path.join(__dirname, '../app/javascript/**/*.js'),
    path.join(__dirname, '../app/views/**/*.turbo_stream.erb'),
    path.join(__dirname, '../app/views/layouts/**/*.erb'),
  ],

  // Safelist: 동적으로 생성되거나 content 스캔이 안 되는 클래스만 추가
  // ERB 파일의 클래스는 content 경로로 자동 감지되므로 여기 불필요
  safelist: [
    // 커스텀 애니메이션 클래스 (CSS에서 @keyframes로 정의)
    'animate-fade-in',
  ],

  theme: {
    extend: {
      // 커스텀 색상 (필요시 확장)
      colors: {
        primary: {
          50: '#eef2ff',
          100: '#e0e7ff',
          200: '#c7d2fe',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#312e81',
        },
      },
    },
  },

  plugins: [],
}
