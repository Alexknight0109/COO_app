import { Controller, Get, Post, Patch, Delete, Body, Param } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { CreateReportDto } from './dto/create-report.dto';
import { UpdateReportDto } from './dto/update-report.dto';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get()
  async findAll() {
    return this.reportsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.reportsService.findOne(id);
  }

  @Post()
  async create(@Body() createReportDto: CreateReportDto) {
    return this.reportsService.create(createReportDto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateReportDto: UpdateReportDto) {
    return this.reportsService.update(id, updateReportDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.reportsService.remove(id);
  }
}
