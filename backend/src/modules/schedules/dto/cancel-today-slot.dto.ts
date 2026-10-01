import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CancelTodaySlotDto {
  @ApiPropertyOptional({
    description: 'Specific date for the cancellation override in YYYY-MM-DD format (defaults to current server date)',
    example: '2026-09-30',
  })
  @IsOptional()
  @IsString()
  date?: string;

  @ApiProperty({
    description: 'Reason for the cancellation notified by the faculty member or department',
    example: 'Faculty notified he will not be taking today class due to illness',
  })
  @IsNotEmpty()
  @IsString()
  reason: string;

  @ApiPropertyOptional({
    description: 'Whether to immediately free up the physical classroom to AVAILABLE in the live room engine',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  freeRoom?: boolean;
}
