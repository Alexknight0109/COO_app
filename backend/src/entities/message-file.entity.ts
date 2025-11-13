import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Message } from './message.entity';

@Entity('message_files')
export class MessageFile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Message)
  @JoinColumn({ name: 'message_id' })
  message: Message;

  @Column({ name: 'message_id' })
  messageId: string;

  @Column()
  fileName: string;

  @Column()
  fileUrl: string;

  @Column()
  fileType: string;

  @Column()
  fileSize: number;

  @CreateDateColumn()
  createdAt: Date;
}
