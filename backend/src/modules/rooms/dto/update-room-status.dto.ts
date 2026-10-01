import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { RoomStatus } from '@prisma/client';

export class UpdateRoomStatusDto {
  @ApiProperty({
    enum: RoomStatus,
    example: RoomStatus.RESERVED,
    description: 'New real-time status of the room',
  })
  @IsEnum(RoomStatus, { message: 'status must be a valid RoomStatus enum' })
  @IsNotEmpty({ message: 'status is required' })
  status!: RoomStatus;

  @ApiProperty({
    example: 1,
    description:
      'Current optimistic concurrency version of the room. Must match the latest database version.',
  })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsNotEmpty({ message: 'version is required for Optimistic Concurrency Control (OCC)' })
  version!: number;

  @ApiPropertyOptional({
    example: 'Reserved for Batch 68 Algorithms Extra Class',
    description: 'Reason or note for audit logging',
  })
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional({ example: 'Algorithms (CSE06131)' })
  @IsOptional()
  @IsString()
  currentCourse?: string;

  @ApiPropertyOptional({ example: 'DNS' })
  @IsOptional()
  @IsString()
  currentTeacher?: string;

  @ApiPropertyOptional({ example: '68' })
  @IsOptional()
  @IsString()
  currentBatch?: string;

  @ApiPropertyOptional({
    example: 60,
    description: 'Lease duration in minutes. Automatically sets leaseExpiresAt = now + duration.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(5)
  leaseDurationMinutes?: number;
}
