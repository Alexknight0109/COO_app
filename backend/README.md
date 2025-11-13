# ALMED OPS Control System - Backend

NestJS backend application for ALMED OPS Control System.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

3. Update the `.env` file with your database credentials.

4. Make sure PostgreSQL is running and create the database:
```sql
CREATE DATABASE almed_ops;
```

5. Run the application:
```bash
npm run start:dev
```

The API will be available at `http://localhost:3001/api`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `GET /api/auth/profile` - Get current user profile

### Tasks
- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/:id` - Get task by ID
- `POST /api/tasks` - Create new task
- `PATCH /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `PATCH /api/tasks/:id/status` - Update task status

### Messages
- `GET /api/messages` - Get all messages
- `GET /api/messages/conversation/:userId` - Get conversation with user
- `POST /api/messages` - Send message
- `POST /api/messages/:id/read` - Mark message as read

### Notifications
- `GET /api/notifications` - Get all notifications
- `PATCH /api/notifications/:id/read` - Mark notification as read

### Calendar
- `GET /api/calendar` - Get calendar events
- `POST /api/calendar` - Create calendar event

### Projects
- `GET /api/projects` - Get all projects
- `GET /api/projects/:id` - Get project by ID
- `POST /api/projects` - Create project

### Sites
- `GET /api/sites` - Get all sites
- `GET /api/sites/:id` - Get site by ID

### Complaints
- `GET /api/complaints` - Get all complaints
- `GET /api/complaints/:id` - Get complaint by ID

### Factory
- `GET /api/factory` - Get all factory productions
- `GET /api/factory/:id` - Get factory production by ID

### Inventory
- `GET /api/inventory` - Get all inventory items
- `GET /api/inventory/:id` - Get inventory item by ID

### Accounts
- `GET /api/accounts` - Get all accounts
- `GET /api/accounts/:id` - Get account by ID

### HR
- `GET /api/hr/employees` - Get all employees
- `GET /api/hr/departments` - Get all departments

### Reports
- `GET /api/reports` - Get all reports
- `GET /api/reports/:id` - Get report by ID

## Database Schema

The application uses TypeORM with PostgreSQL. All entities are in `src/entities/`.

## Authentication

The application uses JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <token>
```
