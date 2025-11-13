import { Controller, Get, Post, Patch, Delete, Body, Param } from '@nestjs/common';
import { AccountsService } from './accounts.service';
import { CreateAccountDto } from './dto/create-account.dto';
import { UpdateAccountDto } from './dto/update-account.dto';
import { CreatePaymentStageDto } from './dto/create-payment-stage.dto';
import { UpdatePaymentStageDto } from './dto/update-payment-stage.dto';

@Controller('accounts')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  async findAll() {
    return this.accountsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.accountsService.findOne(id);
  }

  @Post()
  async create(@Body() createAccountDto: CreateAccountDto) {
    return this.accountsService.create(createAccountDto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateAccountDto: UpdateAccountDto) {
    return this.accountsService.update(id, updateAccountDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.accountsService.remove(id);
  }

  @Get(':id/payment-stages')
  async getPaymentStages(@Param('id') id: string) {
    return this.accountsService.getPaymentStages(id);
  }

  @Post('payment-stages')
  async createPaymentStage(@Body() createPaymentStageDto: CreatePaymentStageDto) {
    return this.accountsService.createPaymentStage(createPaymentStageDto);
  }

  @Patch('payment-stages/:id')
  async updatePaymentStage(@Param('id') id: string, @Body() updatePaymentStageDto: UpdatePaymentStageDto) {
    return this.accountsService.updatePaymentStage(id, updatePaymentStageDto);
  }
}
