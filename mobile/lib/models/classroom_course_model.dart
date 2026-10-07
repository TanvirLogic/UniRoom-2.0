import 'schedule_slot_model.dart';

/// CourseCohort
/// Represents a batch and section pairing for a course.
class CourseCohort {
  final String batch;
  final String section;

  const CourseCohort({required this.batch, required this.section});

  String get label => section.isNotEmpty ? 'Batch $batch ($section)' : 'Batch $batch';
  String get fullLabel => section.isNotEmpty ? 'Batch $batch • Section $section' : 'Batch $batch';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseCohort &&
          runtimeType == other.runtimeType &&
          batch == other.batch &&
          section == other.section;

  @override
  int get hashCode => batch.hashCode ^ section.hashCode;
}

/// ClassroomCourseModel
/// Aggregates all weekly routine slots belonging to a distinct course,
/// across batches and sections.
class ClassroomCourseModel {
  final String courseCode;
  final String courseTitle;
  final String facultyInitials;
  final String? facultyName;
  final List<ScheduleSlotModel> weeklySlots;

  ClassroomCourseModel({
    required this.courseCode,
    required this.courseTitle,
    required this.facultyInitials,
    this.facultyName,
    required this.weeklySlots,
  });

  int get classesPerWeek => weeklySlots.length;

  /// Returns distinct cohorts taught in this course e.g. [CourseCohort(batch: '61', section: 'D')]
  List<CourseCohort> get distinctCohorts {
    final seen = <String>{};
    final list = <CourseCohort>[];
    for (final s in weeklySlots) {
      final b = s.batch.trim();
      final sec = s.section.trim();
      if (b.isNotEmpty || sec.isNotEmpty) {
        final key = '$b:$sec';
        if (!seen.contains(key)) {
          seen.add(key);
          list.add(CourseCohort(batch: b, section: sec));
        }
      }
    }
    list.sort((a, b) {
      final cmp = a.batch.compareTo(b.batch);
      if (cmp != 0) return cmp;
      return a.section.compareTo(b.section);
    });
    return list;
  }

  /// Returns distinct cohort labels e.g. ["Batch 61 (D)", "Batch 68 (A)"]
  List<String> get cohorts => distinctCohorts.map((c) => c.label).toList();

  /// Returns distinct batches e.g. ["61", "68"]
  List<String> get batches {
    final set = <String>{};
    for (final s in weeklySlots) {
      if (s.batch.trim().isNotEmpty) set.add(s.batch.trim());
    }
    return set.toList()..sort();
  }

  /// Returns distinct sections e.g. ["A", "D"]
  List<String> get sections {
    final set = <String>{};
    for (final s in weeklySlots) {
      if (s.section.trim().isNotEmpty) set.add(s.section.trim());
    }
    return set.toList()..sort();
  }

  /// Check if this course has a lecture active right now
  bool isRunningNow(DateTime now) {
    return weeklySlots.any((s) => s.getTimingState(now) == SlotTimingState.runningNow);
  }

  /// Get the slot running right now
  ScheduleSlotModel? get runningSlot {
    final now = DateTime.now();
    for (final s in weeklySlots) {
      if (s.getTimingState(now) == SlotTimingState.runningNow) return s;
    }
    return null;
  }
}

/// Alias for backwards compatibility
typedef ClassroomCourse = ClassroomCourseModel;
