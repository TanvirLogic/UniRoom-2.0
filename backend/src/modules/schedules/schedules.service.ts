import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { DayOfWeek, RoomStatus, Role, OverrideAction } from '@prisma/client';
import { IngestRoutineDto, RoutineSlotDto } from './dto/ingest-routine.dto';
import { CancelTodaySlotDto } from './dto/cancel-today-slot.dto';
import { RescheduleTodaySlotDto } from './dto/reschedule-today-slot.dto';
import { PushNotificationService } from '../notifications/push-notification.service';
import { JwtPayload } from '../../common/decorators/current-user.decorator';

export interface CollisionDiagnostic {
  type: 'ROOM_DOUBLE_BOOKED' | 'FACULTY_CONFLICT' | 'SECTION_OVERLAP';
  severity: 'CRITICAL' | 'WARNING';
  entity: string;
  day: DayOfWeek;
  timeWindow: string;
  conflictingSlots: RoutineSlotDto[];
  message: string;
}

export interface CombinedSectionInfo {
  dayOfWeek: DayOfWeek;
  startTime: string;
  endTime: string;
  roomNumber: string;
  facultyCode: string;
  courseCode: string;
  courseName: string;
  sections: string[];
}

export interface ValidationReport {
  isValid: boolean;
  totalSlots: number;
  distinctRooms: string[];
  distinctBatches: string[];
  distinctFaculty: string[];
  distinctCourses: string[];
  collisions: CollisionDiagnostic[];
  unmappedRooms: string[];
  combinedSections: CombinedSectionInfo[];
}

