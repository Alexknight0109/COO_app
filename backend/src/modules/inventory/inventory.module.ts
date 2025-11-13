import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { InventoryItem } from '../../entities/inventory.entity';
import { InventoryTransaction } from '../../entities/inventory-transaction.entity';

@Module({
  imports: [TypeOrmModule.forFeature([InventoryItem, InventoryTransaction])],
  controllers: [InventoryController],
  providers: [InventoryService],
})
export class InventoryModule {}
