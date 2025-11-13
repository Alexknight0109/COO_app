import { Controller, Get, Param, Patch, Body, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { User } from '../../entities/user.entity';

@Controller('users')
// @UseGuards(AuthGuard('jwt')) // Commented out for now to allow testing without auth
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  async findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() userData: Partial<User>) {
    return this.usersService.update(id, userData);
  }
}
