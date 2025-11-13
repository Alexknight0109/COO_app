import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

export enum ReportType {
  DAILY_REPORT = 'DAILY_REPORT',
  WORK_SUMMARY = 'WORK_SUMMARY',
  QUOTATION = 'QUOTATION',
  SITE_PHOTOS = 'SITE_PHOTOS',
  FACTORY_LOG = 'FACTORY_LOG',
  SALES_REPORT = 'SALES_REPORT',
}

@Entity('reports')
export class Report {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: ReportType,
  })
  type: ReportType;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  content: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  createdBy: User;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ type: 'json', nullable: true })
  files: { name: string; url: string; type: string }[];

  @Column({ type: 'date' })
  reportDate: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
