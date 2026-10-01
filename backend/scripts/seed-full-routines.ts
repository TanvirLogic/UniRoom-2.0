import * as dotenv from 'dotenv';
dotenv.config();
import { PrismaClient, Role, RoomStatus, DayOfWeek } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Starting Full Timetable & Routine Seed...');

  const passwordHash = await bcrypt.hash('Password123!', 10);

  // 1. Resolve University
  let university = await prisma.university.findFirst();
  if (!university) {
    university = await prisma.university.create({
      data: {
        name: 'Uttara University',
        code: 'UU',
        domain: 'uttara.edu.bd',
        operatingDays: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
      },
    });
  }
  console.log(`🏛️ University: ${university.name}`);

  // 2. Resolve Departments
  let sweDept = await prisma.department.findFirst({
    where: { code: 'SWE', universityId: university.id },
  });
  if (!sweDept) {
    sweDept = await prisma.department.create({
      data: {
        universityId: university.id,
        name: 'Department of Software Engineering',
        code: 'SWE',
      },
    });
  }

  let cseDept = await prisma.department.findFirst({
    where: { code: 'CSE', universityId: university.id },
  });
  if (!cseDept) {
    cseDept = await prisma.department.create({
      data: {
        universityId: university.id,
        name: 'Department of Computer Science & Engineering',
        code: 'CSE',
      },
    });
  }
  console.log(`📚 Departments: SWE (${sweDept.id}), CSE (${cseDept.id})`);

  // 3. Buildings & Rooms
  let mainBuilding = await prisma.building.findFirst({
    where: { name: 'Main Academic Building' },
  });
  if (!mainBuilding) {
    mainBuilding = await prisma.building.create({
      data: {
        departmentId: sweDept.id,
        name: 'Main Academic Building',
        campusName: 'Main Campus',
      },
    });
  }

  let labBuilding = await prisma.building.findFirst({
    where: { name: 'Engineering Complex' },
  });
  if (!labBuilding) {
    labBuilding = await prisma.building.create({
      data: {
        departmentId: cseDept.id,
        name: 'Engineering Complex',
        campusName: 'Main Campus',
      },
    });
  }

  // Ensure standard physical rooms exist
  const roomDefinitions = [
    { roomNumber: '5028 (506)', floor: 5, capacity: 50, buildingId: mainBuilding.id, deptId: sweDept.id },
    { roomNumber: '5030 (508)', floor: 5, capacity: 55, buildingId: mainBuilding.id, deptId: sweDept.id },
    { roomNumber: '4012', floor: 4, capacity: 60, buildingId: mainBuilding.id, deptId: sweDept.id },
    { roomNumber: '3015', floor: 3, capacity: 45, buildingId: mainBuilding.id, deptId: sweDept.id },
    { roomNumber: 'Lab 6001', floor: 6, capacity: 40, buildingId: labBuilding.id, deptId: sweDept.id },
    { roomNumber: '5070 (502)', floor: 5, capacity: 50, buildingId: mainBuilding.id, deptId: cseDept.id },
    { roomNumber: '6170 (614)', floor: 6, capacity: 50, buildingId: labBuilding.id, deptId: cseDept.id },
    { roomNumber: '3180 (313)', floor: 3, capacity: 50, buildingId: mainBuilding.id, deptId: cseDept.id },
    { roomNumber: 'Lab 5180 (511)', floor: 5, capacity: 40, buildingId: labBuilding.id, deptId: cseDept.id },
    { roomNumber: 'Lab 6180 (613)', floor: 6, capacity: 40, buildingId: labBuilding.id, deptId: cseDept.id },
    { roomNumber: '5060 (503)', floor: 5, capacity: 50, buildingId: mainBuilding.id, deptId: cseDept.id },
    { roomNumber: '4080 (405)', floor: 4, capacity: 55, buildingId: mainBuilding.id, deptId: cseDept.id },
  ];

  const roomMap = new Map<string, string>(); // roomNumber -> id

  for (const r of roomDefinitions) {
    let existing = await prisma.room.findFirst({
      where: { roomNumber: r.roomNumber, universityId: university.id },
    });
    if (!existing) {
      existing = await prisma.room.create({
        data: {
          universityId: university.id,
          departmentId: r.deptId,
          buildingId: r.buildingId,
          roomNumber: r.roomNumber,
          floor: r.floor,
          capacity: r.capacity,
          currentStatus: RoomStatus.AVAILABLE,
          version: 1,
        },
      });
    }
    roomMap.set(r.roomNumber, existing.id);
  }

  // Get all existing rooms in the DB to populate the map
  const allRooms = await prisma.room.findMany({ where: { universityId: university.id } });
  for (const r of allRooms) {
    roomMap.set(r.roomNumber, r.id);
  }
  console.log(`🚪 Active Classrooms mapped: ${roomMap.size}`);

  // 4. Fix any 12-hour slots in the database
  const timeFixMap: Record<string, string> = {
    '01:00': '13:00',
    '01:30': '13:30',
    '02:00': '14:00',
    '02:30': '14:30',
    '03:00': '15:00',
    '03:30': '15:30',
    '04:00': '16:00',
    '04:30': '16:30',
    '05:00': '17:00',
  };

  const slotsToFix = await prisma.scheduleSlot.findMany();
  let fixCount = 0;
  for (const slot of slotsToFix) {
    let updated = false;
    let newStart = slot.startTime;
    let newEnd = slot.endTime;

    if (timeFixMap[slot.startTime]) {
      newStart = timeFixMap[slot.startTime];
      updated = true;
    }
    if (timeFixMap[slot.endTime]) {
      newEnd = timeFixMap[slot.endTime];
      updated = true;
    }

    if (updated) {
      await prisma.scheduleSlot.update({
        where: { id: slot.id },
        data: { startTime: newStart, endTime: newEnd },
      });
      fixCount++;
    }
  }
  if (fixCount > 0) {
    console.log(`🔧 Converted ${fixCount} slots from 12-hour to 24-hour time format.`);
  }

  // 5. Create or Update Users
  const usersToUpsert = [
    // CSE 68 B
    {
      email: 'cr.cse68b@uttara.edu.bd',
      fullName: 'Karim CR (CSE 68B)',
      role: Role.CR,
      studentId: '2241071002',
      departmentId: cseDept.id,
      batch: '68',
      section: 'B',
      isApprovedCr: true,
    },
    {
      email: 'student.karim@uttara.edu.bd',
      fullName: 'Karim Student',
      role: Role.STUDENT,
      studentId: '2241071003',
      departmentId: cseDept.id,
      batch: '68',
      section: 'B',
      isApprovedCr: false,
    },
    // CSE 68 A
    {
      email: 'cr.cse68a@uttara.edu.bd',
      fullName: 'Arif CR (CSE 68A)',
      role: Role.CR,
      studentId: '2241071001',
      departmentId: cseDept.id,
      batch: '68',
      section: 'A',
      isApprovedCr: true,
    },
    {
      email: 'student.cse68a@uttara.edu.bd',
      fullName: 'Arif Student',
      role: Role.STUDENT,
      studentId: '2241071004',
      departmentId: cseDept.id,
      batch: '68',
      section: 'A',
      isApprovedCr: false,
    },
    // SWE 68 A
    {
      email: 'cr.seca@uttara.edu.bd',
      fullName: 'Tanvir Ahmed (CR A)',
      role: Role.CR,
      studentId: '2241081001',
      departmentId: sweDept.id,
      batch: '68',
      section: 'A',
      isApprovedCr: true,
    },
    {
      email: 'student.seca@uttara.edu.bd',
      fullName: 'Rahim Student (Sec A)',
      role: Role.STUDENT,
      studentId: '2241081003',
      departmentId: sweDept.id,
      batch: '68',
      section: 'A',
      isApprovedCr: false,
    },
    // SWE 68 B
    {
      email: 'cr.secb@uttara.edu.bd',
      fullName: 'Sabbir Hossain (CR B)',
      role: Role.CR,
      studentId: '2241081002',
      departmentId: sweDept.id,
      batch: '68',
      section: 'B',
      isApprovedCr: true,
    },
    {
      email: 'student.secb@uttara.edu.bd',
      fullName: 'Mimi Student (Sec B)',
      role: Role.STUDENT,
      studentId: '2241081004',
      departmentId: sweDept.id,
      batch: '68',
      section: 'B',
      isApprovedCr: false,
    },
    // Faculty
    {
      email: 'faculty.dns@uttara.edu.bd',
      fullName: 'Dr. Nazmul Shakib',
      role: Role.FACULTY,
      facultyId: 'DNS',
      departmentId: sweDept.id,
      batch: null,
      section: null,
      isApprovedCr: false,
    },
    {
      email: 'faculty.khk@uttara.edu.bd',
      fullName: 'Kamrul Hasan Khan',
      role: Role.FACULTY,
      facultyId: 'KHK',
      departmentId: sweDept.id,
      batch: null,
      section: null,
      isApprovedCr: false,
    },
    {
      email: 'faculty.amu@uttara.edu.bd',
      fullName: 'Dr. Al Mamun',
      role: Role.FACULTY,
      facultyId: 'AMU',
      departmentId: cseDept.id,
      batch: null,
      section: null,
      isApprovedCr: false,
    },
    {
      email: 'faculty.szc@uttara.edu.bd',
      fullName: 'Shahid Zaman Chowdhury',
      role: Role.FACULTY,
      facultyId: 'SZC',
      departmentId: cseDept.id,
      batch: null,
      section: null,
      isApprovedCr: false,
    },
    // Admin
    {
      email: 'admin@uttara.edu.bd',
      fullName: 'System Administrator',
      role: Role.SUPER_ADMIN,
      departmentId: sweDept.id,
      batch: null,
      section: null,
      isApprovedCr: false,
    },
  ];

  for (const u of usersToUpsert) {
    const existing = await prisma.user.findFirst({ where: { email: u.email } });
    if (existing) {
      await prisma.user.update({
        where: { id: existing.id },
        data: {
          fullName: u.fullName,
          role: u.role,
          departmentId: u.departmentId,
          batch: u.batch,
          section: u.section,
          studentId: (u as any).studentId,
          facultyId: (u as any).facultyId,
          isApprovedCr: u.isApprovedCr,
          passwordHash,
          isEmailVerified: true,
        },
      });
    } else {
      await prisma.user.create({
        data: {
          universityId: university.id,
          email: u.email,
          fullName: u.fullName,
          role: u.role,
          departmentId: u.departmentId,
          batch: u.batch,
          section: u.section,
          studentId: (u as any).studentId,
          facultyId: (u as any).facultyId,
          isApprovedCr: u.isApprovedCr,
          passwordHash,
          isEmailVerified: true,
        },
      });
    }
  }
  console.log(`👥 Upserted ${usersToUpsert.length} test accounts (Password: Password123!).`);

  // 6. Comprehensive SWE Routine Slots across SAT-THU
  // To provide full coverage for Batch 68 Sec A & B, Batch 67, Batch 69
  const sweSlotsData: Array<{
    batch: string;
    section: string;
    dayOfWeek: DayOfWeek;
    startTime: string;
    endTime: string;
    courseCode: string;
    courseName: string;
    facultyInitials: string;
    roomNumber: string;
  }> = [
    // SWE BATCH 68 SECTION B (Full Week)
    // SUN
    { batch: '68', section: 'B', dayOfWeek: 'SUN', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-221', courseName: 'Database Management Systems', facultyInitials: 'KHK', roomNumber: '5028 (506)' },
    { batch: '68', section: 'B', dayOfWeek: 'SUN', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-321', courseName: 'Software Architecture & Design', facultyInitials: 'DNS', roomNumber: '5030 (508)' },
    { batch: '68', section: 'B', dayOfWeek: 'SUN', startTime: '11:25', endTime: '12:45', courseCode: 'MAT-201', courseName: 'Linear Algebra & Statistics', facultyInitials: 'AMU', roomNumber: '4012' },
    { batch: '68', section: 'B', dayOfWeek: 'SUN', startTime: '13:15', endTime: '15:55', courseCode: 'SWE-222', courseName: 'DBMS Sessional Lab', facultyInitials: 'KHK', roomNumber: 'Lab 6001' },

    // MON
    { batch: '68', section: 'B', dayOfWeek: 'MON', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-322', courseName: 'Web Engineering & Frameworks', facultyInitials: 'KHK', roomNumber: '5028 (506)' },
    { batch: '68', section: 'B', dayOfWeek: 'MON', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-211', courseName: 'Data Structures & Algorithms', facultyInitials: 'SZC', roomNumber: '5030 (508)' },
    { batch: '68', section: 'B', dayOfWeek: 'MON', startTime: '13:15', endTime: '14:35', courseCode: 'ENG-102', courseName: 'Professional Communication', facultyInitials: 'RIR', roomNumber: '4012' },

    // TUE
    { batch: '68', section: 'B', dayOfWeek: 'TUE', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-321', courseName: 'Software Architecture & Design', facultyInitials: 'DNS', roomNumber: '5028 (506)' },
    { batch: '68', section: 'B', dayOfWeek: 'TUE', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-221', courseName: 'Database Management Systems', facultyInitials: 'KHK', roomNumber: '5030 (508)' },
    { batch: '68', section: 'B', dayOfWeek: 'TUE', startTime: '11:25', endTime: '14:35', courseCode: 'SWE-323', courseName: 'Web Engineering Lab (Node & Flutter)', facultyInitials: 'KHK', roomNumber: 'Lab 6001' },

    // WED
    { batch: '68', section: 'B', dayOfWeek: 'WED', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-211', courseName: 'Data Structures & Algorithms', facultyInitials: 'SZC', roomNumber: '4012' },
    { batch: '68', section: 'B', dayOfWeek: 'WED', startTime: '10:05', endTime: '11:25', courseCode: 'MAT-201', courseName: 'Linear Algebra & Statistics', facultyInitials: 'AMU', roomNumber: '5028 (506)' },
    { batch: '68', section: 'B', dayOfWeek: 'WED', startTime: '13:15', endTime: '14:35', courseCode: 'SWE-322', courseName: 'Web Engineering & Frameworks', facultyInitials: 'KHK', roomNumber: '5030 (508)' },

    // THU (TODAY)
    { batch: '68', section: 'B', dayOfWeek: 'THU', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-321', courseName: 'Software Architecture & Design', facultyInitials: 'DNS', roomNumber: '5030 (508)' },
    { batch: '68', section: 'B', dayOfWeek: 'THU', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-322', courseName: 'Web Engineering & Frameworks', facultyInitials: 'KHK', roomNumber: '5028 (506)' },
    { batch: '68', section: 'B', dayOfWeek: 'THU', startTime: '11:25', endTime: '12:45', courseCode: 'SWE-221', courseName: 'Database Management Systems', facultyInitials: 'KHK', roomNumber: '4012' },
    { batch: '68', section: 'B', dayOfWeek: 'THU', startTime: '13:15', endTime: '14:35', courseCode: 'ENG-102', courseName: 'Technical Writing & Seminar', facultyInitials: 'RIR', roomNumber: '3015' },
    { batch: '68', section: 'B', dayOfWeek: 'THU', startTime: '14:35', endTime: '15:55', courseCode: 'SWE-411', courseName: 'Artificial Intelligence & ML', facultyInitials: 'AMU', roomNumber: '5028 (506)' },

    // SAT
    { batch: '68', section: 'B', dayOfWeek: 'SAT', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-321', courseName: 'Software Architecture & Design', facultyInitials: 'DNS', roomNumber: '5028 (506)' },
    { batch: '68', section: 'B', dayOfWeek: 'SAT', startTime: '11:25', endTime: '14:35', courseCode: 'SWE-212', courseName: 'OOP Java & Design Patterns Lab', facultyInitials: 'SZC', roomNumber: 'Lab 6001' },

    // SWE BATCH 68 SECTION A (Full Week)
    // SUN
    { batch: '68', section: 'A', dayOfWeek: 'SUN', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-321', courseName: 'Software Architecture & Design', facultyInitials: 'DNS', roomNumber: '5030 (508)' },
    { batch: '68', section: 'A', dayOfWeek: 'SUN', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-221', courseName: 'Database Management Systems', facultyInitials: 'KHK', roomNumber: '5028 (506)' },
    { batch: '68', section: 'A', dayOfWeek: 'SUN', startTime: '13:15', endTime: '14:35', courseCode: 'SWE-322', courseName: 'Web Engineering & Frameworks', facultyInitials: 'KHK', roomNumber: '4012' },

    // MON
    { batch: '68', section: 'A', dayOfWeek: 'MON', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-211', courseName: 'Data Structures & Algorithms', facultyInitials: 'SZC', roomNumber: '5028 (506)' },
    { batch: '68', section: 'A', dayOfWeek: 'MON', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-322', courseName: 'Web Engineering & Frameworks', facultyInitials: 'KHK', roomNumber: '5030 (508)' },
    { batch: '68', section: 'A', dayOfWeek: 'MON', startTime: '11:25', endTime: '14:35', courseCode: 'SWE-222', courseName: 'DBMS Sessional Lab', facultyInitials: 'KHK', roomNumber: 'Lab 6001' },

    // TUE
    { batch: '68', section: 'A', dayOfWeek: 'TUE', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-221', courseName: 'Database Management Systems', facultyInitials: 'KHK', roomNumber: '4012' },
    { batch: '68', section: 'A', dayOfWeek: 'TUE', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-321', courseName: 'Software Architecture & Design', facultyInitials: 'DNS', roomNumber: '5030 (508)' },
    { batch: '68', section: 'A', dayOfWeek: 'TUE', startTime: '13:15', endTime: '14:35', courseCode: 'MAT-201', courseName: 'Linear Algebra & Statistics', facultyInitials: 'AMU', roomNumber: '3015' },

    // WED
    { batch: '68', section: 'A', dayOfWeek: 'WED', startTime: '08:45', endTime: '10:05', courseCode: 'MAT-201', courseName: 'Linear Algebra & Statistics', facultyInitials: 'AMU', roomNumber: '5030 (508)' },
    { batch: '68', section: 'A', dayOfWeek: 'WED', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-211', courseName: 'Data Structures & Algorithms', facultyInitials: 'SZC', roomNumber: '5028 (506)' },
    { batch: '68', section: 'A', dayOfWeek: 'WED', startTime: '11:25', endTime: '14:35', courseCode: 'SWE-323', courseName: 'Web Engineering Lab', facultyInitials: 'KHK', roomNumber: 'Lab 6001' },

    // THU (TODAY)
    { batch: '68', section: 'A', dayOfWeek: 'THU', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-322', courseName: 'Web Engineering & Frameworks', facultyInitials: 'KHK', roomNumber: '5028 (506)' },
    { batch: '68', section: 'A', dayOfWeek: 'THU', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-321', courseName: 'Software Architecture & Design', facultyInitials: 'DNS', roomNumber: '5030 (508)' },
    { batch: '68', section: 'A', dayOfWeek: 'THU', startTime: '13:15', endTime: '14:35', courseCode: 'SWE-411', courseName: 'Artificial Intelligence & ML', facultyInitials: 'AMU', roomNumber: '4012' },
    { batch: '68', section: 'A', dayOfWeek: 'THU', startTime: '14:35', endTime: '15:55', courseCode: 'ENG-102', courseName: 'Technical Writing', facultyInitials: 'RIR', roomNumber: '3015' },

    // SWE BATCH 69 SECTION A (First Year)
    { batch: '69', section: 'A', dayOfWeek: 'THU', startTime: '08:45', endTime: '10:05', courseCode: 'SWE-111', courseName: 'Structured Programming Language', facultyInitials: 'DNS', roomNumber: '4012' },
    { batch: '69', section: 'A', dayOfWeek: 'THU', startTime: '10:05', endTime: '11:25', courseCode: 'MAT-101', courseName: 'Differential Calculus', facultyInitials: 'AMU', roomNumber: '3015' },
    { batch: '69', section: 'A', dayOfWeek: 'THU', startTime: '11:25', endTime: '14:35', courseCode: 'SWE-112', courseName: 'SPL C Programming Lab', facultyInitials: 'DNS', roomNumber: 'Lab 6001' },

    // SWE BATCH 67 SECTION A (Senior Year)
    { batch: '67', section: 'A', dayOfWeek: 'THU', startTime: '10:05', endTime: '11:25', courseCode: 'SWE-421', courseName: 'Cloud Computing & DevOps', facultyInitials: 'KHK', roomNumber: '4012' },
    { batch: '67', section: 'A', dayOfWeek: 'THU', startTime: '13:15', endTime: '14:35', courseCode: 'SWE-422', courseName: 'Software Quality Assurance', facultyInitials: 'DNS', roomNumber: '5030 (508)' },
  ];

  // Insert or update SWE slots
  let sweSlotCount = 0;
  for (const s of sweSlotsData) {
    const roomId = roomMap.get(s.roomNumber) || Array.from(roomMap.values())[0];

    const existing = await prisma.scheduleSlot.findFirst({
      where: {
        departmentId: sweDept.id,
        batch: s.batch,
        section: s.section,
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
      },
    });

    if (existing) {
      await prisma.scheduleSlot.update({
        where: { id: existing.id },
        data: {
          endTime: s.endTime,
          courseCode: s.courseCode,
          courseName: s.courseName,
          facultyInitials: s.facultyInitials,
          roomId,
          isActive: true,
        },
      });
    } else {
      await prisma.scheduleSlot.create({
        data: {
          departmentId: sweDept.id,
          batch: s.batch,
          section: s.section,
          dayOfWeek: s.dayOfWeek,
          startTime: s.startTime,
          endTime: s.endTime,
          courseCode: s.courseCode,
          courseName: s.courseName,
          facultyInitials: s.facultyInitials,
          roomId,
          isActive: true,
        },
      });
    }
    sweSlotCount++;
  }
  console.log(`✅ Seeded/Updated ${sweSlotCount} comprehensive SWE routine slots.`);

  // 7. Ensure CSE Batch 68 has afternoon slots on THU (today) as well
  const cseExtraThuSlots = [
    { batch: '68', section: 'B', dayOfWeek: 'THU' as DayOfWeek, startTime: '13:15', endTime: '14:35', courseCode: 'CSE06132', courseName: 'Computer Programming II (OOP)', facultyInitials: 'DNS', roomNumber: '5070 (502)' },
    { batch: '68', section: 'B', dayOfWeek: 'THU' as DayOfWeek, startTime: '14:35', endTime: '17:15', courseCode: 'CSE0613202', courseName: 'OOP Java Lab', facultyInitials: 'DNS', roomNumber: 'Lab 5180 (511)' },
  ];

  for (const s of cseExtraThuSlots) {
    const roomId = roomMap.get(s.roomNumber) || Array.from(roomMap.values())[0];
    const existing = await prisma.scheduleSlot.findFirst({
      where: {
        departmentId: cseDept.id,
        batch: s.batch,
        section: s.section,
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
      },
    });
    if (!existing) {
      await prisma.scheduleSlot.create({
        data: {
          departmentId: cseDept.id,
          batch: s.batch,
          section: s.section,
          dayOfWeek: s.dayOfWeek,
          startTime: s.startTime,
          endTime: s.endTime,
          courseCode: s.courseCode,
          courseName: s.courseName,
          facultyInitials: s.facultyInitials,
          roomId,
          isActive: true,
        },
      });
      console.log(`➕ Added CSE 68B afternoon slot: ${s.courseCode} (${s.startTime}-${s.endTime})`);
    }
  }

  // 8. Summary Count
  const totalCse = await prisma.scheduleSlot.count({ where: { departmentId: cseDept.id } });
  const totalSwe = await prisma.scheduleSlot.count({ where: { departmentId: sweDept.id } });
  const totalRooms = await prisma.room.count({ where: { universityId: university.id } });
  const totalUsers = await prisma.user.count({ where: { universityId: university.id } });

  console.log('----------------------------------------------------');
  console.log('🎉 Database Population Complete!');
  console.log(`📊 CSE Slots: ${totalCse}`);
  console.log(`📊 SWE Slots: ${totalSwe}`);
  console.log(`📊 Rooms: ${totalRooms}`);
  console.log(`📊 Users: ${totalUsers}`);
  console.log('----------------------------------------------------');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding full routines:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
