import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ProjectsService } from './projects.service';
import { Project } from '../../entities/project.entity';

@Controller('projects')
// @UseGuards(AuthGuard('jwt')) // Commented out for now to allow testing without auth
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Get()
  async findAll() {
    return this.projectsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.projectsService.findOne(id);
  }

  @Post()
  async create(@Body() projectData: Partial<Project>) {
    return this.projectsService.create(projectData);
  }
}
