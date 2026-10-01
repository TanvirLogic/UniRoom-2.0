import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { ResendVerificationDto } from './dto/resend-verification.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { VerifyResetPinDto } from './dto/verify-reset-pin.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { Role, Prisma } from '@prisma/client';
import { JwtPayload } from '../../common/decorators/current-user.decorator';

@Injectable()
export class AuthService {
  private readonly saltRounds = 10;
  private readonly accessSecret: string;
  private readonly refreshSecret: string;
  private readonly accessExpiresIn: string;
  private readonly refreshExpiresIn: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly emailService: EmailService,
  ) {
    this.accessSecret = this.configService.get<string>('JWT_ACCESS_SECRET')!;
    this.refreshSecret = this.configService.get<string>('JWT_REFRESH_SECRET')!;
    this.accessExpiresIn = this.configService.get<string>('JWT_ACCESS_EXPIRATION', '15m');
    this.refreshExpiresIn = this.configService.get<string>('JWT_REFRESH_EXPIRATION', '7d');
  }

  private generateSixDigitPin(): string {
    return crypto.randomInt(100000, 1000000).toString();
  }

  async register(dto: RegisterDto) {
    const email = dto.email.toLowerCase().trim();

    // 1. Check for existing user
    const existingUser = await this.prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      if (existingUser.isEmailVerified) {
        throw new ConflictException('An account with this email address already exists and is verified. Please log in.');
      }
      // If user registered earlier but never verified, we update their details and re-issue a verification PIN
      const passwordHash = await bcrypt.hash(dto.password, this.saltRounds);
      const updatedUser = await this.prisma.user.update({
        where: { email },
        data: {
          passwordHash,
          fullName: dto.fullName.trim(),
          universityId: dto.universityId,
          departmentId: dto.departmentId,
          role: dto.role,
          studentId: dto.studentId?.trim(),
          batch: dto.batch?.trim(),
          section: dto.section?.trim().toUpperCase(),
          facultyId: dto.facultyId?.trim().toUpperCase(),
        },
      });

      return this.dispatchVerificationPin(updatedUser.email, updatedUser.fullName);
    }

    // 2. Validate University
    const university = await this.prisma.university.findUnique({
      where: { id: dto.universityId },
    });
    if (!university) {
      throw new NotFoundException(`University with ID '${dto.universityId}' does not exist`);
    }

    // 3. Validate Department belongs to the specified University
    const department = await this.prisma.department.findFirst({
      where: { id: dto.departmentId, universityId: dto.universityId },
    });
    if (!department) {
      throw new NotFoundException(
        `Department with ID '${dto.departmentId}' not found in university '${university.name}'`,
      );
    }

    // 4. Role-specific validation
    if ((dto.role === Role.STUDENT || dto.role === Role.CR) && !dto.studentId?.trim()) {
      throw new BadRequestException('Student ID / Roll number is required for Student and CR registration');
    }

    if (dto.role === Role.CR && (!dto.batch || !dto.section)) {
      throw new BadRequestException('CR registration requires both batch and section');
    }

    if (dto.role === Role.STUDENT && (!dto.batch || !dto.section)) {
      throw new BadRequestException('Student registration requires both batch and section');
    }

    if (dto.role === Role.FACULTY && !dto.facultyId) {
      throw new BadRequestException('Faculty registration requires faculty initials/code');
    }

    // 5. Check student ID uniqueness within the same university
    if (dto.studentId?.trim()) {
      const existingStudent = await this.prisma.user.findFirst({
        where: {
          universityId: dto.universityId,
          studentId: dto.studentId.trim(),
        },
      });
      if (existingStudent) {
        throw new ConflictException(
          `Student ID '${dto.studentId.trim()}' is already registered in this university`,
        );
      }
    }

    // 6. Cryptographic Password Hashing
    const passwordHash = await bcrypt.hash(dto.password, this.saltRounds);

    // 7. Persist user with isEmailVerified = false
    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        fullName: dto.fullName.trim(),
        universityId: dto.universityId,
        departmentId: dto.departmentId,
        role: dto.role,
        studentId: dto.studentId?.trim(),
        batch: dto.batch?.trim(),
        section: dto.section?.trim().toUpperCase(),
        facultyId: dto.facultyId?.trim().toUpperCase(),
        isApprovedCr: false,
        isEmailVerified: false,
      },
    });

    // 7. Generate and send 6-digit verification PIN
    return this.dispatchVerificationPin(user.email, user.fullName);
  }

  private async dispatchVerificationPin(email: string, fullName: string) {
    const pin = this.generateSixDigitPin();
    const pinHash = await bcrypt.hash(pin, this.saltRounds);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Clear any previous pins for this email
    await this.prisma.emailVerificationPin.deleteMany({
      where: { email },
    });

    // Store new hashed PIN
    await this.prisma.emailVerificationPin.create({
      data: {
        email,
        pinHash,
        expiresAt,
      },
    });

    // Dispatch email
    await this.emailService.sendVerificationEmail(email, fullName, pin);

    return {
      success: true,
      message: 'Registration initiated successfully. A 6-digit verification PIN has been sent to your institutional email.',
      email,
      expiresIn: '10 minutes',
    };
  }

  async verifyEmail(dto: VerifyEmailDto) {
    const email = dto.email.toLowerCase().trim();

    // 1. Locate user
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException('Account with this email does not exist');
    }

    if (user.isEmailVerified) {
      throw new BadRequestException('Email address is already verified. You can log in directly.');
    }

    // 2. Fetch latest active verification PIN
    const pinRecord = await this.prisma.emailVerificationPin.findFirst({
      where: { email },
      orderBy: { createdAt: 'desc' },
    });

    if (!pinRecord) {
      throw new BadRequestException('No verification PIN requested for this email. Please request a new PIN.');
    }

    if (pinRecord.expiresAt < new Date()) {
      throw new BadRequestException('Verification PIN has expired. Please request a fresh PIN.');
    }

    if (pinRecord.attempts >= 5) {
      throw new BadRequestException('Too many failed attempts. This PIN is invalidated. Please request a fresh PIN.');
    }

    // 3. Cryptographically compare PIN
    const isPinValid = await bcrypt.compare(dto.pin, pinRecord.pinHash);

    if (!isPinValid) {
      await this.prisma.emailVerificationPin.update({
        where: { id: pinRecord.id },
        data: { attempts: { increment: 1 } },
      });
      const remainingAttempts = 5 - (pinRecord.attempts + 1);
      throw new BadRequestException(
        `Invalid verification PIN. ${remainingAttempts > 0 ? remainingAttempts + ' attempt(s) remaining.' : 'PIN invalidated.'}`,
      );
    }

    // 4. Mark user as verified
    const verifiedUser = await this.prisma.user.update({
      where: { email },
      data: { isEmailVerified: true },
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        studentId: true,
        universityId: true,
        departmentId: true,
        batch: true,
        section: true,
        facultyId: true,
        isApprovedCr: true,
        isEmailVerified: true,
        createdAt: true,
        university: {
          select: { id: true, name: true, code: true },
        },
        department: {
          select: { id: true, name: true, code: true },
        },
      },
    });

    // 5. If user is Faculty, auto-link existing schedule slots
    if (verifiedUser.role === Role.FACULTY && verifiedUser.facultyId && verifiedUser.departmentId) {
      await this.prisma.scheduleSlot.updateMany({
        where: {
          departmentId: verifiedUser.departmentId,
          facultyInitials: { equals: verifiedUser.facultyId, mode: 'insensitive' },
        },
        data: {
          facultyUserId: verifiedUser.id,
        },
      });
    }

    // 6. Clean up consumed verification PINs
    await this.prisma.emailVerificationPin.deleteMany({
      where: { email },
    });

    // 7. Generate and return JWT token pair
    const tokens = await this.generateTokens(verifiedUser);

    return {
      message: 'Institutional email successfully verified. Welcome to UniRoom-Live 2.0!',
      user: verifiedUser,
      ...tokens,
    };
  }

  async resendVerificationPin(dto: ResendVerificationDto) {
    const email = dto.email.toLowerCase().trim();

    // 1. Locate user
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException('Account with this email does not exist');
    }

    if (user.isEmailVerified) {
      throw new BadRequestException('Email address is already verified. You can log in directly.');
    }

    // 2. Rate-limiting check: 60-second cooldown
    const latestPin = await this.prisma.emailVerificationPin.findFirst({
      where: { email },
      orderBy: { createdAt: 'desc' },
    });

    if (latestPin) {
      const elapsedSeconds = (Date.now() - latestPin.createdAt.getTime()) / 1000;
      if (elapsedSeconds < 60) {
        const cooldownRemaining = Math.ceil(60 - elapsedSeconds);
        throw new BadRequestException(
          `Please wait ${cooldownRemaining} second(s) before requesting another verification PIN.`,
        );
      }
    }

    // 3. Dispatch fresh PIN
    return this.dispatchVerificationPin(user.email, user.fullName);
  }

  async login(dto: LoginDto) {
    const email = dto.email.toLowerCase().trim();

    // 1. Locate user by email (case-insensitive)
    const user = await this.prisma.user.findFirst({
      where: {
        email: { equals: email, mode: 'insensitive' },
      },
      include: {
        university: {
          select: { id: true, name: true, code: true },
        },
        department: {
          select: { id: true, name: true, code: true },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // 2. Cryptographic password comparison
    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // 3. Email verification guard
    if (!user.isEmailVerified) {
      throw new UnauthorizedException(
        'Your institutional email has not been verified yet. Please submit the 6-digit PIN sent to your email, or request a fresh PIN.',
      );
    }

    // 3b. If user is Faculty, auto-link any unlinked schedule slots matching facultyId
    if (user.role === Role.FACULTY && user.facultyId && user.departmentId) {
      await this.prisma.scheduleSlot.updateMany({
        where: {
          departmentId: user.departmentId,
          facultyInitials: { equals: user.facultyId, mode: 'insensitive' },
          facultyUserId: null,
        },
        data: {
          facultyUserId: user.id,
        },
      });
    }

    // 4. Strip password hash
    const { passwordHash: _, ...sanitizedUser } = user;

    // 5. Generate Token Pair
    const tokens = await this.generateTokens(sanitizedUser);

    return {
      user: sanitizedUser,
      ...tokens,
    };
  }

  async refresh(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync<JwtPayload>(refreshToken, {
        secret: this.refreshSecret,
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: {
          id: true,
          email: true,
          fullName: true,
          role: true,
          studentId: true,
          universityId: true,
          departmentId: true,
          batch: true,
          section: true,
          facultyId: true,
          isApprovedCr: true,
          isEmailVerified: true,
          createdAt: true,
          university: {
            select: { id: true, name: true, code: true },
          },
          department: {
            select: { id: true, name: true, code: true },
          },
        },
      });

      if (!user) {
        throw new UnauthorizedException('User session no longer valid');
      }

      return this.generateTokens(user);
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token. Please log in again.');
    }
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        studentId: true,
        universityId: true,
        departmentId: true,
        batch: true,
        section: true,
        facultyId: true,
        isApprovedCr: true,
        isEmailVerified: true,
        createdAt: true,
        university: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
        department: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    return user;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    const data: Prisma.UserUpdateInput = {};

    if (dto.fullName) data.fullName = dto.fullName.trim();
    if (dto.studentId) data.studentId = dto.studentId.trim();
    if (dto.batch) data.batch = dto.batch.trim();
    if (dto.section) data.section = dto.section.trim().toUpperCase();

    if (dto.departmentId) {
      const dept = await this.prisma.department.findFirst({
        where: {
          OR: [
            { id: dto.departmentId },
            { code: { equals: dto.departmentId, mode: 'insensitive' } },
          ],
        },
      });
      if (dept) {
        data.department = { connect: { id: dept.id } };
      }
    }

    if (dto.facultyId && user.role === Role.FACULTY) {
      data.facultyId = dto.facultyId.trim().toUpperCase();
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        fullName: true,
        role: true,
        studentId: true,
        universityId: true,
        departmentId: true,
        batch: true,
        section: true,
        facultyId: true,
        isApprovedCr: true,
        isEmailVerified: true,
        createdAt: true,
        university: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
        department: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
      },
    });

    if (dto.facultyId && user.role === Role.FACULTY) {
      await this.prisma.scheduleSlot.updateMany({
        where: { facultyInitials: dto.facultyId.trim().toUpperCase() },
        data: { facultyUserId: user.id },
      });
    }

    return updatedUser;
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const email = dto.email.toLowerCase().trim();

    // 1. Locate user
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException('Account with this email does not exist. Please check your email or register.');
    }

    if (!user.isEmailVerified) {
      throw new BadRequestException('Your email is not verified yet. Please complete email verification first.');
    }

    // 2. Cooldown check: 60-second rate-limiting
    const latestPin = await this.prisma.passwordResetPin.findFirst({
      where: { email },
      orderBy: { createdAt: 'desc' },
    });

    if (latestPin) {
      const elapsedSeconds = (Date.now() - latestPin.createdAt.getTime()) / 1000;
      if (elapsedSeconds < 60) {
        const cooldownRemaining = Math.ceil(60 - elapsedSeconds);
        throw new BadRequestException(
          `Please wait ${cooldownRemaining} second(s) before requesting another password reset PIN.`,
        );
      }
    }

    // 3. Generate 6-digit PIN and hash it
    const pin = this.generateSixDigitPin();
    const pinHash = await bcrypt.hash(pin, this.saltRounds);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // 4. Invalidate any existing reset pins for this email
    await this.prisma.passwordResetPin.deleteMany({
      where: { email },
    });

    // 5. Store new hashed PIN
    await this.prisma.passwordResetPin.create({
      data: {
        email,
        pinHash,
        expiresAt,
      },
    });

    // 6. Dispatch email via EmailService
    await this.emailService.sendPasswordResetEmail(user.email, user.fullName, pin);

    return {
      success: true,
      message: 'A 6-digit password reset PIN has been sent to your email.',
      email,
      expiresIn: '10 minutes',
    };
  }

  async verifyResetPin(dto: VerifyResetPinDto) {
    const email = dto.email.toLowerCase().trim();

    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException('Account with this email does not exist.');
    }

    const pinRecord = await this.prisma.passwordResetPin.findFirst({
      where: { email },
      orderBy: { createdAt: 'desc' },
    });

    if (!pinRecord) {
      throw new BadRequestException('No password reset PIN requested for this email. Please request a new PIN.');
    }

    if (pinRecord.expiresAt < new Date()) {
      throw new BadRequestException('Password reset PIN has expired. Please request a fresh PIN.');
    }

    if (pinRecord.attempts >= 5) {
      throw new BadRequestException('Too many failed attempts. This PIN is invalidated. Please request a fresh PIN.');
    }

    const isPinValid = await bcrypt.compare(dto.pin, pinRecord.pinHash);

    if (!isPinValid) {
      await this.prisma.passwordResetPin.update({
        where: { id: pinRecord.id },
        data: { attempts: { increment: 1 } },
      });
      const remainingAttempts = 5 - (pinRecord.attempts + 1);
      throw new BadRequestException(
        `Invalid password reset PIN. ${remainingAttempts > 0 ? remainingAttempts + ' attempt(s) remaining.' : 'PIN invalidated.'}`,
      );
    }

    return {
      success: true,
      message: 'PIN verified successfully. You may now proceed to set a new password.',
      email,
    };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const email = dto.email.toLowerCase().trim();

    // 1. Locate user
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException('Account with this email does not exist.');
    }

    // 2. Fetch latest active reset PIN
    const pinRecord = await this.prisma.passwordResetPin.findFirst({
      where: { email },
      orderBy: { createdAt: 'desc' },
    });

    if (!pinRecord) {
      throw new BadRequestException('No password reset PIN requested for this email. Please request a new PIN.');
    }

    if (pinRecord.expiresAt < new Date()) {
      throw new BadRequestException('Password reset PIN has expired. Please request a fresh PIN.');
    }

    if (pinRecord.attempts >= 5) {
      throw new BadRequestException('Too many failed attempts. This PIN is invalidated. Please request a fresh PIN.');
    }

    // 3. Cryptographically compare PIN
    const isPinValid = await bcrypt.compare(dto.pin, pinRecord.pinHash);

    if (!isPinValid) {
      await this.prisma.passwordResetPin.update({
        where: { id: pinRecord.id },
        data: { attempts: { increment: 1 } },
      });
      const remainingAttempts = 5 - (pinRecord.attempts + 1);
      throw new BadRequestException(
        `Invalid password reset PIN. ${remainingAttempts > 0 ? remainingAttempts + ' attempt(s) remaining.' : 'PIN invalidated.'}`,
      );
    }

    // 4. Hash new password
    const passwordHash = await bcrypt.hash(dto.newPassword, this.saltRounds);

    // 5. Update user password
    await this.prisma.user.update({
      where: { email },
      data: { passwordHash },
    });

    // 6. Delete used reset PINs
    await this.prisma.passwordResetPin.deleteMany({
      where: { email },
    });

    return {
      success: true,
      message: 'Password has been reset successfully. You can now log in with your new password.',
    };
  }

  private async generateTokens(user: {
    id: string;
    email: string;
    role: Role;
    universityId?: string | null;
    departmentId?: string | null;
    studentId?: string | null;
    batch?: string | null;
    section?: string | null;
    facultyId?: string | null;
  }) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      universityId: user.universityId ?? undefined,
      departmentId: user.departmentId ?? undefined,
      studentId: user.studentId ?? undefined,
      batch: user.batch ?? undefined,
      section: user.section ?? undefined,
      facultyId: user.facultyId ?? undefined,
    };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.accessSecret,
        expiresIn: this.accessExpiresIn,
      }),
      this.jwtService.signAsync(payload, {
        secret: this.refreshSecret,
        expiresIn: this.refreshExpiresIn,
      }),
    ]);

    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: this.accessExpiresIn,
    };
  }
}
