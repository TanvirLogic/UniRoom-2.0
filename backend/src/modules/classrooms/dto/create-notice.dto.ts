import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateNoticeDto {
  @ApiProperty({ example: 'CSE-412', description: 'Course code for the classroom' })
  @IsString()
  @IsNotEmpty()
  courseCode: string;

  @ApiProperty({ example: 'Midterm Syllabus & Date', description: 'Title/Subject of the notice' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'Midterm exam covering chapters 1 through 4.', description: 'Content body of the notice' })
  @IsString()
  @IsNotEmpty()
  content: string;

  @ApiPropertyOptional({ example: 'Batch 61 (D)', description: 'Target cohort label or All Cohorts' })
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
