import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateBuildingDto {
  @ApiProperty({ example: 'CSE', description: 'Department ID or Code' })
  @IsString({ message: 'Department ID must be a string' })
  @IsNotEmpty({ message: 'Department ID is required' })
  departmentId!: string;

  @ApiPropertyOptional({ example: 'Permanent Campus', default: 'Main Campus', description: 'Campus name' })
  @IsOptional()
  @IsString()
  campusName?: string;

  @ApiProperty({ example: 'Building B', description: 'Building name / block' })
  @IsString()
  @IsNotEmpty({ message: 'Building name is required' })
  name!: string;
}
