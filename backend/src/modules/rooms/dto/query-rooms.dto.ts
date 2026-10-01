import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { RoomStatus } from '@prisma/client';

export class QueryRoomsDto {
  @ApiPropertyOptional({ description: 'Filter by University ID or Code' })
  @IsOptional()
  @IsString()
  universityId?: string;

  @ApiPropertyOptional({ description: 'Filter by Department ID or Code' })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ description: 'Filter by Building ID' })
  @IsOptional()
  @IsString()
  buildingId?: string;

  @ApiPropertyOptional({ example: 'Permanent Campus', description: 'Filter by Campus name' })
  @IsOptional()
  @IsString()
  campusName?: string;

  @ApiPropertyOptional({ example: 5, description: 'Filter by floor level' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  floor?: number;

  @ApiPropertyOptional({
    enum: RoomStatus,
    description: 'Filter by real-time room status (AVAILABLE, RUNNING_CLASS, RESERVED, MAINTENANCE)',
  })
  @IsOptional()
  @IsEnum(RoomStatus)
  status?: RoomStatus;

  @ApiPropertyOptional({ example: 40, description: 'Minimum seating capacity' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  minCapacity?: number;

  @ApiPropertyOptional({ example: '5210', description: 'Search query for room number or name' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ example: 1, default: 1, description: 'Page number' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20, description: 'Results per page' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 20;
}
