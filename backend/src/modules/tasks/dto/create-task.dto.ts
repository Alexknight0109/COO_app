import { IsString, IsEnum, IsOptional, IsDateString, IsUUID } from 'class-validator';
import { TaskStatus, TaskPriority, TaskTemplate } from '../../../entities/task.entity';

export class CreateTaskDto {
  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsEnum(TaskStatus)
  @IsOptional()
  status?: TaskStatus;

  @IsEnum(TaskPriority)
  @IsOptional()
  priority?: TaskPriority;

  @IsUUID()
  assigneeId: string;

  @IsUUID()
  @IsOptional()
  projectId?: string;

  @IsUUID()
  @IsOptional()
  siteId?: string;

  @IsUUID()
  @IsOptional()
  complaintId?: string;

  @IsEnum(TaskTemplate)
  @IsOptional()
  template?: TaskTemplate;

  @IsDateString()
  @IsOptional()
  dueDate?: string;
}
