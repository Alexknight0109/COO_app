import { Controller, Get, Post, Param, Patch, Body, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
// @UseGuards(AuthGuard('jwt')) // Commented out for now to allow testing without auth
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  async findAll(@Request() req) {
    // For now, use a default user ID from query
    // When auth is enabled: req.user?.userId
    const userId = (req.query?.userId as string) || 'default-user-id';
    return this.notificationsService.findAll(userId);
  }

  @Patch(':id/read')
  async markAsRead(@Param('id') id: string) {
    return this.notificationsService.markAsRead(id);
  }
}
