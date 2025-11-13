import { Controller, Get, Post, Patch, Delete, Body, Param } from '@nestjs/common';
import { FactoryService } from './factory.service';
import { CreateFactoryProductionDto } from './dto/create-factory-production.dto';
import { UpdateFactoryProductionDto } from './dto/update-factory-production.dto';

@Controller('factory')
export class FactoryController {
  constructor(private readonly factoryService: FactoryService) {}

  @Get()
  async findAll() {
    return this.factoryService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.factoryService.findOne(id);
  }

  @Post()
  async create(@Body() createFactoryProductionDto: CreateFactoryProductionDto) {
    return this.factoryService.create(createFactoryProductionDto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateFactoryProductionDto: UpdateFactoryProductionDto) {
    return this.factoryService.update(id, updateFactoryProductionDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.factoryService.remove(id);
  }
}
