import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class VerifyResetPinDto {
  @ApiProperty({
    example: 'bmwthriad2023@gmail.com',
    description: 'Email address associated with the password reset request',
  })
  @IsEmail({}, { message: 'Please provide a valid email address' })
  @IsNotEmpty({ message: 'Email address is required' })
  email!: string;

  @ApiProperty({
    example: '492816',
    minLength: 6,
    maxLength: 6,
    description: '6-digit numeric password reset PIN',
  })
  @IsString()
  @Length(6, 6, { message: 'Password reset PIN must be exactly 6 digits' })
  @Matches(/^[0-9]{6}$/, { message: 'Password reset PIN must consist of digits only' })
  pin!: string;
}
