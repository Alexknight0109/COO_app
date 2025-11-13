import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CalendarEvent } from '../../entities/calendar-event.entity';

@Injectable()
export class CalendarService {
  constructor(
    @InjectRepository(CalendarEvent)
    private calendarRepository: Repository<CalendarEvent>,
  ) {}

  async findAll(userId?: string) {
    const query = this.calendarRepository.createQueryBuilder('event');
    if (userId) {
      query.where('event.userId = :userId', { userId });
    }
    return query.orderBy('event.startDate', 'ASC').getMany();
  }

  async findOne(id: string) {
    return this.calendarRepository.findOne({ where: { id } });
  }

  async create(eventData: Partial<CalendarEvent>) {
    const event = this.calendarRepository.create(eventData);
    return this.calendarRepository.save(event);
  }

  async update(id: string, eventData: Partial<CalendarEvent>) {
    await this.calendarRepository.update(id, eventData);
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.calendarRepository.delete(id);
    return { message: 'Event deleted successfully' };
  }
}
