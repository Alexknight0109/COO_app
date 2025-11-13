/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Dark theme (Primary)
        dark: {
          bg: '#0D0F21',
          card: '#13152B',
          sidebar: '#111324',
          text: '#FFFFFF',
          textSecondary: '#A0AEC0',
          border: '#1A1D35',
          hover: '#1A1D35',
        },
        // Light theme (Secondary)
        light: {
          bg: '#F8F9FE',
          card: '#FFFFFF',
          sidebar: '#FFFFFF',
          text: '#1A202C',
          textSecondary: '#4A5568',
          border: '#E2E8F0',
          hover: '#F7FAFC',
        },
        // Accent colors (gradients)
        accent: {
          purple: '#8B5CF6',
          blue: '#3B82F6',
        },
      },
      backgroundImage: {
        'gradient-purple-blue': 'linear-gradient(135deg, #8B5CF6 0%, #3B82F6 100%)',
      },
      borderRadius: {
        'card': '12px',
        'card-lg': '16px',
      },
      boxShadow: {
        'glow': '0 0 20px rgba(139, 92, 246, 0.3)',
        'glow-hover': '0 0 30px rgba(139, 92, 246, 0.5)',
        'card-light': '0 2px 8px rgba(0, 0, 0, 0.05)',
      },
    },
  },
  plugins: [],
}
