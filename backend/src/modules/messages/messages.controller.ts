import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { MessagesService } from './messages.service';
import { CreateMessageDto } from './dto/create-message.dto';

@Controller('messages')
// @UseGuards(AuthGuard('jwt')) // Commented out for now to allow testing without auth
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Get()
  async findAll(@Request() req) {
    // For now, use a default user ID from query
    // When auth is enabled: req.user?.userId
    const userId = req.query?.userId as string || 'default-user-id';
    return this.messagesService.findAll(userId);
  }

  @Get('conversation/:userId')
  async findConversation(@Param('userId') userId: string, @Request() req) {
    // For now, use a default current user ID from query
    // When auth is enabled: req.user?.userId
    const currentUserId = req.query?.currentUserId as string || 'default-user-id';
    return this.messagesService.findConversation(currentUserId, userId);
  }

  @Post()
  async create(@Body() createMessageDto: CreateMessageDto & { senderId?: string }, @Request() req) {
    // For now, use senderId from body or default
    // When auth is enabled: req.user?.userId
    const senderId = createMessageDto.senderId || req.body?.senderId || 'default-user-id';
    return this.messagesService.create(createMessageDto, senderId);
  }

  @Post(':id/read')
  async markAsRead(@Param('id') id: string, @Request() req) {
    // For now, use a default user ID from body
    // When auth is enabled: req.user?.userId
    const userId = req.body?.userId || 'default-user-id';
    return this.messagesService.markAsRead(id, userId);
  }
}
