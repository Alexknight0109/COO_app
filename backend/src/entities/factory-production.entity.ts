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

export enum ProductionStage {
  CUTTING = 'CUTTING',
  ASSEMBLY = 'ASSEMBLY',
  WELDING = 'WELDING',
  INSULATION = 'INSULATION',
  ELECTRICAL = 'ELECTRICAL',
  QC = 'QC',
  PAINTING = 'PAINTING',
  DISPATCH_READY = 'DISPATCH_READY',
}

export enum ProductionStatus {
  PENDING = 'PENDING',
  IN_PROGRESS = 'IN_PROGRESS',
  QC_FAILED = 'QC_FAILED',
  QC_PASSED = 'QC_PASSED',
  DISPATCHED = 'DISPATCHED',
}

@Entity('factory_productions')
export class FactoryProduction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  ahuSerial: string;

  @Column({
    type: 'enum',
    enum: ProductionStage,
  })
  currentStage: ProductionStage;

  @Column({
    type: 'enum',
    enum: ProductionStatus,
    default: ProductionStatus.PENDING,
  })
  status: ProductionStatus;

  @Column({ type: 'json', nullable: true })
  workStages: { stage: ProductionStage; startedAt: Date; completedAt?: Date }[];

  @Column({ type: 'text', nullable: true })
  qcNotes: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'qc_inspector_id' })
  qcInspector: User;

  @Column({ nullable: true, name: 'qc_inspector_id' })
  qcInspectorId: string;

  @Column({ type: 'date', nullable: true })
  dispatchDate: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
