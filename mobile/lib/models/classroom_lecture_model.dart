class ClassroomLectureModel {
  final String id;
  final String courseCode;
  final String lectureNumber;
  final String title;
  final String date;
  final String topics;
  final String link;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String department;
  final String? batch;
  final String? section;
  final String? targetCohort;
  final DateTime createdAt;

  ClassroomLectureModel({
    required this.id,
    required this.courseCode,
    required this.lectureNumber,
    required this.title,
    required this.date,
    required this.topics,
    required this.link,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.department,
    this.batch,
    this.section,
    this.targetCohort,
    required this.createdAt,
  });

  factory ClassroomLectureModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return ClassroomLectureModel(
      id: json['id']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      lectureNumber: json['lectureNumber']?.toString() ?? (json['number']?.toString() ?? 'Lecture'),
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      topics: json['topics']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? (json['author']?['id']?.toString() ?? ''),
      authorName: json['authorName']?.toString() ?? (json['author']?['fullName']?.toString() ?? 'Faculty'),
      authorRole: json['authorRole']?.toString() ?? (json['author']?['role']?.toString() ?? 'FACULTY'),
      department: json['department']?.toString() ?? 'CSE',
      batch: json['batch']?.toString(),
      section: json['section']?.toString(),
      targetCohort: json['targetCohort']?.toString() ?? json['cohort']?.toString() ?? 'All Sections',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseCode': courseCode,
      'lectureNumber': lectureNumber,
      'title': title,
      'date': date,
      'topics': topics,
      'link': link,
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
