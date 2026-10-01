import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { EmailModule } from './modules/email/email.module';
import { MetaModule } from './modules/meta/meta.module';
import { UniversitiesModule } from './modules/universities/universities.module';
import { RoomsModule } from './modules/rooms/rooms.module';
import { SchedulesModule } from './modules/schedules/schedules.module';
import { NotificationsModule } from './modules/notifications/notifications.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    HealthModule,
    EmailModule,
    NotificationsModule,
    AuthModule,
    MetaModule,
    UniversitiesModule,
    RoomsModule,
    SchedulesModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
