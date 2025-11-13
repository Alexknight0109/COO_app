import { IsString, IsOptional, IsEnum, IsArray } from 'class-validator';

export class CreateComplaintDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsEnum(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'])
  status?: string;

  @IsOptional()
  @IsEnum(['LOW', 'MEDIUM', 'HIGH', 'URGENT'])
  priority?: string;

  @IsOptional()
  @IsString()
  assignedToId?: string;

  @IsOptional()
  @IsString()
  customerName?: string;

  @IsOptional()
  @IsString()
  customerContact?: string;

  @IsOptional()
  @IsString()
  siteId?: string;

  @IsOptional()
  @IsArray()
  photos?: string[];
}

