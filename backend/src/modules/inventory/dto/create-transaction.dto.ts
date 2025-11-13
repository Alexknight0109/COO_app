import { IsString, IsNumber, IsEnum, IsOptional } from 'class-validator';

export class CreateTransactionDto {
  @IsString()
  inventoryId: string;

  @IsEnum(['IN', 'OUT'])
  type: 'IN' | 'OUT';

  @IsNumber()
  quantity: number;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsString()
  siteId?: string;

  @IsOptional()
  @IsString()
  projectId?: string;
}

