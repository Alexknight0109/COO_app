import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Report } from '../../entities/report.entity';
import { CreateReportDto } from './dto/create-report.dto';
import { UpdateReportDto } from './dto/update-report.dto';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Report)
    private reportsRepository: Repository<Report>,
  ) {}

  async findAll() {
    return this.reportsRepository.find({
      relations: ['createdByUser'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string) {
    return this.reportsRepository.findOne({
      where: { id },
      relations: ['createdByUser'],
    });
  }

  async create(createReportDto: CreateReportDto) {
    const report = this.reportsRepository.create(createReportDto);
    return this.reportsRepository.save(report);
  }

  async update(id: string, updateReportDto: UpdateReportDto) {
    await this.reportsRepository.update(id, updateReportDto);
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.reportsRepository.delete(id);
    return { message: 'Report deleted successfully' };
  }
}
