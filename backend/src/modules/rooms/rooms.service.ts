import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DayOfWeek, OverrideAction, Prisma, Role, RoomStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { UpdateRoomStatusDto } from './dto/update-room-status.dto';
import { QueryRoomsDto } from './dto/query-rooms.dto';
import { FindFreeRoomDto } from './dto/find-free-room.dto';
import { CreateBuildingDto } from './dto/create-building.dto';
import { UpdateBuildingDto } from './dto/update-building.dto';
import { BookExtraClassDto } from './dto/book-extra-class.dto';
import { PushNotificationService } from '../notifications/push-notification.service';

interface UserContext {
  id?: string;
  universityId?: string;
  departmentId?: string;
  role?: Role | string;
}

@Injectable()
export class RoomsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  // ---------------------------------------------------------------------------
  // 1. Buildings CRUD
  // ---------------------------------------------------------------------------

  async getBuildings(departmentId?: string, universityId?: string) {
    const where: Prisma.BuildingWhereInput = {};

    if (departmentId) {
      where.departmentId = departmentId;
    } else if (universityId) {
      where.department = {
        university: {
          OR: [
            { id: universityId },
            { code: { equals: universityId, mode: 'insensitive' } },
          ],
        },
      };
    }

    return this.prisma.building.findMany({
      where,
      include: {
        department: {
          select: {
            id: true,
            name: true,
            code: true,
            universityId: true,
            university: { select: { id: true, code: true, name: true } },
          },
        },
        _count: { select: { rooms: true } },
      },
      orderBy: { name: 'asc' },
    });
  }

  async getBuildingById(id: string) {
    const building = await this.prisma.building.findUnique({
      where: { id },
      include: {
        department: true,
        rooms: {
          orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
        },
      },
    });

    if (!building) {
      throw new NotFoundException(`Building with ID '${id}' not found`);
    }

    return building;
  }

  async createBuilding(dto: CreateBuildingDto) {
    const dept = await this.prisma.department.findFirst({
      where: {
        OR: [
          { id: dto.departmentId },
          { code: { equals: dto.departmentId, mode: 'insensitive' } },
        ],
      },
    });
    if (!dept) {
      throw new NotFoundException(`Department with identifier '${dto.departmentId}' not found`);
    }

    return this.prisma.building.create({
      data: {
        departmentId: dept.id,
        name: dto.name.trim(),
        campusName: dto.campusName?.trim() || 'Main Campus',
      },
      include: { department: true },
    });
  }

  async updateBuilding(id: string, dto: UpdateBuildingDto) {
    await this.getBuildingById(id);

    return this.prisma.building.update({
      where: { id },
      data: {
        ...(dto.departmentId && { departmentId: dto.departmentId }),
        ...(dto.name && { name: dto.name.trim() }),
        ...(dto.campusName !== undefined && { campusName: dto.campusName.trim() }),
      },
      include: { department: true },
    });
  }

  async deleteBuilding(id: string) {
    await this.getBuildingById(id);
    return this.prisma.building.delete({ where: { id } });
  }

  // ---------------------------------------------------------------------------
  // 2. Room Inventory & Query Engine
  // ---------------------------------------------------------------------------

  async getRooms(query: QueryRoomsDto, user?: UserContext) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const where: Prisma.RoomWhereInput = {};

    // Multi-tenant scoping: if user is not SUPER_ADMIN, scope strictly to their university
    if (user && user.role !== Role.SUPER_ADMIN && user.universityId) {
      where.university = {
        OR: [
          { id: user.universityId },
          { code: { equals: user.universityId, mode: 'insensitive' } },
        ],
      };
    } else if (query.universityId) {
      where.university = {
        OR: [
          { id: query.universityId },
          { code: { equals: query.universityId, mode: 'insensitive' } },
        ],
      };
    }

    if (query.departmentId) {
      where.department = {
        OR: [
          { id: query.departmentId },
          { code: { equals: query.departmentId, mode: 'insensitive' } },
        ],
      };
    }
    if (query.buildingId) where.buildingId = query.buildingId;
    if (query.floor !== undefined) where.floor = query.floor;
    if (query.status) where.currentStatus = query.status;
    if (query.minCapacity) where.capacity = { gte: query.minCapacity };

    if (query.campusName) {
      where.building = { campusName: { contains: query.campusName, mode: 'insensitive' } };
    }

    if (query.search) {
      where.roomNumber = { contains: query.search.trim(), mode: 'insensitive' };
    }

    // Execute paginated rooms query and status groupBy concurrently (2 queries instead of 6)
    const [rooms, statusGroups, totalCount] = await Promise.all([
      this.prisma.room.findMany({
        where,
        include: {
          building: { select: { id: true, name: true, campusName: true } },
          department: { select: { id: true, code: true, name: true } },
        },
        orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
        skip,
        take: limit,
      }),
      this.prisma.room.groupBy({
        by: ['currentStatus'],
        where,
        _count: { _all: true },
      }),
      this.prisma.room.count({ where }),
    ]);

    let availableCount = 0;
    let runningClassCount = 0;
    let reservedCount = 0;
    let maintenanceCount = 0;

    for (const group of statusGroups) {
      const count = group._count._all;
      if (group.currentStatus === RoomStatus.AVAILABLE) availableCount = count;
      else if (group.currentStatus === RoomStatus.RUNNING_CLASS) runningClassCount = count;
      else if (group.currentStatus === RoomStatus.RESERVED) reservedCount = count;
      else if (group.currentStatus === RoomStatus.MAINTENANCE) maintenanceCount = count;
    }

    return {
      stats: {
        total: totalCount,
        available: availableCount,
        runningClass: runningClassCount,
        reserved: reservedCount,
        maintenance: maintenanceCount,
      },
      pagination: {
        page,
        limit,
        totalPages: Math.ceil(totalCount / limit) || 1,
        hasNextPage: page * limit < totalCount,
        hasPreviousPage: page > 1,
      },
      rooms,
    };
  }

  async getRoomById(id: string) {
    let room = await this.prisma.room.findUnique({
      where: { id },
      include: {
        building: true,
        department: true,
        university: { select: { id: true, name: true, code: true } },
        scheduleSlots: {
          where: { isActive: true },
          orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
        },
        roomLogs: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: {
            changedByUser: { select: { id: true, fullName: true, role: true, email: true } },
          },
        },
      },
    });

    if (!room) {
      room = await this.prisma.room.findFirst({
        where: {
          OR: [
            { roomNumber: { equals: id, mode: 'insensitive' } },
            { roomNumber: { contains: id, mode: 'insensitive' } },
          ],
        },
        include: {
          building: true,
          department: true,
          university: { select: { id: true, name: true, code: true } },
          scheduleSlots: {
            where: { isActive: true },
            orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
          },
          roomLogs: {
            take: 10,
            orderBy: { createdAt: 'desc' },
            include: {
              changedByUser: { select: { id: true, fullName: true, role: true, email: true } },
            },
          },
        },
      });
    }

    if (!room) {
      throw new NotFoundException(`Room with ID '${id}' not found`);
    }

    return room;
  }

  async createRoom(dto: CreateRoomDto) {
    let targetUniId = dto.universityId;
    if (dto.universityId) {
      const uni = await this.prisma.university.findFirst({
        where: {
          OR: [
            { id: dto.universityId },
            { code: { equals: dto.universityId, mode: 'insensitive' } },
          ],
        },
      });
      if (uni) targetUniId = uni.id;
    }

    let targetDeptId = dto.departmentId;
    if (dto.departmentId) {
      const dept = await this.prisma.department.findFirst({
        where: {
          OR: [
            { id: dto.departmentId },
            { code: { equals: dto.departmentId, mode: 'insensitive' } },
          ],
        },
      });
      if (dept) targetDeptId = dept.id;
    }

    const building = await this.prisma.building.findUnique({
      where: { id: dto.buildingId },
    });
    if (!building) {
      throw new NotFoundException(`Building with ID '${dto.buildingId}' not found`);
    }

    const normalizedRoomNumber = dto.roomNumber.trim();

    const existing = await this.prisma.room.findUnique({
      where: {
        buildingId_roomNumber: {
          buildingId: dto.buildingId,
          roomNumber: normalizedRoomNumber,
        },
      },
    });

    if (existing) {
      // Overwrite all room infos according to the new allocation - no conflict thrown
      return this.prisma.room.update({
        where: { id: existing.id },
        data: {
          universityId: targetUniId,
          departmentId: targetDeptId,
          buildingId: dto.buildingId,
          floor: dto.floor !== undefined ? dto.floor : existing.floor,
          capacity: dto.capacity !== undefined ? dto.capacity : existing.capacity,
          currentStatus: dto.currentStatus ?? existing.currentStatus,
        },
        include: { building: true, department: true },
      });
    }

    return this.prisma.room.create({
      data: {
        universityId: targetUniId,
        departmentId: targetDeptId,
        buildingId: dto.buildingId,
        roomNumber: normalizedRoomNumber,
        floor: dto.floor ?? 1,
        capacity: dto.capacity ?? 40,
        currentStatus: dto.currentStatus ?? RoomStatus.AVAILABLE,
        version: 1,
      },
      include: { building: true, department: true },
    });
  }

  async updateRoom(id: string, dto: UpdateRoomDto) {
    const room = await this.getRoomById(id);

    let targetUniId = dto.universityId;
    if (dto.universityId) {
      const uni = await this.prisma.university.findFirst({
        where: {
          OR: [
            { id: dto.universityId },
            { code: { equals: dto.universityId, mode: 'insensitive' } },
          ],
        },
      });
      if (uni) targetUniId = uni.id;
    }

    let targetDeptId = dto.departmentId;
    if (dto.departmentId) {
      const dept = await this.prisma.department.findFirst({
        where: {
          OR: [
            { id: dto.departmentId },
            { code: { equals: dto.departmentId, mode: 'insensitive' } },
          ],
        },
      });
      if (dept) targetDeptId = dept.id;
    }

    if (dto.roomNumber || dto.buildingId) {
      const targetBuildingId = dto.buildingId || room.buildingId;
      const targetRoomNumber = dto.roomNumber?.trim() || room.roomNumber;

      const existing = await this.prisma.room.findFirst({
        where: {
          buildingId: targetBuildingId,
          roomNumber: targetRoomNumber,
          NOT: { id },
        },
      });

      if (existing) {
        // Overwrite existing room info according to the new allocation
        return this.prisma.room.update({
          where: { id: existing.id },
          data: {
            departmentId: targetDeptId || existing.departmentId,
            floor: dto.floor !== undefined ? dto.floor : existing.floor,
            capacity: dto.capacity !== undefined ? dto.capacity : existing.capacity,
            currentStatus: dto.currentStatus ?? existing.currentStatus,
          },
          include: { building: true, department: true },
        });
      }
    }

    return this.prisma.room.update({
      where: { id },
      data: {
        ...(targetUniId && { universityId: targetUniId }),
        ...(targetDeptId && { departmentId: targetDeptId }),
        ...(dto.buildingId && { buildingId: dto.buildingId }),
        ...(dto.roomNumber && { roomNumber: dto.roomNumber.trim() }),
        ...(dto.floor !== undefined && { floor: dto.floor }),
        ...(dto.capacity !== undefined && { capacity: dto.capacity }),
        ...(dto.currentStatus && { currentStatus: dto.currentStatus }),
      },
      include: { building: true, department: true },
    });
  }

  async deleteRoom(id: string) {
    await this.getRoomById(id);
    return this.prisma.room.delete({ where: { id } });
  }

  // ---------------------------------------------------------------------------
  // 3. Room Status Toggle with Optimistic Concurrency Control (OCC)
  // ---------------------------------------------------------------------------

  async updateRoomStatus(id: string, dto: UpdateRoomStatusDto, userId: string) {
    let room = await this.prisma.room.findUnique({
      where: { id },
    });

    if (!room) {
      room = await this.prisma.room.findFirst({
        where: {
          OR: [
            { roomNumber: { equals: id, mode: 'insensitive' } },
            { roomNumber: { contains: id, mode: 'insensitive' } },
          ],
        },
      });
    }

    if (!room) {
      throw new NotFoundException(`Room with ID '${id}' not found`);
    }

    const realId = room.id;

    // OCC Check: Verify version matches to prevent double-booking collisions
    if (room.version !== dto.version) {
      throw new ConflictException(
        `Optimistic Concurrency Lock Conflict: Room status was modified by another user. Your version was ${dto.version}, but current version is ${room.version}. Please refresh and try again.`,
      );
    }

    const leaseExpiresAt = dto.leaseDurationMinutes
      ? new Date(Date.now() + dto.leaseDurationMinutes * 60 * 1000)
      : dto.status === RoomStatus.AVAILABLE
        ? null
        : room.leaseExpiresAt;

    // Atomic transaction: update room + increment version + write RoomLog
    const result = await this.prisma.$transaction(async (tx) => {
      const updatedRoom = await tx.room.update({
        where: { id: realId },
        data: {
          currentStatus: dto.status,
          version: { increment: 1 },
          leaseExpiresAt,
          currentCourse: dto.currentCourse ?? (dto.status === RoomStatus.AVAILABLE ? null : room.currentCourse),
          currentTeacher: dto.currentTeacher ?? (dto.status === RoomStatus.AVAILABLE ? null : room.currentTeacher),
          currentBatch: dto.currentBatch ?? (dto.status === RoomStatus.AVAILABLE ? null : room.currentBatch),
        },
        include: { building: true, department: true },
      });

      const auditLog = await tx.roomLog.create({
        data: {
          roomId: realId,
          changedByUserId: userId,
          previousStatus: room.currentStatus,
          newStatus: dto.status,
          note: dto.note ?? null,
        },
        include: {
          changedByUser: { select: { fullName: true, email: true, role: true } },
        },
      });

      return {
        room: updatedRoom,
        auditLog,
      };
    });

    // Broadcast FCM alert to department CRs when a room is made free
    if (dto.status === RoomStatus.AVAILABLE && (result.room.department?.code || result.room.departmentId)) {
      const deptCode = result.room.department?.code || 'all';
      this.pushNotificationService.sendToCrTopic(deptCode, {
        title: `Room ${result.room.roomNumber} is Now Free! 🟢`,
        body: `A class ended or was cancelled in Room ${result.room.roomNumber}. Tap to claim for your batch.`,
        data: { roomId: result.room.id, type: 'ROOM_FREED' },
      }).catch(() => {});
    }

    return result;
  }

  /**
   * Dedicated CR / Faculty endpoint to book an available room for an extra class
   * Automatically sends FCM push notifications to all students in that department, batch & section
   */
  async bookExtraClass(id: string, dto: BookExtraClassDto, userId: string) {
    let room = await this.prisma.room.findUnique({
      where: { id },
      include: { department: true, building: true },
    });

    if (!room) {
      room = await this.prisma.room.findFirst({
        where: {
          OR: [
            { roomNumber: { equals: id, mode: 'insensitive' } },
            { roomNumber: { contains: id, mode: 'insensitive' } },
          ],
        },
        include: { department: true, building: true },
      });
    }

    if (!room) {
      throw new NotFoundException(`Room with ID '${id}' not found`);
    }

    const realId = room.id;

    if (room.version !== dto.version) {
      throw new ConflictException(
        `Optimistic Concurrency Lock Conflict: Room status was modified by another user. Current version is ${room.version}. Please refresh and try again.`,
      );
    }

    const duration = dto.durationMinutes || 90;
    const leaseExpiresAt = new Date(Date.now() + duration * 60 * 1000);
    const cohortDisplay = `Batch ${dto.batch} (${dto.section})`;

    const result = await this.prisma.$transaction(async (tx) => {
      const updatedRoom = await tx.room.update({
        where: { id: realId },
        data: {
          currentStatus: RoomStatus.RUNNING_CLASS,
          version: { increment: 1 },
          leaseExpiresAt,
          currentCourse: dto.courseName,
          currentTeacher: dto.teacherInitials || null,
          currentBatch: cohortDisplay,
        },
        include: { building: true, department: true },
      });

      const auditLog = await tx.roomLog.create({
        data: {
          roomId: realId,
          changedByUserId: userId,
          previousStatus: room.currentStatus,
          newStatus: RoomStatus.RUNNING_CLASS,
          note: dto.note || `Extra class booked by CR for ${cohortDisplay}: ${dto.courseName}`,
        },
        include: {
          changedByUser: { select: { fullName: true, email: true, role: true } },
        },
      });

      return { room: updatedRoom, auditLog };
    });

    // Broadcast FCM Push Notification to all students of this department, batch, and section
    const deptCode = room.department?.code || 'all';
    this.pushNotificationService.sendToSectionTopic(deptCode, dto.batch, dto.section, {
      title: `⚡ Extra Class Booked: ${dto.courseName}`,
      body: `Room ${room.roomNumber} (${room.building.name}) is booked for ${cohortDisplay}. Teacher: ${dto.teacherInitials || 'Assigned Faculty'}.`,
      data: {
        roomId: room.id,
        courseName: dto.courseName,
        teacher: dto.teacherInitials || '',
        batch: dto.batch,
        section: dto.section,
        type: 'EXTRA_CLASS_BOOKED',
      },
    }).catch(() => {});

    // Also notify the faculty member if initials provided
    if (dto.teacherInitials) {
      this.pushNotificationService.sendToFacultyTopic(dto.teacherInitials, {
        title: `Room ${room.roomNumber} Reserved for Your Class`,
        body: `${cohortDisplay} booked Room ${room.roomNumber} for ${dto.courseName}.`,
        data: { roomId: room.id, type: 'FACULTY_CLASS_ALERT' },
      }).catch(() => {});
    }

    return result;
  }

  async getRoomLogs(roomId: string, limit = 20) {
    const room = await this.getRoomById(roomId);

    return this.prisma.roomLog.findMany({
      where: { roomId: room.id },
      take: Math.min(100, Math.max(1, limit)),
      orderBy: { createdAt: 'desc' },
      include: {
        changedByUser: {
          select: { id: true, fullName: true, email: true, role: true },
        },
      },
    });
  }

  // ---------------------------------------------------------------------------
  // 4. "Find Me a Free Room Now" (1-Tap Algorithmic Engine)
  // ---------------------------------------------------------------------------

  async findFreeRoomsNow(dto: FindFreeRoomDto, user?: UserContext) {
    const targetDepartmentId = dto.departmentId || user?.departmentId;
    const targetUniversityId = user?.universityId;

    // 1. Determine target date and DayOfWeek
    let targetDate: Date;
    if (dto.date) {
      targetDate = new Date(`${dto.date}T00:00:00.000Z`);
      if (isNaN(targetDate.getTime())) {
        throw new BadRequestException('Invalid date format. Expected YYYY-MM-DD');
      }
    } else {
      targetDate = new Date();
    }

    const dayOfWeekMap: Record<number, DayOfWeek> = {
      0: DayOfWeek.SUN,
      1: DayOfWeek.MON,
      2: DayOfWeek.TUE,
      3: DayOfWeek.WED,
      4: DayOfWeek.THU,
      5: DayOfWeek.FRI,
      6: DayOfWeek.SAT,
    };
    const targetDayOfWeek = dayOfWeekMap[targetDate.getDay()];

    // 2. Determine target time interval [reqStart, reqEnd] in HH:mm
    let reqStart: string;
    if (dto.startTime) {
      reqStart = dto.startTime;
    } else {
      const now = new Date();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      reqStart = `${hours}:${minutes}`;
    }

    const durationMinutes = dto.durationMinutes || 60;
    const reqEnd = this.addMinutesToTime(reqStart, durationMinutes);

    // 3. Query all candidate rooms for this department/university (strictly AVAILABLE rooms only)
    const roomWhere: Prisma.RoomWhereInput = {
      currentStatus: RoomStatus.AVAILABLE,
    };

    if (targetDepartmentId) {
      roomWhere.department = {
        OR: [
          { id: targetDepartmentId },
          { code: { equals: targetDepartmentId, mode: 'insensitive' } },
        ],
      };
    }
    if (targetUniversityId && user?.role !== Role.SUPER_ADMIN) {
      roomWhere.university = {
        OR: [
          { id: targetUniversityId },
          { code: { equals: targetUniversityId, mode: 'insensitive' } },
        ],
      };
    }
    if (dto.buildingId) roomWhere.buildingId = dto.buildingId;
    if (dto.floor !== undefined) roomWhere.floor = dto.floor;
    if (dto.minCapacity) roomWhere.capacity = { gte: dto.minCapacity };

    const candidateRooms = await this.prisma.room.findMany({
      where: roomWhere,
      include: {
        building: { select: { id: true, name: true, campusName: true } },
        department: { select: { id: true, code: true, name: true } },
        scheduleSlots: {
          where: {
            dayOfWeek: targetDayOfWeek,
            isActive: true,
          },
          include: {
            overrides: {
              where: {
                overrideDate: {
                  gte: new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate()),
                  lt: new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate() + 1),
                },
              },
            },
          },
          orderBy: { startTime: 'asc' },
        },
      },
    });

    const now = new Date();
    const freeRooms: Array<{
      room: (typeof candidateRooms)[0];
      freeWindow: { start: string; end: string; durationMinutes: number };
      freeUntil: string;
      freeMinutesRemaining: number;
      nextClass?: {
        startTime: string;
        endTime: string;
        courseName: string;
        facultyInitials: string;
        batch: string;
        section: string;
      };
    }> = [];

    for (const room of candidateRooms) {
      // Check live reservation lease or active occupation
      if (
        room.currentStatus !== RoomStatus.AVAILABLE ||
        (room.leaseExpiresAt && room.leaseExpiresAt > now)
      ) {
        continue; // Active lease held by another user or class currently running!
      }

      // Check timetable overlap
      let isOccupied = false;
      let nextClassAfterWindow: (typeof room.scheduleSlots)[0] | null = null;

      for (const slot of room.scheduleSlots) {
        // Check if class slot is cancelled via override
        const isCancelled = slot.overrides.some(
          (o) => o.action === OverrideAction.CANCELLED,
        );

        if (isCancelled) {
          continue; // Slot was cancelled for today! Room is freed!
        }

        // Interval overlap formula: slot.startTime < reqEnd && slot.endTime > reqStart
        const hasOverlap = slot.startTime < reqEnd && slot.endTime > reqStart;

        if (hasOverlap) {
          isOccupied = true;
          break;
        }

        // Track the next upcoming class after requested start time
        if (slot.startTime >= reqStart) {
          if (!nextClassAfterWindow || slot.startTime < nextClassAfterWindow.startTime) {
            nextClassAfterWindow = slot;
          }
        }
      }

      if (!isOccupied) {
        const freeUntil = nextClassAfterWindow ? nextClassAfterWindow.startTime : '20:00';
        const freeMinutesRemaining = this.calculateMinuteDifference(reqStart, freeUntil);

        freeRooms.push({
          room,
          freeWindow: {
            start: reqStart,
            end: reqEnd,
            durationMinutes,
          },
          freeUntil,
          freeMinutesRemaining: Math.max(0, freeMinutesRemaining),
          ...(nextClassAfterWindow && {
            nextClass: {
              startTime: nextClassAfterWindow.startTime,
              endTime: nextClassAfterWindow.endTime,
              courseName: nextClassAfterWindow.courseName,
              facultyInitials: nextClassAfterWindow.facultyInitials,
              batch: nextClassAfterWindow.batch,
              section: nextClassAfterWindow.section,
            },
          }),
        });
      }
    }

    // Rank candidate free rooms:
    // 1. Proximity to requested capacity (smallest adequate room first)
    // 2. Length of free duration (rooms free for longer come first)
    freeRooms.sort((a, b) => {
      const capA = a.room.capacity;
      const capB = b.room.capacity;
      const targetCap = dto.minCapacity || 30;

      const diffA = Math.abs(capA - targetCap);
      const diffB = Math.abs(capB - targetCap);

      if (diffA !== diffB) return diffA - diffB;
      return b.freeMinutesRemaining - a.freeMinutesRemaining;
    });

    return {
      query: {
        date: targetDate.toISOString().split('T')[0],
        dayOfWeek: targetDayOfWeek,
        requestedStart: reqStart,
        requestedEnd: reqEnd,
        durationMinutes,
        candidateCount: candidateRooms.length,
        freeRoomsFound: freeRooms.length,
      },
      results: freeRooms,
    };
  }

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  private addMinutesToTime(timeStr: string, minutesToAdd: number): string {
    const [hours, minutes] = timeStr.split(':').map(Number);
    const totalMinutes = hours * 60 + minutes + minutesToAdd;

    const newHours = Math.floor(totalMinutes / 60) % 24;
    const newMinutes = totalMinutes % 60;

    return `${String(newHours).padStart(2, '0')}:${String(newMinutes).padStart(2, '0')}`;
  }

  private calculateMinuteDifference(startStr: string, endStr: string): number {
    const [startH, startM] = startStr.split(':').map(Number);
    const [endH, endM] = endStr.split(':').map(Number);

    return endH * 60 + endM - (startH * 60 + startM);
  }
}
