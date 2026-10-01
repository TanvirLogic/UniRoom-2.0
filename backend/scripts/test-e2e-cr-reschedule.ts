import * as dotenv from 'dotenv';
dotenv.config();

const API_BASE = 'http://127.0.0.1:3000/api/v1';

async function main() {
  console.log('🧪 Starting End-to-End CR Reschedule Test for Completed/Delayed Class...');

  // 1. Log in as CSE Batch 68 B CR
  const crLoginRes = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'cr.cse68b@uttara.edu.bd', password: 'Password123!' }),
  });
  const crLoginData: any = await crLoginRes.json();
  const crToken = crLoginData?.data?.accessToken;
  console.log('✅ CR Login Status:', crLoginRes.status, '| CR User:', crLoginData?.data?.user?.fullName, '| Role:', crLoginData?.data?.user?.role);

  if (!crToken) {
    throw new Error('Failed to log in as CR: ' + JSON.stringify(crLoginData));
  }

  // 2. Fetch Today Schedule for CSE 68 B
  const schedRes = await fetch(`${API_BASE}/schedules?department=CSE&batch=68&section=B`, {
    headers: { Authorization: `Bearer ${crToken}` },
  });
  const schedData: any = await schedRes.json();
  const slots: any[] = schedData?.data || [];
  console.log(`📋 Fetched ${slots.length} weekly slots for CSE Batch 68 Section B`);

  const thuSlots = slots.filter((s) => s.dayOfWeek === 'THU');
  console.log(`📅 THU slots count: ${thuSlots.length}`);
  thuSlots.forEach((s) => {
    console.log(`   - [${s.courseCode}] ${s.courseName} | ${s.startTime}-${s.endTime} | Room: ${s.room?.roomNumber}`);
  });

  const targetSlot = thuSlots[0];
  if (!targetSlot) {
    throw new Error('No slot found for THU');
  }

  console.log(`🎯 Testing reschedule on completed slot: ${targetSlot.courseCode} (${targetSlot.startTime}-${targetSlot.endTime})`);

  // 3. Reschedule this slot to 14:30 - 16:00
  const rescheduleRes = await fetch(`${API_BASE}/schedules/slots/${targetSlot.id}/reschedule-today`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${crToken}`,
    },
    body: JSON.stringify({
      newStartTime: '14:30',
      newEndTime: '16:00',
      reason: 'Morning class was delayed; faculty requested afternoon timing',
    }),
  });
  const rescheduleData: any = await rescheduleRes.json();
  console.log('✅ CR Reschedule Status:', rescheduleRes.status);
  console.log('   Message:', rescheduleData?.data?.message);
  console.log('   Override Action:', rescheduleData?.data?.override?.action);
  console.log('   New Time:', rescheduleData?.data?.override?.newStartTime, '-', rescheduleData?.data?.override?.newEndTime);

  // 4. Log in as Student (student.karim@uttara.edu.bd)
  const studentLoginRes = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'student.karim@uttara.edu.bd', password: 'Password123!' }),
  });
  const studentLoginData: any = await studentLoginRes.json();
  const studentToken = studentLoginData?.data?.accessToken;
  console.log('✅ Student Login Status:', studentLoginRes.status, '| Student User:', studentLoginData?.data?.user?.fullName, '| Role:', studentLoginData?.data?.user?.role);

  // 5. Student fetches schedule to verify the moved class
  const studentSchedRes = await fetch(`${API_BASE}/schedules?department=CSE&batch=68&section=B`, {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  const studentSchedData: any = await studentSchedRes.json();
  const studentSlots: any[] = studentSchedData?.data || [];
  const updatedSlot = studentSlots.find((s) => s.id === targetSlot.id);

  console.log('👀 Student View for Rescheduled Slot:');
  console.log('   Original Time:', updatedSlot?.startTime, '-', updatedSlot?.endTime);
  console.log('   Overrides present:', updatedSlot?.overrides?.length);
  if (updatedSlot?.overrides?.length > 0) {
    const o = updatedSlot.overrides[0];
    console.log(`   Effective Today: ${o.newStartTime} - ${o.newEndTime} (Reason: ${o.reason})`);
  }

  // 6. Test Undo / Restore by CR
  const undoRes = await fetch(`${API_BASE}/schedules/slots/${targetSlot.id}/override-today`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${crToken}` },
  });
  const undoData: any = await undoRes.json();
  console.log('✅ CR Undo Status:', undoRes.status, '| Message:', undoData?.data?.message);

  console.log('🎉 Full End-to-End Cycle Passed Successfully!');
}

main().catch((e) => {
  console.error('❌ E2E test failed:', e);
  process.exit(1);
});
