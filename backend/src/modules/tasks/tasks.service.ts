import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task, TaskStatus, TaskPriority } from '../../entities/task.entity';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private tasksRepository: Repository<Task>,
  ) {}

  async findAll(userId?: string) {
    const query = this.tasksRepository.createQueryBuilder('task');
    
    if (userId) {
      query.where('task.assigneeId = :userId', { userId });
    }
    
    return query
      .leftJoinAndSelect('task.assignee', 'assignee')
      .leftJoinAndSelect('task.assigner', 'assigner')
      .orderBy('task.createdAt', 'DESC')
      .getMany();
  }

  async findOne(id: string) {
    return this.tasksRepository.findOne({
      where: { id },
      relations: ['assignee', 'assigner', 'project', 'site', 'comments', 'files'],
    });
  }

  async create(taskData: Partial<Task>) {
    const task = this.tasksRepository.create(taskData);
    return this.tasksRepository.save(task);
  }

  async update(id: string, taskData: Partial<Task>) {
    await this.tasksRepository.update(id, taskData);
    return this.findOne(id);
  }

  async delete(id: string) {
    return this.tasksRepository.delete(id);
  }

  async updateStatus(id: string, status: TaskStatus) {
    await this.tasksRepository.update(id, { status });
    return this.findOne(id);
  }
}
