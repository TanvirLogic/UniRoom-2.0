import * as dotenv from 'dotenv';
dotenv.config();
import { PrismaClient } from '@prisma/client';
import * as jwt from 'jsonwebtoken';

const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    include: { department: true }
  });

  const slots = await prisma.scheduleSlot.findMany({
    where: { batch: '68', dayOfWeek: 'THU' },
    include: { department: true }
  });

  console.log('--- ALL USERS ---');
  for (const u of users) {
    console.log(`User: ${u.email} | Role: ${u.role} | Dept: ${u.department?.code} (${u.departmentId}) | Batch: ${u.batch} | Sec: ${u.section}`);
  }

  console.log('\n--- THURSDAY SLOTS FOR BATCH 68 ---');
  for (const s of slots) {
    console.log(`Slot ID: ${s.id} | Course: ${s.courseCode} | Dept: ${s.department?.code} (${s.departmentId}) | Batch: ${s.batch}-${s.section} | Time: ${s.startTime}-${s.endTime}`);
  }
}

main().finally(() => prisma.$disconnect());
