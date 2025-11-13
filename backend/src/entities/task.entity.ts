import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { Project } from './project.entity';
import { Site } from './site.entity';
import { Complaint } from './complaint.entity';
import { TaskComment } from './task-comment.entity';
import { TaskFile } from './task-file.entity';
import { TaskTimeLog } from './task-time-log.entity';

export enum TaskStatus {
  NOT_STARTED = 'NOT_STARTED',
  WORKING = 'WORKING',
  BLOCKED = 'BLOCKED',
  REVIEWING = 'REVIEWING',
  COMPLETED = 'COMPLETED',
}

export enum TaskPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export enum TaskTemplate {
  QUOTATION = 'QUOTATION',
  SITE_REPORT = 'SITE_REPORT',
  PURCHASE_FOLLOW_UP = 'PURCHASE_FOLLOW_UP',
  INSTALLATION = 'INSTALLATION',
  MAINTENANCE = 'MAINTENANCE',
}

@Entity('tasks')
export class Task {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({
    type: 'enum',
    enum: TaskStatus,
    default: TaskStatus.NOT_STARTED,
  })
  status: TaskStatus;

  @Column({
    type: 'enum',
    enum: TaskPriority,
    default: TaskPriority.MEDIUM,
  })
  priority: TaskPriority;

  @ManyToOne(() => User, (user) => user.assignedTasks)
  @JoinColumn({ name: 'assignee_id' })
  assignee: User;

  @Column({ name: 'assignee_id' })
  assigneeId: string;

  @ManyToOne(() => User, (user) => user.createdTasks)
  @JoinColumn({ name: 'assigner_id' })
  assigner: User;

  @Column({ name: 'assigner_id' })
  assignerId: string;

  @ManyToOne(() => Project, (project) => project.tasks, { nullable: true })
  @JoinColumn({ name: 'project_id' })
  project: Project;

  @Column({ nullable: true, name: 'project_id' })
  projectId: string;

  @ManyToOne(() => Site, (site) => site.tasks, { nullable: true })
  @JoinColumn({ name: 'site_id' })
  site: Site;

  @Column({ nullable: true, name: 'site_id' })
  siteId: string;

  @ManyToOne(() => Complaint, (complaint) => complaint.tasks, { nullable: true })
  @JoinColumn({ name: 'complaint_id' })
  complaint: Complaint;

  @Column({ nullable: true, name: 'complaint_id' })
  complaintId: string;

  @Column({
    type: 'enum',
    enum: TaskTemplate,
    nullable: true,
  })
  template: TaskTemplate;

  @Column({ type: 'date', nullable: true })
  dueDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  startTime: Date;

  @Column({ type: 'timestamp', nullable: true })
  endTime: Date;

  @OneToMany(() => TaskComment, (comment) => comment.task)
  comments: TaskComment[];

  @OneToMany(() => TaskFile, (file) => file.task)
  files: TaskFile[];

  @OneToMany(() => TaskTimeLog, (log) => log.task)
  timeLogs: TaskTimeLog[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
