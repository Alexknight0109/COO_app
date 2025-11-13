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
import { Task } from './task.entity';
import { User } from './user.entity';

export enum ComplaintStatus {
  OPEN = 'OPEN',
  ASSIGNED = 'ASSIGNED',
  IN_PROGRESS = 'IN_PROGRESS',
  RESOLVED = 'RESOLVED',
  CLOSED = 'CLOSED',
}

@Entity('complaints')
export class Complaint {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  ticketNumber: string;

  @Column()
  customerName: string;

  @Column({ nullable: true })
  customerPhone: string;

  @Column({ type: 'text' })
  description: string;

  @Column({
    type: 'enum',
    enum: ComplaintStatus,
    default: ComplaintStatus.OPEN,
  })
  status: ComplaintStatus;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'assigned_engineer_id' })
  assignedEngineer: User;

  @Column({ nullable: true, name: 'assigned_engineer_id' })
  assignedEngineerId: string;

  @Column({ type: 'text', nullable: true })
  spareParts: string;

  @Column({ type: 'json', nullable: true })
  photos: string[];

  @Column({ nullable: true })
  customerSignature: string; // URL

  @Column({ type: 'timestamp', nullable: true })
  resolvedAt: Date;

  @OneToMany(() => Task, (task) => task.complaint)
  tasks: Task[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
