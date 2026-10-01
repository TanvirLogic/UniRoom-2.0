import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateAcademicBatchDto {
  @ApiPropertyOptional({ example: ['A', 'B', 'C', 'D'], description: 'Updated list of sections' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  sections?: string[];

  @ApiPropertyOptional({ example: true, description: 'Batch active state' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
