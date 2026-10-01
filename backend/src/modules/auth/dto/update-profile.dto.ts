import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Length, Matches } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Tanvir Hossain', description: 'User full display name' })
  @IsOptional()
  @IsString()
  @Length(2, 70, { message: 'fullName must be between 2 and 70 characters' })
  fullName?: string;

  @ApiPropertyOptional({ example: '2241081422', description: 'Student roll or registration ID' })
  @IsOptional()
  @IsString()
  @Length(3, 30)
  studentId?: string;

  @ApiPropertyOptional({
    example: '8d3b43bb-3db4-44a6-b91a-c614327aa61a',
    description: 'Target department UUID or code',
  })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ example: '68', description: 'Academic batch (e.g. 68)' })
  @IsOptional()
  @IsString()
  batch?: string;

  @ApiPropertyOptional({ example: 'A', description: 'Cohort section (e.g. A, B, C)' })
  @IsOptional()
  @IsString()
  @Length(1, 5)
  section?: string;

  @ApiPropertyOptional({ example: 'DNS', description: 'Faculty teacher code initials' })
  @IsOptional()
  @IsString()
  @Matches(/^[A-Z]{2,6}$/, { message: 'facultyId must be 2 to 6 uppercase letters (e.g. DNS)' })
  facultyId?: string;
}
