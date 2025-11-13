import { PartialType, OmitType } from '@nestjs/mapped-types';
import { IsOptional, IsString } from 'class-validator';
import { CreateEmployeeDto } from './create-employee.dto';

export class UpdateEmployeeDto extends PartialType(OmitType(CreateEmployeeDto, ['password'] as const)) {
  @IsOptional()
  @IsString()
  password?: string;
}

