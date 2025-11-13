import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HRController } from './hr.controller';
import { HRService } from './hr.service';
import { User } from '../../entities/user.entity';
import { Department } from '../../entities/department.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Department]),
    AuthModule,
  ],
  controllers: [HRController],
  providers: [HRService],
})
export class HRModule {}
