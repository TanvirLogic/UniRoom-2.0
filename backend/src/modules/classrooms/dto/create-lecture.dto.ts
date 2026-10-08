import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateLectureDto {
  @ApiProperty({ example: 'CSE-412', description: 'Course code for the classroom' })
  @IsString()
  @IsNotEmpty()
  courseCode: string;

  @ApiPropertyOptional({ example: 'Lecture 01', description: 'Lecture serial or number' })
  @IsString()
  @IsOptional()
  lectureNumber?: string;

  @ApiProperty({ example: 'Design Patterns & Clean Architecture', description: 'Topic / Title of the lecture' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ example: 'Oct 8, 2026', description: 'Lecture date string' })
  @IsString()
  @IsOptional()
  date?: string;

  @ApiPropertyOptional({ example: 'Discussed singleton, builder, and factory patterns.', description: 'Topics covered & summary' })
  @IsString()
  @IsOptional()
  topics?: string;

  @ApiPropertyOptional({ example: 'https://drive.google.com/...', description: 'Resource slides / material link' })
  @IsString()
  @IsOptional()
  link?: string;

  @ApiPropertyOptional({ example: 'Batch 61 (D)', description: 'Target batch & section label or All Sections' })
  @IsString()
  @IsOptional()
  targetCohort?: string;

  @ApiPropertyOptional({ example: 'CSE', description: 'Department code' })
  @IsString()
  @IsOptional()
  department?: string;

  @ApiPropertyOptional({ example: '61', description: 'Batch number' })
  @IsString()
  @IsOptional()
  batch?: string;

  @ApiPropertyOptional({ example: 'D', description: 'Section letter' })
  @IsString()
  @IsOptional()
  section?: string;
}
