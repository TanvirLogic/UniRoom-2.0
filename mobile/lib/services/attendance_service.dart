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
          // Sanitize: purge any legacy hardcoded dummy IDs
          students = decoded
              .map((item) => SectionStudentModel.fromJson(Map<String, dynamic>.from(item)))
              .where((s) => !s.studentId.startsWith('22410810'))
              .toList();
        } catch (_) {}
      }
    }

    // Try fetching live roster from backend
    try {
      final token = await _authService.getAccessToken();
      if (token != null) {
        final queryParams = <String, String>{};
        if (department.trim().isNotEmpty) queryParams['department'] = department.trim();
        if (batch.trim().isNotEmpty) queryParams['batch'] = batch.trim();
        if (section.trim().isNotEmpty) queryParams['section'] = section.trim();

        final uri = Uri.parse(ApiConstants.sectionStudents).replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        final response = await http.get(
          uri,
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
    } catch (_) {
      // Offline fallback: keep cached students
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
    buffer.writeln('👥 Section: $department | Batch: $batch | Section: $section');
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
}
