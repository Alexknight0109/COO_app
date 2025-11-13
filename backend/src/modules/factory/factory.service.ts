import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FactoryProduction } from '../../entities/factory-production.entity';
import { CreateFactoryProductionDto } from './dto/create-factory-production.dto';
import { UpdateFactoryProductionDto } from './dto/update-factory-production.dto';

@Injectable()
export class FactoryService {
  constructor(
    @InjectRepository(FactoryProduction)
    private factoryRepository: Repository<FactoryProduction>,
  ) {}

  async findAll() {
    return this.factoryRepository.find({
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string) {
    return this.factoryRepository.findOne({ where: { id } });
  }

  async create(createFactoryProductionDto: CreateFactoryProductionDto) {
    const production = this.factoryRepository.create(createFactoryProductionDto as any);
    return this.factoryRepository.save(production);
  }

  async update(id: string, updateFactoryProductionDto: UpdateFactoryProductionDto) {
    await this.factoryRepository.update(id, updateFactoryProductionDto as any);
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.factoryRepository.delete(id);
    return { message: 'Factory production deleted successfully' };
  }
}
