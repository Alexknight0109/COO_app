import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  ManyToMany,
  JoinTable,
  JoinColumn,
} from 'typeorm';
import { Project } from './project.entity';
import { Task } from './task.entity';
import { SiteLog } from './site-log.entity';
import { InstallationStage } from './installation-stage.entity';
import { User } from './user.entity';

export enum SiteStatus {
  PLANNING = 'PLANNING',
  IN_PROGRESS = 'IN_PROGRESS',
  INSTALLATION = 'INSTALLATION',
  TESTING = 'TESTING',
  COMPLETED = 'COMPLETED',
  ON_HOLD = 'ON_HOLD',
}

@Entity('sites')
export class Site {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'text', nullable: true })
  address: string;

  @Column({ nullable: true })
  location: string;

  @Column({
    type: 'enum',
    enum: SiteStatus,
    default: SiteStatus.PLANNING,
  })
  status: SiteStatus;

  @ManyToOne(() => Project, (project) => project.sites)
  @JoinColumn({ name: 'project_id' })
  project: Project;

  @Column({ name: 'project_id' })
  projectId: string;

  @OneToMany(() => Task, (task) => task.site)
  tasks: Task[];

  @OneToMany(() => SiteLog, (log) => log.site)
  logs: SiteLog[];

  @OneToMany(() => InstallationStage, (stage) => stage.site)
  installationStages: InstallationStage[];

  @ManyToMany(() => User)
  @JoinTable({
    name: 'site_team_members',
    joinColumn: { name: 'site_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'user_id', referencedColumnName: 'id' },
  })
  teamMembers: User[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
