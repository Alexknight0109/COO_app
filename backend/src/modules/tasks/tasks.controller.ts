import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TasksService } from './tasks.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

@Controller('tasks')
// @UseGuards(AuthGuard('jwt')) // Commented out for now to allow testing without auth
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Get()
  async findAll(@Request() req, @Query('userId') userId?: string) {
    // For now, return all tasks without filtering
    // When auth is enabled: const filterUserId = userId || req.user?.userId;
    return this.tasksService.findAll(userId || undefined);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.tasksService.findOne(id);
  }

  @Post()
  async create(@Body() createTaskDto: CreateTaskDto, @Request() req) {
    // For now, use a default assigner ID
    // When auth is enabled: assignerId: req.user?.userId
    const taskData: any = {
      ...createTaskDto,
      assignerId: 'default-user-id', // TODO: Use actual user ID from auth
    };
    
    // Convert dueDate string to Date if provided
    if (createTaskDto.dueDate) {
      taskData.dueDate = new Date(createTaskDto.dueDate);
    }
    
    return this.tasksService.create(taskData);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateTaskDto: UpdateTaskDto) {
    // Convert dueDate string to Date if provided
    const updateData: any = { ...updateTaskDto };
    if (updateTaskDto.dueDate) {
      updateData.dueDate = new Date(updateTaskDto.dueDate);
    }
    return this.tasksService.update(id, updateData);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.tasksService.delete(id);
  }

  @Patch(':id/status')
  async updateStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.tasksService.updateStatus(id, status as any);
  }
}
