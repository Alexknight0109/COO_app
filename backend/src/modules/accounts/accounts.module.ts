import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AccountsController } from './accounts.controller';
import { AccountsService } from './accounts.service';
import { Account } from '../../entities/account.entity';
import { PaymentStage } from '../../entities/payment-stage.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Account, PaymentStage])],
  controllers: [AccountsController],
  providers: [AccountsService],
})
export class AccountsModule {}
