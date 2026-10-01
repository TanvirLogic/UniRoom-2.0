import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UniversitiesService } from './universities.service';
import { CreateUniversityDto } from './dto/create-university.dto';
import { UpdateUniversityDto } from './dto/update-university.dto';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@ApiTags('Institutional Entities: Universities & Departments')
@Controller()
export class UniversitiesController {
  constructor(private readonly universitiesService: UniversitiesService) {}

  // ---------------------------------------------------------------------------
  // Public / General University Endpoints
  // ---------------------------------------------------------------------------

  @Get('universities')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'List all universities (Public)' })
  @ApiQuery({ name: 'onlyActive', required: false, type: Boolean, example: true })
  @ApiResponse({ status: 200, description: 'Universities retrieved successfully' })
  async getUniversities(@Query('onlyActive') onlyActive?: string) {
    const filterActive = onlyActive !== 'false';
    return this.universitiesService.findAllUniversities(filterActive);
  }

  @Get('universities/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get details of a specific university' })
  @ApiResponse({ status: 200, description: 'University found' })
  @ApiResponse({ status: 404, description: 'University not found' })
  async getUniversityById(@Param('id') id: string) {
    return this.universitiesService.findUniversityById(id);
  }

  @Get('universities/:universityId/departments')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get all departments for a given university' })
  @ApiResponse({ status: 200, description: 'Departments retrieved successfully' })
  async getDepartmentsByUniversity(@Param('universityId') universityId: string) {
    return this.universitiesService.getDepartmentsByUniversity(universityId);
  }

  @Get('departments')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'List all academic departments with optional university/search filter' })
  @ApiQuery({ name: 'university', required: false, description: 'Filter by university code (e.g. "UU") or ID' })
  @ApiQuery({ name: 'search', required: false, description: 'Search by department name or code' })
  @ApiResponse({ status: 200, description: 'Departments retrieved successfully' })
  async getDepartments(
    @Query('university') university?: string,
    @Query('search') search?: string,
  ) {
    return this.universitiesService.findAllDepartments({ university, search });
  }

  @Get('departments/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get details of a specific department by ID or Code' })
  @ApiResponse({ status: 200, description: 'Department details retrieved' })
  @ApiResponse({ status: 404, description: 'Department not found' })
  async getDepartmentById(@Param('id') id: string) {
    return this.universitiesService.findDepartmentById(id);
  }

  // ---------------------------------------------------------------------------
  // Super Admin University Endpoints
  // ---------------------------------------------------------------------------

  @Post('admin/universities')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a new university (Super Admin only)' })
  @ApiResponse({ status: 201, description: 'University created successfully' })
  @ApiResponse({ status: 409, description: 'University code already exists' })
  async createUniversity(@Body() dto: CreateUniversityDto) {
    return this.universitiesService.createUniversity(dto);
  }

  @Put('admin/universities/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update university details (Super Admin only)' })
  @ApiResponse({ status: 200, description: 'University updated successfully' })
  async updateUniversity(
    @Param('id') id: string,
    @Body() dto: UpdateUniversityDto,
  ) {
    return this.universitiesService.updateUniversity(id, dto);
  }

  @Delete('admin/universities/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Delete a university and cascade children (Super Admin only)' })
  @ApiResponse({ status: 200, description: 'University deleted successfully' })
  async deleteUniversity(@Param('id') id: string) {
    return this.universitiesService.deleteUniversity(id);
  }

  // ---------------------------------------------------------------------------
  // Super Admin Department Endpoints
  // ---------------------------------------------------------------------------

  @Post('admin/departments')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a new academic department (Super Admin only)' })
  @ApiResponse({ status: 201, description: 'Department created successfully' })
  async createDepartment(@Body() dto: CreateDepartmentDto) {
    return this.universitiesService.createDepartment(dto);
  }

  @Put('admin/departments/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update academic department details (Super Admin only)' })
  @ApiResponse({ status: 200, description: 'Department updated successfully' })
  async updateDepartment(
    @Param('id') id: string,
    @Body() dto: UpdateDepartmentDto,
  ) {
    return this.universitiesService.updateDepartment(id, dto);
  }

  @Delete('admin/departments/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Delete an academic department (Super Admin only)' })
  @ApiResponse({ status: 200, description: 'Department deleted successfully' })
  async deleteDepartment(@Param('id') id: string) {
    return this.universitiesService.deleteDepartment(id);
  }
}
