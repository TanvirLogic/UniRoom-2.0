import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { SchedulesController } from './schedules.controller';
import { SchedulesService } from './schedules.service';
import { RoutineParserService } from './services/routine-parser.service';

@Module({
  imports: [PrismaModule],
  controllers: [SchedulesController],
  providers: [SchedulesService, RoutineParserService],
  exports: [SchedulesService],
})
export class SchedulesModule {}
