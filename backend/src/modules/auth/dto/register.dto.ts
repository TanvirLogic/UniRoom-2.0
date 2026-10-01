import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { Role } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: 'student.batch68@uttara.edu.bd', description: 'Institutional email address' })
  @IsEmail({}, { message: 'Please provide a valid institutional email address' })
  email!: string;

  @ApiProperty({ example: 'SecurePassword123!', minLength: 6, description: 'Plaintext password (hashed with bcrypt)' })
  @IsString()
  @MinLength(6, { message: 'Password must be at least 6 characters long' })
  password!: string;

  @ApiProperty({ example: 'Sadia Rahman', description: 'Full name of the user' })
  @IsString()
  @IsNotEmpty({ message: 'Full name is required' })
  fullName!: string;

  @ApiProperty({ example: 'UU', description: 'University ID (e.g. UU)' })
  @IsString()
  @IsNotEmpty({ message: 'University ID is required' })
  universityId!: string;

  @ApiProperty({ example: 'CSE', description: 'Department ID (e.g. CSE, EEE, BBA, ENGLISH)' })
  @IsString()
  @IsNotEmpty({ message: 'Department ID is required' })
  departmentId!: string;

  @ApiProperty({ enum: Role, default: Role.STUDENT, description: 'Assigned system role' })
  @IsEnum(Role, { message: 'Role must be STUDENT, CR, FACULTY, or SUPER_ADMIN' })
  role!: Role;

  @ApiPropertyOptional({ example: '2241081422', description: 'Institutional Student ID / Roll number (required for Student and CR)' })
  @IsOptional()
  @IsString()
  studentId?: string;

  @ApiPropertyOptional({ example: '68', description: 'Student/CR academic batch' })
  @IsOptional()
  @IsString()
  batch?: string;

  @ApiPropertyOptional({ example: 'A', description: 'Student/CR section' })
  @IsOptional()
  @IsString()
  section?: string;

  @ApiPropertyOptional({ example: 'DNS', description: 'Faculty initials/code' })
  @IsOptional()
  @IsString()
  facultyId?: string;
}
