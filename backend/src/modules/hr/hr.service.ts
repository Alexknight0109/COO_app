import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';
import { Department } from '../../entities/department.entity';
import { AuthService } from '../auth/auth.service';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@Injectable()
export class HRService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Department)
    private departmentsRepository: Repository<Department>,
    private authService: AuthService,
  ) {}

  async findAllEmployees() {
    return this.usersRepository.find({
      relations: ['department'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOneEmployee(id: string) {
    return this.usersRepository.findOne({
      where: { id },
      relations: ['department'],
    });
  }

  async createEmployee(createEmployeeDto: CreateEmployeeDto) {
    // Use auth service to create user
    return this.authService.register(
      createEmployeeDto.email,
      createEmployeeDto.password,
      createEmployeeDto.firstName,
      createEmployeeDto.lastName,
      createEmployeeDto.role,
    );
  }

  async updateEmployee(id: string, updateEmployeeDto: UpdateEmployeeDto) {
    await this.usersRepository.update(id, updateEmployeeDto);
    return this.findOneEmployee(id);
  }

  async removeEmployee(id: string) {
    await this.usersRepository.delete(id);
    return { message: 'Employee deleted successfully' };
  }

  async findAllDepartments() {
    return this.departmentsRepository.find({
      relations: ['members'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOneDepartment(id: string) {
    return this.departmentsRepository.findOne({
      where: { id },
      relations: ['members'],
    });
  }

  async createDepartment(createDepartmentDto: CreateDepartmentDto) {
    const department = this.departmentsRepository.create(createDepartmentDto);
    return this.departmentsRepository.save(department);
  }

  async updateDepartment(id: string, updateDepartmentDto: UpdateDepartmentDto) {
    await this.departmentsRepository.update(id, updateDepartmentDto);
    return this.findOneDepartment(id);
  }

  async removeDepartment(id: string) {
    await this.departmentsRepository.delete(id);
    return { message: 'Department deleted successfully' };
  }
}
