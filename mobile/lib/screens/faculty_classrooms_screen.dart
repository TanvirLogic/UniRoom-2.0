import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/classroom_course_model.dart';
import '../models/schedule_slot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import 'classroom_detail_screen.dart';
import 'free_rooms_screen.dart';

/// FacultyClassroomsScreen
/// Dedicated classroom management hub for faculty members.
/// Groups all assigned teaching slots by course, displaying all assigned
/// batches and sections together in one unified card per course.
class FacultyClassroomsScreen extends StatefulWidget {
  const FacultyClassroomsScreen({super.key});

  @override
  State<FacultyClassroomsScreen> createState() => _FacultyClassroomsScreenState();
}

class _FacultyClassroomsScreenState extends State<FacultyClassroomsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Aggregates all weekly routine slots assigned to this faculty by distinct course code
  List<ClassroomCourseModel> _buildClassrooms(List<ScheduleSlotModel> slots) {
    final map = <String, List<ScheduleSlotModel>>{};
    for (final s in slots) {
      final code = s.courseCode.trim().toUpperCase();
      if (code.isEmpty) continue;
      map.putIfAbsent(code, () => []).add(s);
    }

    final courses = <ClassroomCourseModel>[];
    for (final entry in map.entries) {
      final courseSlots = entry.value;
      // Sort slots by day of week and start time
      courseSlots.sort((a, b) {
        final dayOrder = {'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4, 'FRI': 5, 'SAT': 6, 'SUN': 7};
        final dA = dayOrder[a.dayOfWeek.toUpperCase()] ?? 8;
        final dB = dayOrder[b.dayOfWeek.toUpperCase()] ?? 8;
        if (dA != dB) return dA.compareTo(dB);
        return a.startTime.compareTo(b.startTime);
      });

      final first = courseSlots.first;
      courses.add(ClassroomCourseModel(
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

    final teacherCode = user?.facultyId ?? 'DNS';
    final dept = user?.effectiveDepartmentCode ?? 'CSE';

    final allClassrooms = _buildClassrooms(schedule.allWeeklySlots);
    final filtered = _searchQuery.trim().isEmpty
        ? allClassrooms
        : allClassrooms.where((c) {
            final q = _searchQuery.toLowerCase().trim();
            final matchesCode = c.courseCode.toLowerCase().contains(q);
            final matchesTitle = c.courseTitle.toLowerCase().contains(q);
            final matchesCohort = c.cohorts.any((ch) => ch.toLowerCase().contains(q));
            return matchesCode || matchesTitle || matchesCohort;
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Faculty Classrooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              '$dept • Faculty: $teacherCode',
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
                teacherCode: teacherCode,
                dept: dept,
                courseCount: allClassrooms.length,
                allClassrooms: allClassrooms,
              ),
              const SizedBox(height: 14),

              // 2. Search Field
              TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search course code, title, or batch/section...',
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

              // 3. Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assigned Courses (${filtered.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (schedule.isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. Classrooms List
              if (schedule.isLoading && allClassrooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primarySky)),
                )
              else if (filtered.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _buildCourseCard(filtered[index]),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String teacherCode,
    required String dept,
    required int courseCount,
    required List<ClassroomCourseModel> allClassrooms,
  }) {
    final allBatches = <String>{};
    final allSections = <String>{};
    for (final c in allClassrooms) {
      allBatches.addAll(c.batches);
      for (final cohort in c.distinctCohorts) {
        allSections.add(cohort.label);
      }
    }
    final sortedBatches = allBatches.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primarySky, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Hub • $teacherCode',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Department of $dept',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.auto_stories_rounded,
                value: '$courseCount',
                label: 'Courses',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.meeting_room_outlined,
                value: '${allSections.length}',
                label: 'Sections',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.groups_rounded,
                value: sortedBatches.isEmpty ? 'N/A' : sortedBatches.join(', '),
                label: 'Batches',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primarySky),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Course Card displaying Course Info and ALL assigned Batches & Sections together
  Widget _buildCourseCard(ClassroomCourseModel course) {
    final distinctCohorts = course.distinctCohorts;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassroomDetailScreen(classroom: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Course Code & Live/Class status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySky.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.courseCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.primarySky,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySky.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined, size: 12, color: AppColors.primarySky),
                        SizedBox(width: 4),
                        Text(
                          'Classroom',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primarySky,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Course Title
              Text(
                course.courseTitle,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              // Assigned Batches & Sections (Key requirement)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 14, color: AppColors.primarySky),
                        const SizedBox(width: 6),
                        const Text(
                          'Assigned Batches & Sections:',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (distinctCohorts.isEmpty)
                      const Text(
                        'All Sections',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: distinctCohorts.map((cohort) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primarySky,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cohort.label,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
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
              const SizedBox(height: 12),

              // Footer: Action Bar
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      const Text(
                        'Lectures',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.campaign_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      const Text(
                        'Notices',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Text(
                        'Enter Classroom',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primarySky,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primarySky),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Assigned Classrooms Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'No course routine slots matched your query or faculty initials. Check master routine or tap refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => context.read<ScheduleProvider>().loadSchedules(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh Schedules'),
            ),
          ],
        ),
      ),
    );
  }
}
