import { IsString, IsNumber, IsOptional } from 'class-validator';

export class CreateAccountDto {
  @IsOptional()
  @IsString()
  projectId?: string;

  @IsOptional()
  @IsString()
  poNumber?: string;

  @IsOptional()
  @IsNumber()
  poValue?: number;

  @IsOptional()
  @IsNumber()
  outstandingBalance?: number;

  @IsOptional()
  @IsString()
  status?: string;
}

