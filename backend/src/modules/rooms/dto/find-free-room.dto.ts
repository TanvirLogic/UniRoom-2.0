import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class FindFreeRoomDto {
  @ApiPropertyOptional({ description: 'Filter by Department ID or Code (defaults to user department)' })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({
    example: 60,
    default: 60,
    description: 'Required free duration in minutes (15 to 240)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(15)
  @Max(240)
  durationMinutes: number = 60;

  @ApiPropertyOptional({ example: 40, description: 'Minimum seating capacity needed' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  minCapacity?: number;

  @ApiPropertyOptional({ description: 'Filter by Building ID' })
  @IsOptional()
  @IsString()
  buildingId?: string;

  @ApiPropertyOptional({ example: 5, description: 'Filter by floor level' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  floor?: number;

  @ApiPropertyOptional({
    example: '11:25',
    description: 'Start time in 24-hour HH:mm format. Defaults to current local time.',
  })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'startTime must be in 24-hour HH:mm format (e.g. 09:30 or 14:15)',
  })
  startTime?: string;

  @ApiPropertyOptional({
    example: '2026-09-24',
    description: 'Date in YYYY-MM-DD format. Defaults to today.',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'date must be in YYYY-MM-DD format (e.g. 2026-09-24)',
  })
  date?: string;
}
