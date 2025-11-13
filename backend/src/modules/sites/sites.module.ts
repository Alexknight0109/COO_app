import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SitesController } from './sites.controller';
import { SitesService } from './sites.service';
import { Site } from '../../entities/site.entity';
import { SiteLog } from '../../entities/site-log.entity';
import { InstallationStage } from '../../entities/installation-stage.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Site, SiteLog, InstallationStage])],
  controllers: [SitesController],
  providers: [SitesService],
  exports: [SitesService],
})
export class SitesModule {}
