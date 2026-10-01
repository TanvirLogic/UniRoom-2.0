import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class VerifyEmailDto {
  @ApiProperty({ example: 'student.batch68@uttara.edu.bd', description: 'Registered institutional email address' })
  @IsEmail({}, { message: 'Please provide a valid institutional email address' })
  email!: string;

  @ApiProperty({ example: '482910', description: '6-digit numeric verification PIN' })
  @IsString()
  @IsNotEmpty({ message: 'Verification PIN is required' })
  @Length(6, 6, { message: 'PIN must be exactly 6 digits' })
  @Matches(/^[0-9]{6}$/, { message: 'PIN must consist of 6 numeric digits' })
  pin!: string;
}
