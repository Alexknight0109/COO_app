import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findAll() {
    return this.usersRepository.find({
      relations: ['department'],
    });
  }

  async findOne(id: string) {
    return this.usersRepository.findOne({
      where: { id },
      relations: ['department'],
    });
  }

  async findByEmail(email: string) {
    return this.usersRepository.findOne({ where: { email } });
  }

  async update(id: string, userData: Partial<User>) {
    await this.usersRepository.update(id, userData);
    return this.findOne(id);
  }
}
