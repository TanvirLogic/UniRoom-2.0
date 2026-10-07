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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sheet Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySky.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.primarySky, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Post Classroom Notice',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.classroom.courseCode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Notice Title Field
                TextField(
                  controller: _noteTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notice Title',
                    hintText: 'e.g. Midterm Syllabus & Exam Date',
                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primarySky, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
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
                const SizedBox(height: 14),

                // Cohort Dropdown if multiple cohorts
                if (cohortOptions.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: targetCohort,
                    decoration: InputDecoration(
                      labelText: 'Target Cohort / Section',
                      prefixIcon: const Icon(Icons.groups_rounded, color: AppColors.primarySky, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
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
                    items: cohortOptions
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => targetCohort = val);
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Notice Content Field
                TextField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Notice Content',
                    hintText: 'Write notice details, deadlines, or room instructions...',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 56),
                      child: Icon(Icons.notes_rounded, color: AppColors.primarySky, size: 20),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
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
                const SizedBox(height: 20),

                // Post Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      Navigator.pop(sheetCtx);
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Publish Notice',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySky.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.primarySky, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Post Lecture Material',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.classroom.courseCode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _lecNumCtrl,
                        decoration: InputDecoration(
                          labelText: 'Lecture #',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _lecDateCtrl,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _lecTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lecture Topic / Title',
                    hintText: 'e.g. Design Patterns & Architecture',
                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primarySky, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (cohortOptions.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: targetCohort,
                    decoration: InputDecoration(
                      labelText: 'Assigned Cohort',
                      prefixIcon: const Icon(Icons.groups_rounded, color: AppColors.primarySky, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: cohortOptions
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => targetCohort = val);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _lecTopicsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Topics Covered & Summary',
                    hintText: 'e.g. Discussed singleton, builder, and factory patterns.',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes_rounded, color: AppColors.primarySky, size: 20),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _lecLinkCtrl,
                  decoration: InputDecoration(
                    labelText: 'Slides / Resource Link (Optional)',
                    hintText: 'e.g. https://drive.google.com/...',
                    prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primarySky, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      Navigator.pop(sheetCtx);
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Publish Lecture',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        actions: [
          if (_tabController.index == 0 && canManageNotices)
            IconButton(
              tooltip: 'New Notice',
              icon: const Icon(Icons.add_rounded),
              onPressed: _addNoteDialog,
            )
          else if (_tabController.index == 1 && canManageLectures)
            IconButton(
              tooltip: 'New Lecture',
              icon: const Icon(Icons.add_rounded),
              onPressed: _addLectureDialog,
            ),
        ],
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
      if (_notes.isEmpty) return null; // Avoid competing button on empty state
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primarySky.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: AppColors.primarySky,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: const Text(
            'New Notice',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, letterSpacing: 0.2),
          ),
          onPressed: _addNoteDialog,
        ),
      );
    } else if (_tabController.index == 1 && canManageLectures) {
      if (_lectures.isEmpty) return null; // Avoid competing button on empty state
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primarySky.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: AppColors.primarySky,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.post_add_rounded, size: 20),
          label: const Text(
            'New Lecture',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, letterSpacing: 0.2),
          ),
          onPressed: _addLectureDialog,
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySky.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    size: 32,
                    color: AppColors.primarySky,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Notices Posted Yet',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canManage
                      ? 'Broadcast syllabus updates, assignment deadlines, or exam reminders to your students.'
                      : 'Your faculty or CR will post announcements and classroom notices here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySky,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addNoteDialog,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Post Notice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySky.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Notice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primarySky)),
                      ),
                      if (cohort != null && cohort.isNotEmpty && cohort != 'All Cohorts') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(cohort, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
                        setState(() => _notes.removeAt(index));
                        _saveNotes();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (title.isNotEmpty && title != 'Class Notice') ...[
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 5),
              ],
              Text(
                note['text'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySky.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 30,
                    color: AppColors.primarySky,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Lectures Posted Yet',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canManage
                      ? 'Upload weekly lecture topics, covered modules, and slide resources for your students.'
                      : 'Your faculty will post weekly lecture summaries and slides here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySky,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addLectureDialog,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Post Lecture Material',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
