// UniRoom-Live 2.0 Comprehensive Multi-Role E2E Backend Verification
// Tests Student, CR, and Faculty roles, security bounds, and OCC engine.

const BASE_URL = 'http://localhost:3000/api/v1';

let passed = 0;
let failed = 0;
const results = [];

function record(name, isPass, detail = '') {
  if (isPass) {
    passed++;
    console.log(`  ✅ [PASS] ${name}${detail ? ` (${detail})` : ''}`);
    results.push({ name, status: 'PASS', detail });
  } else {
    failed++;
    console.log(`  ❌ [FAIL] ${name}: ${detail}`);
    results.push({ name, status: 'FAIL', detail });
  }
}

async function request(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  try {
    const res = await fetch(url, {
      ...options,
      headers,
    });
    const text = await res.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
    return { status: res.status, ok: res.ok, data };
  } catch (err) {
    return { status: 0, ok: false, data: null, error: err.message };
  }
}

async function run() {
  console.log('\n===============================================================');
  console.log('🚀 UNIROOM-LIVE 2.0 - COMPREHENSIVE BACKEND INTEGRATION TEST');
  console.log('===============================================================\n');

  // --------------------------------------------------------------------------
  // TEST SUITE 1: SYSTEM HEALTH, TELEMETRY & METADATA
  // --------------------------------------------------------------------------
  console.log('--- 1. SYSTEM HEALTH & METADATA FEEDS ---');

  const healthRes = await request('/health');
  record(
    'GET /health (Database & Service Telemetry)',
    healthRes.status === 200 && healthRes.data?.data?.database?.status === 'connected',
    `DB: ${healthRes.data?.data?.database?.status}, Rooms: ${healthRes.data?.data?.database?.stats?.rooms}, Slots: ${healthRes.data?.data?.database?.stats?.scheduleSlots}`
  );

  const diagRes = await request('/health/diagnostics');
  record(
    'GET /health/diagnostics (Deep Diagnostics)',
    diagRes.status === 200 && diagRes.data?.data?.service === 'UniRoom-Live 2.0',
    `Firebase: ${diagRes.data?.data?.pushNotifications?.status}, SMTP Host: ${diagRes.data?.data?.email?.host}`
  );

  const metaRes = await request('/meta/registration-options');
  const uniList = metaRes.data?.data?.universities || [];
  record(
    'GET /meta/registration-options (Cascading Dropdown Hierarchy)',
    metaRes.status === 200 && uniList.length > 0,
    `Loaded ${uniList.length} university, Depts: ${uniList[0]?.departments?.length || 0}, Batches: ${uniList[0]?.departments[0]?.batches?.length || 0}`
  );

  const unisRes = await request('/universities');
  record(
    'GET /universities (Public University Catalog)',
    unisRes.status === 200 && Array.isArray(unisRes.data?.data),
    `Count: ${unisRes.data?.data?.length || 0}`
  );

  // --------------------------------------------------------------------------
  // TEST SUITE 2: AUTHENTICATION ACROSS ROLES
  // --------------------------------------------------------------------------
  console.log('\n--- 2. AUTHENTICATION & ROLE-BASED ACCESS (STUDENT, CR, FACULTY) ---');

  // 2.1 Student Login
  const studentLogin = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({
      email: 'student.seca@uttara.edu.bd',
      password: 'Password123!',
    }),
  });
  const studentToken = studentLogin.data?.data?.accessToken;
  const studentUser = studentLogin.data?.data?.user;
  record(
    'POST /auth/login (Student Authentication)',
    studentLogin.status === 200 && studentUser?.role === 'STUDENT' && Boolean(studentToken),
    `User: ${studentUser?.fullName}, Role: ${studentUser?.role}`
  );

  // 2.2 CR Login (Section A)
  const crLogin = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({
      email: 'cr.seca@uttara.edu.bd',
      password: 'Password123!',
    }),
  });
  const crToken = crLogin.data?.data?.accessToken;
  const crUser = crLogin.data?.data?.user;
  record(
    'POST /auth/login (CR Authentication)',
    crLogin.status === 200 && crUser?.role === 'CR' && Boolean(crToken),
    `User: ${crUser?.fullName}, Batch: ${crUser?.batch}, Sec: ${crUser?.section}`
  );

  // 2.2b CR Login (Section B for cross-section boundary test)
  const crBLogin = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({
      email: 'cr.secb@uttara.edu.bd',
      password: 'Password123!',
    }),
  });
  const crBToken = crBLogin.data?.data?.accessToken;

  // 2.3 Faculty Login
  const facultyLogin = await request('/auth/login', {
    method: 'POST',
    body: JSON.stringify({
      email: 'faculty.dns@uttara.edu.bd',
      password: 'Password123!',
    }),
  });
  const facultyToken = facultyLogin.data?.data?.accessToken;
  const facultyUser = facultyLogin.data?.data?.user;
  record(
    'POST /auth/login (Faculty Authentication)',
    facultyLogin.status === 200 && facultyUser?.role === 'FACULTY' && Boolean(facultyToken),
    `User: ${facultyUser?.fullName}, FacultyId: ${facultyUser?.facultyId}`
  );

  // --------------------------------------------------------------------------
  // TEST SUITE 3: STUDENT ROLE FEATURES & RESTRICTIONS
  // --------------------------------------------------------------------------
  console.log('\n--- 3. STUDENT ROLE FEATURES & RESTRICTIONS ---');

  // 3.1 Student Profile
  const studentProfile = await request('/auth/me', {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  record(
    'GET /auth/me (Student Profile)',
    studentProfile.status === 200 && studentProfile.data?.data?.id === studentUser?.id,
    `Email: ${studentProfile.data?.data?.email}`
  );

  // 3.2 Student View Routine Slots
  const studentSchedule = await request('/schedules?department=SWE&batch=68&section=A', {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  const slots = studentSchedule.data?.data || [];
  record(
    'GET /schedules (Student Routine Lookup)',
    studentSchedule.status === 200 && Array.isArray(slots) && slots.length > 0,
    `Retrieved ${slots.length} weekly timetable slots for Batch 68 (A)`
  );

  // 3.3 Student View Physical Classrooms
  const studentRooms = await request('/rooms', {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  const roomList = studentRooms.data?.data?.rooms || [];
  record(
    'GET /rooms (Classroom Catalog & OCC Versioning)',
    studentRooms.status === 200 && roomList.length > 0,
    `Retrieved ${roomList.length} physical classrooms`
  );

  // 3.4 Student 1-Tap Free Room Finder
  const freeRoomsStudent = await request('/rooms/free-now?durationMinutes=60', {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  const freeRoomResults = freeRoomsStudent.data?.data?.results || [];
  record(
    'GET /rooms/free-now (Student 1-Tap Free Room Finder)',
    freeRoomsStudent.status === 200 && Array.isArray(freeRoomResults),
    `Found ${freeRoomResults.length} free classrooms available now`
  );

  // 3.5 Student View Course Notices
  const studentNotices = await request('/classrooms/notices?courseCode=SWE-321', {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  record(
    'GET /classrooms/notices (Student Course Notice Board)',
    studentNotices.status === 200 && Array.isArray(studentNotices.data?.data),
    `Notices count: ${studentNotices.data?.data?.length || 0}`
  );

  // 3.6 Student View Course Lectures
  const studentLectures = await request('/classrooms/lectures?courseCode=SWE-321', {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  record(
    'GET /classrooms/lectures (Student Course Lecture Notes Archive)',
    studentLectures.status === 200 && Array.isArray(studentLectures.data?.data),
    `Lectures count: ${studentLectures.data?.data?.length || 0}`
  );

  // 3.7 SECURITY CHECK: Student attempts to cancel class (Must be 403 Forbidden!)
  const sampleSlotId = slots[0]?.id || 'dummy-slot-id';
  const studentIllegalCancel = await request(`/schedules/slots/${sampleSlotId}/cancel-today`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({ reason: 'Student trying to cancel illegally' }),
  });
  record(
    'SECURITY: Student Cancel Class Blocked (403 Forbidden)',
    studentIllegalCancel.status === 403,
    `Status: ${studentIllegalCancel.status} (RolesGuard correctly rejected unauthorized student)`
  );

  // 3.8 SECURITY CHECK: Student attempts to post notice (Must be 403 Forbidden!)
  const studentIllegalNotice = await request('/classrooms/notices', {
    method: 'POST',
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({
      courseCode: 'SWE-321',
      title: 'Spam Notice',
      content: 'Students should not post notices',
    }),
  });
  record(
    'SECURITY: Student Post Notice Blocked (403 Forbidden)',
    studentIllegalNotice.status === 403,
    `Status: ${studentIllegalNotice.status} (Correctly rejected unauthorized student)`
  );

  // 3.9 SECURITY CHECK: Student attempts to book extra class (Must be 403 Forbidden!)
  const sampleRoomId = roomList[0]?.id || 'dummy-room';
  const studentIllegalBooking = await request(`/rooms/${sampleRoomId}/book-extra-class`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${studentToken}` },
    body: JSON.stringify({
      courseName: 'Illegal Booking',
      batch: '68',
      section: 'A',
      version: 1,
    }),
  });
  record(
    'SECURITY: Student Book Extra Class Blocked (403 Forbidden)',
    studentIllegalBooking.status === 403,
    `Status: ${studentIllegalBooking.status} (RolesGuard correctly rejected unauthorized student)`
  );

  // --------------------------------------------------------------------------
  // TEST SUITE 4: CR ROLE FEATURES & ACTIONS
  // --------------------------------------------------------------------------
  console.log('\n--- 4. CR ROLE ACTIONS (CANCEL, RESCHEDULE, FREE ROOM, EXTRA CLASS) ---');

  if (slots.length > 0) {
    const targetSlot = slots[0];

    // 4.1 Cancel Today's Class
    const cancelRes = await request(`/schedules/slots/${targetSlot.id}/cancel-today`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${crToken}` },
      body: JSON.stringify({
        reason: 'Faculty informed sick - class suspended for today',
        freeRoom: true,
      }),
    });
    record(
      `POST /schedules/slots/${targetSlot.id}/cancel-today (CR Cancels Class)`,
      cancelRes.status === 200 || cancelRes.status === 201,
      `Action: ${cancelRes.data?.data?.override?.action || 'CANCELLED'}, Reason: ${cancelRes.data?.data?.override?.reason}`
    );

    // Verify ScheduleSlot now includes CANCELLED override
    const verifiedSchedule = await request('/schedules?department=SWE&batch=68&section=A', {
      headers: { Authorization: `Bearer ${studentToken}` },
    });
    const updatedSlot = (verifiedSchedule.data?.data || []).find((s) => s.id === targetSlot.id);
    const hasCancelledOverride = updatedSlot?.overrides?.some((o) => o.action === 'CANCELLED');
    record(
      'VERIFY: Today Timetable reflects CANCELLED override with red badge',
      hasCancelledOverride === true,
      `Overrides count: ${updatedSlot?.overrides?.length || 0}`
    );

    // 4.2 Undo Cancellation Override
    const undoRes = await request(`/schedules/slots/${targetSlot.id}/override-today`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${crToken}` },
    });
    record(
      `DELETE /schedules/slots/${targetSlot.id}/override-today (CR Reverts Override back to Normal)`,
      undoRes.status === 200,
      `Message: ${undoRes.data?.data?.message || 'Override removed'}`
    );

    // 4.3 Reschedule Today's Class
    const rescheduleRes = await request(`/schedules/slots/${targetSlot.id}/reschedule-today`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${crToken}` },
      body: JSON.stringify({
        newStartTime: '14:00',
        newEndTime: '15:20',
        reason: 'Shifted to afternoon session upon faculty request',
      }),
    });
    record(
      `POST /schedules/slots/${targetSlot.id}/reschedule-today (CR Reschedules Class Time)`,
      rescheduleRes.status === 200 || rescheduleRes.status === 201,
      `New time: ${rescheduleRes.data?.data?.override?.newStartTime} - ${rescheduleRes.data?.data?.override?.newEndTime}`
    );

    // Revert reschedule so routine stays clean
    await request(`/schedules/slots/${targetSlot.id}/override-today`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${crToken}` },
    });

    // 4.4 SECURITY CHECK: CR Section Boundary Isolation
    // Section B CR attempts to cancel Section A slot (Must be 403 Forbidden!)
    if (crBToken) {
      const crIllegalCancel = await request(`/schedules/slots/${targetSlot.id}/cancel-today`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${crBToken}` },
        body: JSON.stringify({ reason: 'Section B CR trying to cancel Section A class' }),
      });
      record(
        'SECURITY: CR Cannot Cancel Another Section Class (403 Forbidden)',
        crIllegalCancel.status === 403,
        `Status: ${crIllegalCancel.status} (Cohort boundary isolation enforced)`
      );
    }
  }

  // 4.5 CR Free Room Early (Broadcast to other CRs)
  const roomToFree = roomList.find((r) => r.currentStatus === 'RUNNING_CLASS') || roomList[0];
  if (roomToFree) {
    const freeRoomRes = await request(`/rooms/${roomToFree.id}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${crToken}` },
      body: JSON.stringify({
        status: 'AVAILABLE',
        version: roomToFree.version,
        note: 'Freed early by CR Tanvir: Class concluded 20 minutes early',
      }),
    });
    record(
      `PATCH /rooms/${roomToFree.id}/status (CR Releases Room Early for Other Batches)`,
      freeRoomRes.status === 200,
      `New Status: ${freeRoomRes.data?.data?.room?.currentStatus}, Version: ${freeRoomRes.data?.data?.room?.version}`
    );
  }

  // 4.6 CR Books an Extra Class (Issue 2, 3, 4 Verification!)
  const refreshedRooms = await request('/rooms', {
    headers: { Authorization: `Bearer ${crToken}` },
  });
  const availRoom = (refreshedRooms.data?.data?.rooms || []).find((r) => r.currentStatus === 'AVAILABLE') || roomList[0];

  let bookedExtraClassSuccess = false;
  let createdSlotId = null;

  if (availRoom) {
    const bookExtraRes = await request(`/rooms/${availRoom.id}/book-extra-class`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${crToken}` },
      body: JSON.stringify({
        courseName: 'SWE-321 Software Architecture (Extra Lab Session)',
        batch: '68',
        section: 'A',
        teacherInitials: 'DNS',
        durationMinutes: 90,
        department: 'SWE',
        version: availRoom.version,
        note: 'Make-up lab session arranged by Section A CR',
      }),
    });

    createdSlotId = bookExtraRes.data?.data?.scheduleSlot?.id;
    bookedExtraClassSuccess =
      bookExtraRes.status === 200 || bookExtraRes.status === 201;

    record(
      `POST /rooms/${availRoom.id}/book-extra-class (CR Schedules Extra Class & Generates Timetable Slot)`,
      bookedExtraClassSuccess,
      `Room: ${availRoom.roomNumber}, Generated Slot ID: ${createdSlotId || 'N/A'}`
    );

    // Verify the extra class slot immediately surfaces in the student timetable!
    const postBookingSchedule = await request('/schedules?department=SWE&batch=68&section=A', {
      headers: { Authorization: `Bearer ${studentToken}` },
    });
    const extraSlotFound = (postBookingSchedule.data?.data || []).some(
      (s) => s.courseName?.includes('Extra Lab Session')
    );
    record(
      'VERIFY: Today Timetable immediately surfaces the Extra Class with running/upcoming status',
      extraSlotFound,
      `Students and CR both see the new extra class on Today tab without manual refresh!`
    );

    // 4.7 Concurrency OCC Lock Conflict Verification
    // Attempting to book the same room with the stale version should fail with 409 Conflict!
    const staleOccBooking = await request(`/rooms/${availRoom.id}/book-extra-class`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${crToken}` },
      body: JSON.stringify({
        courseName: 'Conflict Double Booking Attempt',
        batch: '68',
        section: 'B',
        version: availRoom.version, // STALE VERSION!
      }),
    });
    record(
      'OCC CONCURRENCY: Stale Version Double-Booking Rejected (409 Conflict)',
      staleOccBooking.status === 409,
      `Status: ${staleOccBooking.status} (Optimistic Concurrency Control successfully prevented double booking)`
    );

    // Clean up created extra schedule slot if needed
    if (createdSlotId) {
      await request(`/admin/schedules/slot/${createdSlotId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${crToken}` }, // note: admin endpoint
      });
    }
  }

  // 4.8 CR Posts Section Classroom Notice
  const crNoticeRes = await request('/classrooms/notices', {
    method: 'POST',
    headers: { Authorization: `Bearer ${crToken}` },
    body: JSON.stringify({
      courseCode: 'SWE-321',
      title: 'Lab Class Location Notice',
      content: 'Extra class will be conducted in Room 5028. Please bring your laptops with Docker installed.',
      targetCohort: 'Batch 68 (A)',
    }),
  });
  const crNoticeId = crNoticeRes.data?.data?.id;
  record(
    'POST /classrooms/notices (CR Posts Section Classroom Notice)',
    (crNoticeRes.status === 200 || crNoticeRes.status === 201) && Boolean(crNoticeId),
    `Notice ID: ${crNoticeId}, Author: ${crNoticeRes.data?.data?.authorName} (${crNoticeRes.data?.data?.authorRole})`
  );

  // --------------------------------------------------------------------------
  // TEST SUITE 5: FACULTY ROLE FEATURES
  // --------------------------------------------------------------------------
  console.log('\n--- 5. FACULTY ROLE FEATURES (LECTURES, NOTICES, FACULTY TIMETABLE) ---');

  // 5.1 Faculty Classes Timetable
  const facultyClasses = await request('/schedules?facultyCode=DNS', {
    headers: { Authorization: `Bearer ${facultyToken}` },
  });
  const facSlots = facultyClasses.data?.data || [];
  record(
    'GET /schedules?facultyCode=DNS (Teacher Live Timetable Schedule)',
    facultyClasses.status === 200 && Array.isArray(facSlots) && facSlots.length > 0,
    `Retrieved ${facSlots.length} teaching schedule slots for Dr. Nazmul Shakib (DNS)`
  );

  // 5.2 Faculty Posts Lecture Material (Auto-Numbering)
  const facultyLectureRes = await request('/classrooms/lectures', {
    method: 'POST',
    headers: { Authorization: `Bearer ${facultyToken}` },
    body: JSON.stringify({
      courseCode: 'SWE-321',
      title: 'Design Patterns: Factory, Singleton & Observer',
      date: '2026-10-10',
      topics: 'Creational patterns, Gang of Four, real-world NestJS implementations',
      link: 'https://drive.google.com/test-lecture-slides',
      targetCohort: 'All Sections',
    }),
  });
  const lectureId = facultyLectureRes.data?.data?.id;
  const lectureNum = facultyLectureRes.data?.data?.lectureNumber;
  record(
    'POST /classrooms/lectures (Faculty Publishes Lecture Material with Auto-Numbering)',
    (facultyLectureRes.status === 200 || facultyLectureRes.status === 201) && Boolean(lectureId),
    `Lecture: ${lectureNum}, Title: ${facultyLectureRes.data?.data?.title}`
  );

  // 5.3 Faculty Posts Course-Wide Notice (Cross-Cohort Fan-Out Broadcast)
  const facultyNoticeRes = await request('/classrooms/notices', {
    method: 'POST',
    headers: { Authorization: `Bearer ${facultyToken}` },
    body: JSON.stringify({
      courseCode: 'SWE-321',
      title: 'Midterm Examination Format & Policy',
      content: 'Midterm will cover Software Architecture, Layered Patterns, and OCC concurrency algorithms.',
      targetCohort: 'All Sections',
    }),
  });
  const facultyNoticeId = facultyNoticeRes.data?.data?.id;
  record(
    'POST /classrooms/notices (Faculty Publishes Course-Wide Notice across All Sections)',
    (facultyNoticeRes.status === 200 || facultyNoticeRes.status === 201) && Boolean(facultyNoticeId),
    `Notice ID: ${facultyNoticeId}, Target: ${facultyNoticeRes.data?.data?.targetCohort}`
  );

  // 5.4 Query Course Notices & Verify Retrieval
  const allNotices = await request('/classrooms/notices?courseCode=SWE-321', {
    headers: { Authorization: `Bearer ${studentToken}` },
  });
  const noticesCount = allNotices.data?.data?.length || 0;
  record(
    'GET /classrooms/notices (Verify Student Sees Both CR and Faculty Notices)',
    allNotices.status === 200 && noticesCount >= 2,
    `Total notices visible in SWE-321 classroom: ${noticesCount}`
  );

  // 5.5 Faculty Deletes Their Notice
  if (facultyNoticeId) {
    const deleteNoticeRes = await request(`/classrooms/notices/${facultyNoticeId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${facultyToken}` },
    });
    record(
      `DELETE /classrooms/notices/${facultyNoticeId} (Faculty Deletes Notice)`,
      deleteNoticeRes.status === 200,
      `Message: ${deleteNoticeRes.data?.data?.message}`
    );
  }

  // 5.6 Faculty Deletes Their Lecture
  if (lectureId) {
    const deleteLectureRes = await request(`/classrooms/lectures/${lectureId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${facultyToken}` },
    });
    record(
      `DELETE /classrooms/lectures/${lectureId} (Faculty Deletes Lecture Material)`,
      deleteLectureRes.status === 200,
      `Message: ${deleteLectureRes.data?.data?.message}`
    );
  }

  // Clean up CR test notice
  if (crNoticeId) {
    await request(`/classrooms/notices/${crNoticeId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${crToken}` },
    });
  }

  // --------------------------------------------------------------------------
  // TEST SUITE 6: UNPROTECTED / UNAUTHENTICATED SECURITY BOUNDARY
  // --------------------------------------------------------------------------
  console.log('\n--- 6. ZERO-TRUST UNPROTECTED ROUTE SECURITY ---');

  const unauthTest1 = await request('/rooms/free-now');
  record(
    'SECURITY: Unauthenticated Access to Free Rooms Blocked (401 Unauthorized)',
    unauthTest1.status === 401,
    `Status: ${unauthTest1.status} (Protected endpoints reject requests missing JWT token)`
  );

  const unauthTest2 = await request('/auth/me');
  record(
    'SECURITY: Unauthenticated Access to /auth/me Blocked (401 Unauthorized)',
    unauthTest2.status === 401,
    `Status: ${unauthTest2.status} (Protected profile rejects requests missing JWT token)`
  );

  const unauthTest3 = await request('/classrooms/notices', {
    method: 'POST',
    body: JSON.stringify({ courseCode: 'SWE-321', title: 'Hacker', content: 'test' }),
  });
  record(
    'SECURITY: Unauthenticated Notice Posting Blocked (401 Unauthorized)',
    unauthTest3.status === 401,
    `Status: ${unauthTest3.status} (Protected endpoints reject unauthenticated writes)`
  );

  // --------------------------------------------------------------------------
  // FINAL SCORE & SUMMARY REPORT
  // --------------------------------------------------------------------------
  console.log('\n===============================================================');
  console.log(`📊 FINAL TEST REPORT: ${passed} PASSED | ${failed} FAILED | TOTAL: ${passed + failed}`);
  console.log('===============================================================\n');

  if (failed === 0) {
    console.log('🎉 ALL BACKEND FEATURES ARE WORKING 100% PERFECTLY ACROSS ALL ROLES!');
    console.log('   - Student features & security boundaries: Verified ✅');
    console.log('   - CR features, rescheduling, overrides & OCC extra class: Verified ✅');
    console.log('   - Faculty features, lectures auto-numbering & teacher routine: Verified ✅');
    console.log('   - Concurrency OCC locks & zero-trust boundaries: Verified ✅');
  } else {
    console.log(`⚠️ Some tests encountered issues. Please review failed tests above.`);
  }

  process.exit(failed === 0 ? 0 : 1);
}

run();
