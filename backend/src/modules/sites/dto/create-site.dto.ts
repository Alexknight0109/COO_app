import { IsString, IsOptional, IsEnum } from 'class-validator';
import { SiteStatus } from '../../../entities/site.entity';

export class CreateSiteDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsEnum(SiteStatus)
  status?: SiteStatus;

  @IsOptional()
  @IsString()
  projectId?: string;
}

