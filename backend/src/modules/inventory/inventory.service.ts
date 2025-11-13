import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InventoryItem } from '../../entities/inventory.entity';
import { InventoryTransaction } from '../../entities/inventory-transaction.entity';
import { CreateInventoryItemDto } from './dto/create-inventory-item.dto';
import { UpdateInventoryItemDto } from './dto/update-inventory-item.dto';
import { CreateTransactionDto } from './dto/create-transaction.dto';

@Injectable()
export class InventoryService {
  constructor(
    @InjectRepository(InventoryItem)
    private itemsRepository: Repository<InventoryItem>,
    @InjectRepository(InventoryTransaction)
    private transactionsRepository: Repository<InventoryTransaction>,
  ) {}

  async findAllItems() {
    return this.itemsRepository.find({
      relations: ['transactions'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOneItem(id: string) {
    return this.itemsRepository.findOne({
      where: { id },
      relations: ['transactions'],
    });
  }

  async createItem(createInventoryItemDto: CreateInventoryItemDto) {
    const item = this.itemsRepository.create(createInventoryItemDto);
    return this.itemsRepository.save(item);
  }

  async updateItem(id: string, updateInventoryItemDto: UpdateInventoryItemDto) {
    await this.itemsRepository.update(id, updateInventoryItemDto);
    return this.findOneItem(id);
  }

  async removeItem(id: string) {
    await this.itemsRepository.delete(id);
    return { message: 'Inventory item deleted successfully' };
  }

  async getTransactions(inventoryId?: string) {
    const query = this.transactionsRepository.createQueryBuilder('transaction');
    if (inventoryId) {
      query.where('transaction.inventoryId = :inventoryId', { inventoryId });
    }
    return query.orderBy('transaction.createdAt', 'DESC').getMany();
  }

  async createTransaction(createTransactionDto: CreateTransactionDto) {
    const transaction = this.transactionsRepository.create(createTransactionDto);
    const saved = await this.transactionsRepository.save(transaction);
    
    // Update inventory quantity
    const item = await this.findOneItem(createTransactionDto.inventoryId);
    if (item) {
      if (createTransactionDto.type === 'IN') {
        item.quantity += createTransactionDto.quantity;
      } else {
        item.quantity -= createTransactionDto.quantity;
      }
      await this.itemsRepository.save(item);
    }
    
    return saved;
  }
}
