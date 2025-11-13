import { IsString, IsEmail, IsOptional } from 'class-validator';

export class CreateEmployeeDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;

  @IsString()
  firstName: string;

  @IsString()
  lastName: string;

  @IsString()
  role: string;

  @IsOptional()
  @IsString()
  departmentId?: string;
}

