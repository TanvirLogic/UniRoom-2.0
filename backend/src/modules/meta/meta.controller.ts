import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { MetaService } from './meta.service';
import {
  CreateAcademicBatchDto,
  UniversityCohortTreeDto,
} from './dto/create-batch.dto';
import { UpdateAcademicBatchDto } from './dto/update-batch.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@ApiTags('Institutional Metadata & Cohort Management')
@Controller()
export class MetaController {
  constructor(private readonly metaService: MetaService) {}

  /// 1. Public Registration Metadata
  @Get('meta/registration-options')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get active universities, departments, batches, and sections for client registration dropdowns',
  })
  @ApiResponse({
    status: 200,
    description: 'Hierarchical tree of active universities, departments, batches and sections',
  })
  async getRegistrationOptions() {
    return this.metaService.getRegistrationOptions();
  }

  /// 2. Super Admin: List Batches & Sections
  @Get('admin/batches')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Super Admin: List academic batches and sections by university & department',
  })
  @ApiQuery({ name: 'university', required: false, description: 'University code (e.g. UU) or UUID' })
  @ApiQuery({ name: 'department', required: false, description: 'Department code (e.g. CSE) or UUID' })
  @ApiQuery({ name: 'departmentId', required: false, description: 'Direct Department UUID' })
  async getAdminBatches(
    @Query('university') university?: string,
    @Query('department') department?: string,
    @Query('departmentId') departmentId?: string,
  ) {
    return this.metaService.getAdminBatches({ university, department, departmentId });
  }

  /// 3. Super Admin: Get Single Batch by ID
  @Get('admin/batches/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Get details of an academic batch by ID' })
  @ApiResponse({ status: 200, description: 'Academic batch found' })
  @ApiResponse({ status: 404, description: 'Academic batch not found' })
  async getBatchById(@Param('id') id: string) {
    return this.metaService.getBatchById(id);
  }

  /// 4. Super Admin: Easy Hierarchical Batch Insertion / Upsert
  @Post('admin/batches')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Super Admin: Insert/Upsert batches under a university and department',
    description: `Supports insertion in an intuitive hierarchy:
    university -> department -> list of batches with their sections.
    Accepts university & department by code (e.g. "UU" and "CSE") or UUIDs!`,
  })
  @ApiResponse({ status: 201, description: 'Academic batches created/upserted successfully' })
  async createBatch(@Body() dto: CreateAcademicBatchDto) {
    return this.metaService.createOrUpsertBatch(dto);
  }

  /// 4. Super Admin: Full University Cohort Tree Sync
  @Post('admin/batches/university-tree')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Super Admin: Bulk insert/upsert all departments and batches for an entire university in 1 call',
    description: `Payload structure:
    {
      "university": "UU",
      "departments": [
        {
          "department": "CSE",
          "batches": [
            { "name": "68", "sections": ["A", "B", "C"] },
            { "name": "69", "sections": ["A", "B"] }
          ]
        },
        {
          "department": "EEE",
          "batches": [
            { "name": "64", "sections": ["A"] }
          ]
        }
      ]
    }`,
  })
  @ApiResponse({ status: 201, description: 'University cohort tree synced successfully' })
  async syncUniversityTree(@Body() dto: UniversityCohortTreeDto) {
    return this.metaService.syncUniversityCohortTree(dto);
  }

  /// 5. Super Admin: Update Batch or Sections
  @Put('admin/batches/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Update active sections or status of an academic batch' })
  async updateBatch(@Param('id') id: string, @Body() dto: UpdateAcademicBatchDto) {
    return this.metaService.updateBatch(id, dto);
  }

  /// 6. Super Admin: Delete an Academic Batch
  @Delete('admin/batches/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Delete an academic batch' })
  async deleteBatch(@Param('id') id: string) {
    return this.metaService.deleteBatch(id);
  }
}
