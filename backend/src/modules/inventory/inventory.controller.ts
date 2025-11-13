import { Controller, Get, Post, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { CreateInventoryItemDto } from './dto/create-inventory-item.dto';
import { UpdateInventoryItemDto } from './dto/update-inventory-item.dto';
import { CreateTransactionDto } from './dto/create-transaction.dto';

@Controller('inventory')
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get()
  async findAll() {
    return this.inventoryService.findAllItems();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.inventoryService.findOneItem(id);
  }

  @Post()
  async create(@Body() createInventoryItemDto: CreateInventoryItemDto) {
    return this.inventoryService.createItem(createInventoryItemDto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateInventoryItemDto: UpdateInventoryItemDto) {
    return this.inventoryService.updateItem(id, updateInventoryItemDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.inventoryService.removeItem(id);
  }

  @Get('transactions')
  async getTransactions(@Query('inventoryId') inventoryId?: string) {
    return this.inventoryService.getTransactions(inventoryId);
  }

  @Post('transactions')
  async createTransaction(@Body() createTransactionDto: CreateTransactionDto) {
    return this.inventoryService.createTransaction(createTransactionDto);
  }
}
