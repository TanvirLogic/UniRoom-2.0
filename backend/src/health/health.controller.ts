import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('Health & Diagnostics')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'System & Database Health Check' })
  @ApiResponse({ status: 200, description: 'Service and database are operational' })
  async checkHealth() {
    // Ping the Neon PostgreSQL database
    await this.prisma.$queryRaw`SELECT 1`;

    const universityCount = await this.prisma.university.count();
    const roomCount = await this.prisma.room.count();
    const slotCount = await this.prisma.scheduleSlot.count();

    return {
      status: 'ok',
      service: 'UniRoom-Live 2.0 Backend',
      database: 'PostgreSQL (Neon Serverless)',
      stats: {
        universities: universityCount,
        rooms: roomCount,
        scheduleSlots: slotCount,
      },
    };
  }
}
