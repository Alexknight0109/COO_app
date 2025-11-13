import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Complaint } from '../../entities/complaint.entity';
import { CreateComplaintDto } from './dto/create-complaint.dto';
import { UpdateComplaintDto } from './dto/update-complaint.dto';

@Injectable()
export class ComplaintsService {
  constructor(
    @InjectRepository(Complaint)
    private complaintsRepository: Repository<Complaint>,
  ) {}

  async findAll() {
    return this.complaintsRepository.find({
      relations: ['assignedEngineer'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string) {
    return this.complaintsRepository.findOne({
      where: { id },
      relations: ['assignedEngineer', 'tasks'],
    });
  }

  async create(createComplaintDto: CreateComplaintDto) {
    const complaint = this.complaintsRepository.create(createComplaintDto as any);
    return this.complaintsRepository.save(complaint);
  }

  async update(id: string, updateComplaintDto: UpdateComplaintDto) {
    await this.complaintsRepository.update(id, updateComplaintDto as any);
    return this.findOne(id);
  }

  async updateStatus(id: string, status: string) {
    await this.complaintsRepository.update(id, { status: status as any });
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.complaintsRepository.delete(id);
    return { message: 'Complaint deleted successfully' };
  }
}
