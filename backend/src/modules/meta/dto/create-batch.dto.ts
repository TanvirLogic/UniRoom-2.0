import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class BatchItemDto {
  @ApiProperty({ example: '68', description: 'Batch name or number (e.g. 68, 69, Spring-24)' })
  @IsString()
  @IsNotEmpty({ message: 'Batch name is required' })
  name!: string;

  @ApiProperty({
    example: ['A', 'B', 'C'],
    description: 'List of active sections in this batch',
  })
  @IsArray()
  @IsString({ each: true, message: 'Each section must be a string' })
  sections!: string[];

  @ApiPropertyOptional({ default: true, description: 'Whether this batch is active' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class CreateAcademicBatchDto {
  @ApiPropertyOptional({
    example: 'UU',
    description: 'University code (e.g. "UU"), university name, or UUID. Helps find the exact department.',
  })
  @IsOptional()
  @IsString()
  university?: string;

  @ApiPropertyOptional({
    example: 'CSE',
    description: 'Department code (e.g. "CSE"), department name, or department UUID.',
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    example: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    description: 'Department UUID (legacy/direct field)',
  })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({
    type: [BatchItemDto],
    description: 'List of batches and their sections under this university and department',
    example: [
      { name: '68', sections: ['A', 'B', 'C'] },
      { name: '69', sections: ['A', 'B'] },
      { name: '70', sections: ['A', 'B', 'C', 'D'] },
    ],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BatchItemDto)
  batches?: BatchItemDto[];

  // Support single-batch direct input for convenience:
  @ApiPropertyOptional({ example: '70', description: 'Batch name (if submitting a single batch)' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    example: ['A', 'B', 'C'],
    description: 'List of active sections (if submitting a single batch)',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  sections?: string[];

  @ApiPropertyOptional({ default: true, description: 'Whether this batch is active' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class DepartmentBatchesDto {
  @ApiProperty({
    example: 'CSE',
    description: 'Department code (e.g. "CSE"), name, or UUID',
  })
  @IsString()
  @IsNotEmpty({ message: 'Department identifier is required' })
  department!: string;

  @ApiProperty({
    type: [BatchItemDto],
    description: 'List of batches and their sections for this department',
    example: [
      { name: '68', sections: ['A', 'B', 'C'] },
      { name: '69', sections: ['A', 'B'] },
    ],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BatchItemDto)
  batches!: BatchItemDto[];
}

export class UniversityCohortTreeDto {
  @ApiProperty({
    example: 'UU',
    description: 'University code (e.g. "UU"), university name, or UUID',
  })
  @IsString()
  @IsNotEmpty({ message: 'University identifier is required' })
  university!: string;

  @ApiProperty({
    type: [DepartmentBatchesDto],
    description: 'List of departments with their batches and sections',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DepartmentBatchesDto)
  departments!: DepartmentBatchesDto[];
}
