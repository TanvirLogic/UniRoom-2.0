import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { ClassroomsService } from './classrooms.service';
import { CreateNoticeDto } from './dto/create-notice.dto';
import { CreateLectureDto } from './dto/create-lecture.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Classrooms')
@Controller('classrooms')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class ClassroomsController {
  constructor(private readonly classroomsService: ClassroomsService) {}

  @Post('notices')
  @ApiOperation({
    summary: 'Publish a new classroom notice and trigger FCM push notifications to students',
  })
  @ApiResponse({ status: 201, description: 'Notice published and push notifications dispatched' })
  async createNotice(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateNoticeDto,
  ) {
    return this.classroomsService.createNotice(userId, dto);
  }

  @Get('notices')
  @ApiOperation({ summary: 'Get all published notices for a course classroom' })
  @ApiQuery({ name: 'courseCode', required: true, example: 'CSE-412' })
  @ApiQuery({ name: 'department', required: false, example: 'CSE' })
  @ApiQuery({ name: 'batch', required: false, example: '61' })
  @ApiQuery({ name: 'section', required: false, example: 'D' })
  @ApiResponse({ status: 200, description: 'List of notices for the specified course' })
  async getNotices(
    @Query('courseCode') courseCode: string,
    @Query('department') department?: string,
    @Query('batch') batch?: string,
    @Query('section') section?: string,
  ) {
    return this.classroomsService.getNotices({
      courseCode: courseCode || '',
      department,
      batch,
      section,
    });
  }

  @Delete('notices/:id')
  @ApiOperation({ summary: 'Delete a classroom notice' })
  @ApiResponse({ status: 200, description: 'Notice deleted successfully' })
  async deleteNotice(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.classroomsService.deleteNotice(userId, id);
  }

  @Post('lectures')
  @ApiOperation({
    summary: 'Publish a new classroom lecture material and trigger FCM push notifications to students',
  })
  @ApiResponse({ status: 201, description: 'Lecture published and push notifications dispatched' })
  async createLecture(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateLectureDto,
  ) {
    return this.classroomsService.createLecture(userId, dto);
  }

  @Get('lectures')
  @ApiOperation({ summary: 'Get all published lecture materials for a course classroom' })
  @ApiQuery({ name: 'courseCode', required: true, example: 'CSE-412' })
  @ApiQuery({ name: 'department', required: false, example: 'CSE' })
  @ApiQuery({ name: 'batch', required: false, example: '61' })
  @ApiQuery({ name: 'section', required: false, example: 'D' })
  @ApiResponse({ status: 200, description: 'List of lecture materials for the specified course' })
  async getLectures(
    @Query('courseCode') courseCode: string,
    @Query('department') department?: string,
    @Query('batch') batch?: string,
    @Query('section') section?: string,
  ) {
    return this.classroomsService.getLectures({
      courseCode: courseCode || '',
      department,
      batch,
      section,
    });
  }

  @Delete('lectures/:id')
  @ApiOperation({ summary: 'Delete a classroom lecture material' })
  @ApiResponse({ status: 200, description: 'Lecture deleted successfully' })
  async deleteLecture(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.classroomsService.deleteLecture(userId, id);
  }
}
