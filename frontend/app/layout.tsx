import type { Metadata } from 'next'
import './globals.css'
import { ThemeProvider } from '@/components/theme/ThemeProvider'
import { Toaster } from 'react-hot-toast'

export const metadata: Metadata = {
  title: 'ALMED OPS CONTROL SYSTEM',
  description: 'Universal internal operating system for all ALMED employees',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider>
          {children}
          <Toaster
            position="top-right"
            toastOptions={{
              style: {
                background: 'var(--bg-card)',
                color: 'var(--text-primary)',
                border: '1px solid var(--border-color)',
              },
            }}
          />
        </ThemeProvider>
      </body>
    </html>
  )
}
