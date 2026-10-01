import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateAcademicBatchDto,
  UniversityCohortTreeDto,
} from './dto/create-batch.dto';
import { UpdateAcademicBatchDto } from './dto/update-batch.dto';

@Injectable()
export class MetaService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------------------------------------------------------------------------
  // Helper: Universal University & Department Resolver
  // Resolves entities by UUID, unique code (e.g. 'UU', 'CSE'), or name
  // ---------------------------------------------------------------------------
  private async resolveDepartment(options: {
    university?: string;
    department?: string;
    departmentId?: string;
  }) {
    const uniInput = options.university?.trim();
    const deptInput = (options.department || options.departmentId || '').trim();

    if (!deptInput) {
      throw new BadRequestException(
        'Department identifier (code, name, or UUID) must be provided',
      );
    }

    let universityId: string | undefined;

    // 1. Resolve University if provided
    if (uniInput) {
      const university = await this.prisma.university.findFirst({
        where: {
          OR: [
            { id: uniInput },
            { code: { equals: uniInput, mode: 'insensitive' } },
            { name: { contains: uniInput, mode: 'insensitive' } },
          ],
        },
      });

      if (!university) {
        const availableUnis = await this.prisma.university.findMany({
          select: { code: true, name: true },
        });
        const list = availableUnis.map((u) => `${u.code} (${u.name})`).join(', ');
        throw new NotFoundException(
          `University '${uniInput}' not found. Available universities: ${list || 'None'}`,
        );
      }
      universityId = university.id;
    }

    // 2. Resolve Department within University
    const deptWhere: any = {};
    if (universityId) {
      deptWhere.universityId = universityId;
    }

    const department = await this.prisma.department.findFirst({
      where: {
        ...deptWhere,
        OR: [
          { id: deptInput },
          { code: { equals: deptInput, mode: 'insensitive' } },
          { name: { contains: deptInput, mode: 'insensitive' } },
        ],
      },
      include: {
        university: {
          select: { id: true, code: true, name: true },
        },
      },
    });

    if (!department) {
      const availableDepts = await this.prisma.department.findMany({
        where: universityId ? { universityId } : {},
        select: { code: true, name: true },
      });
      const list = availableDepts.map((d) => `${d.code} (${d.name})`).join(', ');
      throw new NotFoundException(
        `Department '${deptInput}' not found${
          uniInput ? ` in university '${uniInput}'` : ''
        }. Available departments: ${list || 'None'}`,
      );
    }

    return department;
  }

  // ---------------------------------------------------------------------------
  // 1. Public Metadata: Returns active universities, departments, batches, sections
  // ---------------------------------------------------------------------------
  async getRegistrationOptions() {
    const universities = await this.prisma.university.findMany({
      where: { isActive: true },
      select: {
        id: true,
        code: true,
        name: true,
        domain: true,
        departments: {
          select: {
            id: true,
            code: true,
            name: true,
            academicBatches: {
              where: { isActive: true },
              select: {
                id: true,
                name: true,
                sections: true,
              },
              orderBy: { name: 'desc' },
            },
          },
          orderBy: { code: 'asc' },
        },
      },
      orderBy: { code: 'asc' },
    });

    return {
      universities: universities.map((u) => ({
        id: u.id,
        code: u.code,
        name: u.name,
        domain: u.domain,
        departments: u.departments.map((d) => ({
          id: d.id,
          code: d.code,
          name: d.name,
          batches: d.academicBatches.map((b) => ({
            id: b.id,
            name: b.name,
            sections: b.sections,
          })),
        })),
      })),
    };
  }

  // ---------------------------------------------------------------------------
  // 2. Super Admin: List academic batches by university & department
  // ---------------------------------------------------------------------------
  async getAdminBatches(query?: {
    university?: string;
    department?: string;
    departmentId?: string;
  }) {
    let departmentId = query?.departmentId;

    if (!departmentId && (query?.university || query?.department)) {
      if (query.department) {
        const dept = await this.resolveDepartment({
          university: query.university,
          department: query.department,
        });
        departmentId = dept.id;
      }
    }

    const where: any = {};
    if (departmentId) {
      where.departmentId = departmentId;
    } else if (query?.university) {
      const uniInput = query.university.trim();
      where.department = {
        university: {
          OR: [
            { id: uniInput },
            { code: { equals: uniInput, mode: 'insensitive' } },
            { name: { contains: uniInput, mode: 'insensitive' } },
          ],
        },
      };
    }

    return this.prisma.academicBatch.findMany({
      where,
      include: {
        department: {
          select: {
            id: true,
            code: true,
            name: true,
            university: {
              select: { id: true, code: true, name: true },
            },
          },
        },
      },
      orderBy: [{ departmentId: 'asc' }, { name: 'desc' }],
    });
  }

  // ---------------------------------------------------------------------------
  // Super Admin: Get single batch details by ID
  // ---------------------------------------------------------------------------
  async getBatchById(id: string) {
    const batch = await this.prisma.academicBatch.findUnique({
      where: { id },
      include: {
        department: {
          select: {
            id: true,
            code: true,
            name: true,
            university: {
              select: { id: true, code: true, name: true },
            },
          },
        },
      },
    });

    if (!batch) {
      throw new NotFoundException(`Academic batch with ID '${id}' not found`);
    }

    return batch;
  }

  // ---------------------------------------------------------------------------
  // 3. Super Admin: Hierarchical Batch Insertion / Upsert
  // Supports: university -> department -> list of batches [ { name, sections } ]
  // Also supports single batch { name, sections } directly
  // ---------------------------------------------------------------------------
  async createOrUpsertBatch(dto: CreateAcademicBatchDto) {
    const department = await this.resolveDepartment({
      university: dto.university,
      department: dto.department,
      departmentId: dto.departmentId,
    });

    // Case A: Bulk list of batches passed under department
    if (dto.batches && dto.batches.length > 0) {
      const results = [];

      for (const b of dto.batches) {
        const cleanSections = Array.from(
          new Set(b.sections.map((s) => s.trim().toUpperCase())),
        ).sort();

        const record = await this.prisma.academicBatch.upsert({
          where: {
            departmentId_name: {
              departmentId: department.id,
              name: b.name.trim(),
            },
          },
          update: {
            sections: cleanSections,
            isActive: b.isActive ?? true,
          },
          create: {
            departmentId: department.id,
            name: b.name.trim(),
            sections: cleanSections,
            isActive: b.isActive ?? true,
          },
        });
        results.push(record);
      }

      return {
        success: true,
        university: department.university,
        department: {
          id: department.id,
          code: department.code,
          name: department.name,
        },
        totalBatchesProcessed: results.length,
        batches: results,
      };
    }

    // Case B: Single batch passed directly at root
    if (dto.name && dto.sections) {
      const cleanSections = Array.from(
        new Set(dto.sections.map((s) => s.trim().toUpperCase())),
      ).sort();

      const batch = await this.prisma.academicBatch.upsert({
        where: {
          departmentId_name: {
            departmentId: department.id,
            name: dto.name.trim(),
          },
        },
        update: {
          sections: cleanSections,
          isActive: dto.isActive ?? true,
        },
        create: {
          departmentId: department.id,
          name: dto.name.trim(),
          sections: cleanSections,
          isActive: dto.isActive ?? true,
        },
      });

      return {
        success: true,
        university: department.university,
        department: {
          id: department.id,
          code: department.code,
          name: department.name,
        },
        batch,
      };
    }

    throw new BadRequestException(
      'Invalid payload: You must provide either a "batches" array or single batch ("name" and "sections").',
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Super Admin: Full University Cohort Tree Sync
  // Format: university -> departments -> batches -> sections
  // ---------------------------------------------------------------------------
  async syncUniversityCohortTree(dto: UniversityCohortTreeDto) {
    const uniInput = dto.university.trim();

    const university = await this.prisma.university.findFirst({
      where: {
        OR: [
          { id: uniInput },
          { code: { equals: uniInput, mode: 'insensitive' } },
          { name: { contains: uniInput, mode: 'insensitive' } },
        ],
      },
    });

    if (!university) {
      throw new NotFoundException(`University '${uniInput}' not found`);
    }

    const processedDepartments = [];

    for (const deptDto of dto.departments) {
      const department = await this.resolveDepartment({
        university: university.id,
        department: deptDto.department,
      });

      const batchResults = [];
      for (const b of deptDto.batches) {
        const cleanSections = Array.from(
          new Set(b.sections.map((s) => s.trim().toUpperCase())),
        ).sort();

        const record = await this.prisma.academicBatch.upsert({
          where: {
            departmentId_name: {
              departmentId: department.id,
              name: b.name.trim(),
            },
          },
          update: {
            sections: cleanSections,
            isActive: b.isActive ?? true,
          },
          create: {
            departmentId: department.id,
            name: b.name.trim(),
            sections: cleanSections,
            isActive: b.isActive ?? true,
          },
        });
        batchResults.push(record);
      }

      processedDepartments.push({
        department: {
          id: department.id,
          code: department.code,
          name: department.name,
        },
        totalBatches: batchResults.length,
        batches: batchResults,
      });
    }

    return {
      success: true,
      university: {
        id: university.id,
        code: university.code,
        name: university.name,
      },
      departments: processedDepartments,
    };
  }

  // ---------------------------------------------------------------------------
  // 5. Super Admin: Update existing batch or sections by batch ID
  // ---------------------------------------------------------------------------
  async updateBatch(id: string, dto: UpdateAcademicBatchDto) {
    const batch = await this.prisma.academicBatch.findUnique({
      where: { id },
    });

    if (!batch) {
      throw new NotFoundException(`Academic batch with ID '${id}' not found`);
    }

    const cleanSections = dto.sections
      ? Array.from(new Set(dto.sections.map((s) => s.trim().toUpperCase()))).sort()
      : undefined;

    return this.prisma.academicBatch.update({
      where: { id },
      data: {
        sections: cleanSections,
        isActive: dto.isActive,
      },
    });
  }

  // ---------------------------------------------------------------------------
  // 6. Super Admin: Delete an academic batch
  // ---------------------------------------------------------------------------
  async deleteBatch(id: string) {
    const batch = await this.prisma.academicBatch.findUnique({
      where: { id },
    });

    if (!batch) {
      throw new NotFoundException(`Academic batch with ID '${id}' not found`);
    }

    return this.prisma.academicBatch.delete({
      where: { id },
    });
  }

  // ---------------------------------------------------------------------------
  // 7. Routine Ingestion Auto-Discovery Sync Engine
  // ---------------------------------------------------------------------------
  async syncBatchesFromRoutineSlots(
    slots: Array<{ departmentId: string; batch: string; section: string }>,
  ) {
    const batchMap = new Map<string, { departmentId: string; batch: string; sections: Set<string> }>();

    for (const slot of slots) {
      const key = `${slot.departmentId}_${slot.batch.trim()}`;
      if (!batchMap.has(key)) {
        batchMap.set(key, {
          departmentId: slot.departmentId,
          batch: slot.batch.trim(),
          sections: new Set<string>(),
        });
      }
      batchMap.get(key)!.sections.add(slot.section.trim().toUpperCase());
    }

    const results = [];
    for (const item of batchMap.values()) {
      const sectionList = Array.from(item.sections).sort();
      const record = await this.prisma.academicBatch.upsert({
        where: {
          departmentId_name: {
            departmentId: item.departmentId,
            name: item.batch,
          },
        },
        update: {
          sections: {
            push: sectionList,
          },
          isActive: true,
        },
        create: {
          departmentId: item.departmentId,
          name: item.batch,
          sections: sectionList,
          isActive: true,
        },
      });
      results.push(record);
    }

    return results;
  }
}
