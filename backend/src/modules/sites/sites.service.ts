import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Site } from '../../entities/site.entity';
import { SiteLog } from '../../entities/site-log.entity';
import { CreateSiteDto } from './dto/create-site.dto';
import { UpdateSiteDto } from './dto/update-site.dto';
import { CreateSiteLogDto } from './dto/create-site-log.dto';

@Injectable()
export class SitesService {
  constructor(
    @InjectRepository(Site)
    private sitesRepository: Repository<Site>,
    @InjectRepository(SiteLog)
    private siteLogsRepository: Repository<SiteLog>,
  ) {}

  async findAll() {
    return this.sitesRepository.find({
      relations: ['project', 'teamMembers'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string) {
    return this.sitesRepository.findOne({
      where: { id },
      relations: ['project', 'teamMembers', 'logs', 'tasks'],
    });
  }

  async create(createSiteDto: CreateSiteDto) {
    const site = this.sitesRepository.create(createSiteDto);
    return this.sitesRepository.save(site);
  }

  async update(id: string, updateSiteDto: UpdateSiteDto) {
    await this.sitesRepository.update(id, updateSiteDto);
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.sitesRepository.delete(id);
    return { message: 'Site deleted successfully' };
  }

  async getLogs(siteId: string) {
    return this.siteLogsRepository.find({
      where: { siteId },
      relations: ['createdBy'],
      order: { createdAt: 'DESC' },
    });
  }

  async createLog(createSiteLogDto: CreateSiteLogDto) {
    const log = this.siteLogsRepository.create({
      ...createSiteLogDto,
      logDate: new Date(),
      userId: createSiteLogDto.userId || null, // Optional for now
    });
    return this.siteLogsRepository.save(log);
  }
}
