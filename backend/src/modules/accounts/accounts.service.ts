import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Account } from '../../entities/account.entity';
import { PaymentStage } from '../../entities/payment-stage.entity';
import { CreateAccountDto } from './dto/create-account.dto';
import { UpdateAccountDto } from './dto/update-account.dto';
import { CreatePaymentStageDto } from './dto/create-payment-stage.dto';
import { UpdatePaymentStageDto } from './dto/update-payment-stage.dto';

@Injectable()
export class AccountsService {
  constructor(
    @InjectRepository(Account)
    private accountsRepository: Repository<Account>,
    @InjectRepository(PaymentStage)
    private paymentStagesRepository: Repository<PaymentStage>,
  ) {}

  async findAll() {
    return this.accountsRepository.find({
      relations: ['project', 'paymentStages'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string) {
    return this.accountsRepository.findOne({
      where: { id },
      relations: ['project', 'paymentStages'],
    });
  }

  async create(createAccountDto: CreateAccountDto) {
    const account = this.accountsRepository.create(createAccountDto);
    return this.accountsRepository.save(account);
  }

  async update(id: string, updateAccountDto: UpdateAccountDto) {
    await this.accountsRepository.update(id, updateAccountDto);
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.accountsRepository.delete(id);
    return { message: 'Account deleted successfully' };
  }

  async getPaymentStages(accountId: string) {
    return this.paymentStagesRepository.find({
      where: { accountId },
      order: { dueDate: 'ASC' },
    });
  }

  async createPaymentStage(createPaymentStageDto: CreatePaymentStageDto) {
    const stage = this.paymentStagesRepository.create(createPaymentStageDto);
    return this.paymentStagesRepository.save(stage);
  }

  async updatePaymentStage(id: string, updatePaymentStageDto: UpdatePaymentStageDto) {
    await this.paymentStagesRepository.update(id, updatePaymentStageDto);
    return this.paymentStagesRepository.findOne({ where: { id } });
  }
}
