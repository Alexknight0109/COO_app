import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Project } from '../../entities/project.entity';

@Injectable()
export class ProjectsService {
  constructor(
    @InjectRepository(Project)
    private projectsRepository: Repository<Project>,
  ) {}

  async findAll() {
    return this.projectsRepository.find({
      relations: ['sites', 'teamMembers'],
    });
  }

  async findOne(id: string) {
    return this.projectsRepository.findOne({
      where: { id },
      relations: ['sites', 'teamMembers', 'tasks'],
    });
  }

  async create(projectData: Partial<Project>) {
    const project = this.projectsRepository.create(projectData);
    return this.projectsRepository.save(project);
  }
}
