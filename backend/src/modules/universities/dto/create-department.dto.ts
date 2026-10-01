import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateDepartmentDto {
  @ApiPropertyOptional({ example: 'UU', description: 'University ID or readable code (e.g. "UU")' })
  @IsOptional()
  @IsString({ message: 'University identifier must be a string' })
  university?: string;

  @ApiPropertyOptional({ example: 'UU', description: 'University ID fallback' })
  @IsOptional()
  @IsString({ message: 'University ID must be a string' })
  universityId?: string;

  @ApiProperty({ example: 'Computer Science & Engineering', description: 'Full department name' })
  @IsString()
  @IsNotEmpty({ message: 'Department name is required' })
  name!: string;

  @ApiProperty({ example: 'CSE', description: 'Department short code' })
  @IsString()
  @IsNotEmpty({ message: 'Department code is required' })
  code!: string;
}
