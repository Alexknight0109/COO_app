import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FactoryController } from './factory.controller';
import { FactoryService } from './factory.service';
import { FactoryProduction } from '../../entities/factory-production.entity';

@Module({
  imports: [TypeOrmModule.forFeature([FactoryProduction])],
  controllers: [FactoryController],
  providers: [FactoryService],
})
export class FactoryModule {}
