import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Site } from './site.entity';
import { User } from './user.entity';

@Entity('site_logs')
export class SiteLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Site, (site) => site.logs)
  @JoinColumn({ name: 'site_id' })
  site: Site;

  @Column({ name: 'site_id' })
  siteId: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'user_id' })
  createdBy: User;

  @Column({ name: 'user_id', nullable: true })
  userId: string;

  @Column({ type: 'text', nullable: true })
  workDone: string;

  @Column({ type: 'text', nullable: true })
  materialsNeeded: string;

  @Column({ type: 'text', nullable: true })
  issues: string;

  @Column({ type: 'json', nullable: true })
  photos: string[]; // URLs

  @Column({ type: 'date' })
  logDate: Date;

  @CreateDateColumn()
  createdAt: Date;
}
