class ClassroomNoticeModel {
  final String id;
  final String courseCode;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String department;
  final String? batch;
  final String? section;
  final String? targetCohort;
  final DateTime createdAt;

  ClassroomNoticeModel({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.department,
    this.batch,
    this.section,
    this.targetCohort,
    required this.createdAt,
  });

  factory ClassroomNoticeModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return ClassroomNoticeModel(
      id: json['id']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Class Notice',
      content: json['content']?.toString() ?? (json['text']?.toString() ?? ''),
      authorId: json['authorId']?.toString() ?? (json['author']?['id']?.toString() ?? ''),
      authorName: json['authorName']?.toString() ?? (json['author']?['fullName']?.toString() ?? 'Faculty'),
      authorRole: json['authorRole']?.toString() ?? (json['author']?['role']?.toString() ?? 'FACULTY'),
      department: json['department']?.toString() ?? 'CSE',
      batch: json['batch']?.toString(),
      section: json['section']?.toString(),
      targetCohort: json['targetCohort']?.toString() ?? json['cohort']?.toString() ?? 'All Cohorts',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseCode': courseCode,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'department': department,
      'batch': batch,
      'section': section,
      'targetCohort': targetCohort,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
