import { IsString, IsNumber, IsOptional, IsEnum } from 'class-validator';

export class CreatePaymentStageDto {
  @IsString()
  accountId: string;

  @IsString()
  stage: string;

  @IsNumber()
  amount: number;

  @IsOptional()
  @IsString()
  dueDate?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

