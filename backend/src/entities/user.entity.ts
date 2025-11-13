import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
  ManyToMany,
  JoinTable,
} from 'typeorm';
import { Task } from './task.entity';
import { Message } from './message.entity';
import { Notification } from './notification.entity';
import { CalendarEvent } from './calendar-event.entity';
import { Department } from './department.entity';

export enum UserRole {
  COO = 'COO',
  DIRECTOR = 'DIRECTOR',
  MANAGER = 'MANAGER',
  FACTORY_MANAGER = 'FACTORY_MANAGER',
  SITE_ENGINEER = 'SITE_ENGINEER',
  SITE_MANAGER = 'SITE_MANAGER',
  OFFICE_STAFF = 'OFFICE_STAFF',
  ACCOUNTS = 'ACCOUNTS',
  STOREKEEPER = 'STOREKEEPER',
  SALES = 'SALES',
  SERVICE_TEAM = 'SERVICE_TEAM',
  GENERAL_STAFF = 'GENERAL_STAFF',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column()
  firstName: string;

  @Column()
  lastName: string;

  @Column({ nullable: true })
  phone: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.GENERAL_STAFF,
  })
  role: UserRole;

  @ManyToOne(() => Department, (department) => department.members)
  @JoinColumn({ name: 'department_id' })
  department: Department;

  @Column({ nullable: true, name: 'department_id' })
  departmentId: string;

  @Column({ nullable: true })
  avatar: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: 'dark' })
  themePreference: string; // 'dark' or 'light'

  @OneToMany(() => Task, (task) => task.assignee)
  assignedTasks: Task[];

  @OneToMany(() => Task, (task) => task.assigner)
  createdTasks: Task[];

  @OneToMany(() => Message, (message) => message.sender)
  sentMessages: Message[];

  @ManyToMany(() => Message, (message) => message.recipients)
  receivedMessages: Message[];

  @OneToMany(() => Notification, (notification) => notification.user)
  notifications: Notification[];

  @OneToMany(() => CalendarEvent, (event) => event.user)
  calendarEvents: CalendarEvent[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
