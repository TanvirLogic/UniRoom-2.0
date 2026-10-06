import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/section_student_model.dart';
import '../models/attendance_record_model.dart';
import 'auth_service.dart';

/// AttendanceService
/// Handles loading section roster, taking daily attendance, generating
/// formatted SMS text for faculty, and local persistence of attendance history.
class AttendanceService {
  final AuthService _authService;
  static const String _recordsKey = 'uniroom_saved_attendance_records_v1';

  AttendanceService({AuthService? authService})
      : _authService = authService ?? AuthService();

  String _rosterKey(String dept, String batch, String sec) =>
      'uniroom_roster_${dept.toUpperCase()}_${batch}_${sec.toUpperCase()}';

  /// 1. Fetch Section Students
  /// Queries backend GET /auth/section-students. Live database records are the ground truth.
  Future<List<SectionStudentModel>> getSectionStudents({
    required String department,
    required String batch,
    required String section,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _rosterKey(department, batch, section);

    List<SectionStudentModel> students = [];

    // Check local cache if not forcing refresh
    if (!forceRefresh) {
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final List decoded = jsonDecode(cachedStr);
          students = decoded
              .map((item) => SectionStudentModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        } catch (_) {}
      }
    }

    // Try fetching live roster from backend
    try {
      final token = await _authService.getAccessToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse(ApiConstants.sectionStudents),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          final List list = decoded is Map && decoded.containsKey('data')
              ? decoded['data']
              : (decoded is List ? decoded : []);

          if (list.isNotEmpty) {
            final liveStudents = list
                .map((item) => SectionStudentModel.fromJson(Map<String, dynamic>.from(item)))
                .toList();

            // Retain any ongoing attendance selection state (isPresent)
            final presenceMap = {for (final s in students) s.studentId: s.isPresent};
            for (final s in liveStudents) {
              if (presenceMap.containsKey(s.studentId)) {
                s.isPresent = presenceMap[s.studentId]!;
              }
            }

            students = liveStudents;

            // Sort by student roll ID ascending
            students.sort((a, b) => a.studentId.compareTo(b.studentId));

            // Persist latest live roster to cache
            await prefs.setString(
              cacheKey,
              jsonEncode(students.map((s) => s.toJson()).toList()),
            );

            return students;
          }
        }
      }
    } catch (_) {
      // Offline fallback: keep cached students
    }

    // If still empty (e.g. offline first-launch), use default cohort
    if (students.isEmpty) {
      students = _getDefaultCohort(department, batch, section);
    }

    // Sort by student roll ID ascending
    students.sort((a, b) => a.studentId.compareTo(b.studentId));

    // Persist latest roster
    await prefs.setString(
      cacheKey,
      jsonEncode(students.map((s) => s.toJson()).toList()),
    );

    return students;
  }

  /// 2. Quick-add a new student to section roster
  Future<SectionStudentModel> addStudent({
    required String studentId,
    required String fullName,
    required String department,
    required String batch,
    required String section,
  }) async {
    final cleanId = studentId.trim();
    final cleanName = fullName.trim();

    final newStudent = SectionStudentModel(
      id: cleanId,
      studentId: cleanId,
      fullName: cleanName,
      department: department,
      batch: batch,
      section: section,
      isPresent: true,
    );

    // Try sending to backend
    try {
      final token = await _authService.getAccessToken();
      if (token != null) {
        await http.post(
          Uri.parse(ApiConstants.sectionStudents),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'studentId': cleanId,
            'fullName': cleanName,
          }),
        ).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    // Update local roster
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _rosterKey(department, batch, section);
    final currentList = await getSectionStudents(
      department: department,
      batch: batch,
      section: section,
    );

    // Replace if exists, or append
    final index = currentList.indexWhere((s) => s.studentId == cleanId);
    if (index != -1) {
      currentList[index] = newStudent;
    } else {
      currentList.add(newStudent);
    }

    currentList.sort((a, b) => a.studentId.compareTo(b.studentId));
    await prefs.setString(
      cacheKey,
      jsonEncode(currentList.map((s) => s.toJson()).toList()),
    );

    return newStudent;
  }

  /// 3. Remove a student from local roster
  Future<void> removeStudent({
    required String studentId,
    required String department,
    required String batch,
    required String section,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _rosterKey(department, batch, section);
    final currentList = await getSectionStudents(
      department: department,
      batch: batch,
      section: section,
    );

    currentList.removeWhere((s) => s.studentId == studentId);
    await prefs.setString(
      cacheKey,
      jsonEncode(currentList.map((s) => s.toJson()).toList()),
    );
  }

  /// 4. Reset roster back to defaults
  Future<List<SectionStudentModel>> resetRoster({
    required String department,
    required String batch,
    required String section,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _rosterKey(department, batch, section);
    await prefs.remove(cacheKey);
    return getSectionStudents(
      department: department,
      batch: batch,
      section: section,
    );
  }

  /// 5. Save an attendance session record
  Future<void> saveAttendanceRecord(AttendanceRecordModel record) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedRecords();

    // Replace if same ID exists, or prepend new record
    list.removeWhere((r) => r.id == record.id);
    list.insert(0, record);

    // Keep up to 60 most recent records
    if (list.length > 60) {
      list.removeRange(60, list.length);
    }

    final encodedList = list.map((r) => r.toJson()).toList();
    await prefs.setString(_recordsKey, jsonEncode(encodedList));
  }

  /// 6. Retrieve all saved attendance records
  Future<List<AttendanceRecordModel>> getSavedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List decoded = jsonDecode(raw);
      return decoded
          .map((item) => AttendanceRecordModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 7. Delete a specific saved record
  Future<void> deleteRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedRecords();
    list.removeWhere((r) => r.id == recordId);
    final encodedList = list.map((r) => r.toJson()).toList();
    await prefs.setString(_recordsKey, jsonEncode(encodedList));
  }

  /// 8. Generate Clean Plain Text Formatted for Personal SMS to Faculty
  /// Format requested: "Id - Name will be stored in a text format so that he can copy and paste to faculty in personal sms ."
  String generateFacultySmsText({
    required String dateFormatted,
    required String courseCode,
    required String courseTitle,
    required String department,
    required String batch,
    required String section,
    required List<SectionStudentModel> allStudents,
    bool compactMode = false,
  }) {
    final present = allStudents.where((s) => s.isPresent).toList();
    final absent = allStudents.where((s) => !s.isPresent).toList();

    present.sort((a, b) => a.studentId.compareTo(b.studentId));
    absent.sort((a, b) => a.studentId.compareTo(b.studentId));

    final courseDisplay = courseCode.isNotEmpty
        ? (courseTitle.isNotEmpty ? '$courseCode ($courseTitle)' : courseCode)
        : 'Daily Routine Class';

    if (compactMode) {
      // Compact SMS format for character-limited SMS
      final buffer = StringBuffer();
      buffer.writeln('[$department $batch-$section] Attendance');
      buffer.writeln('Date: $dateFormatted');
      buffer.writeln('Course: $courseDisplay');
      buffer.writeln('Present (${present.length}/${allStudents.length}):');
      for (int i = 0; i < present.length; i++) {
        buffer.writeln('${present[i].studentId} - ${present[i].fullName}');
      }
      if (absent.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Absent (${absent.length}):');
        for (int i = 0; i < absent.length; i++) {
          buffer.writeln('${absent[i].studentId} - ${absent[i].fullName}');
        }
      }
      return buffer.toString().trim();
    }

    // Standard Professional SMS Format
    final buffer = StringBuffer();
    buffer.writeln('📌 Class Attendance Report');
    buffer.writeln('📅 Date: $dateFormatted');
    buffer.writeln('📚 Course: $courseDisplay');
    buffer.writeln('👥 Cohort: $department | Batch: $batch | Section: $section');
    buffer.writeln('📊 Summary: ${present.length} Present / ${absent.length} Absent (Total: ${allStudents.length})');
    buffer.writeln();

    buffer.writeln('✅ Present List (${present.length}):');
    if (present.isEmpty) {
      buffer.writeln('None');
    } else {
      for (int i = 0; i < present.length; i++) {
        final s = present[i];
        buffer.writeln('${i + 1}. ${s.studentId} - ${s.fullName}${s.isCr ? " (CR)" : ""}');
      }
    }

    buffer.writeln();
    buffer.writeln('❌ Absent List (${absent.length}):');
    if (absent.isEmpty) {
      buffer.writeln('None (100% Attendance)');
    } else {
      for (int i = 0; i < absent.length; i++) {
        final s = absent[i];
        buffer.writeln('${i + 1}. ${s.studentId} - ${s.fullName}');
      }
    }

    return buffer.toString().trim();
  }

  /// Default Realistic Cohort Fallback
  List<SectionStudentModel> _getDefaultCohort(String dept, String batch, String section) {
    final cleanSec = section.toUpperCase().trim();
    final isSecB = cleanSec.contains('B');

    if (isSecB) {
      return [
        SectionStudentModel(id: '2241081002', studentId: '2241081002', fullName: 'Sabbir Hossain', department: dept, batch: batch, section: 'B', isCr: true),
        SectionStudentModel(id: '2241081003', studentId: '2241081003', fullName: 'Tanvir Hasan', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081005', studentId: '2241081005', fullName: 'Md. Abdullah', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081008', studentId: '2241081008', fullName: 'Sumaiya Akter', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081011', studentId: '2241081011', fullName: 'Fahim Shahriar', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081014', studentId: '2241081014', fullName: 'Mehedi Hasan', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081018', studentId: '2241081018', fullName: 'Nusrat Jahan', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081021', studentId: '2241081021', fullName: 'Mahir Faysal', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081025', studentId: '2241081025', fullName: 'Ayesha Siddika', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081029', studentId: '2241081029', fullName: 'Sakib Al Hasan', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081033', studentId: '2241081033', fullName: 'Sadia Islam', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081037', studentId: '2241081037', fullName: 'Rayhan Ahmed', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081042', studentId: '2241081042', fullName: 'Rifat Hossain', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081046', studentId: '2241081046', fullName: 'Farzana Haque', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081051', studentId: '2241081051', fullName: 'Karim Student', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081055', studentId: '2241081055', fullName: 'Naimul Islam', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081058', studentId: '2241081058', fullName: 'Tamanna Rahman', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081062', studentId: '2241081062', fullName: 'Shahriar Kabir', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081066', studentId: '2241081066', fullName: 'Jannatul Ferdous', department: dept, batch: batch, section: 'B'),
        SectionStudentModel(id: '2241081070', studentId: '2241081070', fullName: 'Ashiqur Rahman', department: dept, batch: batch, section: 'B'),
      ];
    } else {
      // Section A Default Roster
      return [
        SectionStudentModel(id: '2241081001', studentId: '2241081001', fullName: 'Tanvir Ahmed', department: dept, batch: batch, section: 'A', isCr: true),
        SectionStudentModel(id: '2241081004', studentId: '2241081004', fullName: 'Rakibul Islam', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081007', studentId: '2241081007', fullName: 'Sadman Sakib', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081010', studentId: '2241081010', fullName: 'Anika Tabassum', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081013', studentId: '2241081013', fullName: 'Hasibul Hossain', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081017', studentId: '2241081017', fullName: 'Tasnim Alam', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081020', studentId: '2241081020', fullName: 'Siyam Ahmed', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081024', studentId: '2241081024', fullName: 'Nadia Sultana', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081028', studentId: '2241081028', fullName: 'Mahmudul Hasan', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081032', studentId: '2241081032', fullName: 'Marufa Akter', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081036', studentId: '2241081036', fullName: 'Shakil Khan', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081040', studentId: '2241081040', fullName: 'Nishat Rumman', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081045', studentId: '2241081045', fullName: 'Imran Hossain', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081050', studentId: '2241081050', fullName: 'Rahim Student', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081054', studentId: '2241081054', fullName: 'Arifur Rahman', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081060', studentId: '2241081060', fullName: 'Shraboni Roy', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081065', studentId: '2241081065', fullName: 'Zahidul Islam', department: dept, batch: batch, section: 'A'),
        SectionStudentModel(id: '2241081072', studentId: '2241081072', fullName: 'Ishrat Jahan', department: dept, batch: batch, section: 'A'),
      ];
    }
  }
}
