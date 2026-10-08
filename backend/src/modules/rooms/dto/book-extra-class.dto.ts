import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';

export class BookExtraClassDto {
  @ApiProperty({ example: 1, description: 'Current room OCC version to prevent double-booking' })
  @IsInt()
  @Min(1)
  version: number;

  @ApiProperty({ example: 'SWE-321 Software Architecture', description: 'Course name or code' })
  @IsString()
  @IsNotEmpty()
  courseName: string;

  @ApiProperty({ example: '68', description: 'Batch number' })
  @IsString()
  @IsNotEmpty()
  batch: string;

  @ApiProperty({ example: 'B', description: 'Section letter or name' })
  @IsString()
  @IsNotEmpty()
  section: string;

  @ApiProperty({ example: 'DNS', required: false, description: 'Faculty initial/code' })
  @IsString()
  @IsOptional()
  teacherInitials?: string;

  @ApiProperty({ example: 90, required: false, description: 'Class duration in minutes' })
  @IsInt()
  @IsOptional()
  durationMinutes?: number;

  @ApiProperty({ example: 'Makeup class for Thursday', required: false })
  @IsString()
  @IsOptional()
  note?: string;

  @ApiProperty({ example: 'CSE', required: false, description: 'Department code' })
  @IsString()
  @IsOptional()
  department?: string;

  @ApiProperty({ example: '11:30', required: false, description: 'Start time in HH:mm format' })
  @IsString()
  @IsOptional()
  startTime?: string;
}
