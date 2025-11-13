import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class CreateFactoryProductionDto {
  @IsString()
  ahuSerialNumber: string;

  @IsString()
  stage: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  qcStatus?: string;

  @IsOptional()
  @IsBoolean()
  dispatchReady?: boolean;

  @IsOptional()
  @IsString()
  notes?: string;
}

