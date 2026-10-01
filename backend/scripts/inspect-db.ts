import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const slots = await prisma.scheduleSlot.findMany({
    where: { batch: '68', dayOfWeek: 'THU' },
    select: {
      id: true,
      batch: true,
      section: true,
      courseCode: true,
      courseName: true,
      startTime: true,
      endTime: true,
      overrides: {
        select: {
          id: true,
          action: true,
          newStartTime: true,
          newEndTime: true,
          reason: true,
          overrideDate: true,
        },
      },
      department: { select: { code: true } },
    },
  });
  console.log('Slots on THU for Batch 68:', JSON.stringify(slots, null, 2));
}

main().finally(async () => {
  await prisma.$disconnect();
});
