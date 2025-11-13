import { IsString, IsOptional, IsArray } from 'class-validator';

export class CreateSiteLogDto {
  @IsString()
  siteId: string;

  @IsOptional()
  @IsString()
  workDone?: string;

  @IsOptional()
  @IsString()
  materialsNeeded?: string;

  @IsOptional()
  @IsString()
  issues?: string;

  @IsOptional()
  @IsArray()
  photos?: string[];

  @IsOptional()
  @IsString()
  userId?: string;
}

