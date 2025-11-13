import { Controller, Get, Post, Patch, Delete, Body, Param } from '@nestjs/common';
import { ComplaintsService } from './complaints.service';
import { CreateComplaintDto } from './dto/create-complaint.dto';
import { UpdateComplaintDto } from './dto/update-complaint.dto';

@Controller('complaints')
export class ComplaintsController {
  constructor(private readonly complaintsService: ComplaintsService) {}

  @Get()
  async findAll() {
    return this.complaintsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.complaintsService.findOne(id);
  }

  @Post()
  async create(@Body() createComplaintDto: CreateComplaintDto) {
    return this.complaintsService.create(createComplaintDto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateComplaintDto: UpdateComplaintDto) {
    return this.complaintsService.update(id, updateComplaintDto);
  }

  @Patch(':id/status')
  async updateStatus(@Param('id') id: string, @Body() body: { status: string }) {
    return this.complaintsService.updateStatus(id, body.status);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.complaintsService.remove(id);
  }
}
