import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { RoomStatus } from '@prisma/client';

export class CreateRoomDto {
  @ApiProperty({ example: 'UU', description: 'University ID or Code' })
  @IsString({ message: 'University ID must be a string' })
  @IsNotEmpty({ message: 'University ID is required' })
  universityId!: string;

  @ApiProperty({ example: 'CSE', description: 'Department ID or Code' })
  @IsString({ message: 'Department ID must be a string' })
  @IsNotEmpty({ message: 'Department ID is required' })
  departmentId!: string;

  @ApiProperty({ example: 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', description: 'Building ID' })
  @IsString({ message: 'Building ID must be a string' })
  @IsNotEmpty({ message: 'Building ID is required' })
  buildingId!: string;

  @ApiProperty({ example: 'AI Lab 5210 (514)', description: 'Human-readable room number or name' })
  @IsString()
  @IsNotEmpty({ message: 'Room number is required' })
  roomNumber!: string;

  @ApiPropertyOptional({ example: 5, default: 1, description: 'Floor level' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0, { message: 'Floor must be at least 0 (Ground)' })
  floor?: number;

  @ApiPropertyOptional({ example: 45, default: 40, description: 'Seating capacity' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'Capacity must be at least 1' })
  capacity?: number;

  @ApiPropertyOptional({
    enum: RoomStatus,
    default: RoomStatus.AVAILABLE,
    description: 'Initial room status',
  })
  @IsOptional()
  @IsEnum(RoomStatus)
  currentStatus?: RoomStatus;
}
