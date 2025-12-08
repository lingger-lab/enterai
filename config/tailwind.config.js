const path = require('path');

/** @type {import('tailwindcss').Config} */
module.exports = {
  // 개발 환경: 절대 경로 사용 및 모든 파일 포함
  content: [
    path.resolve(__dirname, "../app/views/**/*.{html,erb}"),
    path.resolve(__dirname, "../app/helpers/**/*.rb"),
    path.resolve(__dirname, "../app/javascript/**/*.js"),
    path.resolve(__dirname, "../app/assets/stylesheets/**/*.css"),
  ],
  // 개발 환경: 모든 Tailwind 유틸리티 클래스를 포함하도록 safelist 사용
  // 패턴이 작동하지 않으므로 직접 클래스 추가
  safelist: [
    // 배경색 - 직접 추가
    'bg-white', 'bg-indigo-50', 'bg-indigo-600', 'bg-gray-50', 'bg-gradient-to-br', 'bg-gradient-to-r',
    'from-indigo-50', 'from-indigo-600', 'via-white', 'to-purple-50', 'to-purple-600',
    // 텍스트 색상 - 직접 추가
    'text-indigo-600', 'text-indigo-700', 'text-indigo-100', 'text-gray-700', 'text-gray-900', 'text-gray-600', 'text-white',
    // 레이아웃 - 직접 추가
    'min-h-screen', 'max-w-7xl', 'max-w-3xl', 'max-w-4xl', 'mx-auto',
    'px-4', 'px-8', 'py-2', 'py-3', 'py-4', 'py-12', 'py-20', 'p-8',
    'w-full', 'w-5', 'w-6', 'w-8', 'h-5', 'h-6', 'h-16',
    // Flexbox - 직접 추가
    'flex', 'items-center', 'justify-center', 'justify-between', 'gap-4', 'space-y-3', 'space-y-6', 'space-x-8',
    // 텍스트 - 직접 추가
    'text-center', 'text-xl', 'text-2xl', 'text-lg', 'font-bold', 'font-semibold', 'mb-4', 'mb-6', 'mb-8', 'mr-2',
    // 테두리 및 그림자 - 직접 추가
    'border', 'border-t', 'border-2', 'border-gray-300', 'rounded-lg', 'rounded-xl', 'rounded', 'shadow-sm', 'shadow-lg', 'shadow-xl',
    // 상태 - 직접 추가
    'hover:bg-indigo-700', 'hover:bg-indigo-50', 'hover:bg-gray-100', 'hover:text-indigo-600', 'hover:text-indigo-700', 'hover:text-indigo-800', 'hover:shadow-xl', 'hover:scale-105',
    'focus:outline-none', 'focus:ring-2', 'focus:ring-indigo-500', 'focus:ring-white', 'focus:ring-offset-2', 'focus:ring-offset-indigo-600', 'focus:border-indigo-500',
    // 반응형 - 직접 추가
    'hidden', 'md:hidden', 'md:flex', 'sm:px-6', 'sm:px-8', 'lg:px-8',
    // 기타 - 직접 추가
    'sticky', 'top-0', 'z-50', 'transition-all', 'transition-colors', 'transition-shadow', 'transform', 'underline',
    // 추가 클래스들 (ERB 파일에서 사용되는 모든 클래스)
    'block', 'stroke-current', 'fill-none', 'stroke-2', 'stroke-linecap-round', 'stroke-linejoin-round',
    // 모든 배경색 클래스 패턴 (백업)
    { pattern: /^bg-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|white|black|transparent|current)/ },
    { pattern: /^bg-gradient-to-(t|tr|r|br|b|bl|l|tl)/ },
    { pattern: /^(from|via|to)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|white|black)-(50|100|200|300|400|500|600|700|800|900|950)/ },
    // 모든 텍스트 색상 클래스 패턴
    { pattern: /^text-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|white|black|current|xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl|8xl|9xl|left|center|right|justify)/ },
    // 모든 레이아웃 클래스 패턴
    { pattern: /^(min|max)-(w|h)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|auto|full|min|max|fit|screen|svw|lvw|dvw)/ },
    { pattern: /^(w|h|min-w|min-h|max-w|max-h)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|auto|full|min|max|fit|screen|svw|lvw|dvw)/ },
    { pattern: /^(p|px|py|pt|pr|pb|pl|m|mx|my|mt|mr|mb|ml)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|auto)/ },
    // Flexbox 및 Grid 패턴
    { pattern: /^(flex|grid|inline-flex|inline-grid|block|inline-block|inline|hidden|table|table-row|table-cell)/ },
    { pattern: /^(items|justify|content|self|place)-(start|end|center|between|around|evenly|stretch|baseline|auto)/ },
    { pattern: /^(gap|gap-x|gap-y)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)/ },
    { pattern: /^space-(x|y)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|reverse)/ },
    // 텍스트 스타일 패턴
    { pattern: /^font-(thin|extralight|light|normal|medium|semibold|bold|extrabold|black)/ },
    { pattern: /^text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl|8xl|9xl)/ },
    { pattern: /^text-(left|center|right|justify|start|end)/ },
    // 테두리 및 그림자 패턴
    { pattern: /^border(-(t|r|b|l|x|y))?(-(0|2|4|8))?/ },
    { pattern: /^border-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|white|black|current|transparent)-(50|100|200|300|400|500|600|700|800|900|950)/ },
    { pattern: /^rounded(-(none|sm|md|lg|xl|2xl|3xl|full))?(-(tl|tr|bl|br))?/ },
    { pattern: /^shadow(-(none|sm|md|lg|xl|2xl|inner))?/ },
    // 상태 클래스는 직접 추가된 클래스로 충분 (패턴 제거)
    // 반응형 클래스는 직접 추가된 클래스로 충분 (패턴 제거)
    // 기타 필수 클래스
    // 배경색
    'bg-white', 'bg-indigo-50', 'bg-indigo-600', 'bg-gray-50',
    'bg-gradient-to-br', 'bg-gradient-to-r',
    'from-indigo-50', 'from-indigo-600', 'via-white', 'to-purple-50', 'to-purple-600',
    // 텍스트 색상
    'text-indigo-600', 'text-indigo-700', 'text-indigo-100', 'text-gray-700', 'text-gray-900', 'text-gray-600', 'text-white',
    // 레이아웃
    'min-h-screen', 'max-w-7xl', 'max-w-3xl', 'max-w-4xl', 'mx-auto',
    'px-4', 'px-8', 'py-2', 'py-3', 'py-4', 'py-12', 'py-20', 'p-8',
    'w-full', 'w-5', 'w-6', 'w-8', 'h-5', 'h-6', 'h-16',
    // Flexbox
    'flex', 'items-center', 'justify-center', 'gap-4', 'space-y-3', 'space-y-6', 'space-x-8',
    // 텍스트
    'text-center', 'text-xl', 'text-2xl', 'text-lg', 'font-bold', 'font-semibold', 'mb-4', 'mb-6', 'mb-8', 'mr-2',
    // 테두리 및 그림자
    'border', 'border-t', 'border-2', 'border-gray-300', 'rounded-lg', 'rounded-xl', 'rounded', 'shadow-sm', 'shadow-lg', 'shadow-xl',
    // 상태
    'hover:bg-indigo-700', 'hover:bg-indigo-50', 'hover:bg-gray-100', 'hover:text-indigo-600', 'hover:text-indigo-700', 'hover:text-indigo-800', 'hover:shadow-xl', 'hover:scale-105',
    'focus:outline-none', 'focus:ring-2', 'focus:ring-indigo-500', 'focus:ring-white', 'focus:ring-offset-2', 'focus:ring-offset-indigo-600', 'focus:border-indigo-500',
    // 반응형
    'hidden', 'md:hidden', 'md:flex', 'sm:px-6', 'sm:px-8', 'lg:px-8',
    // 기타
    'sticky', 'top-0', 'z-50', 'transition-all', 'transition-colors', 'transition-shadow', 'transform', 'underline'
  ],
  theme: {
    extend: {
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
  // ✅ Propshaft 빌드 경로
  output: "app/assets/builds/application.css",
  // 개발 환경에서는 모든 클래스 포함 (성능 최적화는 프로덕션에서)
  // content가 제대로 작동하지 않을 때를 대비한 안전장치
  corePlugins: {
    preflight: true,
  },
  // 모든 유틸리티 클래스 포함 (개발 환경용)
  // 프로덕션에서는 content 기반으로 최적화 필요
  important: false,
}

