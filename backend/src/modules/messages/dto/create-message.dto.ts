import { IsString, IsEnum, IsArray, IsOptional, IsUUID } from 'class-validator';
import { MessageType, BroadcastTarget } from '../../../entities/message.entity';

export class CreateMessageDto {
  @IsString()
  content: string;

  @IsEnum(MessageType)
  type: MessageType;

  @IsArray()
  @IsUUID('4', { each: true })
  @IsOptional()
  recipientIds?: string[];

  @IsString()
  @IsOptional()
  groupId?: string;

  @IsEnum(BroadcastTarget)
  @IsOptional()
  broadcastTarget?: BroadcastTarget;
}
