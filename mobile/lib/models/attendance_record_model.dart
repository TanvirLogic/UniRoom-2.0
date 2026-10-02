import 'dart:convert';

/// AttendanceStudentEntry
/// Lightweight entry representing an individual student's attendance state.
class AttendanceStudentEntry {
  final String studentId;
  final String fullName;
  final bool isPresent;

  AttendanceStudentEntry({
    required this.studentId,
    required this.fullName,
    required this.isPresent,
  });

  factory AttendanceStudentEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceStudentEntry(
      studentId: json['studentId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      isPresent: json['isPresent'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'isPresent': isPresent,
    };
  }
}

/// AttendanceRecordModel
/// Represents a saved attendance session for a specific date and course.
class AttendanceRecordModel {
  final String id;
  final DateTime date;
  final String dateFormatted;
  final String courseCode;
  final String courseTitle;
  final String department;
  final String batch;
  final String section;
  final List<AttendanceStudentEntry> students;
  final String formattedSmsText;
  final DateTime savedAt;

  AttendanceRecordModel({
    required this.id,
    required this.date,
    required this.dateFormatted,
    required this.courseCode,
    required this.courseTitle,
    required this.department,
    required this.batch,
    required this.section,
    required this.students,
    required this.formattedSmsText,
    required this.savedAt,
  });

  int get totalCount => students.length;
  int get presentCount => students.where((s) => s.isPresent).length;
  int get absentCount => students.where((s) => !s.isPresent).length;

  List<AttendanceStudentEntry> get presentStudents =>
      students.where((s) => s.isPresent).toList();

  List<AttendanceStudentEntry> get absentStudents =>
      students.where((s) => !s.isPresent).toList();

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    var rawStudents = json['students'];
    List<AttendanceStudentEntry> studentList = [];
    if (rawStudents is List) {
      studentList = rawStudents
          .map((s) => AttendanceStudentEntry.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }

    return AttendanceRecordModel(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      dateFormatted: json['dateFormatted'] ?? '',
      courseCode: json['courseCode'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      department: json['department'] ?? '',
      batch: json['batch'] ?? '',
      section: json['section'] ?? '',
      students: studentList,
      formattedSmsText: json['formattedSmsText'] ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'dateFormatted': dateFormatted,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'department': department,
      'batch': batch,
      'section': section,
      'students': students.map((s) => s.toJson()).toList(),
      'formattedSmsText': formattedSmsText,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static AttendanceRecordModel fromJsonString(String str) =>
      AttendanceRecordModel.fromJson(jsonDecode(str));
}