@Injectable()
export class SchedulesService {
  private readonly logger = new Logger(SchedulesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  /**
   * Helper: Check if two time intervals [S1, E1] and [S2, E2] overlap on the same day
   */
  private checkIntervalOverlap(
    day1: DayOfWeek,
    start1: string,
    end1: string,
    day2: DayOfWeek,
    start2: string,
    end2: string,
  ): boolean {
    if (day1 !== day2) return false;
    return start1 < end2 && end1 > start2;
  }

  /**
   * Infer floor number from room string (e.g. "5030" -> 5, "6020" -> 6, "AI Lab 5210" -> 5, "0018" -> 1)
   */
  private inferFloorFromRoom(roomNumber: string): number {
    const match = roomNumber.match(/\b([1-9])\d{3}\b/);
    if (match) {
      return parseInt(match[1], 10);
    }
    const digitMatch = roomNumber.match(/\d/);
    return digitMatch ? Math.min(Math.max(1, parseInt(digitMatch[0], 10)), 9) : 1;
  }

  /**
   * 1. Pre-Flight Mathematical Collision & Overlap Validator
   */
  async validateRoutine(dto: IngestRoutineDto): Promise<ValidationReport> {
    const slots = dto.slots || [];
    const collisions: CollisionDiagnostic[] = [];

    // Aggregate distinct sets
    const distinctRooms = [...new Set(slots.map((s) => s.roomNumber.trim()))].sort();
    const distinctBatches = [...new Set(slots.map((s) => s.batch.trim()))].sort();
    const distinctFaculty = [...new Set(slots.map((s) => s.facultyCode.trim().toUpperCase()))].sort();
    const distinctCourses = [...new Set(slots.map((s) => s.courseCode.trim().toUpperCase()))].sort();

    // 1. Identify legitimate Joint/Combined Section Lectures:
    // When multiple sections share the same room, faculty, course, day, and time window
    const groupMap = new Map<string, RoutineSlotDto[]>();
    for (const s of slots) {
      const key = `${s.dayOfWeek}_${s.startTime.trim()}_${s.endTime.trim()}_${s.roomNumber.trim().toLowerCase()}_${s.facultyCode.trim().toUpperCase()}_${s.courseCode.trim().toUpperCase()}`;
      if (!groupMap.has(key)) {
        groupMap.set(key, []);
      }
      groupMap.get(key)!.push(s);
    }

    const combinedSections: CombinedSectionInfo[] = [];
    for (const group of groupMap.values()) {
      if (group.length > 1) {
        combinedSections.push({
          dayOfWeek: group[0].dayOfWeek,
          startTime: group[0].startTime.trim(),
          endTime: group[0].endTime.trim(),
          roomNumber: group[0].roomNumber.trim(),
          facultyCode: group[0].facultyCode.trim().toUpperCase(),
          courseCode: group[0].courseCode.trim().toUpperCase(),
          courseName: group[0].courseName.trim(),
          sections: group.map((g) => `Batch ${g.batch.trim()} (${g.section.trim().toUpperCase()})`),
        });
      }
    }

    // 2. Check pairwise collisions across all slots
    for (let i = 0; i < slots.length; i++) {
      for (let j = i + 1; j < slots.length; j++) {
        const a = slots[i];
        const b = slots[j];

        const overlaps = this.checkIntervalOverlap(
          a.dayOfWeek,
          a.startTime,
          a.endTime,
          b.dayOfWeek,
          b.startTime,
          b.endTime,
        );

        if (!overlaps) continue;

        const sameRoom = a.roomNumber.trim().toLowerCase() === b.roomNumber.trim().toLowerCase();
        const sameFac =
          a.facultyCode.trim().toUpperCase() === b.facultyCode.trim().toUpperCase() &&
          a.facultyCode.trim().toUpperCase() !== 'TBA';
        const sameCourse = a.courseCode.trim().toUpperCase() === b.courseCode.trim().toUpperCase();
        const sameTime = a.startTime.trim() === b.startTime.trim() && a.endTime.trim() === b.endTime.trim();
        const diffBatchOrSection =
          a.batch.trim() !== b.batch.trim() ||
          a.section.trim().toUpperCase() !== b.section.trim().toUpperCase();

        // Legitimate Combined / Merged Section Lecture:
        // A single class held simultaneously for multiple batches/sections in the same room by the same teacher
        if (sameRoom && sameFac && sameCourse && sameTime && diffBatchOrSection) {
          continue;
        }

        // 1. Room Double-Booking Collision (different teachers or courses competing for the same room)
        if (sameRoom) {
          collisions.push({
            type: 'ROOM_DOUBLE_BOOKED',
            severity: 'CRITICAL',
            entity: a.roomNumber,
            day: a.dayOfWeek,
            timeWindow: `${a.startTime}-${a.endTime} vs ${b.startTime}-${b.endTime}`,
            conflictingSlots: [a, b],
            message: `Room '${a.roomNumber}' is double-booked on ${a.dayOfWeek} between ${a.startTime} and ${b.endTime}.`,
          });
        }

        // 2. Faculty Simultaneous Conflict (faculty scheduled in two different places simultaneously)
        if (sameFac) {
          collisions.push({
            type: 'FACULTY_CONFLICT',
            severity: 'CRITICAL',
            entity: a.facultyCode,
            day: a.dayOfWeek,
            timeWindow: `${a.startTime}-${a.endTime}`,
            conflictingSlots: [a, b],
            message: `Faculty '${a.facultyCode}' is scheduled in two places simultaneously on ${a.dayOfWeek} at ${a.startTime}.`,
          });
        }

        // 3. Batch & Section Simultaneous Class Overlap (same students having two different classes at once)
        if (!diffBatchOrSection) {
          collisions.push({
            type: 'SECTION_OVERLAP',
            severity: 'CRITICAL',
            entity: `Batch ${a.batch} Sec ${a.section}`,
            day: a.dayOfWeek,
            timeWindow: `${a.startTime}-${a.endTime}`,
            conflictingSlots: [a, b],
            message: `Batch ${a.batch} Section ${a.section} has two simultaneous classes on ${a.dayOfWeek} at ${a.startTime}.`,
          });
        }
      }
    }

    // Check which rooms do not currently exist in the database
    const existingRooms = await this.prisma.room.findMany({
      where: {
        roomNumber: { in: distinctRooms },
      },
      select: { roomNumber: true },
    });
    const existingRoomSet = new Set(existingRooms.map((r) => r.roomNumber.trim().toLowerCase()));
    const unmappedRooms = distinctRooms.filter(
      (r) => !existingRoomSet.has(r.trim().toLowerCase()),
    );

    return {
      isValid: collisions.length === 0,
      totalSlots: slots.length,
      distinctRooms,
      distinctBatches,
      distinctFaculty,
      distinctCourses,
      collisions,
      unmappedRooms,
      combinedSections,
    };
  }

  /**
   * 2. Atomic Database Hydration (Single PostgreSQL Transaction)
   */
  async ingestRoutine(dto: IngestRoutineDto) {
    const { university: uniInput, department: deptInput, slots } = dto;

    if (!slots || slots.length === 0) {
      throw new BadRequestException('Routine must contain at least one valid slot.');
    }

    return this.prisma.$transaction(
      async (tx) => {
        // 1. Resolve University
        const university = await tx.university.findFirst({
          where: {
            OR: [
              { id: uniInput },
              { code: { equals: uniInput, mode: 'insensitive' } },
              { name: { contains: uniInput, mode: 'insensitive' } },
            ],
          },
        });

        if (!university) {
          throw new NotFoundException(`University '${uniInput}' not found.`);
        }

        // 2. Resolve Department within University
        const department = await tx.department.findFirst({
          where: {
            universityId: university.id,
            OR: [
              { id: deptInput },
              { code: { equals: deptInput, mode: 'insensitive' } },
              { name: { contains: deptInput, mode: 'insensitive' } },
            ],
          },
          include: {
            buildings: true,
          },
        });

        if (!department) {
          throw new NotFoundException(
            `Department '${deptInput}' not found in university '${university.code}'.`,
          );
        }

        // 3. Resolve or Auto-Provision Default Building
        let building = department.buildings[0];
        if (!building) {
          building = await tx.building.create({
            data: {
              departmentId: department.id,
              name: 'Building B',
              campusName: 'Permanent Campus',
            },
          });
        }

        // 4. Batch Auto-Provision & Overwrite All Physical Rooms According to Allocation
        const uniqueRoomNumbers = [...new Set(slots.map((s) => s.roomNumber.trim()))];
        const existingRooms = await tx.room.findMany({
          where: { departmentId: department.id },
        });

        // Overwrite existing rooms with inferred floor, capacity, and current department building
        for (const er of existingRooms) {
          await tx.room.update({
            where: { id: er.id },
            data: {
              floor: this.inferFloorFromRoom(er.roomNumber),
              capacity: er.roomNumber.toLowerCase().includes('lab') ? 40 : 50,
              buildingId: building.id,
              departmentId: department.id,
            },
          });
        }

        const roomMap = new Map<string, string>(); // lower(roomNumber) -> roomId
        for (const er of existingRooms) {
          roomMap.set(er.roomNumber.trim().toLowerCase(), er.id);
        }

        const roomsToInsert: {
          universityId: string;
          departmentId: string;
          buildingId: string;
          roomNumber: string;
          floor: number;
          capacity: number;
          currentStatus: RoomStatus;
          version: number;
        }[] = [];

        for (const rNum of uniqueRoomNumbers) {
          if (!roomMap.has(rNum.trim().toLowerCase())) {
            roomsToInsert.push({
              universityId: university.id,
              departmentId: department.id,
              buildingId: building.id,
              roomNumber: rNum,
              floor: this.inferFloorFromRoom(rNum),
              capacity: rNum.toLowerCase().includes('lab') ? 40 : 50,
              currentStatus: RoomStatus.AVAILABLE,
              version: 1,
            });
          }
        }

        if (roomsToInsert.length > 0) {
          await tx.room.createMany({
            data: roomsToInsert,
            skipDuplicates: true,
          });

          // Reload rooms to get generated IDs
          const refreshedRooms = await tx.room.findMany({
            where: { departmentId: department.id },
          });
          for (const r of refreshedRooms) {
            roomMap.set(r.roomNumber.trim().toLowerCase(), r.id);
          }
        }

        // 4b. Auto-Align Academic Batches and Sections (academic_batches)
        const batchMap = new Map<string, Set<string>>();
        for (const s of slots) {
          const bName = s.batch.trim();
          const sName = s.section.trim().toUpperCase();
          if (!batchMap.has(bName)) {
            batchMap.set(bName, new Set());
          }
          batchMap.get(bName)!.add(sName);
        }

        let batchesSynced = 0;
        for (const [bName, secSet] of batchMap.entries()) {
          const sectionsArr = Array.from(secSet).sort();
          const existingBatch = await tx.academicBatch.findUnique({
            where: {
              departmentId_name: {
                departmentId: department.id,
                name: bName,
              },
            },
          });

          if (existingBatch) {
            const mergedSections = Array.from(
              new Set([...existingBatch.sections, ...sectionsArr]),
            ).sort();
            await tx.academicBatch.update({
              where: { id: existingBatch.id },
              data: {
                sections: mergedSections,
                isActive: true,
              },
            });
          } else {
            await tx.academicBatch.create({
              data: {
                departmentId: department.id,
                name: bName,
                sections: sectionsArr,
                isActive: true,
              },
            });
          }
          batchesSynced++;
        }

        // 4c. Auto-Link Existing Faculty User Accounts
        const facultyUsers = await tx.user.findMany({
          where: {
            departmentId: department.id,
            role: Role.FACULTY,
            facultyId: { not: null },
          },
        });

        const facultyMap = new Map<string, string>(); // upper(facultyId) -> user.id
        for (const fu of facultyUsers) {
          if (fu.facultyId) {
            facultyMap.set(fu.facultyId.trim().toUpperCase(), fu.id);
          }
        }

        // 5. Clear Previous Master Schedule Slots for this Department (Atomic Overwrite)
        await tx.scheduleSlot.deleteMany({
          where: { departmentId: department.id },
        });

        // 6. Overwrite Conflicting Room Allocations (Latest Allocation Wins - No Room Double-Bookings)
        // Note: Joint/Combined Section Lectures (same room, faculty, course, day, and time window across different sections)
        // are legitimate shared lectures and must BOTH be preserved so each section can access its timetable!
        const resolvedSlots: RoutineSlotDto[] = [];
        let resolvedRoomConflicts = 0;

        for (const s of slots) {
          const sNorm = s.roomNumber.trim().toLowerCase();
          const sFac = s.facultyCode.trim().toUpperCase();
          const sCourse = s.courseCode.trim().toUpperCase();

          const existingIdx = resolvedSlots.findIndex((prev) => {
            if (
              prev.roomNumber.trim().toLowerCase() === sNorm &&
              prev.dayOfWeek === s.dayOfWeek
            ) {
              const overlaps = prev.startTime < s.endTime && prev.endTime > s.startTime;
              if (!overlaps) return false;

              // Check if this is a Combined/Joint Section lecture:
              const isCombined =
                prev.facultyCode.trim().toUpperCase() === sFac &&
                prev.courseCode.trim().toUpperCase() === sCourse &&
                prev.startTime.trim() === s.startTime.trim() &&
                prev.endTime.trim() === s.endTime.trim() &&
                (prev.batch.trim() !== s.batch.trim() ||
                  prev.section.trim().toUpperCase() !== s.section.trim().toUpperCase());

              if (isCombined) {
                // Legitimate combined lecture: keep both sections active
                return false;
              }

              // True room double-booking collision: overwrite with latest allocation
              return true;
            }
            return false;
          });

          if (existingIdx !== -1) {
            // Overwrite earlier conflicting allocation with the latest allocation
            resolvedSlots[existingIdx] = s;
            resolvedRoomConflicts++;
          } else {
            resolvedSlots.push(s);
          }
        }

        // 7. Bulk Insert All Clean Schedule Slots
        const slotData = resolvedSlots.map((s) => {
          const roomId = roomMap.get(s.roomNumber.trim().toLowerCase());
          if (!roomId) {
            throw new BadRequestException(
              `Room mapping failed for room number '${s.roomNumber}'.`,
            );
          }
          const facCode = s.facultyCode.trim().toUpperCase();
          return {
            departmentId: department.id,
            roomId,
            facultyUserId: facultyMap.get(facCode) || null,
            facultyInitials: facCode,
            batch: s.batch.trim(),
            section: s.section.trim().toUpperCase(),
            courseCode: s.courseCode.trim().toUpperCase(),
            courseName: s.courseName.trim(),
            dayOfWeek: s.dayOfWeek,
            startTime: s.startTime.trim(),
            endTime: s.endTime.trim(),
            isActive: true,
          };
        });

        const result = await tx.scheduleSlot.createMany({
          data: slotData,
        });

        return {
          success: true,
          university: university.name,
          department: department.name,
          slotsCreated: result.count,
          roomsProvisioned: roomsToInsert.length,
          roomsOverwritten: existingRooms.length,
          batchesSynced,
          facultyLinked: facultyMap.size,
          roomConflictsOverwritten: resolvedRoomConflicts,
          timestamp: new Date().toISOString(),
        };
      },
      { maxWait: 15000, timeout: 30000 },
    );
  }

  /**
   * 3. Query Active Schedules
   */
  async getSchedules(query?: {
    university?: string;
    department?: string;
    batch?: string;
    section?: string;
    courseCode?: string;
    dayOfWeek?: DayOfWeek;
    roomId?: string;
    facultyCode?: string;
    date?: string;
  }) {
    const where: any = { isActive: true };

    if (query?.dayOfWeek) where.dayOfWeek = query.dayOfWeek;
    if (query?.batch) where.batch = query.batch;
    if (query?.section) where.section = { equals: query.section, mode: 'insensitive' };
    if (query?.courseCode) {
      where.courseCode = { contains: query.courseCode.trim(), mode: 'insensitive' };
    }
    if (query?.roomId) where.roomId = query.roomId;
    if (query?.facultyCode) {
      where.facultyInitials = { equals: query.facultyCode, mode: 'insensitive' };
    }

    if (query?.department) {
      const dept = await this.prisma.department.findFirst({
        where: {
          OR: [
            { id: query.department },
            { code: { equals: query.department, mode: 'insensitive' } },
          ],
          ...(query.university && {
            university: {
              OR: [
                { id: query.university },
                { code: { equals: query.university, mode: 'insensitive' } },
              ],
            },
          }),
        },
        select: { id: true },
      });
      if (dept) {
        where.departmentId = dept.id;
      } else {
        where.department = {
          code: { equals: query.department, mode: 'insensitive' },
        };
      }
    } else if (query?.university) {
      where.department = {
        university: {
          OR: [
            { id: query.university },
            { code: { equals: query.university, mode: 'insensitive' } },
          ],
        },
      };
    }

    // Determine target date window for daily overrides (e.g. today's cancellations or time changes)
    const targetDate = query?.date ? new Date(query.date) : new Date();
    const dateStart = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), 0, 0, 0);
    const dateEnd = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate() + 1, 0, 0, 0);

    return this.prisma.scheduleSlot.findMany({
      where,
      include: {
        room: {
          select: {
            id: true,
            roomNumber: true,
            floor: true,
            capacity: true,
            currentStatus: true,
            version: true,
            building: { select: { id: true, name: true, campusName: true } },
          },
        },
        department: {
          select: { id: true, code: true, name: true, universityId: true },
        },
        facultyUser: {
          select: { id: true, fullName: true, email: true },
        },
        overrides: {
          where: {
            overrideDate: {
              gte: dateStart,
              lt: dateEnd,
            },
          },
          include: {
            newRoom: {
              select: { id: true, roomNumber: true, floor: true, building: { select: { name: true } } },
            },
            createdByUser: {
              select: { id: true, fullName: true, role: true },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }, { batch: 'asc' }],
    });
  }

  /**
   * 4. Cancel Today's Class Slot (CR / Faculty / Admin Emergency Control)
   * Creates a ScheduleOverride for today, frees up the physical room, and notifies cohort students.
   */
  async cancelTodaySlot(slotId: string, dto: CancelTodaySlotDto, user: JwtPayload) {
    const slot = await this.prisma.scheduleSlot.findUnique({
      where: { id: slotId },
      include: {
        room: true,
        department: true,
      },
    });

    if (!slot) {
      throw new NotFoundException(`Schedule slot with ID '${slotId}' not found.`);
    }

    // Permission Check:
    // If CR: must belong to the slot's department, batch, and section
    if (user.role === Role.CR) {
      if (
        (user.departmentId && slot.departmentId && user.departmentId !== slot.departmentId) ||
        (user.batch && slot.batch && user.batch !== slot.batch) ||
        (user.section && slot.section && user.section.toLowerCase() !== slot.section.toLowerCase())
      ) {
        throw new ForbiddenException('CR can only cancel classes for their own department, batch, and section.');
      }
    }

    const targetDate = dto.date ? new Date(dto.date) : new Date();
    const overrideDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate());

    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Create ScheduleOverride
      const override = await tx.scheduleOverride.create({
        data: {
          scheduleSlotId: slot.id,
          overrideDate,
          action: OverrideAction.CANCELLED,
          reason: dto.reason || 'Faculty informed will not take class today',
          createdByUserId: user.sub,
        },
        include: {
          createdByUser: { select: { id: true, fullName: true, role: true } },
        },
      });

      // 2. Free up physical room if requested (defaults to true)
      let updatedRoom: any = null;
      if (dto.freeRoom !== false && slot.roomId) {
        const room = await tx.room.findUnique({ where: { id: slot.roomId } });
        if (room) {
          updatedRoom = await tx.room.update({
            where: { id: slot.roomId },
            data: {
              currentStatus: RoomStatus.AVAILABLE,
              version: { increment: 1 },
              currentCourse: null,
              currentTeacher: null,
              currentBatch: null,
              leaseExpiresAt: null,
            },
            include: { building: true, department: true },
          });

          await tx.roomLog.create({
            data: {
              roomId: slot.roomId,
              changedByUserId: user.sub,
              previousStatus: room.currentStatus,
              newStatus: RoomStatus.AVAILABLE,
              note: `Room freed: Class cancelled today for ${slot.courseCode} (Batch ${slot.batch}-${slot.section}) - ${dto.reason}`,
            },
          });
        }
      }

      return { override, room: updatedRoom };
    });

    // 3. Broadcast FCM Push Notifications
    const deptCode = slot.department?.code || 'all';

    // Broadcast to section students: class cancelled!
    this.pushNotificationService.sendToSectionTopic(deptCode, slot.batch, slot.section, {
      title: `🚨 Class Cancelled Today: ${slot.courseCode}`,
      body: `Notice: ${slot.courseName} (${slot.startTime}-${slot.endTime}) is cancelled today. Reason: ${dto.reason || 'Faculty unavailable'}.`,
      data: {
        type: 'CLASS_CANCELLED',
        slotId: slot.id,
        courseCode: slot.courseCode,
        courseName: slot.courseName,
        reason: dto.reason || '',
      },
    }).catch(() => {});

    // Broadcast to department CRs that the room is freed
    if (result.room) {
      this.pushNotificationService.sendToCrTopic(deptCode, {
        title: `Room ${result.room.roomNumber} is Now Free! 🟢`,
        body: `Class cancelled in Room ${result.room.roomNumber} (${slot.courseCode}). Tap to claim for your batch.`,
        data: { roomId: result.room.id, type: 'ROOM_FREED' },
      }).catch(() => {});
    }

    return {
      success: true,
      message: `Class ${slot.courseCode} cancelled for today. Push notifications sent to Batch ${slot.batch} (${slot.section}).`,
      override: result.override,
      freedRoom: result.room,
    };
  }

  /**
   * 5. Reschedule Today's Class Slot (CR / Faculty / Admin Emergency Control)
   * Changes the class time (and optionally room) for today only, and notifies cohort students.
   */
  async rescheduleTodaySlot(slotId: string, dto: RescheduleTodaySlotDto, user: JwtPayload) {
    const slot = await this.prisma.scheduleSlot.findUnique({
      where: { id: slotId },
      include: {
        room: true,
        department: true,
      },
    });

    if (!slot) {
      throw new NotFoundException(`Schedule slot with ID '${slotId}' not found.`);
    }

    // Permission check
    if (user.role === Role.CR) {
      if (
        (user.departmentId && slot.departmentId && user.departmentId !== slot.departmentId) ||
        (user.batch && slot.batch && user.batch !== slot.batch) ||
        (user.section && slot.section && user.section.toLowerCase() !== slot.section.toLowerCase())
      ) {
        throw new ForbiddenException('CR can only reschedule classes for their own department, batch, and section.');
      }
    }

    const targetDate = dto.date ? new Date(dto.date) : new Date();
    const overrideDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate());

    // Resolve target room (if specified, could be room number or UUID; else use slot.roomId)
    let targetRoomId = slot.roomId;
    let targetRoomNumber = slot.room?.roomNumber || 'Room TBA';

    if (dto.newRoomId && dto.newRoomId.trim().length > 0) {
      const clean = dto.newRoomId.trim();
      let foundRoom = await this.prisma.room.findUnique({ where: { id: clean } });
      if (!foundRoom) {
        foundRoom = await this.prisma.room.findFirst({
          where: {
            OR: [
              { roomNumber: { equals: clean, mode: 'insensitive' } },
              { roomNumber: { contains: clean, mode: 'insensitive' } },
            ],
          },
        });
      }
      if (foundRoom) {
        targetRoomId = foundRoom.id;
        targetRoomNumber = foundRoom.roomNumber;
      }
    }

    const result = await this.prisma.$transaction(async (tx) => {
      // 1. Create ScheduleOverride
      const override = await tx.scheduleOverride.create({
        data: {
          scheduleSlotId: slot.id,
          overrideDate,
          action: OverrideAction.RESCHEDULED,
          newStartTime: dto.newStartTime,
          newEndTime: dto.newEndTime,
          newRoomId: targetRoomId,
          reason: dto.reason || 'Time shifted for today by faculty/CR request',
          createdByUserId: user.sub,
        },
        include: {
          newRoom: {
            select: { id: true, roomNumber: true, floor: true, building: { select: { name: true } } },
          },
          createdByUser: { select: { id: true, fullName: true, role: true } },
        },
      });

      // 2. If original room changed, free up the old room
      if (targetRoomId !== slot.roomId && slot.roomId) {
        const oldRoom = await tx.room.findUnique({ where: { id: slot.roomId } });
        if (oldRoom && oldRoom.currentStatus === RoomStatus.RUNNING_CLASS) {
          await tx.room.update({
            where: { id: slot.roomId },
            data: {
              currentStatus: RoomStatus.AVAILABLE,
              version: { increment: 1 },
              currentCourse: null,
              currentTeacher: null,
              currentBatch: null,
            },
          });
          await tx.roomLog.create({
            data: {
              roomId: slot.roomId,
              changedByUserId: user.sub,
              previousStatus: oldRoom.currentStatus,
              newStatus: RoomStatus.AVAILABLE,
              note: `Room shifted: Class ${slot.courseCode} moved to Room ${targetRoomNumber}`,
            },
          });
        }
      }

      return { override };
    });

    // 3. Broadcast FCM Push Notifications to section students
    const deptCode = slot.department?.code || 'all';
    this.pushNotificationService.sendToSectionTopic(deptCode, slot.batch, slot.section, {
      title: `⏰ Class Rescheduled Today: ${slot.courseCode}`,
      body: `Notice: ${slot.courseName} moved to ${dto.newStartTime} - ${dto.newEndTime} (Room ${targetRoomNumber}). Reason: ${dto.reason || 'Time changed for today'}.`,
      data: {
        type: 'CLASS_RESCHEDULED',
        slotId: slot.id,
        courseCode: slot.courseCode,
        courseName: slot.courseName,
        newStartTime: dto.newStartTime,
        newEndTime: dto.newEndTime,
        newRoom: targetRoomNumber,
        reason: dto.reason || '',
      },
    }).catch(() => {});

    return {
      success: true,
      message: `Class ${slot.courseCode} rescheduled to ${dto.newStartTime} - ${dto.newEndTime} for today.`,
      override: result.override,
    };
  }

  /**
   * 6. Undo / Revert Today's Override (Restore Regular Timetable)
   */
  async undoTodayOverride(slotId: string, user: JwtPayload) {
    const slot = await this.prisma.scheduleSlot.findUnique({
      where: { id: slotId },
      include: { room: true, department: true },
    });

    if (!slot) {
      throw new NotFoundException(`Schedule slot with ID '${slotId}' not found.`);
    }

    if (user.role === Role.CR) {
      if (
        (user.departmentId && slot.departmentId && user.departmentId !== slot.departmentId) ||
        (user.batch && slot.batch && user.batch !== slot.batch) ||
        (user.section && slot.section && user.section.toLowerCase() !== slot.section.toLowerCase())
      ) {
        throw new ForbiddenException('CR can only modify classes for their own cohort.');
      }
    }

    const today = new Date();
    const dateStart = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0);
    const dateEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1, 0, 0, 0);

    const deleted = await this.prisma.scheduleOverride.deleteMany({
      where: {
        scheduleSlotId: slotId,
        overrideDate: {
          gte: dateStart,
          lt: dateEnd,
        },
      },
    });

    // Notify cohort that original schedule is restored
    const deptCode = slot.department?.code || 'all';
    this.pushNotificationService.sendToSectionTopic(deptCode, slot.batch, slot.section, {
      title: `🔄 Class Schedule Restored: ${slot.courseCode}`,
      body: `${slot.courseName} is back on regular schedule today (${slot.startTime}-${slot.endTime}, Room ${slot.room?.roomNumber || 'TBA'}).`,
      data: {
        type: 'CLASS_RESTORED',
        slotId: slot.id,
        courseCode: slot.courseCode,
      },
    }).catch(() => {});

    return {
      success: true,
      message: `Schedule override removed. Slot returned to normal timetable.`,
      overridesRemoved: deleted.count,
    };
  }

  /**
   * 4. Clear / Delete Department Schedules
   */
  async deleteDepartmentSchedules(university: string, department: string) {
    const dept = await this.prisma.department.findFirst({
      where: {
        code: { equals: department, mode: 'insensitive' },
        university: { code: { equals: university, mode: 'insensitive' } },
      },
    });

    if (!dept) {
      throw new NotFoundException(`Department '${department}' not found.`);
    }

    const deleted = await this.prisma.scheduleSlot.deleteMany({
      where: { departmentId: dept.id },
    });

    return {
      success: true,
      department: dept.code,
      slotsRemoved: deleted.count,
    };
  }

  /**
   * 5. Delete an individual Schedule Slot (for slot-level routine maintenance)
   */
  async deleteScheduleSlot(id: string) {
    const slot = await this.prisma.scheduleSlot.findUnique({
      where: { id },
      include: { room: true },
    });

    if (!slot) {
      throw new NotFoundException(`Schedule slot with ID '${id}' not found.`);
    }

    await this.prisma.scheduleSlot.delete({
      where: { id },
    });

    return {
      success: true,
      deletedSlotId: id,
      message: `Schedule slot for ${slot.courseCode} (Batch ${slot.batch}-${slot.section}) deleted successfully.`,
    };
  }
}
