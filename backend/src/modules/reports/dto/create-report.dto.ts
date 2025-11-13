import { IsString, IsEnum, IsOptional } from 'class-validator';

export class CreateReportDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsEnum(['DAILY', 'WEEKLY', 'MONTHLY', 'SITE', 'FACTORY', 'SALES', 'OTHER'])
  type: string;

  @IsOptional()
  @IsString()
  fileUrl?: string;

  @IsOptional()
  @IsString()
  projectId?: string;

  @IsOptional()
  @IsString()
  siteId?: string;
}

