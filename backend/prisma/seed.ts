import { DayOfWeek, PrismaClient, Role, RoomStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Comprehensive Test & Demo Data Seeding for UniRoom-Live...');

  // 1. Clean existing records in reverse order of foreign key dependencies
  await prisma.emailVerificationPin.deleteMany();
  await prisma.passwordResetPin.deleteMany();
  await prisma.emergencyAnnouncement.deleteMany();
  await prisma.scheduleOverride.deleteMany();
  await prisma.scheduleSlot.deleteMany();
  await prisma.roomLog.deleteMany();
  await prisma.room.deleteMany();
  await prisma.academicBatch.deleteMany();
  await prisma.building.deleteMany();
  await prisma.user.deleteMany();
  await prisma.department.deleteMany();
  await prisma.university.deleteMany();

  console.log('🧹 Cleaned existing database tables.');

  const defaultPassword = 'Password123!';
  const passwordHash = await bcrypt.hash(defaultPassword, 10);

  // 2. Create University
  const university = await prisma.university.create({
    data: {
      name: 'Uttara University',
      code: 'UU',
      domain: 'uttara.edu.bd',
      operatingDays: [
        DayOfWeek.MON,
        DayOfWeek.TUE,
        DayOfWeek.WED,
        DayOfWeek.THU,
        DayOfWeek.FRI,
        DayOfWeek.SAT,
        DayOfWeek.SUN,
      ],
      isActive: true,
    },
  });
  console.log(`🏛️ Created University: ${university.name} (${university.code})`);

  // 3. Create Departments
  const sweDept = await prisma.department.create({
    data: {
      universityId: university.id,
      name: 'Department of Software Engineering',
      code: 'SWE',
    },
  });

  const cseDept = await prisma.department.create({
    data: {
      universityId: university.id,
      name: 'Department of Computer Science & Engineering',
      code: 'CSE',
    },
  });
  console.log(`🏢 Created Departments: ${sweDept.code}, ${cseDept.code}`);

  // 4. Create Academic Batches & Sections
  await prisma.academicBatch.createMany({
    data: [
      {
        departmentId: sweDept.id,
        name: '68',
        sections: ['A', 'B', 'C'],
        isActive: true,
      },
      {
        departmentId: sweDept.id,
        name: '69',
        sections: ['A', 'B'],
        isActive: true,
      },
      {
        departmentId: cseDept.id,
        name: '60',
        sections: ['A', 'B'],
        isActive: true,
      },
    ],
  });
  console.log('📚 Created Batches 68, 69 for SWE and 60 for CSE.');

  // 5. Create Campus Buildings
  const mainBuilding = await prisma.building.create({
    data: {
      departmentId: sweDept.id,
      name: 'Main Academic Building',
      campusName: 'Main Campus',
    },
  });

  const labBuilding = await prisma.building.create({
    data: {
      departmentId: sweDept.id,
      name: 'Engineering Complex',
      campusName: 'Main Campus',
    },
  });
  console.log(`🏗️ Created Buildings: ${mainBuilding.name}, ${labBuilding.name}`);

  // 6. Create Physical Classrooms
  // Room 5030 is currently in RUNNING_CLASS so Section A CR can test "Make Room Free"
  const room5030 = await prisma.room.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      buildingId: mainBuilding.id,
      roomNumber: '5030 (508)',
      floor: 5,
      capacity: 55,
      currentStatus: RoomStatus.RUNNING_CLASS,
      currentCourse: 'SWE-321 Software Architecture',
      currentTeacher: 'DNS',
      currentBatch: 'Batch 68 (A)',
      version: 1,
    },
  });

  // Room 5028 is AVAILABLE so Section B CR can test "Book for My Section Class"
  const room5028 = await prisma.room.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      buildingId: mainBuilding.id,
      roomNumber: '5028 (506)',
      floor: 5,
      capacity: 50,
      currentStatus: RoomStatus.AVAILABLE,
      version: 1,
    },
  });

  const room4012 = await prisma.room.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      buildingId: mainBuilding.id,
      roomNumber: '4012',
      floor: 4,
      capacity: 60,
      currentStatus: RoomStatus.AVAILABLE,
      version: 1,
    },
  });

  const room3015 = await prisma.room.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      buildingId: mainBuilding.id,
      roomNumber: '3015',
      floor: 3,
      capacity: 45,
      currentStatus: RoomStatus.RESERVED,
      currentCourse: 'Special Project Presentation',
      currentBatch: 'Batch 67',
      version: 1,
    },
  });

  const roomLab = await prisma.room.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      buildingId: labBuilding.id,
      roomNumber: 'Lab 6001',
      floor: 6,
      capacity: 40,
      currentStatus: RoomStatus.AVAILABLE,
      version: 1,
    },
  });
  console.log('🚪 Created Classrooms: 5030, 5028, 4012, 3015, Lab 6001.');

  // 7. Create Users for all testing roles
  // Faculty User (DNS)
  const facultyDns = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      fullName: 'Dr. Nazmul Shakib',
      email: 'faculty.dns@uttara.edu.bd',
      passwordHash,
      role: Role.FACULTY,
      facultyId: 'DNS',
      isEmailVerified: true,
    },
  });

  // Section A CR User
  const crSecA = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      fullName: 'Tanvir Ahmed (CR A)',
      email: 'cr.secA@uttara.edu.bd',
      passwordHash,
      role: Role.CR,
      studentId: '2241081001',
      batch: '68',
      section: 'A',
      isApprovedCr: true,
      isEmailVerified: true,
    },
  });

  // Section B CR User
  const crSecB = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      fullName: 'Sabbir Hossain (CR B)',
      email: 'cr.secB@uttara.edu.bd',
      passwordHash,
      role: Role.CR,
      studentId: '2241081002',
      batch: '68',
      section: 'B',
      isApprovedCr: true,
      isEmailVerified: true,
    },
  });

  // Section A Student User
  const studentSecA = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      fullName: 'Rahim Student (Sec A)',
      email: 'student.secA@uttara.edu.bd',
      passwordHash,
      role: Role.STUDENT,
      studentId: '2241081050',
      batch: '68',
      section: 'A',
      isEmailVerified: true,
    },
  });

  // Section B Student User
  const studentSecB = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      fullName: 'Karim Student (Sec B)',
      email: 'student.secB@uttara.edu.bd',
      passwordHash,
      role: Role.STUDENT,
      studentId: '2241081051',
      batch: '68',
      section: 'B',
      isEmailVerified: true,
    },
  });

  // Additional Section B Classmates Roster
  const secBClassmates = [
    { studentId: '2241081003', fullName: 'Tanvir Hasan' },
    { studentId: '2241081005', fullName: 'Md. Abdullah' },
    { studentId: '2241081008', fullName: 'Sumaiya Akter' },
    { studentId: '2241081011', fullName: 'Fahim Shahriar' },
    { studentId: '2241081014', fullName: 'Mehedi Hasan' },
    { studentId: '2241081018', fullName: 'Nusrat Jahan' },
    { studentId: '2241081021', fullName: 'Mahir Faysal' },
    { studentId: '2241081025', fullName: 'Ayesha Siddika' },
    { studentId: '2241081029', fullName: 'Sakib Al Hasan' },
    { studentId: '2241081033', fullName: 'Sadia Islam' },
    { studentId: '2241081037', fullName: 'Rayhan Ahmed' },
    { studentId: '2241081042', fullName: 'Rifat Hossain' },
    { studentId: '2241081046', fullName: 'Farzana Haque' },
    { studentId: '2241081055', fullName: 'Naimul Islam' },
    { studentId: '2241081058', fullName: 'Tamanna Rahman' },
    { studentId: '2241081062', fullName: 'Shahriar Kabir' },
    { studentId: '2241081066', fullName: 'Jannatul Ferdous' },
    { studentId: '2241081070', fullName: 'Ashiqur Rahman' },
  ];

  for (const c of secBClassmates) {
    await prisma.user.create({
      data: {
        universityId: university.id,
        departmentId: sweDept.id,
        fullName: c.fullName,
        email: `${c.studentId}@uttara.edu.bd`,
        passwordHash,
        role: Role.STUDENT,
        studentId: c.studentId,
        batch: '68',
        section: 'B',
        isEmailVerified: true,
      },
    });
  }

  // Super Admin User
  const superAdmin = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: sweDept.id,
      fullName: 'Chief University Admin',
      email: 'admin@uttara.edu.bd',
      passwordHash,
      role: Role.SUPER_ADMIN,
      isEmailVerified: true,
    },
  });
  console.log('👥 Created Users: Admin, CR Sec A, CR Sec B, Student Sec A, Student Sec B, Faculty DNS.');

  // 8. Create Schedule Slots across the full week (MON through SUN)
  // Ensures that whenever the app is tested, Today's Schedule and Weekly Routine have rich data.
  const days: DayOfWeek[] = [
    DayOfWeek.MON,
    DayOfWeek.TUE,
    DayOfWeek.WED,
    DayOfWeek.THU,
    DayOfWeek.FRI,
    DayOfWeek.SAT,
    DayOfWeek.SUN,
  ];

  const slotData = [];

  for (const day of days) {
    // Section A Timetable
    slotData.push(
      {
        departmentId: sweDept.id,
        roomId: room4012.id,
        facultyUserId: null,
        facultyInitials: 'MAS',
        batch: '68',
        section: 'A',
        courseCode: 'SWE-211',
        courseName: 'Database Management Systems',
        dayOfWeek: day,
        startTime: '08:30',
        endTime: '10:00',
        isActive: true,
      },
      {
        departmentId: sweDept.id,
        roomId: room5030.id,
        facultyUserId: facultyDns.id,
        facultyInitials: 'DNS',
        batch: '68',
        section: 'A',
        courseCode: 'SWE-321',
        courseName: 'Software Architecture & Design',
        dayOfWeek: day,
        startTime: '10:00',
        endTime: '11:30',
        isActive: true,
      },
      {
        departmentId: sweDept.id,
        roomId: roomLab.id,
        facultyUserId: facultyDns.id,
        facultyInitials: 'DNS',
        batch: '68',
        section: 'A',
        courseCode: 'SWE-411',
        courseName: 'Machine Learning & AI',
        dayOfWeek: day,
        startTime: '01:30',
        endTime: '03:00',
        isActive: true,
      },
    );

    // Section B Timetable
    slotData.push(
      {
        departmentId: sweDept.id,
        roomId: room5028.id,
        facultyUserId: null,
        facultyInitials: 'KHK',
        batch: '68',
        section: 'B',
        courseCode: 'SWE-322',
        courseName: 'Web Engineering & Frameworks',
        dayOfWeek: day,
        startTime: '11:30',
        endTime: '01:00',
        isActive: true,
      },
      {
        departmentId: sweDept.id,
        roomId: room4012.id,
        facultyUserId: null,
        facultyInitials: 'RAH',
        batch: '68',
        section: 'B',
        courseCode: 'SWE-412',
        courseName: 'Cloud Computing Architecture',
        dayOfWeek: day,
        startTime: '03:00',
        endTime: '04:30',
        isActive: true,
      },
    );
  }

  await prisma.scheduleSlot.createMany({ data: slotData });
  console.log(`📅 Created ${slotData.length} Schedule Slots across Monday–Sunday for Batches 68 (A & B).`);

  // 9. Initial Audit Log for Room 5030
  await prisma.roomLog.create({
    data: {
      roomId: room5030.id,
      changedByUserId: crSecA.id,
      previousStatus: RoomStatus.AVAILABLE,
      newStatus: RoomStatus.RUNNING_CLASS,
      note: 'Scheduled class started: SWE-321 with Faculty DNS',
    },
  });

  console.log('\n=============================================================');
  console.log('✨ DUMMY TEST DATABASE READY FOR TESTING!');
  console.log('=============================================================');
  console.log('🔑 ALL ACCOUNTS SHARE THE SAME PASSWORD: Password123!\n');
  console.log('1. [CR - Section A]:    cr.secA@uttara.edu.bd      (Has running class in Room 5030 to make free)');
  console.log('2. [CR - Section B]:    cr.secB@uttara.edu.bd      (Can book Room 5030 or 5028 for Batch 68-B)');
  console.log('3. [Student - Sec A]:   student.secA@uttara.edu.bd (Batch 68, Sec A Schedule & notices)');
  console.log('4. [Student - Sec B]:   student.secB@uttara.edu.bd (Batch 68, Sec B Schedule & notices)');
  console.log('5. [Faculty - DNS]:     faculty.dns@uttara.edu.bd  (Teaches SWE-321 & SWE-411)');
  console.log('6. [Super Admin]:       admin@uttara.edu.bd        (Full campus admin panel access)');
  console.log('=============================================================\n');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
