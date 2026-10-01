import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Role } from '@prisma/client';

@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      return true; // Authentication guard should run first
    }

    // Super Admin has cross-tenant authority
    if (user.role === Role.SUPER_ADMIN) {
      return true;
    }

    const requestedUniversityId =
      request.params?.universityId ||
      request.body?.universityId ||
      request.query?.universityId;

    if (requestedUniversityId && requestedUniversityId !== user.universityId) {
      throw new ForbiddenException(
        'Cross-tenant violation: You cannot access or modify resources belonging to another university.',
      );
    }

    return true;
  }
}
