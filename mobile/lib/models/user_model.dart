/// User Model
/// Converts JSON payloads from the backend API into strongly-typed Dart objects.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'STUDENT', 'CR', 'FACULTY', 'SUPER_ADMIN'
  final String? studentId; // e.g. "2241081422"
  final String universityId;
  final String departmentId;
  final String? batch; // e.g. "68"
  final String? section; // e.g. "A"
  final String? facultyId; // e.g. "DNS"
  final bool isApprovedCr;
  final bool isEmailVerified;
  final String? universityName;
  final String? universityCode;
  final String? departmentName;
  final String? departmentCode;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentId,
    required this.universityId,
    required this.departmentId,
    this.batch,
    this.section,
    this.facultyId,
    this.isApprovedCr = false,
    this.isEmailVerified = false,
    this.universityName,
    this.universityCode,
    this.departmentName,
    this.departmentCode,
  });

  /// Factory constructor to build a UserModel instance from a JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? uniName;
    String? uniCode;
    if (json['university'] is Map<String, dynamic>) {
      uniName = json['university']['name'];
      uniCode = json['university']['code'];
    }

    String? deptName;
    String? deptCode;
    if (json['department'] is Map<String, dynamic>) {
      deptName = json['department']['name'];
      deptCode = json['department']['code'];
    }

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'STUDENT',
      studentId: json['studentId'],
      universityId: json['universityId'] ?? '',
      departmentId: json['departmentId'] ?? '',
      batch: json['batch'],
      section: json['section'],
      facultyId: json['facultyId'],
      isApprovedCr: json['isApprovedCr'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      universityName: uniName ?? json['universityName'],
      universityCode: uniCode ?? json['universityCode'],
      departmentName: deptName ?? json['departmentName'],
      departmentCode: deptCode ?? json['departmentCode'],
    );
  }

  /// Serialize UserModel instance to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'studentId': studentId,
      'universityId': universityId,
      'departmentId': departmentId,
      'batch': batch,
      'section': section,
      'facultyId': facultyId,
      'isApprovedCr': isApprovedCr,
      'isEmailVerified': isEmailVerified,
      'universityName': universityName,
      'universityCode': universityCode,
      'departmentName': departmentName,
      'departmentCode': departmentCode,
    };
  }

  // Role helper getters
  bool get isStudent => role == 'STUDENT';
  bool get isCr => role == 'CR';
  bool get isFaculty => role == 'FACULTY';
  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  /// Resolves short department code (e.g. 'SWE', 'CSE') even from cached department names
  String get effectiveDepartmentCode {
    if (departmentCode != null && departmentCode!.trim().isNotEmpty) {
      return departmentCode!.trim().toUpperCase();
    }
    if (departmentName != null) {
      final lower = departmentName!.toLowerCase();
      if (lower.contains('software')) return 'SWE';
      if (lower.contains('computer')) return 'CSE';
      if (lower.contains('business') || lower.contains('bba')) return 'BBA';
      if (lower.contains('civil')) return 'CE';
      if (lower.contains('electrical') || lower.contains('eee')) return 'EEE';
    }
    return departmentId.isNotEmpty ? departmentId : 'SWE';
  }
}
