import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { TasksModule } from './modules/tasks/tasks.module';
import { MessagesModule } from './modules/messages/messages.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { CalendarModule } from './modules/calendar/calendar.module';
import { ProjectsModule } from './modules/projects/projects.module';
import { SitesModule } from './modules/sites/sites.module';
import { ComplaintsModule } from './modules/complaints/complaints.module';
import { FactoryModule } from './modules/factory/factory.module';
import { InventoryModule } from './modules/inventory/inventory.module';
import { AccountsModule } from './modules/accounts/accounts.module';
import { HRModule } from './modules/hr/hr.module';
import { ReportsModule } from './modules/reports/reports.module';
import { UploadModule } from './modules/upload/upload.module';

// Import all entities
import { User } from './entities/user.entity';
import { Department } from './entities/department.entity';
import { Task } from './entities/task.entity';
import { TaskComment } from './entities/task-comment.entity';
import { TaskFile } from './entities/task-file.entity';
import { TaskTimeLog } from './entities/task-time-log.entity';
import { Message } from './entities/message.entity';
import { MessageFile } from './entities/message-file.entity';
import { Notification } from './entities/notification.entity';
import { CalendarEvent } from './entities/calendar-event.entity';
import { Project } from './entities/project.entity';
import { Site } from './entities/site.entity';
import { SiteLog } from './entities/site-log.entity';
import { InstallationStage } from './entities/installation-stage.entity';
import { Complaint } from './entities/complaint.entity';
import { FactoryProduction } from './entities/factory-production.entity';
import { InventoryItem } from './entities/inventory.entity';
import { InventoryTransaction } from './entities/inventory-transaction.entity';
import { Account } from './entities/account.entity';
import { PaymentStage } from './entities/payment-stage.entity';
import { Report } from './entities/report.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      username: process.env.DB_USERNAME || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_DATABASE || 'almed_ops',
      entities: [
        User,
        Department,
        Task,
        TaskComment,
        TaskFile,
        TaskTimeLog,
        Message,
        MessageFile,
        Notification,
        CalendarEvent,
        Project,
        Site,
        SiteLog,
        InstallationStage,
        Complaint,
        FactoryProduction,
        InventoryItem,
        InventoryTransaction,
        Account,
        PaymentStage,
        Report,
      ],
      synchronize: process.env.NODE_ENV !== 'production',
      logging: process.env.NODE_ENV === 'development',
    }),
    AuthModule,
    UsersModule,
    TasksModule,
    MessagesModule,
    NotificationsModule,
    CalendarModule,
    ProjectsModule,
    SitesModule,
    ComplaintsModule,
    FactoryModule,
    InventoryModule,
    AccountsModule,
    HRModule,
    ReportsModule,
    UploadModule,
  ],
})
export class AppModule {}