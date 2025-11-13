import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';
import { TaskStatus, TaskPriority } from '../../../entities/task.entity';

export class UpdateTaskDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @IsOptional()
  @IsEnum(TaskPriority)
  priority?: TaskPriority;

  @IsOptional()
  @IsString()
  assigneeId?: string;

  @IsOptional()
  @IsString()
  projectId?: string;

  @IsOptional()
  @IsString()
  siteId?: string;

  @IsOptional()
  @IsDateString()
  dueDate?: string;
}
