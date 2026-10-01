import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DayOfWeek } from '@prisma/client';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class RoutineSlotDto {
  @ApiProperty({ enum: DayOfWeek, example: 'MON', description: 'Day of week (MON, TUE, WED, THU, FRI, SAT, SUN)' })
  @IsEnum(DayOfWeek, { message: 'dayOfWeek must be one of MON, TUE, WED, THU, FRI, SAT, SUN' })
  dayOfWeek!: DayOfWeek;

  @ApiProperty({ example: '08:45', description: 'Start time in 24-hr format (HH:mm)' })
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'startTime must be in 24-hour format HH:mm' })
  startTime!: string;

  @ApiProperty({ example: '10:05', description: 'End time in 24-hr format (HH:mm)' })
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'endTime must be in 24-hour format HH:mm' })
  endTime!: string;

  @ApiProperty({ example: 'AI Lab 5210 (514)', description: 'Physical classroom or laboratory identifier' })
  @IsString()
  @IsNotEmpty({ message: 'roomNumber is required' })
  roomNumber!: string;

  @ApiPropertyOptional({ example: 'Building B', description: 'Campus building name' })
  @IsOptional()
  @IsString()
  buildingName?: string;

  @ApiPropertyOptional({ example: 'Permanent Campus', description: 'Campus title' })
  @IsOptional()
  @IsString()
  campusName?: string;

  @ApiProperty({ example: 'CSE06131', description: 'Academic course code' })
  @IsString()
  @IsNotEmpty({ message: 'courseCode is required' })
  courseCode!: string;

  @ApiProperty({ example: 'Data Structures & Algorithms', description: 'Course title' })
  @IsString()
  @IsNotEmpty({ message: 'courseName is required' })
  courseName!: string;

  @ApiProperty({ example: '68', description: 'Academic student batch / cohort' })
  @IsString()
  @IsNotEmpty({ message: 'batch is required' })
  batch!: string;

  @ApiProperty({ example: 'A', description: 'Section identifier' })
  @IsString()
  @IsNotEmpty({ message: 'section is required' })
  section!: string;

  @ApiProperty({ example: 'DNS', description: 'Faculty initials or institutional code' })
  @IsString()
  @IsNotEmpty({ message: 'facultyCode is required' })
  facultyCode!: string;
}

export class IngestRoutineDto {
  @ApiProperty({ example: 'UU', description: 'University code or UUID' })
  @IsString()
  @IsNotEmpty({ message: 'university is required' })
  university!: string;

  @ApiProperty({ example: 'CSE', description: 'Department code or UUID' })
  @IsString()
  @IsNotEmpty({ message: 'department is required' })
  department!: string;

  @ApiPropertyOptional({ example: 'Fall 2026', description: 'Academic semester' })
  @IsOptional()
  @IsString()
  semester?: string;

  @ApiPropertyOptional({ description: 'Operating days' })
  @IsOptional()
  @IsArray()
  operatingDays?: string[];

  @ApiPropertyOptional({ description: 'Configured period time slots' })
  @IsOptional()
  @IsArray()
  periodTimeSlots?: any[];

  @ApiProperty({ type: [RoutineSlotDto], description: 'List of weekly class schedule slots' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RoutineSlotDto)
  slots!: RoutineSlotDto[];
}
