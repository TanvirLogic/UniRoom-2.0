import { PrismaClient, Role, RoomStatus, DayOfWeek } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting UniRoom-Live 2.0 Database Seeding...');

  // 1. Clean existing data in reverse order of foreign key dependencies
  await prisma.emergencyAnnouncement.deleteMany();
  await prisma.scheduleOverride.deleteMany();
  await prisma.scheduleSlot.deleteMany();
  await prisma.roomLog.deleteMany();
  await prisma.room.deleteMany();
  await prisma.building.deleteMany();
  await prisma.user.deleteMany();
  await prisma.department.deleteMany();
  await prisma.university.deleteMany();

  console.log('🧹 Cleaned existing database tables.');

  // 2. Create University
  const university = await prisma.university.create({
    data: {
      name: 'Uttara University',
      code: 'UU',
      domain: 'uttara.edu.bd',
      operatingDays: [DayOfWeek.MON, DayOfWeek.TUE, DayOfWeek.WED, DayOfWeek.THU],
      isActive: true,
    },
  });
  console.log(`✅ Seeded University: ${university.name} (${university.code})`);

  // 3. Create Department
  const department = await prisma.department.create({
    data: {
      universityId: university.id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
    },
  });
  console.log(`✅ Seeded Department: ${department.name} (${department.code})`);

  // 4. Create Building
  const building = await prisma.building.create({
    data: {
      departmentId: department.id,
      campusName: 'Permanent Campus',
      name: 'Building B',
    },
  });
  console.log(`✅ Seeded Building: ${building.name} (${building.campusName})`);

  // 5. Create Core Physical Rooms
  const roomsData = [
    { roomNumber: 'AI Lab 5210 (514)', floor: 5, capacity: 45, currentStatus: RoomStatus.AVAILABLE },
    { roomNumber: '5030 (508)', floor: 5, capacity: 55, currentStatus: RoomStatus.AVAILABLE },
    { roomNumber: 'Phy Lab 6080 (601)', floor: 6, capacity: 40, currentStatus: RoomStatus.AVAILABLE },
    { roomNumber: '6050 (605)', floor: 6, capacity: 50, currentStatus: RoomStatus.AVAILABLE },
  ];

  const createdRooms: Record<string, string> = {};
  for (const r of roomsData) {
    const room = await prisma.room.create({
      data: {
        universityId: university.id,
        departmentId: department.id,
        buildingId: building.id,
        roomNumber: r.roomNumber,
        floor: r.floor,
        capacity: r.capacity,
        currentStatus: r.currentStatus,
      },
    });
    createdRooms[r.roomNumber] = room.id;
  }
  console.log(`✅ Seeded ${Object.keys(createdRooms).length} Physical Rooms`);

  // 6. Create Seed Users (4 Core Roles)
  // Note: Passwords stored as deterministic dummy hashes for development
  const dummyHash = '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW'; // "Password123!"

  const superAdmin = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: department.id,
      fullName: 'Chief University Admin',
      email: 'admin@uttara.edu.bd',
      passwordHash: dummyHash,
      role: Role.SUPER_ADMIN,
    },
  });

  const facultyUser = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: department.id,
      fullName: 'Dr. Dewan Nayemul Shahriar',
      email: 'dns@uttara.edu.bd',
      facultyId: 'DNS',
      passwordHash: dummyHash,
      role: Role.FACULTY,
    },
  });

  const crUser = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: department.id,
      fullName: 'Tanvir Ahmed (CR Batch 68)',
      email: 'cr.batch68a@uttara.edu.bd',
      batch: '68',
      section: 'A',
      isApprovedCr: true,
      passwordHash: dummyHash,
      role: Role.CR,
    },
  });

  const studentUser = await prisma.user.create({
    data: {
      universityId: university.id,
      departmentId: department.id,
      fullName: 'Sadia Rahman (Student)',
      email: 'student.batch68a@uttara.edu.bd',
      batch: '68',
      section: 'A',
      passwordHash: dummyHash,
      role: Role.STUDENT,
    },
  });
  console.log('✅ Seeded 4 Core Roles: Super Admin, Faculty (DNS), CR (Batch 68A), Student');

  // 7. Create Schedule Slots (Master Routine)
  await prisma.scheduleSlot.create({
    data: {
      departmentId: department.id,
      roomId: createdRooms['AI Lab 5210 (514)'],
      facultyUserId: facultyUser.id,
      facultyInitials: 'DNS',
      batch: '68',
      section: 'A',
      courseCode: 'CSE06131',
      courseName: 'Algorithms Design & Analysis',
      dayOfWeek: DayOfWeek.MON,
      startTime: '09:30',
      endTime: '10:50',
    },
  });

  await prisma.scheduleSlot.create({
    data: {
      departmentId: department.id,
      roomId: createdRooms['5030 (508)'],
      facultyInitials: 'AMU',
      batch: '68',
      section: 'A',
      courseCode: 'CSE06133',
      courseName: 'Database Management Systems',
      dayOfWeek: DayOfWeek.MON,
      startTime: '11:00',
      endTime: '12:20',
    },
  });

  await prisma.scheduleSlot.create({
    data: {
      departmentId: department.id,
      roomId: createdRooms['Phy Lab 6080 (601)'],
      facultyInitials: 'RIR',
      batch: '68',
      section: 'A',
      courseCode: 'PHY05111',
      courseName: 'Engineering Physics Lab',
      dayOfWeek: DayOfWeek.TUE,
      startTime: '09:30',
      endTime: '10:50',
    },
  });
  console.log('✅ Seeded 3 Master Schedule Slots for Batch 68 Section A');

  // 8. Create Sample Emergency Broadcast
  await prisma.emergencyAnnouncement.create({
    data: {
      universityId: university.id,
      title: 'Midterm Routine Schedule Ingested',
      message: 'The Spring 2026 routine is now active. CRs can submit schedule adjustments via the dashboard.',
      isActive: true,
    },
  });
  console.log('✅ Seeded Emergency Announcement');

  console.log('🎉 Seeding successfully completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
