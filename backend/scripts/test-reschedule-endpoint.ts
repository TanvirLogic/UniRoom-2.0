import * as dotenv from 'dotenv';
dotenv.config();
import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';

const prisma = new PrismaClient();

async function main() {
  // 1. Find or create CR user for SWE Batch 68 Sec B
  let cr = await prisma.user.findFirst({
    where: { email: 'cr.secb@uttara.edu.bd' },
    include: { department: true }
  });

  console.log('CR user:', cr?.email, cr?.role, cr?.department?.code, cr?.batch, cr?.section);

  // 2. Find slots for SWE Batch 68 Sec B
  const slot = await prisma.scheduleSlot.findFirst({
    where: {
      departmentId: cr!.departmentId,
      batch: cr!.batch!,
      section: cr!.section!,
      dayOfWeek: 'THU'
    },
    include: { department: true, room: true }
  });

  console.log('Found slot:', slot?.id, slot?.courseCode, slot?.startTime, slot?.endTime);

  if (!slot) {
    console.log('No slot found for this CR!');
    return;
  }

  // 3. Make HTTP call to backend endpoint
  const loginRes = await fetch('http://127.0.0.1:3000/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'cr.secb@uttara.edu.bd', password: 'Password123!' })
  });

  const loginData: any = await loginRes.json();
  console.log('Login status:', loginRes.status, 'Token received:', !!loginData?.data?.accessToken);

  const token = loginData?.data?.accessToken;
  if (!token) {
    console.error('Failed to log in:', loginData);
    return;
  }

  // 4. Test Reschedule Today
  const rescheduleRes = await fetch(`http://127.0.0.1:3000/api/v1/schedules/slots/${slot.id}/reschedule-today`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      newStartTime: '14:30',
      newEndTime: '16:00',
      reason: 'Faculty requested afternoon shift (morning class was delayed)'
    })
  });

  const rescheduleData: any = await rescheduleRes.json();
  console.log('Reschedule status:', rescheduleRes.status);
  console.log('Reschedule response:', JSON.stringify(rescheduleData, null, 2));

  // 5. Test Fetch Schedules to see how it looks
  const schedRes = await fetch(`http://127.0.0.1:3000/api/v1/schedules?department=${cr!.department!.code}&batch=${cr!.batch}&section=${cr!.section}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const schedData: any = await schedRes.json();
  console.log('Fetched slots count:', schedData?.data?.length);
  const updatedSlot = schedData?.data?.find((s: any) => s.id === slot.id);
  console.log('Updated slot from API:', JSON.stringify(updatedSlot, null, 2));
}

main().finally(() => prisma.$disconnect());
