import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';
import { DayOfWeek } from '@prisma/client';

export class CreateUniversityDto {
  @ApiProperty({ example: 'Uttara University', description: 'Full name of the university' })
  @IsString()
  @IsNotEmpty({ message: 'University name is required' })
  name!: string;

  @ApiProperty({ example: 'UU', description: 'Unique university abbreviation code' })
  @IsString()
  @IsNotEmpty({ message: 'University code is required' })
  code!: string;

  @ApiPropertyOptional({ example: 'uttara.edu.bd', description: 'Institutional email domain' })
  @IsOptional()
  @IsString()
  domain?: string;

  @ApiPropertyOptional({ example: 'https://example.com/logo.png', description: 'University logo URL' })
  @IsOptional()
  @IsString()
  logoUrl?: string;

  @ApiPropertyOptional({
    enum: DayOfWeek,
    isArray: true,
    example: [DayOfWeek.MON, DayOfWeek.TUE, DayOfWeek.WED, DayOfWeek.THU],
    description: 'Weekly operating class days',
  })
  @IsOptional()
  @IsArray()
  @IsEnum(DayOfWeek, { each: true, message: 'Each day must be a valid DayOfWeek enum' })
  operatingDays?: DayOfWeek[];

  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
