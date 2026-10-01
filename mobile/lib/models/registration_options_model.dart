/// Academic Batch Option Model
/// Holds the list of academic batches and sections per department.
/// e.g. Batch 68 with sections A, B, C.
class AcademicBatchOption {
  final String id;
  final String name; // e.g. "68" or "Spring-24"
  final List<String> sections; // e.g. ["A", "B", "C"]

  AcademicBatchOption({
    required this.id,
    required this.name,
    required this.sections,
  });

  factory AcademicBatchOption.fromJson(Map<String, dynamic> json) {
    return AcademicBatchOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sections': sections,
    };
  }
}

/// Department Option Model
/// Holds department ID, code, name, and its corresponding batches.
class DepartmentOption {
  final String id;
  final String code; // e.g. "CSE"
  final String name; // e.g. "Computer Science & Engineering"
  final List<AcademicBatchOption> batches;

  DepartmentOption({
    required this.id,
    required this.code,
    required this.name,
    required this.batches,
  });

  factory DepartmentOption.fromJson(Map<String, dynamic> json) {
    return DepartmentOption(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      batches: (json['batches'] as List<dynamic>?)
              ?.map((e) => AcademicBatchOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'batches': batches.map((b) => b.toJson()).toList(),
    };
  }
}

/// University Option Model
/// Holds university information and its affiliated departments.
class UniversityOption {
  final String id;
  final String code; // e.g. "UU"
  final String name; // e.g. "Uttara University"
  final String domain; // e.g. "uttara.edu.bd"
  final List<DepartmentOption> departments;

  UniversityOption({
    required this.id,
    required this.code,
    required this.name,
    required this.domain,
    required this.departments,
  });

  factory UniversityOption.fromJson(Map<String, dynamic> json) {
    return UniversityOption(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      domain: json['domain'] ?? '',
      departments: (json['departments'] as List<dynamic>?)
              ?.map((e) => DepartmentOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'domain': domain,
      'departments': departments.map((d) => d.toJson()).toList(),
    };
  }
}

/// Registration Options Root Model
/// Parses the hierarchical response from GET /api/v1/meta/registration-options.
class RegistrationOptionsModel {
  final List<UniversityOption> universities;

  RegistrationOptionsModel({
    required this.universities,
  });

  factory RegistrationOptionsModel.fromJson(Map<String, dynamic> json) {
    final list = json['universities'] as List<dynamic>? ?? [];
    return RegistrationOptionsModel(
      universities: list
          .map((e) => UniversityOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Offline / Loading fallback data
  factory RegistrationOptionsModel.fallback() {
    return RegistrationOptionsModel(
      universities: [
        UniversityOption(
          id: 'UU',
          code: 'UU',
          name: 'Uttara University',
          domain: 'uttara.edu.bd',
          departments: [
            DepartmentOption(
              id: 'CSE',
              code: 'CSE',
              name: 'Computer Science & Engineering',
              batches: [
                AcademicBatchOption(id: 'b-cse-68', name: '68', sections: ['A', 'B', 'C']),
                AcademicBatchOption(id: 'b-cse-67', name: '67', sections: ['A', 'B']),
                AcademicBatchOption(id: 'b-cse-66', name: '66', sections: ['A', 'B']),
                AcademicBatchOption(id: 'b-cse-65', name: '65', sections: ['A', 'B']),
              ],
            ),
            DepartmentOption(
              id: 'EEE',
              code: 'EEE',
              name: 'Electrical & Electronic Engineering',
              batches: [
                AcademicBatchOption(id: 'b-eee-68', name: '68', sections: ['A', 'B']),
                AcademicBatchOption(id: 'b-eee-67', name: '67', sections: ['A']),
              ],
            ),
            DepartmentOption(
              id: 'BBA',
              code: 'BBA',
              name: 'Bachelor of Business Administration',
              batches: [
                AcademicBatchOption(id: 'b-bba-68', name: '68', sections: ['A', 'B']),
                AcademicBatchOption(id: 'b-bba-67', name: '67', sections: ['A']),
              ],
            ),
            DepartmentOption(
              id: 'ENGLISH',
              code: 'ENGLISH',
              name: 'Department of English',
              batches: [
                AcademicBatchOption(id: 'b-eng-68', name: '68', sections: ['A']),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
