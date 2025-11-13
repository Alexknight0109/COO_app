'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  HomeIcon,
  ChatBubbleLeftRightIcon,
  ClipboardDocumentListIcon,
  CalendarIcon,
  FolderIcon,
  DocumentTextIcon,
  WrenchScrewdriverIcon,
  CubeIcon,
  ShoppingCartIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  ChartBarIcon,
  Cog6ToothIcon,
} from '@heroicons/react/24/outline'

const menuItems = [
  { name: 'Dashboard', icon: HomeIcon, path: '/dashboard' },
  { name: 'Messages', icon: ChatBubbleLeftRightIcon, path: '/messages' },
  { name: 'Tasks', icon: ClipboardDocumentListIcon, path: '/tasks' },
  { name: 'Calendar', icon: CalendarIcon, path: '/calendar' },
  { name: 'Projects & Sites', icon: FolderIcon, path: '/projects' },
  { name: 'Site Logs', icon: DocumentTextIcon, path: '/site-logs' },
  { name: 'Complaints', icon: WrenchScrewdriverIcon, path: '/complaints' },
  { name: 'Factory', icon: CubeIcon, path: '/factory' },
  { name: 'Inventory', icon: ShoppingCartIcon, path: '/inventory' },
  { name: 'Accounts', icon: CurrencyDollarIcon, path: '/accounts' },
  { name: 'HR / Employees', icon: UserGroupIcon, path: '/hr' },
  { name: 'Reports', icon: ChartBarIcon, path: '/reports' },
  { name: 'Settings', icon: Cog6ToothIcon, path: '/settings' },
]

export function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="sidebar w-64 min-h-screen fixed left-0 top-0 p-4 overflow-y-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold gradient-purple-blue bg-clip-text text-transparent">
          ALMED OPS
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Control System
        </p>
      </div>

      <nav className="space-y-1">
        {menuItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.path || pathname?.startsWith(item.path + '/')

          return (
            <Link
              key={item.path}
              href={item.path}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 ${
                isActive
                  ? 'bg-gradient-purple-blue text-white shadow-glow'
                  : 'text-[var(--text-secondary)] hover:bg-[var(--hover-bg)] hover:text-[var(--text-primary)]'
              }`}
            >
              <Icon className="w-5 h-5" />
              <span className="font-medium">{item.name}</span>
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
