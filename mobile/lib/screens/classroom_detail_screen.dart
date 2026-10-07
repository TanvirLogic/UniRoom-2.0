import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../models/classroom_course_model.dart';
import '../models/section_student_model.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';

/// ClassroomDetailScreen
/// Dedicated virtual classroom hub for a course:
/// - Notice Board: Faculty/CR can post notices; Students have read-only view.
/// - Lectures: Faculty can post lecture outlines, topics, and slide links; Students have read-only view.
/// - Classmates / Cohort: Roster of enrolled students with CR identification.
class ClassroomDetailScreen extends StatefulWidget {
  final ClassroomCourseModel classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AttendanceService _attendanceService = AttendanceService();

  // Classmates state
  List<SectionStudentModel> _classmates = [];
  bool _isLoadingClassmates = true;
  String _classmateSearch = '';
  CourseCohort? _selectedCohort;

  // Notices state
  List<Map<String, dynamic>> _notes = [];
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _noteTitleCtrl = TextEditingController();

  // Lectures state
  List<Map<String, dynamic>> _lectures = [];
  final TextEditingController _lecNumCtrl = TextEditingController();
  final TextEditingController _lecTitleCtrl = TextEditingController();
  final TextEditingController _lecDateCtrl = TextEditingController();
  final TextEditingController _lecTopicsCtrl = TextEditingController();
  final TextEditingController _lecLinkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    final cohorts = widget.classroom.distinctCohorts;
    if (cohorts.isNotEmpty) {
      _selectedCohort = cohorts.first;
    }

