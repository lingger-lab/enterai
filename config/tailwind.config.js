const path = require('path');

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    path.join(__dirname, '../app/views/**/*.html.erb'),
    path.join(__dirname, '../app/helpers/**/*.rb'),
    path.join(__dirname, '../app/javascript/**/*.js'),
    path.join(__dirname, '../app/assets/stylesheets/**/*.css'),
  ],
  safelist: [
    // 명시적으로 사용 중인 모든 클래스
    // 배경색
    'bg-white', 'bg-indigo-50', 'bg-indigo-100', 'bg-indigo-600', 'bg-gray-50', 'bg-gray-900',
    'bg-gradient-to-br', 'bg-gradient-to-r',
    'from-indigo-50', 'from-indigo-600', 'via-white', 'to-purple-50', 'to-purple-600',
    // 텍스트 색상
    'text-white', 'text-indigo-50', 'text-indigo-100', 'text-indigo-600', 'text-indigo-700',
    'text-gray-300', 'text-gray-400', 'text-gray-500', 'text-gray-600', 'text-gray-700', 'text-gray-900',
    // 레이아웃
    'min-h-screen', 'max-w-2xl', 'max-w-3xl', 'max-w-4xl', 'max-w-7xl', 'mx-auto',
    'px-4', 'px-6', 'px-8', 'py-2', 'py-3', 'py-4', 'py-12', 'py-20', 'p-6', 'p-8',
    'w-full', 'w-5', 'w-6', 'w-8', 'w-12', 'w-16', 'h-5', 'h-6', 'h-8', 'h-12', 'h-16',
    'sm:px-6', 'sm:px-8', 'sm:flex-row', 'lg:px-8', 'lg:grid-cols-4',
    // Flexbox & Grid
    'flex', 'inline-block', 'block', 'grid', 'flex-col',
    'items-start', 'items-center', 'justify-center', 'justify-between',
    'gap-4', 'gap-8', 'space-x-8', 'space-y-2', 'space-y-3', 'space-y-6',
    'grid-cols-1', 'md:grid-cols-2', 'md:grid-cols-3',
    // 텍스트 스타일
    'text-base', 'text-lg', 'text-xl', 'text-2xl', 'text-3xl', 'text-4xl', 'text-5xl',
    'md:text-lg', 'md:text-xl', 'md:text-2xl', 'md:text-4xl', 'md:text-5xl', 'md:text-6xl',
    'font-medium', 'font-semibold', 'font-bold', 'text-center', 'text-left',
    // Margin & Padding
    'mb-2', 'mb-4', 'mb-6', 'mb-8', 'mb-16', 'mr-2', 'mt-1', 'mt-8', 'pt-4', 'pt-8',
    // 테두리 & 그림자
    'border', 'border-t', 'border-2', 'border-b-2',
    'border-gray-300', 'border-gray-800', 'border-blue-200', 'border-indigo-600',
    'rounded', 'rounded-lg', 'rounded-xl', 'rounded-full',
    'shadow-sm', 'shadow-lg', 'shadow-xl',
    // Position
    'sticky', 'top-0', 'z-50',
    // Display & Visibility
    'hidden', 'md:hidden', 'md:flex',
    // Transitions & Transforms
    'transition-all', 'transition-colors', 'transition-shadow', 'transform',
    // Hover states
    'hover:bg-indigo-50', 'hover:bg-indigo-700', 'hover:bg-gray-50', 'hover:bg-gray-100',
    'hover:text-white', 'hover:text-indigo-600', 'hover:text-indigo-700', 'hover:text-indigo-800',
    'hover:shadow-xl', 'hover:scale-105', 'hover:scale-[1.02]',
    // Focus states
    'focus:outline-none', 'focus:ring-2', 'focus:ring-indigo-500', 'focus:ring-white',
    'focus:ring-offset-2', 'focus:ring-offset-indigo-600', 'focus:border-indigo-500',
    // Active states
    'active:scale-[0.98]',
    // 기타
    'underline', 'cursor-pointer', 'animate-spin', 'animate-fade-in',
    // 추가 유틸리티
    'bg-blue-50', 'bg-green-100',
    'text-blue-800', 'text-green-600', 'text-red-600',
    {
      pattern: /^(bg|text|border)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900|950)$/,
    },
    {
      pattern: /^(p|px|py|pt|pr|pb|pl|m|mx|my|mt|mr|mb|ml|gap|space-x|space-y)-(0|1|2|3|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)$/,
    },
    {
      pattern: /^(w|h|min-w|min-h|max-w|max-h)-(0|1|2|3|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|auto|full|screen)$/,
    },
    {
      pattern: /^text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl|8xl|9xl)$/,
    },
    {
      pattern: /^(md|lg|xl|2xl):(flex|grid|hidden|block|inline|text|bg|border|p|m|w|h)/,
    },
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
}
