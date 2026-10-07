import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { ResendVerificationDto } from './dto/resend-verification.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { VerifyResetPinDto } from './dto/verify-reset-pin.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@ApiTags('Authentication & Identity')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register a new institutional user and send 6-digit email verification PIN' })
  @ApiResponse({ status: 201, description: 'Registration initiated; verification PIN dispatched to email' })
  @ApiResponse({ status: 409, description: 'Account with this email already exists and is verified' })
  @ApiResponse({ status: 400, description: 'Validation failure' })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('verify-email')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify institutional email using 6-digit PIN and receive JWT token pair' })
  @ApiResponse({ status: 200, description: 'Email verified successfully; returns JWT tokens and sanitized profile' })
  @ApiResponse({ status: 400, description: 'Invalid, expired, or max-attempt exceeded PIN' })
  @ApiResponse({ status: 404, description: 'Account not found' })
  async verifyEmail(@Body() dto: VerifyEmailDto) {
    return this.authService.verifyEmail(dto);
  }

  @Post('resend-verification')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Resend fresh 6-digit email verification PIN (enforces 60-second cooldown)' })
  @ApiResponse({ status: 200, description: 'Fresh PIN sent to email' })
  @ApiResponse({ status: 400, description: 'Rate limit active (cooldown) or email already verified' })
  @ApiResponse({ status: 404, description: 'Account not found' })
  async resendVerification(@Body() dto: ResendVerificationDto) {
    return this.authService.resendVerificationPin(dto);
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request a 6-digit password reset PIN sent to institutional email' })
  @ApiResponse({ status: 200, description: 'Password reset PIN dispatched to email' })
  @ApiResponse({ status: 400, description: 'Rate limit active (cooldown) or email not verified' })
  @ApiResponse({ status: 404, description: 'Account not found' })
  async forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  @Post('verify-reset-pin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify 6-digit password reset PIN before proceeding to reset password' })
  @ApiResponse({ status: 200, description: 'PIN verified successfully' })
  @ApiResponse({ status: 400, description: 'Invalid, expired, or max-attempt exceeded PIN' })
  @ApiResponse({ status: 404, description: 'Account not found' })
  async verifyResetPin(@Body() dto: VerifyResetPinDto) {
    return this.authService.verifyResetPin(dto);
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset account password using 6-digit PIN and new password' })
  @ApiResponse({ status: 200, description: 'Password reset successfully' })
  @ApiResponse({ status: 400, description: 'Invalid, expired, or max-attempt exceeded PIN' })
  @ApiResponse({ status: 404, description: 'Account not found' })
  async resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'User login with verified email and password' })
  @ApiResponse({ status: 200, description: 'Authenticated successfully; returns JWT token pair' })
  @ApiResponse({ status: 401, description: 'Invalid email, password, or unverified email' })
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Exchange a valid refresh token for a fresh token pair' })
  @ApiResponse({ status: 200, description: 'New token pair issued' })
  @ApiResponse({ status: 401, description: 'Invalid or expired refresh token' })
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get current authenticated user session details' })
  @ApiResponse({ status: 200, description: 'Current profile data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getProfile(@CurrentUser('sub') userId: string) {
    return this.authService.getProfile(userId);
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update authenticated user academic profile (section, batch, name, studentId)' })
  @ApiResponse({ status: 200, description: 'Profile updated successfully' })
  async updateProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.authService.updateProfile(userId, dto);
  }

  @Get('section-students')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get all students enrolled in the caller or specified department, batch, and section' })
  @ApiResponse({ status: 200, description: 'List of section classmates' })
  async getSectionStudents(
    @CurrentUser('sub') userId: string,
    @Query('department') department?: string,
    @Query('batch') batch?: string,
    @Query('section') section?: string,
  ) {
    return this.authService.getSectionStudents(userId, { department, batch, section });
  }

  @Post('section-students')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.CR, Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'CR or Admin quick-adds a student to their section students list' })
  @ApiResponse({ status: 201, description: 'Classmate added or updated in section students list' })
  async addSectionStudent(
    @CurrentUser('sub') userId: string,
    @Body() dto: { studentId: string; fullName: string; email?: string },
  ) {
    return this.authService.addSectionStudent(userId, dto);
  }

  @Get('admin-test')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Test endpoint restricted strictly to Super Admins' })
  @ApiResponse({ status: 200, description: 'Access granted' })
  @ApiResponse({ status: 403, description: 'Forbidden: Insufficient role permissions' })
  async adminTest(@CurrentUser() user: any) {
    return {
      message: 'Access granted to Super Admin secured route',
      user,
    };
  }
}
