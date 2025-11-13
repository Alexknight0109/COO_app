import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Site } from './site.entity';
import { User } from './user.entity';

export enum InstallationStageType {
  SURVEY = 'SURVEY',
  PREPARATION = 'PREPARATION',
  EQUIPMENT_DELIVERY = 'EQUIPMENT_DELIVERY',
  INSTALLATION = 'INSTALLATION',
  ELECTRICAL = 'ELECTRICAL',
  TESTING = 'TESTING',
  COMMISSIONING = 'COMMISSIONING',
  HANDOVER = 'HANDOVER',
}

export enum StageStatus {
  PENDING = 'PENDING',
  IN_PROGRESS = 'IN_PROGRESS',
  BLOCKED = 'BLOCKED',
  COMPLETED = 'COMPLETED',
}

@Entity('installation_stages')
export class InstallationStage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Site, (site) => site.installationStages)
  @JoinColumn({ name: 'site_id' })
  site: Site;

  @Column({ name: 'site_id' })
  siteId: string;

  @Column({
    type: 'enum',
    enum: InstallationStageType,
  })
  stageType: InstallationStageType;

  @Column({
    type: 'enum',
    enum: StageStatus,
    default: StageStatus.PENDING,
  })
  status: StageStatus;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'json', nullable: true })
  photos: string[];

  @Column({ type: 'text', nullable: true })
  blockers: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'assigned_to_id' })
  assignedTo: User;

  @Column({ nullable: true, name: 'assigned_to_id' })
  assignedToId: string;

  @Column({ type: 'date', nullable: true })
  startDate: Date;

  @Column({ type: 'date', nullable: true })
  completedDate: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
