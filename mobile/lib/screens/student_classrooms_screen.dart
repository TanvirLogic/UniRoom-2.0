import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/schedule_slot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import 'classroom_detail_screen.dart';
import 'free_rooms_screen.dart';

/// ClassroomCourse
/// Helper structure aggregating all weekly slots belonging to a distinct course
class ClassroomCourse {
  final String courseCode;
  final String courseTitle;
  final String facultyInitials;
  final String? facultyName;
  final List<ScheduleSlotModel> weeklySlots;

  ClassroomCourse({
    required this.courseCode,
    required this.courseTitle,
    required this.facultyInitials,
    this.facultyName,
    required this.weeklySlots,
  });

  int get classesPerWeek => weeklySlots.length;

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

/// StudentClassroomsScreen
/// Automatically builds virtual digital classrooms for students based on their
/// section's master timetable/routine.
class StudentClassroomsScreen extends StatefulWidget {
  const StudentClassroomsScreen({super.key});

  @override
  State<StudentClassroomsScreen> createState() => _StudentClassroomsScreenState();
}

class _StudentClassroomsScreenState extends State<StudentClassroomsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Group all weekly routine slots by distinct course code
  List<ClassroomCourse> _buildClassrooms(List<ScheduleSlotModel> slots) {
    final map = <String, List<ScheduleSlotModel>>{};
    for (final s in slots) {
      final code = s.courseCode.trim().toUpperCase();
      map.putIfAbsent(code, () => []).add(s);
    }

    final courses = <ClassroomCourse>[];
    for (final entry in map.entries) {
      final courseSlots = entry.value;
      // Sort slots by Day and Start Time
      courseSlots.sort((a, b) {
        final dayOrder = {'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4, 'FRI': 5, 'SAT': 6, 'SUN': 7};
        final dA = dayOrder[a.dayOfWeek.toUpperCase()] ?? 8;
        final dB = dayOrder[b.dayOfWeek.toUpperCase()] ?? 8;
        if (dA != dB) return dA.compareTo(dB);
        return a.startTime.compareTo(b.startTime);
      });

      final first = courseSlots.first;
      courses.add(ClassroomCourse(
        courseCode: entry.key,
        courseTitle: first.courseTitle,
        facultyInitials: first.facultyInitials,
        facultyName: first.facultyName,
        weeklySlots: courseSlots,
      ));
    }

    // Sort alphabetically by course code
    courses.sort((a, b) => a.courseCode.compareTo(b.courseCode));
    return courses;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final user = auth.user;

    final dept = user?.effectiveDepartmentCode ?? 'CSE';
    final batch = user?.batch ?? '61';
    final section = user?.section ?? 'D';

    final allClassrooms = _buildClassrooms(schedule.allWeeklySlots);
    final filtered = _searchQuery.trim().isEmpty
        ? allClassrooms
        : allClassrooms.where((c) {
            final q = _searchQuery.toLowerCase().trim();
            return c.courseCode.toLowerCase().contains(q) ||
                c.courseTitle.toLowerCase().contains(q) ||
                c.facultyInitials.toLowerCase().contains(q) ||
                (c.facultyName?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Classrooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              '$dept • Batch $batch ($section)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Campus Free Rooms',
            icon: const Icon(Icons.meeting_room_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FreeRoomsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh Routine',
            icon: Icon(
              Icons.refresh_rounded,
              color: schedule.isLoading ? AppColors.primarySky : AppColors.textSecondary,
            ),
            onPressed: schedule.isLoading ? null : () => schedule.loadSchedules(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primarySky,
        onRefresh: () => schedule.loadSchedules(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overview Banner
              _buildOverviewCard(
                dept: dept,
                batch: batch,
                section: section,
                courseCount: allClassrooms.length,
                totalClasses: schedule.allWeeklySlots.length,
              ),
              const SizedBox(height: 14),

              // 2. Search Field
              TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search course code, title, or teacher...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primarySky, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Classrooms List
              if (schedule.isLoading && allClassrooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primarySky)),
                )
              else if (filtered.isEmpty)
                _buildEmptyState(schedule.isLoading)
              else
                ...filtered.map((classroom) => _buildClassroomCard(context, classroom, schedule.currentTime)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String dept,
    required String batch,
    required String section,
    required int courseCount,
    required int totalClasses,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: AppColors.primarySky, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automated Section Classrooms',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Synced with $dept Batch $batch ($section) timetable',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySky.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$courseCount Courses',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primarySky,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(BuildContext context, ClassroomCourse course, DateTime now) {
    final running = course.isRunningNow(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: running ? AppColors.success : AppColors.border,
          width: running ? 1.6 : 1,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassroomDetailScreen(classroom: course),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Pill + Teacher Initials + Status Chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.courseCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primarySky,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        course.facultyInitials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (running)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: AppColors.success, size: 8),
                            SizedBox(width: 5),
                            Text(
                              'Live Now',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        '${course.classesPerWeek} classes/week',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Course Full Title
                Text(
                  course.courseTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Teacher Full Name if present
                if (course.facultyName != null && course.facultyName!.isNotEmpty) ...[
                  Text(
                    'Instructor: ${course.facultyName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                const Divider(height: 16),

                // Weekly slots summary preview pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: course.weeklySlots.map((slot) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slot.dayOfWeek,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primarySky,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${slot.startTime} • Rm ${slot.roomNumber ?? "TBA"}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLoading) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No classrooms matching "$_searchQuery"'
                  : 'No classrooms found in section timetable.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Classrooms are automatically built once your section schedule is assigned.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
