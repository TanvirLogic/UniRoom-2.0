import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/classroom_course_model.dart';
import '../models/classroom_notice_model.dart';
import '../models/classroom_lecture_model.dart';
import '../models/section_student_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/attendance_service.dart';
import '../services/classroom_service.dart';

/// ClassroomDetailScreen
/// Dedicated virtual classroom hub for a course:
/// - Notice Board: Faculty/CR can post notices; Students have read-only view.
/// - Lectures: Faculty can post lecture outlines, topics, and slide links; Students have read-only view.
/// - Classmates / Section: List of enrolled students with CR identification.
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
  final ClassroomService _classroomService = ClassroomService();

  // Classmates state
  List<SectionStudentModel> _classmates = [];
  bool _isLoadingClassmates = true;
  String _classmateSearch = '';
  CourseCohort? _selectedCohort;

  // Notices state
  List<ClassroomNoticeModel> _notices = [];
  bool _isLoadingNotices = false;
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _noteTitleCtrl = TextEditingController();

  // Lectures state
  List<ClassroomLectureModel> _lectures = [];
  bool _isLoadingLectures = false;
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

  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() => _isLoadingNotices = true);
    try {
      final user = context.read<AuthProvider>().user;
      final dept = user?.effectiveDepartmentCode;
      final batch = user?.batch;
      final section = user?.section;

      final list = await _classroomService.fetchNotices(
        courseCode: widget.classroom.courseCode,
        department: dept,
        batch: batch,
        section: section,
      );

      if (mounted) {
        setState(() {
          _notices = list;
          _isLoadingNotices = false;
        });

        // Sync to in-app NotificationProvider so they appear in notification tray & update bell badge
        try {
          context.read<NotificationProvider>().syncClassroomNotices(list);
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingNotices = false);
    }
  }

  Future<void> _deleteNoticeDialog(ClassroomNoticeModel notice, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text('Are you sure you want to delete "${notice.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await _classroomService.deleteNotice(notice.id, widget.classroom.courseCode);
        if (success && mounted) {
          setState(() => _notices.removeAt(index));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notice deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete notice: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadLectures() async {
    if (!mounted) return;
    setState(() => _isLoadingLectures = true);
    try {
      final user = context.read<AuthProvider>().user;
      final dept = user?.effectiveDepartmentCode;
      final batch = user?.batch;
      final section = user?.section;

      final list = await _classroomService.fetchLectures(
        courseCode: widget.classroom.courseCode,
        department: dept,
        batch: batch,
        section: section,
      );

      if (mounted) {
        setState(() {
          _lectures = list;
          _isLoadingLectures = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLectures = false);
    }
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
        forceRefresh: true,
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
    String targetCohort = 'All Sections';
    final cohortOptions = ['All Sections', ...widget.classroom.cohorts];
    bool isSubmitting = false;

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

                // Section Dropdown if multiple sections exist
                if (cohortOptions.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: targetCohort,
                    decoration: InputDecoration(
                      labelText: 'Target Batch & Section',
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
                    onChanged: isSubmitting
                        ? null
                        : (val) {
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final text = _noteCtrl.text.trim();
                            if (text.isEmpty) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                const SnackBar(content: Text('Please enter notice content')),
                              );
                              return;
                            }

                            setDialogState(() => isSubmitting = true);

                            final title = _noteTitleCtrl.text.trim();
                            final user = context.read<AuthProvider>().user;
                            final dept = user?.effectiveDepartmentCode ?? 'CSE';

                            String? targetBatch;
                            String? targetSection;

                            if (targetCohort != 'All Sections' && targetCohort != 'All Cohorts') {
                              for (final c in widget.classroom.distinctCohorts) {
                                if (c.label == targetCohort) {
                                  targetBatch = c.batch;
                                  targetSection = c.section;
                                  break;
                                }
                              }
                            }

                            try {
                              final created = await _classroomService.postNotice(
                                courseCode: widget.classroom.courseCode,
                                title: title.isNotEmpty ? title : 'Class Notice',
                                content: text,
                                targetCohort: targetCohort,
                                department: dept,
                                batch: targetBatch,
                                section: targetSection,
                              );

                              if (mounted) {
                                setState(() {
                                  _notices.insert(0, created);
                                });
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Notice published & broadcasted to students!',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );

                                try {
                                  if (mounted) {
                                    context.read<NotificationProvider>().syncClassroomNotices([created]);
                                  }
                                } catch (_) {}
                              }
                            } catch (err) {
                              if (sheetCtx.mounted) {
                                setDialogState(() => isSubmitting = false);
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to publish notice: $err'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Publish Notice',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                            ],
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

    String targetCohort = 'All Sections';
    final cohortOptions = ['All Sections', ...widget.classroom.cohorts];
    bool isSubmitting = false;

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
                      labelText: 'Assigned Section',
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
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = _lecTitleCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                const SnackBar(content: Text('Please enter lecture topic / title')),
                              );
                              return;
                            }

                            setDialogState(() => isSubmitting = true);

                            final user = context.read<AuthProvider>().user;
                            final dept = user?.effectiveDepartmentCode ?? 'CSE';

                            String? targetBatch;
                            String? targetSection;
                            if (targetCohort != 'All Sections' && targetCohort != 'All Cohorts') {
                              for (final c in widget.classroom.distinctCohorts) {
                                if (c.label == targetCohort) {
                                  targetBatch = c.batch;
                                  targetSection = c.section;
                                  break;
                                }
                              }
                            }

                            try {
                              final created = await _classroomService.postLecture(
                                courseCode: widget.classroom.courseCode,
                                lectureNumber: _lecNumCtrl.text.trim().isNotEmpty
                                    ? _lecNumCtrl.text.trim()
                                    : nextNum,
                                title: title,
                                date: _lecDateCtrl.text.trim(),
                                topics: _lecTopicsCtrl.text.trim(),
                                link: _lecLinkCtrl.text.trim(),
                                targetCohort: targetCohort,
                                department: dept,
                                batch: targetBatch,
                                section: targetSection,
                              );

                              if (mounted) {
                                setState(() {
                                  _lectures.removeWhere((l) => l.id == created.id);
                                  _lectures.insert(0, created);
                                });
                              }

                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lecture material published & broadcasted successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              if (sheetCtx.mounted) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      isSubmitting ? 'Publishing...' : 'Publish Lecture',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
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

  String _formatNoticeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute $ampm';
    }
    final m = _monthName(dt.month);
    return '$m ${dt.day}, ${dt.year}';
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
              text: 'Notices (${_notices.length})',
            ),
            Tab(
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              text: 'Lectures (${_lectures.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_alt_outlined, size: 20),
              text: 'Students (${_classmates.length})',
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
                _buildNoticesTab(
                  canManage: canManageNotices,
                  isFaculty: isFaculty,
                  isCr: isCr,
                  userId: user?.id,
                ),
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
      if (_notices.isEmpty) return null; // Avoid competing button on empty state
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
  Widget _buildNoticesTab({
    required bool canManage,
    required bool isFaculty,
    required bool isCr,
    required String? userId,
  }) {
    if (_isLoadingNotices && _notices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primarySky),
      );
    }

    if (_notices.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotes,
        color: AppColors.primarySky,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.12,
            ),
            Center(
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
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      color: AppColors.primarySky,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _notices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final notice = _notices[index];
          final title = notice.title;
          final cohort = notice.targetCohort;
          final canDeleteNotice = isFaculty || (isCr && notice.authorId == userId);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
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
                // Top Tag & Action Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySky.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Notice',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primarySky),
                      ),
                    ),
                    if (cohort != null && cohort.isNotEmpty && cohort != 'All Cohorts' && cohort != 'All Sections') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          cohort,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (canDeleteNotice)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete Notice',
                        onPressed: () => _deleteNoticeDialog(notice, index),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Author & Date Row
                Row(
                  children: [
                    Icon(
                      notice.authorRole == 'FACULTY' ? Icons.school_rounded : Icons.person_pin_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notice.authorName.isNotEmpty ? notice.authorName : 'Faculty',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (notice.authorRole.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (notice.authorRole == 'FACULTY' ? AppColors.primarySky : AppColors.success).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notice.authorRole == 'FACULTY' ? 'Faculty' : 'CR',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: notice.authorRole == 'FACULTY' ? AppColors.primarySky : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatNoticeDate(notice.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                if (title.isNotEmpty && title != 'Class Notice') ...[
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                ],

                // Content Body
                SelectableText(
                  notice.content,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.48),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- TAB 2: LECTURES (Faculty can post; students read-only) ---
  Widget _buildLecturesTab({required bool canManage}) {
    if (_isLoadingLectures && _lectures.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primarySky));
    }

    if (_lectures.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLectures,
        color: AppColors.primarySky,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLectures,
      color: AppColors.primarySky,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _lectures.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final lec = _lectures[index];
          final number = lec.lectureNumber;
          final title = lec.title;
          final date = lec.date;
          final topics = lec.topics;
          final link = lec.link;
          final cohort = lec.targetCohort;

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
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: const Text('Delete Lecture Material?'),
                              content: Text('Are you sure you want to remove "$number: $title"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            try {
                              await _classroomService.deleteLecture(lec.id, widget.classroom.courseCode);
                              if (mounted) {
                                setState(() => _lectures.removeWhere((l) => l.id == lec.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Lecture material deleted')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
                                );
                              }
                            }
                          }
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
                if (cohort != null && cohort.isNotEmpty && cohort != 'All Cohorts' && cohort != 'All Sections') ...[
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
      ),
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
                const Text('Section: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
          'No students found in this section.',
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
