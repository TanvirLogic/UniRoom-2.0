import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PushNotificationService } from '../notifications/push-notification.service';
import { CreateNoticeDto } from './dto/create-notice.dto';
import { Role } from '@prisma/client';

@Injectable()
export class ClassroomsService {
  private readonly logger = new Logger(ClassroomsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  /**
   * Post a classroom notice and automatically broadcast push notifications to enrolled students
   */
  async createNotice(userId: string, dto: CreateNoticeDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { department: true },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    // Notice publishing permission: Faculty, CR, or Super Admin
    const allowedRoles: Role[] = [Role.FACULTY, Role.CR, Role.SUPER_ADMIN];
    if (!allowedRoles.includes(user.role)) {
      throw new ForbiddenException('Only faculty members and CRs can post classroom notices');
    }

    const department = dto.department || user.department?.code || 'CSE';
    let targetBatch = dto.batch?.trim() || null;
    let targetSection = dto.section?.trim() || null;

    // Parse target cohort string if batch/section were not explicitly passed (e.g. "Batch 61 (D)")
    if ((!targetBatch || !targetSection) && dto.targetCohort) {
      const match = dto.targetCohort.match(/Batch\s*(\w+)\s*\(([A-Za-z0-9]+)\)/i);
      if (match) {
        targetBatch = match[1];
        targetSection = match[2];
      }
    }

    const notice = await this.prisma.classroomNotice.create({
      data: {
        courseCode: dto.courseCode.trim().toUpperCase(),
        title: dto.title.trim(),
        content: dto.content.trim(),
        authorId: user.id,
        authorName: user.fullName,
        authorRole: user.role,
        department: department.trim().toUpperCase(),
        batch: targetBatch,
        section: targetSection,
        targetCohort: dto.targetCohort?.trim() || 'All Cohorts',
      },
    });

    this.logger.log(
      `Classroom notice created: ID ${notice.id} for course ${notice.courseCode} by ${user.fullName} (${user.role})`,
    );

    // --------------------------------------------------------------------------
    // Push Notification Broadcasting
    // --------------------------------------------------------------------------
    const pushTitle = `📢 [${notice.courseCode}] ${notice.title}`;
    const pushBody =
      notice.content.length > 140
        ? `${notice.content.substring(0, 137)}...`
        : notice.content;

    const payload = {
      title: pushTitle,
      body: pushBody,
      data: {
        type: 'classroom_notice',
        courseCode: notice.courseCode,
        noticeId: notice.id,
        title: notice.title,
        content: notice.content,
        authorName: notice.authorName,
        createdAt: notice.createdAt.toISOString(),
      },
    };

    // Determine target topics to broadcast to
    const targetTopics: Array<{ dept: string; batch: string; section: string }> = [];

    if (targetBatch && targetSection) {
      targetTopics.push({
        dept: department,
        batch: targetBatch,
        section: targetSection,
      });
    } else {
      // Find all scheduled cohorts for this course code to broadcast across all sections
      const slots = await this.prisma.scheduleSlot.findMany({
        where: {
          courseCode: { equals: notice.courseCode, mode: 'insensitive' },
        },
        select: {
          batch: true,
          section: true,
          department: { select: { code: true } },
        },
      });

      const seen = new Set<string>();
      for (const slot of slots) {
        const d = slot.department?.code || department;
        const key = `${d}_${slot.batch}_${slot.section}`;
        if (!seen.has(key)) {
          seen.add(key);
          targetTopics.push({
            dept: d,
            batch: slot.batch,
            section: slot.section,
          });
        }
      }

      // Fallback: If no slots found but author is a CR with batch and section
      if (targetTopics.length === 0 && user.batch && user.section) {
        targetTopics.push({
          dept: department,
          batch: user.batch,
          section: user.section,
        });
      }
    }

    // Asynchronously dispatch FCM push notifications to all enrolled student topics
    for (const t of targetTopics) {
      try {
        await this.pushNotificationService.sendToSectionTopic(
          t.dept,
          t.batch,
          t.section,
          payload,
        );
        this.logger.log(
          `FCM Notice broadcast sent to topic dept_${t.dept}_batch_${t.batch}_sec_${t.section}`,
        );
      } catch (err: any) {
        this.logger.warn(
          `Failed to send FCM notice to ${t.dept}-${t.batch}-${t.section}: ${err.message}`,
        );
      }
    }

    return notice;
  }

  /**
   * Get all notices for a classroom course
   */
  async getNotices(params: {
    courseCode: string;
    department?: string;
    batch?: string;
    section?: string;
  }) {
    const cleanCourse = params.courseCode.trim().toUpperCase();

    const whereClause: any = {
      courseCode: cleanCourse,
    };

    // If specific section/batch requested, return notices matching this cohort OR all cohorts
    if (params.batch && params.section) {
      whereClause.OR = [
        {
          batch: { equals: params.batch.trim(), mode: 'insensitive' },
          section: { equals: params.section.trim(), mode: 'insensitive' },
        },
        { batch: null },
        { targetCohort: { equals: 'All Cohorts', mode: 'insensitive' } },
      ];
    }

    const notices = await this.prisma.classroomNotice.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      include: {
        author: {
          select: {
            id: true,
            fullName: true,
            role: true,
            facultyId: true,
            studentId: true,
          },
        },
      },
    });

    return notices;
  }

  /**
   * Delete a classroom notice
   */
  async deleteNotice(userId: string, noticeId: string) {
    const notice = await this.prisma.classroomNotice.findUnique({
      where: { id: noticeId },
    });

    if (!notice) {
      throw new NotFoundException('Notice not found');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    const canDelete =
      notice.authorId === user.id ||
      user.role === Role.SUPER_ADMIN ||
      user.role === Role.FACULTY;

    if (!canDelete) {
      throw new ForbiddenException('You do not have permission to delete this notice');
    }

    await this.prisma.classroomNotice.delete({
      where: { id: noticeId },
    });

    this.logger.log(`Classroom notice deleted: ${noticeId} by user ${user.id}`);

    return { success: true, message: 'Classroom notice deleted successfully' };
  }
}
