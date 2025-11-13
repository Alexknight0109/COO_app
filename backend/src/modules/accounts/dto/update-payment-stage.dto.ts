import { PartialType } from '@nestjs/mapped-types';
import { CreatePaymentStageDto } from './create-payment-stage.dto';

export class UpdatePaymentStageDto extends PartialType(CreatePaymentStageDto) {}

