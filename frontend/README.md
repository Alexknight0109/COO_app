# ALMED OPS Control System - Frontend

Next.js frontend application for ALMED OPS Control System.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Run the development server:
```bash
npm run dev
```

The application will be available at `http://localhost:3000`

## Features

- **Dark/Light Theme** - Toggle between themes with CSS variables
- **Responsive Design** - Mobile-friendly layout
- **Dashboard** - Personal dashboard with stats and announcements
- **Task Management** - Drag-and-drop Kanban board
- **Messaging** - Real-time chat interface
- **Calendar** - View and manage events
- **Projects & Sites** - Manage projects and site locations
- **And more...** - See README.md in root for full feature list

## Pages

- `/dashboard` - Main dashboard
- `/tasks` - Task management with Kanban
- `/messages` - Messaging system
- `/calendar` - Calendar view
- `/projects` - Projects and sites
- `/site-logs` - Site log management
- `/complaints` - Service tickets
- `/factory` - Factory production
- `/inventory` - Inventory management
- `/accounts` - Accounts and payments
- `/hr` - HR and employees
- `/reports` - Reports module
- `/settings` - Settings

## Theme System

The application uses CSS variables for theming. Themes are defined in `app/globals.css`:
- Dark theme (default): Deep navy background (#0D0F21)
- Light theme: Light background (#F8F9FE)

Theme preference is saved in localStorage.
