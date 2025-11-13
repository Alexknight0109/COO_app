import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
} from '@nestjs/common';
import { SitesService } from './sites.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { UpdateSiteDto } from './dto/update-site.dto';
import { CreateSiteLogDto } from './dto/create-site-log.dto';

@Controller('sites')
export class SitesController {
  constructor(private readonly sitesService: SitesService) {}

  @Get()
  async findAll() {
    return this.sitesService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.sitesService.findOne(id);
  }

  @Post()
  async create(@Body() createSiteDto: CreateSiteDto) {
    return this.sitesService.create(createSiteDto);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateSiteDto: UpdateSiteDto,
  ) {
    return this.sitesService.update(id, updateSiteDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.sitesService.remove(id);
  }

  @Get(':id/logs')
  async getLogs(@Param('id') id: string) {
    return this.sitesService.getLogs(id);
  }

  @Post('logs')
  async createLog(@Body() createSiteLogDto: CreateSiteLogDto) {
    return this.sitesService.createLog(createSiteLogDto);
  }
}
