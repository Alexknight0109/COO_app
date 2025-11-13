import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { InventoryItem } from './inventory.entity';
import { User } from './user.entity';

@Entity('inventory_transactions')
export class InventoryTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => InventoryItem, (item) => item.transactions)
  @JoinColumn({ name: 'item_id' })
  item: InventoryItem;

  @Column({ name: 'item_id' })
  itemId: string;

  @Column({
    type: 'enum',
    enum: ['IN', 'OUT', 'ADJUSTMENT'],
  })
  type: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  quantity: number;

  @Column({ type: 'text', nullable: true })
  reason: string;

  @Column({ nullable: true })
  siteId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  performedBy: User;

  @Column({ name: 'user_id' })
  userId: string;

  @CreateDateColumn()
  createdAt: Date;
}
