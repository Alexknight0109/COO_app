import { Controller, Get, Post, Patch, Delete, Body, Param, Request } from '@nestjs/common';
import { CalendarService } from './calendar.service';
import { CalendarEvent } from '../../entities/calendar-event.entity';

@Controller('calendar')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Get()
  async findAll(@Request() req) {
    const userId = req.query?.userId as string || undefined;
    return this.calendarService.findAll(userId);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.calendarService.findOne(id);
  }

  @Post()
  async create(@Body() eventData: Partial<CalendarEvent> & { userId?: string }, @Request() req) {
    return this.calendarService.create({
      ...eventData,
      userId: eventData.userId || req.body?.userId || null,
    });
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() eventData: Partial<CalendarEvent>) {
    return this.calendarService.update(id, eventData);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.calendarService.remove(id);
  }
}
