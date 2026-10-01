import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
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
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../common/decorators/current-user.decorator';
import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { UpdateRoomStatusDto } from './dto/update-room-status.dto';
import { QueryRoomsDto } from './dto/query-rooms.dto';
import { FindFreeRoomDto } from './dto/find-free-room.dto';
import { CreateBuildingDto } from './dto/create-building.dto';
import { UpdateBuildingDto } from './dto/update-building.dto';
import { BookExtraClassDto } from './dto/book-extra-class.dto';

@ApiTags('Campus Physical Assets & Real-Time Rooms Engine')
@Controller()
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  // ---------------------------------------------------------------------------
  // 1. Buildings Endpoints
  // ---------------------------------------------------------------------------

  @Get('buildings')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'List buildings filtered by department or university' })
  @ApiQuery({ name: 'departmentId', required: false, type: String })
  @ApiQuery({ name: 'universityId', required: false, type: String })
  async getBuildings(
    @Query('departmentId') departmentId?: string,
    @Query('universityId') universityId?: string,
  ) {
    return this.roomsService.getBuildings(departmentId, universityId);
  }

  @Get('buildings/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get details and rooms of a specific building' })
  async getBuildingById(@Param('id') id: string) {
    return this.roomsService.getBuildingById(id);
  }

  @Post('admin/buildings')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a new campus building (Super Admin only)' })
  async createBuilding(@Body() dto: CreateBuildingDto) {
    return this.roomsService.createBuilding(dto);
  }

  @Put('admin/buildings/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update a campus building (Super Admin only)' })
  async updateBuilding(
    @Param('id') id: string,
    @Body() dto: UpdateBuildingDto,
  ) {
    return this.roomsService.updateBuilding(id, dto);
  }

  @Delete('admin/buildings/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Delete a campus building (Super Admin only)' })
  async deleteBuilding(@Param('id') id: string) {
    return this.roomsService.deleteBuilding(id);
  }

  // ---------------------------------------------------------------------------
  // 2. Real-Time Room Availability & 1-Tap Algorithm
  // ---------------------------------------------------------------------------

  @Get('rooms/free-now')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: '1-Tap "Find Me a Free Room Now" Algorithmic Engine',
    description:
      'Calculates interval overlaps with master routine and daily overrides to rank top free rooms.',
  })
  @ApiResponse({ status: 200, description: 'Ranked list of available rooms returned' })
  async findFreeRoomsNow(
    @Query() dto: FindFreeRoomDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.roomsService.findFreeRoomsNow(dto, user);
  }

  @Get('rooms')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Query all rooms with status filtering, search, and pagination',
    description:
      'High-performance endpoint with aggregated counts (available, running, reserved, maintenance).',
  })
  async getRooms(
    @Query() query: QueryRoomsDto,
    @CurrentUser() user?: JwtPayload,
  ) {
    return this.roomsService.getRooms(query, user);
  }

  @Get('rooms/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Get detailed room information, schedule, and recent logs' })
  async getRoomById(@Param('id') id: string) {
    return this.roomsService.getRoomById(id);
  }

  @Get('rooms/:id/logs')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get audit logs and status change history for a room' })
  async getRoomLogs(
    @Param('id') id: string,
    @Query('limit') limit?: number,
  ) {
    return this.roomsService.getRoomLogs(id, limit ? Number(limit) : 20);
  }

  @Patch('rooms/:id/status')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.FACULTY, Role.CR)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Update room status with Optimistic Concurrency Control (OCC)',
    description:
      'Requires current version number to prevent race-condition double-booking. Audited to room_logs.',
  })
  @ApiResponse({ status: 200, description: 'Room status updated and audit logged' })
  @ApiResponse({ status: 409, description: 'OCC Conflict: Version mismatch' })
  async updateRoomStatus(
    @Param('id') id: string,
    @Body() dto: UpdateRoomStatusDto,
    @CurrentUser('sub') userId: string,
  ) {
    return this.roomsService.updateRoomStatus(id, dto, userId);
  }

  @Post('rooms/:id/book-extra-class')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.FACULTY, Role.CR)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Book an available room for an extra class and notify all cohort students',
    description:
      'CR or Faculty claims an available room, locks it with OCC, and triggers automatic FCM push notifications to all students in that department, batch, and section.',
  })
  @ApiResponse({ status: 200, description: 'Room booked and push notifications broadcasted' })
  @ApiResponse({ status: 409, description: 'OCC Conflict: Version mismatch' })
  async bookExtraClass(
    @Param('id') id: string,
    @Body() dto: BookExtraClassDto,
    @CurrentUser('sub') userId: string,
  ) {
    return this.roomsService.bookExtraClass(id, dto, userId);
  }

  // ---------------------------------------------------------------------------
  // 3. Super Admin Physical Room CRUD
  // ---------------------------------------------------------------------------

  @Post('admin/rooms')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a new physical room (Super Admin only)' })
  @ApiResponse({ status: 201, description: 'Room created successfully' })
  @ApiResponse({ status: 409, description: 'Room number already exists in building' })
  async createRoom(@Body() dto: CreateRoomDto) {
    return this.roomsService.createRoom(dto);
  }

  @Put('admin/rooms/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update physical room details (Super Admin only)' })
  @ApiResponse({ status: 200, description: 'Room updated successfully' })
  async updateRoom(
    @Param('id') id: string,
    @Body() dto: UpdateRoomDto,
  ) {
    return this.roomsService.updateRoom(id, dto);
  }

  @Delete('admin/rooms/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Delete a physical room (Super Admin only)' })
  @ApiResponse({ status: 200, description: 'Room deleted successfully' })
  async deleteRoom(@Param('id') id: string) {
    return this.roomsService.deleteRoom(id);
  }
}
