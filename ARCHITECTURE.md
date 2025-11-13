# ALMED OPS Control System - Architecture

## System Overview

The ALMED OPS Control System is a full-stack internal operating system built with:
- **Frontend**: Next.js 14 (React) with TypeScript
- **Backend**: NestJS with TypeScript
- **Database**: PostgreSQL with TypeORM
- **Real-time**: WebSockets (Socket.IO)
- **Authentication**: JWT (JSON Web Tokens)

## Project Structure

```
COO_app/
├── frontend/                    # Next.js frontend application
│   ├── app/                    # Next.js App Router
│   │   ├── dashboard/         # Dashboard page
│   │   ├── tasks/             # Task management
│   │   ├── messages/          # Messaging system
│   │   ├── calendar/          # Calendar
│   │   ├── projects/          # Projects & Sites
│   │   └── ...                # Other pages
│   ├── components/            # React components
│   │   ├── layout/           # Layout components
│   │   ├── Sidebar.tsx
│   │   └── Header.tsx
│   │   ├── theme/            # Theme system
│   │   │   ├── ThemeProvider.tsx
│   │   │   └── ThemeToggle.tsx
│   │   └── ui/               # UI components
│   │       └── Card.tsx
│   ├── globals.css           # Global styles with CSS variables
│   └── package.json
│
├── backend/                    # NestJS backend application
│   ├── src/
│   │   ├── entities/         # TypeORM entities (database models)
│   │   │   ├── user.entity.ts
│   │   │   ├── task.entity.ts
│   │   │   ├── message.entity.ts
│   │   │   └── ...          # All other entities
│   │   ├── modules/          # Feature modules
│   │   │   ├── auth/        # Authentication
│   │   │   ├── tasks/       # Task management
│   │   │   ├── messages/    # Messaging
│   │   │   └── ...          # All other modules
│   │   ├── config/          # Configuration
│   │   │   └── data-source.ts
│   │   ├── app.module.ts    # Root module
│   │   └── main.ts          # Application entry point
│   └── package.json
│
└── README.md                  # Main documentation
```

## Database Schema

### Core Entities

1. **User** - All employees in the system
   - Roles: COO, Directors, Managers, Factory, Site, Office, Accounts, etc.
   - Relationships: Tasks, Messages, Notifications, Calendar Events

2. **Task** - Task management
   - Status flow: NOT_STARTED → WORKING → BLOCKED → REVIEWING → COMPLETED
   - Can be linked to: Project, Site, Complaint, Inventory
   - Supports: Comments, Files, Time Logs

3. **Message** - Internal messaging
   - Types: DM, GROUP, BROADCAST
   - Supports: File attachments, Read receipts

4. **Project** - Projects and PO information
   - Contains Sites
   - Has team members
   - Linked to Tasks

5. **Site** - Site locations
   - Belongs to Project
   - Has Site Logs
   - Has Installation Stages
   - Has team members

6. **Complaint** - Service tickets
   - Status tracking
   - Engineer assignment
   - Customer signature upload

7. **FactoryProduction** - AHU serial tracking
   - Production stages
   - QC tracking
   - Dispatch status

8. **InventoryItem** - Stock management
   - Stock levels
   - Low stock alerts
   - Transactions

9. **Account** - Financial tracking
   - PO values
   - Payment stages
   - Outstanding balances

10. **CalendarEvent** - Calendar entries
    - Linked to Tasks
    - Meeting scheduling

11. **Notification** - Real-time notifications
    - Various types
    - Read/unread status

12. **Report** - Reports module
    - Daily reports
    - Factory logs
    - Sales reports

## API Structure

All APIs are prefixed with `/api` and use JWT authentication (except auth endpoints).

### Authentication (`/api/auth`)
- `POST /register` - Register new user
- `POST /login` - Login (returns JWT)
- `GET /profile` - Get current user profile

### Tasks (`/api/tasks`)
- `GET /` - Get all tasks (filtered by user if query param)
- `GET /:id` - Get task by ID
- `POST /` - Create task
- `PATCH /:id` - Update task
- `DELETE /:id` - Delete task
- `PATCH /:id/status` - Update task status

### Messages (`/api/messages`)
- `GET /` - Get all messages
- `GET /conversation/:userId` - Get conversation with user
- `POST /` - Send message
- `POST /:id/read` - Mark as read

### Other Modules
Similar REST patterns for:
- Notifications
- Calendar
- Projects
- Sites
- Complaints
- Factory
- Inventory
- Accounts
- HR
- Reports

## Theme System

### CSS Variables

The theme system uses CSS variables defined in `frontend/app/globals.css`:

**Dark Theme (Default):**
- `--bg-primary: #0D0F21`
- `--bg-card: #13152B`
- `--bg-sidebar: #111324`
- `--text-primary: #FFFFFF`
- `--text-secondary: #A0AEC0`

**Light Theme:**
- `--bg-primary: #F8F9FE`
- `--bg-card: #FFFFFF`
- `--bg-sidebar: #FFFFFF`
- `--text-primary: #1A202C`
- `--text-secondary: #4A5568`

### Theme Toggle

Theme preference is saved in localStorage and applied via `data-theme` attribute on the `<html>` element.

## Authentication Flow

1. User registers/logs in via `/api/auth/login`
2. Backend returns JWT token
3. Frontend stores token (localStorage/sessionStorage)
4. All subsequent requests include token in `Authorization: Bearer <token>` header
5. Backend validates token using JWT strategy

## Role-Based Access Control (RBAC)

Roles are defined in `UserRole` enum:
- COO (Super Admin)
- Directors/Management
- Factory Manager
- Site Engineer/Manager
- Office Staff
- Accounts
- Storekeeper
- Sales/Marketing
- Service Team
- General Staff

Permissions can be checked in guards/decorators (to be implemented).

## Real-time Features

WebSockets will be used for:
- Real-time messaging
- Live notifications
- Task updates
- Calendar reminders

Implementation pending - Socket.IO integration needed.

## File Uploads

File uploads will be handled for:
- Task attachments
- Message files
- Site photos
- Reports
- Customer signatures

Implementation pending - File upload service needed.

## Deployment Considerations

### Production Checklist
1. Set `NODE_ENV=production`
2. Disable TypeORM `synchronize` (use migrations)
3. Set strong `JWT_SECRET`
4. Configure proper CORS
5. Set up file storage (AWS S3, etc.)
6. Configure WebSocket in production
7. Set up proper logging
8. Database backups
9. SSL/HTTPS
10. Rate limiting

## Future Enhancements

1. **WebSocket Integration** - Real-time messaging and notifications
2. **File Upload Service** - Handle file uploads properly
3. **Email Notifications** - Send emails for important events
4. **Advanced Permissions** - Fine-grained permission system
5. **Audit Logging** - Track all system changes
6. **Search Functionality** - Global search across modules
7. **Export/Import** - Data export capabilities
8. **Mobile App** - React Native mobile application
9. **Reporting Dashboard** - Advanced analytics
10. **Workflow Engine** - Customizable workflows