    _loadClassmates();
    _loadNotes();
    _loadLectures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteCtrl.dispose();
    _noteTitleCtrl.dispose();
    _lecNumCtrl.dispose();
    _lecTitleCtrl.dispose();
    _lecDateCtrl.dispose();
    _lecTopicsCtrl.dispose();
    _lecLinkCtrl.dispose();
    super.dispose();
  }

  String get _notesStorageKey =>
      'uniroom_classroom_notes_${widget.classroom.courseCode.toUpperCase()}';

  String get _lecturesStorageKey =>
      'uniroom_classroom_lectures_${widget.classroom.courseCode.toUpperCase()}';

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        setState(() {
          _notes = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notesStorageKey, jsonEncode(_notes));
    } catch (_) {}
  }

  Future<void> _loadLectures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lecturesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        setState(() {
          _lectures = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        // Seed default initial lectures if empty
        final initial = [
          {
            'id': 'seed_1',
            'number': 'Lecture 01',
            'title': 'Course Introduction & Syllabus Overview',
            'date': 'Oct 01, 2026',
            'topics': 'Introduction to course outcomes, grading policy, recommended textbooks, and tool setup.',
            'link': 'https://drive.google.com/uniroom/slides-lec01',
            'cohort': 'All Batches',
            'createdAt': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
          },
          {
            'id': 'seed_2',
            'number': 'Lecture 02',
            'title': 'Core Fundamentals & Architecture Principles',
            'date': 'Oct 04, 2026',
            'topics': 'System analysis, domain models, modular design, and requirement breakdown.',
            'link': 'https://github.com/uniroom/lecture-resources',
            'cohort': 'All Batches',
            'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          },
        ];
        setState(() {
          _lectures = initial;
        });
        await prefs.setString(_lecturesStorageKey, jsonEncode(initial));
      }
    } catch (_) {}
  }

  Future<void> _saveLectures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lecturesStorageKey, jsonEncode(_lectures));
    } catch (_) {}
  }

  Future<void> _loadClassmates() async {
    setState(() => _isLoadingClassmates = true);
    final user = context.read<AuthProvider>().user;
    final isFaculty = user?.isFaculty == true;

    final dept = user?.effectiveDepartmentCode ?? 'CSE';
    final String batch;
    final String section;

    if (isFaculty && _selectedCohort != null) {
      batch = _selectedCohort!.batch;
      section = _selectedCohort!.section;
    } else {
      batch = user?.batch ?? (_selectedCohort?.batch ?? '61');
      section = user?.section ?? (_selectedCohort?.section ?? 'D');
    }

    try {
      final list = await _attendanceService.getSectionStudents(
        department: dept,
        batch: batch,
        section: section,
      );
      if (mounted) {
        setState(() {
          _classmates = list;
          _isLoadingClassmates = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingClassmates = false);
    }
  }

  // --- DIALOGS ---

  void _addNoteDialog() {
    _noteTitleCtrl.clear();
    _noteCtrl.clear();
    String targetCohort = 'All Cohorts';
    final cohortOptions = ['All Cohorts', ...widget.classroom.cohorts];

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Post Classroom Notice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _noteTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notice Title',
                    hintText: 'e.g. Midterm Syllabus & Date',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                if (cohortOptions.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: targetCohort,
                    decoration: InputDecoration(
                      labelText: 'Target Cohort',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: cohortOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => targetCohort = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Notice Content',
                    hintText: 'e.g. Midterm exam on Chapter 3 & 4.\nAssignment due this Sunday.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final text = _noteCtrl.text.trim();
                if (text.isNotEmpty) {
                  final title = _noteTitleCtrl.text.trim();
                  final newNote = {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': title.isNotEmpty ? title : 'Class Notice',
                    'text': text,
                    'cohort': targetCohort,
                    'createdAt': DateTime.now().toIso8601String(),
                  };
                  setState(() => _notes.insert(0, newNote));
                  _saveNotes();
                }
                Navigator.pop(dCtx);
              },
              child: const Text('Post Notice'),
            ),
          ],
        ),
      ),
    );
  }

  void _addLectureDialog() {
    final nextNum = 'Lecture ${_lectures.length + 1 < 10 ? '0' : ''}${_lectures.length + 1}';
    _lecNumCtrl.text = nextNum;
    _lecTitleCtrl.clear();
    final now = DateTime.now();
    _lecDateCtrl.text = '${_monthName(now.month)} ${now.day}, ${now.year}';
    _lecTopicsCtrl.clear();
    _lecLinkCtrl.clear();

    String targetCohort = 'All Cohorts';
    final cohortOptions = ['All Cohorts', ...widget.classroom.cohorts];

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Post Lecture & Materials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _lecNumCtrl,
                        decoration: InputDecoration(
                          labelText: 'Lecture #',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _lecDateCtrl,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lecTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lecture Topic / Title',
                    hintText: 'e.g. Design Patterns & Singleton',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                if (cohortOptions.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: targetCohort,
                    decoration: InputDecoration(
                      labelText: 'Assigned Cohort',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: cohortOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => targetCohort = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _lecTopicsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Topics Covered & Summary',
                    hintText: 'e.g. Discussed Creational patterns, singleton thread safety, code examples.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lecLinkCtrl,
                  decoration: InputDecoration(
                    labelText: 'Slides / Resource Link (Optional)',
                    hintText: 'e.g. https://drive.google.com/...',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final title = _lecTitleCtrl.text.trim();
                if (title.isNotEmpty) {
                  final newLec = {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'number': _lecNumCtrl.text.trim().isNotEmpty ? _lecNumCtrl.text.trim() : nextNum,
                    'title': title,
                    'date': _lecDateCtrl.text.trim(),
                    'topics': _lecTopicsCtrl.text.trim(),
                    'link': _lecLinkCtrl.text.trim(),
                    'cohort': targetCohort,
                    'createdAt': DateTime.now().toIso8601String(),
                  };
                  setState(() => _lectures.insert(0, newLec));
                  _saveLectures();
                }
                Navigator.pop(dCtx);
              },
              child: const Text('Post Lecture'),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return m[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isFaculty = user?.isFaculty == true;
    final isCr = user?.isCr == true;

    // Permissions:
    // Notice permission: Faculty and CR can post/delete; students read-only
    final canManageNotices = isFaculty || isCr;
    // Lecture permission: Faculty only can post/delete; students read-only
    final canManageLectures = isFaculty;

    final course = widget.classroom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(course.courseCode, style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primarySky,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primarySky,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.campaign_outlined, size: 20),
              text: 'Notices (${_notes.length})',
            ),
            Tab(
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              text: 'Lectures (${_lectures.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_alt_outlined, size: 20),
              text: 'Roster (${_classmates.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Card
          _buildHeroHeader(course),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNoticesTab(canManage: canManageNotices),
                _buildLecturesTab(canManage: canManageLectures),
                _buildClassmatesTab(isFaculty: isFaculty),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(
        canManageNotices: canManageNotices,
        canManageLectures: canManageLectures,
      ),
    );
  }

  Widget? _buildFab({
    required bool canManageNotices,
    required bool canManageLectures,
  }) {
    if (_tabController.index == 0 && canManageNotices) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primarySky,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Notice'),
        onPressed: _addNoteDialog,
      );
    } else if (_tabController.index == 1 && canManageLectures) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primarySky,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Lecture'),
        onPressed: _addLectureDialog,
      );
    }
    return null;
  }

  Widget _buildHeroHeader(ClassroomCourseModel course) {
    final distinctCohorts = course.distinctCohorts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.courseTitle,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Faculty: ${course.facultyInitials}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primarySky,
                  ),
                ),
              ),
              if (course.facultyName != null && course.facultyName!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    course.facultyName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (distinctCohorts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: distinctCohorts.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    c.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 1: NOTICES (Students are strictly read-only) ---
  Widget _buildNoticesTab({required bool canManage}) {
    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.campaign_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'No notices posted yet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                canManage
                    ? 'Post syllabus updates, exam reminders, or assignment deadlines for this classroom.'
                    : 'Your faculty or CR will post announcements and classroom notices here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              if (canManage) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySky,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _addNoteDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add First Notice'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final note = _notes[index];
        final title = note['title'] as String? ?? 'Class Notice';
        final cohort = note['cohort'] as String?;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Notice', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primarySky)),
                      ),
                      if (cohort != null && cohort.isNotEmpty && cohort != 'All Cohorts') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(cohort, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                      ],
                    ],
                  ),
                  if (canManage)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _notes.removeAt(index));
                        _saveNotes();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (title.isNotEmpty && title != 'Class Notice') ...[
                Text(
                  title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                note['text'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 2: LECTURES (Faculty can post; students read-only) ---
  Widget _buildLecturesTab({required bool canManage}) {
    if (_lectures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'No lectures posted yet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                canManage
                    ? 'Post lecture topics, covered modules, and slide resources for your students.'
                    : 'Your faculty will post weekly lecture summaries and slides here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              if (canManage) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySky,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _addLectureDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Post First Lecture'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _lectures.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final lec = _lectures[index];
        final number = lec['number'] as String? ?? 'Lecture';
        final title = lec['title'] as String? ?? '';
        final date = lec['date'] as String? ?? '';
        final topics = lec['topics'] as String? ?? '';
        final link = lec['link'] as String? ?? '';
        final cohort = lec['cohort'] as String?;

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySky.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          number,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primarySky,
                          ),
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  if (canManage)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _lectures.removeAt(index));
                        _saveLectures();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (cohort != null && cohort.isNotEmpty && cohort != 'All Cohorts') ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(cohort, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
              ],

              // Topics
              if (topics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  topics,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                ),
              ],

              // Resource Link
              if (link.isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resource link copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded, size: 14, color: AppColors.primarySky),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            link,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primarySky,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: ROSTER / CLASSMATES ---
  Widget _buildClassmatesTab({required bool isFaculty}) {
    final distinctCohorts = widget.classroom.distinctCohorts;

    return Column(
      children: [
        // Faculty Cohort Switcher (if multiple cohorts exist for this course)
        if (isFaculty && distinctCohorts.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Text('Cohort: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: distinctCohorts.map((cohort) {
                        final isSelected = _selectedCohort == cohort;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cohort.label),
                            selected: isSelected,
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? AppColors.primarySky : AppColors.textSecondary,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCohort = cohort);
                                _loadClassmates();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
          child: TextField(
            onChanged: (v) => setState(() => _classmateSearch = v),
            decoration: InputDecoration(
              hintText: 'Search student by roll or name...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),

        // Roster List
        Expanded(
          child: _isLoadingClassmates
              ? const Center(child: CircularProgressIndicator(color: AppColors.primarySky))
              : _buildClassmatesList(),
        ),
      ],
    );
  }

  Widget _buildClassmatesList() {
    final filtered = _classmateSearch.trim().isEmpty
        ? _classmates
        : _classmates.where((s) {
            final q = _classmateSearch.toLowerCase().trim();
            return s.studentId.toLowerCase().contains(q) ||
                s.fullName.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No students found in section roster.',
          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final student = filtered[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: student.isCr ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                child: Text(
                  student.studentId.length >= 2
                      ? student.studentId.substring(student.studentId.length - 2)
                      : '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: student.isCr ? AppColors.primarySky : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          student.studentId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (student.isCr) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySky.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CR',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primarySky),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.fullName,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
