/// SectionStudentModel
/// Represents a student enrolled in the CR's specific section cohort.
class SectionStudentModel {
  final String id;
  final String studentId;
  final String fullName;
  final String? email;
  final String? department;
  final String? batch;
  final String? section;
  final bool isCr;
  bool isPresent;

  SectionStudentModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    this.email,
    this.department,
    this.batch,
    this.section,
    this.isCr = false,
    this.isPresent = true, // Default to Present for convenient roll call
  });

  factory SectionStudentModel.fromJson(Map<String, dynamic> json) {
    return SectionStudentModel(
      id: json['id']?.toString() ?? json['studentId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Unknown Student',
      email: json['email']?.toString(),
      department: json['departmentId']?.toString() ?? json['department']?.toString(),
      batch: json['batch']?.toString(),
      section: json['section']?.toString(),
      isCr: json['role'] == 'CR' || json['isCr'] == true,
      isPresent: json['isPresent'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'fullName': fullName,
      'email': email,
      'department': department,
      'batch': batch,
      'section': section,
      'isCr': isCr,
      'isPresent': isPresent,
    };
  }

  SectionStudentModel copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? email,
    String? department,
    String? batch,
    String? section,
    bool? isCr,
    bool? isPresent,
  }) {
    return SectionStudentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      department: department ?? this.department,
      batch: batch ?? this.batch,
      section: section ?? this.section,
      isCr: isCr ?? this.isCr,
      isPresent: isPresent ?? this.isPresent,
    );
  }
}
