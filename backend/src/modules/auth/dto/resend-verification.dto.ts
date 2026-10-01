import { ApiProperty } from '@nestjs/swagger';
import { IsEmail } from 'class-validator';

export class ResendVerificationDto {
  @ApiProperty({ example: 'student.batch68@uttara.edu.bd', description: 'Registered institutional email address' })
  @IsEmail({}, { message: 'Please provide a valid institutional email address' })
  email!: string;
}
