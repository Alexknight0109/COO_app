import { Controller, Get, Post, Patch, Delete, Body, Param } from '@nestjs/common';
import { HRService } from './hr.service';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@Controller('hr')
export class HRController {
  constructor(private readonly hrService: HRService) {}

  @Get('employees')
  async findAllEmployees() {
    return this.hrService.findAllEmployees();
  }

  @Get('employees/:id')
  async findOneEmployee(@Param('id') id: string) {
    return this.hrService.findOneEmployee(id);
  }

  @Post('employees')
  async createEmployee(@Body() createEmployeeDto: CreateEmployeeDto) {
    return this.hrService.createEmployee(createEmployeeDto);
  }

  @Patch('employees/:id')
  async updateEmployee(@Param('id') id: string, @Body() updateEmployeeDto: UpdateEmployeeDto) {
    return this.hrService.updateEmployee(id, updateEmployeeDto);
  }

  @Delete('employees/:id')
  async removeEmployee(@Param('id') id: string) {
    return this.hrService.removeEmployee(id);
  }

  @Get('departments')
  async findAllDepartments() {
    return this.hrService.findAllDepartments();
  }

  @Get('departments/:id')
  async findOneDepartment(@Param('id') id: string) {
    return this.hrService.findOneDepartment(id);
  }

  @Post('departments')
  async createDepartment(@Body() createDepartmentDto: CreateDepartmentDto) {
    return this.hrService.createDepartment(createDepartmentDto);
  }

  @Patch('departments/:id')
  async updateDepartment(@Param('id') id: string, @Body() updateDepartmentDto: UpdateDepartmentDto) {
    return this.hrService.updateDepartment(id, updateDepartmentDto);
  }

  @Delete('departments/:id')
  async removeDepartment(@Param('id') id: string) {
    return this.hrService.removeDepartment(id);
  }
}
