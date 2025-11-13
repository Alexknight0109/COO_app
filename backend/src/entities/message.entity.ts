import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  ManyToMany,
  OneToMany,
  JoinTable,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { MessageFile } from './message-file.entity';

export enum MessageType {
  DM = 'DM',
  GROUP = 'GROUP',
  BROADCAST = 'BROADCAST',
}

export enum BroadcastTarget {
  ALL = 'ALL',
  SITE_TEAM = 'SITE_TEAM',
  FACTORY = 'FACTORY',
  ACCOUNTS = 'ACCOUNTS',
  MANAGERS = 'MANAGERS',
  OFFICE = 'OFFICE',
}

@Entity('messages')
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text' })
  content: string;

  @Column({
    type: 'enum',
    enum: MessageType,
    default: MessageType.DM,
  })
  type: MessageType;

  @ManyToOne(() => User, (user) => user.sentMessages)
  @JoinColumn({ name: 'sender_id' })
  sender: User;

  @Column({ name: 'sender_id' })
  senderId: string;

  @ManyToMany(() => User, (user) => user.receivedMessages)
  @JoinTable({
    name: 'message_recipients',
    joinColumn: { name: 'message_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'user_id', referencedColumnName: 'id' },
  })
  recipients: User[];

  @Column({ nullable: true })
  groupId: string; // For group chats

  @Column({
    type: 'enum',
    enum: BroadcastTarget,
    nullable: true,
  })
  broadcastTarget: BroadcastTarget;

  @OneToMany(() => MessageFile, (file) => file.message)
  files: MessageFile[];

  @Column({ default: false })
  isRead: boolean;

  @Column({ type: 'json', nullable: true })
  readReceipts: { userId: string; readAt: Date }[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
