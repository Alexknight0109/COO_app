import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { InventoryTransaction } from './inventory-transaction.entity';
import { User } from './user.entity';

@Entity('inventory_items')
export class InventoryItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  sku: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  currentStock: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  minStockLevel: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  maxStockLevel: number;

  @Column()
  unit: string; // kg, pcs, m, etc.

  @Column({ default: false })
  isLowStock: boolean;

  @OneToMany(() => InventoryTransaction, (transaction) => transaction.item)
  transactions: InventoryTransaction[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
