import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, Matches } from 'class-validator';

export class RescheduleTodaySlotDto {
  @ApiPropertyOptional({
    description: 'Specific date for the reschedule override in YYYY-MM-DD format (defaults to current server date)',
    example: '2026-09-30',
  })
  @IsOptional()
  @IsString()
  date?: string;

  @ApiProperty({
    description: 'New start time in 24-hour HH:mm format for today only',
    example: '14:00',
  })
  @IsNotEmpty()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'newStartTime must be in valid HH:mm format (e.g. 14:00)',
  })
  newStartTime: string;

  @ApiProperty({
    description: 'New end time in 24-hour HH:mm format for today only',
    example: '15:30',
  })
  @IsNotEmpty()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'newEndTime must be in valid HH:mm format (e.g. 15:30)',
  })
  newEndTime: string;

  @ApiPropertyOptional({
    description: 'Optional new room ID or room number for today (if omitted, keeps current assigned room)',
    example: '5028',
  })
  @IsOptional()
  @IsString()
  newRoomId?: string;

  @ApiProperty({
    description: 'Reason for changing class timing for today',
    example: 'Faculty requested afternoon shift due to morning department meeting',
  })
  @IsNotEmpty()
  @IsString()
  reason: string;
}
