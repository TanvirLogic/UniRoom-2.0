import { Controller, Get, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../modules/email/email.service';
import { PushNotificationService } from '../modules/notifications/push-notification.service';

class TestEmailDto {
  @ApiProperty({ example: 'admin@uttara.edu.bd', description: 'Target email address for test message' })
  @IsNotEmpty()
  @IsEmail()
  email!: string;
}

class TestPushDto {
  @ApiProperty({ example: 'test_channel', required: false, description: 'FCM topic name to broadcast to' })
  @IsOptional()
  @IsString()
  topic?: string;

  @ApiProperty({ example: '', required: false, description: 'Direct device token' })
  @IsOptional()
  @IsString()
  token?: string;

  @ApiProperty({ example: 'Test Notification', required: false })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiProperty({ example: 'Testing push delivery from UniRoom-Live 2.0', required: false })
  @IsOptional()
  @IsString()
  body?: string;
}

@ApiTags('Health & Diagnostics')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'System, Database, Email & Push Notification Health Status' })
  @ApiResponse({ status: 200, description: 'Operational telemetry across services' })
  async checkHealth() {
    // Ping the Neon PostgreSQL database
    let dbStatus = 'connected';
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch (e: any) {
      dbStatus = `disconnected: ${e.message}`;
    }

    const universityCount = await this.prisma.university.count().catch(() => 0);
    const roomCount = await this.prisma.room.count().catch(() => 0);
    const slotCount = await this.prisma.scheduleSlot.count().catch(() => 0);

    const emailStatus = this.emailService.getStatus();
    const pushStatus = this.pushNotificationService.getStatus();

    return {
      status: 'ok',
      service: 'UniRoom-Live 2.0 Backend',
      database: {
        status: dbStatus,
        provider: 'PostgreSQL (Neon Serverless)',
        stats: {
          universities: universityCount,
          rooms: roomCount,
          scheduleSlots: slotCount,
        },
      },
      email: emailStatus,
      pushNotifications: pushStatus,
      timestamp: new Date().toISOString(),
    };
  }

  @Get('diagnostics')
  @ApiOperation({ summary: 'Run deep live diagnostics on SMTP Mail Server and Firebase Admin SDK' })
  async runDiagnostics() {
    const emailVerify = await this.emailService.verifyConnection();
    const pushStatus = this.pushNotificationService.getStatus();

    return {
      service: 'UniRoom-Live 2.0',
      timestamp: new Date().toISOString(),
      email: {
        ...this.emailService.getStatus(),
        verification: emailVerify,
      },
      pushNotifications: {
        ...pushStatus,
      },
    };
  }

  @Post('test-email')
  @ApiOperation({ summary: 'Send a live test email to verify SMTP delivery' })
  async sendTestEmail(@Body() dto: TestEmailDto) {
    if (!dto.email || !dto.email.includes('@')) {
      return {
        success: false,
        message: 'A valid email address is required.',
      };
    }
    return this.emailService.sendTestEmail(dto.email);
  }

  @Post('test-push')
  @ApiOperation({ summary: 'Send a live test push notification to verify FCM delivery' })
  async sendTestPush(@Body() dto: TestPushDto) {
    return this.pushNotificationService.sendTestNotification({
      topic: dto.topic,
      token: dto.token,
      title: dto.title,
      body: dto.body,
    });
  }
}
