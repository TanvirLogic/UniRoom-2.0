import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateUniversityDto } from './dto/create-university.dto';
import { UpdateUniversityDto } from './dto/update-university.dto';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { UpdateDepartmentDto } from './dto/update-department.dto';

@Injectable()
export class UniversitiesService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------------------------------------------------------------------------
  // Universities CRUD
  // ---------------------------------------------------------------------------

  async findAllUniversities(onlyActive = true) {
    return this.prisma.university.findMany({
      where: onlyActive ? { isActive: true } : {},
      include: {
        departments: {
          select: {
            id: true,
            code: true,
            name: true,
            _count: {
              select: { rooms: true, academicBatches: true },
            },
          },
          orderBy: { code: 'asc' },
        },
        _count: {
          select: { rooms: true, users: true },
        },
      },
      orderBy: { code: 'asc' },
    });
  }

  async findUniversityById(idOrCode: string) {
    const trimmed = idOrCode.trim();
    const university = await this.prisma.university.findFirst({
      where: {
        OR: [
          { id: trimmed },
          { code: { equals: trimmed, mode: 'insensitive' } },
        ],
      },
      include: {
        departments: {
          include: {
            buildings: true,
            academicBatches: {
              where: { isActive: true },
              orderBy: { name: 'desc' },
            },
            _count: {
              select: { rooms: true, users: true, scheduleSlots: true },
            },
          },
          orderBy: { code: 'asc' },
        },
        _count: {
          select: { rooms: true, users: true },
        },
      },
    });

    if (!university) {
      throw new NotFoundException(`University '${idOrCode}' not found`);
    }

    return university;
  }

  async createUniversity(dto: CreateUniversityDto) {
    const normalizedCode = dto.code.trim().toUpperCase();

    const existing = await this.prisma.university.findUnique({
      where: { code: normalizedCode },
    });

    if (existing) {
      throw new ConflictException(`University with code '${normalizedCode}' already exists`);
    }

    return this.prisma.university.create({
      data: {
        name: dto.name.trim(),
        code: normalizedCode,
        domain: dto.domain?.trim().toLowerCase(),
        logoUrl: dto.logoUrl?.trim(),
        operatingDays: dto.operatingDays,
        isActive: dto.isActive ?? true,
      },
    });
  }

  async updateUniversity(idOrCode: string, dto: UpdateUniversityDto) {
    const uni = await this.findUniversityById(idOrCode);

    if (dto.code) {
      const normalizedCode = dto.code.trim().toUpperCase();
      const existing = await this.prisma.university.findFirst({
        where: {
          code: normalizedCode,
          NOT: { id: uni.id },
        },
      });

      if (existing) {
        throw new ConflictException(`University with code '${normalizedCode}' already exists`);
      }
    }

    return this.prisma.university.update({
      where: { id: uni.id },
      data: {
        ...(dto.name && { name: dto.name.trim() }),
        ...(dto.code && { code: dto.code.trim().toUpperCase() }),
        ...(dto.domain !== undefined && { domain: dto.domain?.trim().toLowerCase() }),
        ...(dto.logoUrl !== undefined && { logoUrl: dto.logoUrl?.trim() }),
        ...(dto.operatingDays && { operatingDays: dto.operatingDays }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });
  }

  async deleteUniversity(idOrCode: string) {
    const uni = await this.findUniversityById(idOrCode);
    return this.prisma.university.delete({ where: { id: uni.id } });
  }

  // ---------------------------------------------------------------------------
  // Departments CRUD
  // ---------------------------------------------------------------------------

  async findAllDepartments(query?: { university?: string; search?: string }) {
    const where: any = {};

    if (query?.university) {
      const uni = await this.findUniversityById(query.university);
      where.universityId = uni.id;
    }

    if (query?.search) {
      const s = query.search.trim();
      where.OR = [
        { code: { contains: s, mode: 'insensitive' } },
        { name: { contains: s, mode: 'insensitive' } },
      ];
    }

    return this.prisma.department.findMany({
      where,
      include: {
        university: {
          select: { id: true, code: true, name: true },
        },
        buildings: true,
        academicBatches: {
          where: { isActive: true },
          orderBy: { name: 'desc' },
        },
        _count: {
          select: { rooms: true, scheduleSlots: true, users: true },
        },
      },
      orderBy: [{ universityId: 'asc' }, { code: 'asc' }],
    });
  }

  async findDepartmentById(idOrCode: string) {
    const trimmed = idOrCode.trim();
    const dept = await this.prisma.department.findFirst({
      where: {
        OR: [
          { id: trimmed },
          { code: { equals: trimmed, mode: 'insensitive' } },
        ],
      },
      include: {
        university: {
          select: { id: true, code: true, name: true },
        },
        buildings: {
          include: { rooms: true },
        },
        academicBatches: {
          where: { isActive: true },
          orderBy: { name: 'desc' },
        },
        _count: {
          select: { rooms: true, scheduleSlots: true, users: true },
        },
      },
    });

    if (!dept) {
      throw new NotFoundException(`Department '${idOrCode}' not found`);
    }

    return dept;
  }

  async getDepartmentsByUniversity(universityIdOrCode: string) {
    const university = await this.findUniversityById(universityIdOrCode);

    return this.prisma.department.findMany({
      where: { universityId: university.id },
      include: {
        buildings: true,
        academicBatches: {
          where: { isActive: true },
          orderBy: { name: 'desc' },
        },
        _count: {
          select: { rooms: true, scheduleSlots: true, users: true },
        },
      },
      orderBy: { code: 'asc' },
    });
  }

  async createDepartment(dto: CreateDepartmentDto) {
    const uniInput = (dto.university || dto.universityId || '').trim();
    if (!uniInput) {
      throw new ConflictException('University identifier (code or ID, e.g. "UU") is required');
    }

    const university = await this.findUniversityById(uniInput);
    const normalizedCode = dto.code.trim().toUpperCase();

    const existing = await this.prisma.department.findUnique({
      where: {
        universityId_code: {
          universityId: university.id,
          code: normalizedCode,
        },
      },
    });

    if (existing) {
      throw new ConflictException(
        `Department with code '${normalizedCode}' already exists in university '${university.code}'`,
      );
    }

    return this.prisma.department.create({
      data: {
        universityId: university.id,
        name: dto.name.trim(),
        code: normalizedCode,
      },
      include: {
        university: {
          select: { id: true, code: true, name: true },
        },
      },
    });
  }

  async updateDepartment(idOrCode: string, dto: UpdateDepartmentDto) {
    const dept = await this.findDepartmentById(idOrCode);

    let targetUniId = dept.universityId;
    const uniInput = (dto.university || dto.universityId || '').trim();
    if (uniInput) {
      const university = await this.findUniversityById(uniInput);
      targetUniId = university.id;
    }

    if (dto.code) {
      const normalizedCode = dto.code.trim().toUpperCase();

      const existing = await this.prisma.department.findFirst({
        where: {
          universityId: targetUniId,
          code: normalizedCode,
          NOT: { id: dept.id },
        },
      });

      if (existing) {
        throw new ConflictException(
          `Department with code '${normalizedCode}' already exists in this university`,
        );
      }
    }

    return this.prisma.department.update({
      where: { id: dept.id },
      data: {
        universityId: targetUniId,
        ...(dto.name && { name: dto.name.trim() }),
        ...(dto.code && { code: dto.code.trim().toUpperCase() }),
      },
      include: {
        university: {
          select: { id: true, code: true, name: true },
        },
      },
    });
  }

  async deleteDepartment(idOrCode: string) {
    const dept = await this.findDepartmentById(idOrCode);
    return this.prisma.department.delete({ where: { id: dept.id } });
  }
}
