import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Query,
  Param,
  Headers,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { SchedulesService } from './schedules.service';
import { RoutineParserService } from './services/routine-parser.service';
import { IngestRoutineDto } from './dto/ingest-routine.dto';
import { CancelTodaySlotDto } from './dto/cancel-today-slot.dto';
import { RescheduleTodaySlotDto } from './dto/reschedule-today-slot.dto';
import { CurrentUser, JwtPayload } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role, DayOfWeek } from '@prisma/client';

@ApiTags('Schedules & Routine Ingestion')
@Controller()
export class SchedulesController {
  constructor(
    private readonly schedulesService: SchedulesService,
    private readonly routineParserService: RoutineParserService,
  ) {}

  /**
   * 1. Mode A: Parse Timetable File (PDF / Image) using AI Multimodal Document Parser
   */
  @Post('admin/schedules/parse-file')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Parse timetable PDF or Image into structured slots using AI' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        university: { type: 'string', default: 'UU' },
        department: { type: 'string', default: 'CSE' },
      },
    },
  })
  @UseInterceptors(FileInterceptor('file'))
  async parseRoutineFile(
    @UploadedFile() file: { buffer: Buffer; mimetype: string; originalname?: string },
    @Body('university') university?: string,
    @Body('department') department?: string,
    @Headers('x-gemini-key') customApiKey?: string,
  ) {
    if (!file) {
      throw new BadRequestException('Timetable file (PDF or Image) is required.');
    }

    const parsed = await this.routineParserService.parseDocument(
      file.buffer,
      file.mimetype,
      university || 'UU',
      department || 'CSE',
      customApiKey,
    );

    // Automatically run pre-flight collision checks on the extracted slots
    const validation = await this.schedulesService.validateRoutine(parsed);

    return {
      parsedRoutine: parsed,
      validationReport: validation,
    };
  }

  /**
   * 2. Pre-Flight Mathematical Collision & Overlap Validator
   */
  @Post('admin/schedules/validate')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Validate routine slots and calculate timetable collisions' })
  async validateRoutine(@Body() dto: IngestRoutineDto) {
    return this.schedulesService.validateRoutine(dto);
  }

  /**
   * 3. Atomic Database Routine Ingestion
   */
  @Post('admin/schedules/ingest')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Ingest and activate routine in single atomic transaction' })
  async ingestRoutine(@Body() dto: IngestRoutineDto) {
    return this.schedulesService.ingestRoutine(dto);
  }

  /**
   * 4. Public / Student Schedule Query Endpoint with Batch, Section, Course filtering
   */
  @Get('schedules')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Query active master schedule slots by department, batch, section, course, day' })
  @ApiQuery({ name: 'university', required: false })
  @ApiQuery({ name: 'department', required: false })
  @ApiQuery({ name: 'batch', required: false })
  @ApiQuery({ name: 'section', required: false })
  @ApiQuery({ name: 'courseCode', required: false })
  @ApiQuery({ name: 'dayOfWeek', enum: DayOfWeek, required: false })
  @ApiQuery({ name: 'roomId', required: false })
  @ApiQuery({ name: 'facultyCode', required: false })
  @ApiQuery({ name: 'date', required: false, description: 'Target date (YYYY-MM-DD) for calculating daily overrides' })
  async getSchedules(
    @Query('university') university?: string,
    @Query('department') department?: string,
    @Query('batch') batch?: string,
    @Query('section') section?: string,
    @Query('courseCode') courseCode?: string,
    @Query('dayOfWeek') dayOfWeek?: DayOfWeek,
    @Query('roomId') roomId?: string,
    @Query('facultyCode') facultyCode?: string,
    @Query('date') date?: string,
  ) {
    return this.schedulesService.getSchedules({
      university,
      department,
      batch,
      section,
      courseCode,
      dayOfWeek,
      roomId,
      facultyCode,
      date,
    });
  }

  /**
   * 5. Cancel Today's Class (CR / Faculty / Admin Emergency Control)
   */
  @Post('schedules/slots/:id/cancel-today')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.FACULTY, Role.CR)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Cancel a class slot for today only (CR, Faculty, Admin)',
    description: 'Marks slot cancelled for today, optionally frees physical room, and alerts students via push notification.',
  })
  async cancelTodaySlot(
    @Param('id') id: string,
    @Body() dto: CancelTodaySlotDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.schedulesService.cancelTodaySlot(id, dto, user);
  }

  /**
   * 6. Reschedule Today's Class Time/Room (CR / Faculty / Admin Emergency Control)
   */
  @Post('schedules/slots/:id/reschedule-today')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.FACULTY, Role.CR)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Reschedule a class time or room for today only (CR, Faculty, Admin)',
    description: 'Shifts slot timing or room for today only and alerts students via push notification.',
  })
  async rescheduleTodaySlot(
    @Param('id') id: string,
    @Body() dto: RescheduleTodaySlotDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.schedulesService.rescheduleTodaySlot(id, dto, user);
  }

  /**
   * 7. Undo / Revert Today's Override (CR / Faculty / Admin)
   */
  @Delete('schedules/slots/:id/override-today')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.FACULTY, Role.CR)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Undo or revert today schedule override (CR, Faculty, Admin)',
    description: 'Removes cancellation or reschedule override and restores normal routine.',
  })
  async undoTodayOverride(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.schedulesService.undoTodayOverride(id, user);
  }

  /**
   * 5. Clear Department Schedules
   */
  @Delete('admin/schedules')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Clear all schedule slots for a department' })
  @ApiQuery({ name: 'university', required: true })
  @ApiQuery({ name: 'department', required: true })
  async deleteDepartmentSchedules(
    @Query('university') university: string,
    @Query('department') department: string,
  ) {
    return this.schedulesService.deleteDepartmentSchedules(university, department);
  }

  /**
   * 6. Delete a Single Schedule Slot (Routine Maintenance)
   */
  @Delete('admin/schedules/slot/:id')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Super Admin: Delete an individual schedule slot for routine maintenance' })
  async deleteScheduleSlot(@Param('id') id: string) {
    return this.schedulesService.deleteScheduleSlot(id);
  }
}
