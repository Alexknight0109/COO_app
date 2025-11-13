import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from '../../entities/notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private notificationsRepository: Repository<Notification>,
  ) {}

  async findAll(userId: string) {
    return this.notificationsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async create(notificationData: Partial<Notification>) {
    const notification = this.notificationsRepository.create(notificationData);
    return this.notificationsRepository.save(notification);
  }

  async markAsRead(id: string) {
    await this.notificationsRepository.update(id, { isRead: true });
    return this.notificationsRepository.findOne({ where: { id } });
  }
}
