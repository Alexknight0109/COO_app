import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message, MessageType } from '../../entities/message.entity';
import { User } from '../../entities/user.entity';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(Message)
    private messagesRepository: Repository<Message>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findAll(userId: string) {
    return this.messagesRepository
      .createQueryBuilder('message')
      .leftJoinAndSelect('message.sender', 'sender')
      .leftJoinAndSelect('message.recipients', 'recipients')
      .where('sender.id = :userId OR recipients.id = :userId', { userId })
      .orderBy('message.createdAt', 'DESC')
      .getMany();
  }

  async findConversation(userId1: string, userId2: string) {
    return this.messagesRepository
      .createQueryBuilder('message')
      .leftJoinAndSelect('message.sender', 'sender')
      .leftJoinAndSelect('message.recipients', 'recipients')
      .where('message.type = :type', { type: MessageType.DM })
      .andWhere(
        '(sender.id = :userId1 AND recipients.id = :userId2) OR (sender.id = :userId2 AND recipients.id = :userId1)',
        { userId1, userId2 },
      )
      .orderBy('message.createdAt', 'ASC')
      .getMany();
  }

  async create(messageData: Partial<Message> & { recipientIds?: string[] }, senderId: string) {
    const sender = await this.usersRepository.findOne({ where: { id: senderId } });
    const message = this.messagesRepository.create({
      ...messageData,
      sender,
    });

    if (messageData.recipientIds && messageData.recipientIds.length > 0) {
      const recipients = await this.usersRepository.find({
        where: messageData.recipientIds.map(id => ({ id })),
      });
      message.recipients = recipients;
    }

    return this.messagesRepository.save(message);
  }

  async markAsRead(messageId: string, userId: string) {
    const message = await this.messagesRepository.findOne({
      where: { id: messageId },
      relations: ['recipients'],
    });

    if (!message) {
      return null;
    }

    const readReceipts = message.readReceipts || [];
    if (!readReceipts.find((r) => r.userId === userId)) {
      readReceipts.push({ userId, readAt: new Date() });
      message.readReceipts = readReceipts;
      return this.messagesRepository.save(message);
    }

    return message;
  }
}
