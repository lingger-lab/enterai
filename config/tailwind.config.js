/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.{html,erb}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/components/**/*.{rb,html,erb}",
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
