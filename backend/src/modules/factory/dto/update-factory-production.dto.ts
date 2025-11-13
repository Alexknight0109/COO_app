import { PartialType } from '@nestjs/mapped-types';
import { CreateFactoryProductionDto } from './create-factory-production.dto';

export class UpdateFactoryProductionDto extends PartialType(CreateFactoryProductionDto) {}

