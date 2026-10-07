import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/section_student_model.dart';
import '../models/attendance_record_model.dart';
import '../models/schedule_slot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/attendance_service.dart';

/// CrAttendanceScreen
/// CR-exclusive Hub for taking daily section attendance, tracking enrolled section mates,
/// and generating 1-tap plain text ready to copy-paste into personal SMS for faculty.
class CrAttendanceScreen extends StatefulWidget {
  final String? initialCourseCode;
  final String? initialCourseTitle;
  final ScheduleSlotModel? initialSlot;

  const CrAttendanceScreen({
    super.key,
    this.initialCourseCode,
    this.initialCourseTitle,
    this.initialSlot,
  });

  @override
  State<CrAttendanceScreen> createState() => _CrAttendanceScreenState();
}

class _CrAttendanceScreenState extends State<CrAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customCourseController = TextEditingController();

  List<SectionStudentModel> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Selected Date (Defaults to Today)
  DateTime _selectedDate = DateTime.now();

  // Selected Course for Attendance
  String _selectedCourseCode = '';
  String _selectedCourseTitle = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCourseCode != null && widget.initialCourseCode!.isNotEmpty) {
      _selectedCourseCode = widget.initialCourseCode!;
      _selectedCourseTitle = widget.initialCourseTitle ?? widget.initialCourseCode!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCohortAndRoster();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customCourseController.dispose();
    super.dispose();
  }

  /// Format DateTime into readable string (e.g. "02 Oct 2026")
  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    return '$day $month $year';
  }

  /// Load section cohort students
  Future<void> _loadCohortAndRoster({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().user;
    final schedule = context.read<ScheduleProvider>();

    final dept = user?.effectiveDepartmentCode ?? 'SWE';
    final batch = user?.batch ?? '68';
    final section = user?.section ?? 'B';

    // Auto-select course from today's scheduled classes if available
    final todaySlots = schedule.todaySlots;
    if (todaySlots.isNotEmpty && _selectedCourseCode.isEmpty) {
      final running = schedule.runningClass ?? todaySlots.first;
      _selectedCourseCode = running.courseCode;
      _selectedCourseTitle = running.courseTitle;
    } else if (_selectedCourseCode.isEmpty) {
      _selectedCourseCode = 'SWE-321';
      _selectedCourseTitle = 'Software Architecture';
    }

    try {
      final roster = await _attendanceService.getSectionStudents(
        department: dept,
        batch: batch,
        section: section,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _students = roster;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Toggle attendance for an individual student
  void _toggleAttendance(SectionStudentModel student) {
    HapticFeedback.selectionClick();
    setState(() {
      student.isPresent = !student.isPresent;
    });
  }

  /// Mark all students Present
  void _selectAllPresent() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final s in _filteredStudents) {
        s.isPresent = true;
      }
    });
  }

  /// Mark all students Absent
  void _clearAllAbsent() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final s in _filteredStudents) {
        s.isPresent = false;
      }
    });
  }

  /// Invert attendance selection
  void _invertSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final s in _filteredStudents) {
        s.isPresent = !s.isPresent;
      }
    });
  }

  /// Pick date (defaults to today)
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primarySky,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Filtered students based on search query
  List<SectionStudentModel> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final query = _searchQuery.toLowerCase().trim();
    return _students.where((s) {
      return s.studentId.toLowerCase().contains(query) ||
          s.fullName.toLowerCase().contains(query);
    }).toList();
  }

  int get _presentCount => _students.where((s) => s.isPresent).length;
  int get _absentCount => _students.where((s) => !s.isPresent).length;

  /// ---------------------------------------------------------------------------
  /// SAVE & SHOW SMS COPY MODAL
  /// ---------------------------------------------------------------------------
  Future<void> _saveAndShowSmsModal() async {
    final user = context.read<AuthProvider>().user;
    final dept = user?.effectiveDepartmentCode ?? 'SWE';
    final batch = user?.batch ?? '68';
    final section = user?.section ?? 'B';

    final dateFormatted = _formatDate(_selectedDate);

    // Generate formatted SMS text
    final standardText = _attendanceService.generateFacultySmsText(
      dateFormatted: dateFormatted,
      courseCode: _selectedCourseCode,
      courseTitle: _selectedCourseTitle,
      department: dept,
      batch: batch,
      section: section,
      allStudents: _students,
      compactMode: false,
    );

    // Create persistent record
    final recordId = '${_selectedDate.millisecondsSinceEpoch}_$_selectedCourseCode';
    final record = AttendanceRecordModel(
      id: recordId,
      date: _selectedDate,
      dateFormatted: dateFormatted,
      courseCode: _selectedCourseCode,
      courseTitle: _selectedCourseTitle,
      department: dept,
      batch: batch,
      section: section,
      students: _students
          .map((s) => AttendanceStudentEntry(
                studentId: s.studentId,
                fullName: s.fullName,
                isPresent: s.isPresent,
              ))
          .toList(),
      formattedSmsText: standardText,
      savedAt: DateTime.now(),
    );

    await _attendanceService.saveAttendanceRecord(record);
    HapticFeedback.mediumImpact();

    if (!mounted) return;

    // Show modal bottom sheet with SMS preview and copy button
    _showSmsOutputBottomSheet(
      standardText: standardText,
      record: record,
      dept: dept,
      batch: batch,
      section: section,
      dateFormatted: dateFormatted,
    );
  }

  /// Display BottomSheet with formatted text and 1-tap copy
  void _showSmsOutputBottomSheet({
    required String standardText,
    required AttendanceRecordModel record,
    required String dept,
    required String batch,
    required String section,
    required String dateFormatted,
  }) {
    bool useCompact = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final displayText = useCompact
              ? _attendanceService.generateFacultySmsText(
                  dateFormatted: dateFormatted,
                  courseCode: _selectedCourseCode,
                  courseTitle: _selectedCourseTitle,
                  department: dept,
                  batch: batch,
                  section: section,
                  allStudents: _students,
                  compactMode: true,
                )
              : standardText;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Success Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance Saved!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${record.presentCount} Present • ${record.absentCount} Absent • $dateFormatted',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Format Toggle (Standard vs Compact)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => useCompact = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !useCompact ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !useCompact
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Standard Format',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: !useCompact ? AppColors.primarySky : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => useCompact = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: useCompact ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: useCompact
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Compact (Short SMS)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: useCompact ? AppColors.primarySky : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Formatted Text Box
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        displayText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          height: 1.45,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Primary 1-Tap Copy Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text(
                      'Copy Text for Faculty SMS',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: displayText));
                      HapticFeedback.mediumImpact();
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF15803D),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Attendance copied to clipboard! Ready to paste into SMS.',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// HISTORY MODAL
  /// ---------------------------------------------------------------------------
  Future<void> _showHistoryBottomSheet() async {
    final records = await _attendanceService.getSavedRecords();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySky.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.primarySky, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Saved Attendance History',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'No attendance records saved yet.',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final rec = records[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySky.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rec.courseCode.isNotEmpty ? rec.courseCode : 'Class',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primarySky,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec.dateFormatted,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${rec.presentCount} / ${rec.totalCount} Present',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rec.courseTitle.isNotEmpty ? rec.courseTitle : 'Daily Routine Attendance',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primarySky,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copy SMS Text', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: rec.formattedSmsText));
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF15803D),
                                      content: Text('Copied saved record to clipboard!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                tooltip: 'Delete Record',
                                onPressed: () async {
                                  final nav = Navigator.of(sheetCtx);
                                  await _attendanceService.deleteRecord(rec.id);
                                  if (mounted) {
                                    nav.pop();
                                    _showHistoryBottomSheet();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// ADD CLASSMATE DIALOG
  /// ---------------------------------------------------------------------------
  void _showAddStudentDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppColors.primarySky, size: 24),
            SizedBox(width: 10),
            Text('Add Section Mate', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Student Roll ID',
                  hintText: 'e.g. 2241081055',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Shakib Ahmed',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySky,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (idCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              final nav = Navigator.of(dCtx);
              final user = context.read<AuthProvider>().user;
              final dept = user?.effectiveDepartmentCode ?? 'SWE';
              final batch = user?.batch ?? '68';
              final section = user?.section ?? 'B';

              final newStudent = await _attendanceService.addStudent(
                studentId: idCtrl.text.trim(),
                fullName: nameCtrl.text.trim(),
                department: dept,
                batch: batch,
                section: section,
              );

              if (mounted) {
                setState(() {
                  _students.removeWhere((s) => s.studentId == newStudent.studentId);
                  _students.add(newStudent);
                  _students.sort((a, b) => a.studentId.compareTo(b.studentId));
                });
                nav.pop();
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// BUILD MAIN UI
  /// ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final schedule = context.watch<ScheduleProvider>();

    final dept = user?.effectiveDepartmentCode ?? 'SWE';
    final batch = user?.batch ?? '68';
    final section = user?.section ?? 'B';

    final filtered = _filteredStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.initialCourseCode != null ? '${widget.initialCourseCode} Attendance' : 'Section Attendance'),
        actions: [
          IconButton(
            tooltip: 'Attendance History',
            icon: const Icon(Icons.history_rounded),
            onPressed: _showHistoryBottomSheet,
          ),
          IconButton(
            tooltip: 'Add Classmate',
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _showAddStudentDialog,
          ),
          IconButton(
            tooltip: 'Refresh Roster',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadCohortAndRoster(forceRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primarySky))
          : Column(
              children: [
                // 1. Cohort & Date / Course Info Header
                _buildCohortHeader(dept: dept, batch: batch, section: section, schedule: schedule),

                // 2. Search & Filter Bar
                _buildSearchAndActionsBar(),

                // 3. Students List (Tappable Cards with Pull-to-Refresh)
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primarySky,
                    onRefresh: () => _loadCohortAndRoster(forceRefresh: true),
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_outline_rounded, size: 52, color: AppColors.textSecondary),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No students found matching "$_searchQuery"'
                                          : 'No registered students in $dept Batch $batch ($section) yet.',
                                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primarySky,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _loadCohortAndRoster(forceRefresh: true),
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: const Text('Refresh from Cloud'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 96),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final student = filtered[index];
                              return _buildStudentCard(student, index + 1);
                            },
                          ),
                  ),
                ),
              ],
            ),
      // 4. Bottom Sticky Action Bar (Save & Copy SMS)
      bottomSheet: _buildBottomActionBar(),
    );
  }

  /// Cohort Header Card
  Widget _buildCohortHeader({
    required String dept,
    required String batch,
    required String section,
    required ScheduleProvider schedule,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primarySky.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$dept • Batch $batch ($section)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primarySky,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tappable Date Picker Chip
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Course Selector Row
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCourseCode.isNotEmpty
                      ? '$_selectedCourseCode - $_selectedCourseTitle'
                      : 'General Routine Class',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => _showCourseSelectorDialog(schedule),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primarySky,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Change Course Dialog
  void _showCourseSelectorDialog(ScheduleProvider schedule) {
    final todaySlots = schedule.todaySlots;
    final ctrl = TextEditingController(text: _selectedCourseCode);

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Course for Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (todaySlots.isNotEmpty) ...[
                const Text('Today\'s Classes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ...todaySlots.map((slot) => ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: const Icon(Icons.school_outlined, color: AppColors.primarySky, size: 20),
                      title: Text(slot.courseCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text(slot.courseTitle, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        setState(() {
                          _selectedCourseCode = slot.courseCode;
                          _selectedCourseTitle = slot.courseTitle;
                        });
                        Navigator.pop(dCtx);
                      },
                    )),
                const Divider(),
              ],
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Custom Course Code',
                  hintText: 'e.g. SWE-321',
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primarySky, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _selectedCourseCode = ctrl.text.trim().toUpperCase();
                  _selectedCourseTitle = '';
                });
              }
              Navigator.pop(dCtx);
            },
            child: const Text('Set Course'),
          ),
        ],
      ),
    );
  }

  /// Search & Quick Actions Bar
  Widget _buildSearchAndActionsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by student roll ID or name...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              filled: true,
              fillColor: AppColors.surface,
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
          const SizedBox(height: 8),

          // Action Chips & Live Stats
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_presentCount Present',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_absentCount Absent',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Buttons
                GestureDetector(
                  onTap: _selectAllPresent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('All Present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _clearAllAbsent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('Clear All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _invertSelection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('Invert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Student Card (Tappable)
  Widget _buildStudentCard(SectionStudentModel student, int serial) {
    final isPresent = student.isPresent;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPresent ? const Color(0xFF86EFAC) : AppColors.border,
          width: isPresent ? 1.5 : 1,
        ),
      ),
      color: isPresent ? const Color(0xFFF0FDF4) : AppColors.surface,
      child: InkWell(
        onTap: () => _toggleAttendance(student),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar with Roll Suffix or Index
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPresent ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    student.studentId.length >= 3
                        ? student.studentId.substring(student.studentId.length - 2)
                        : '$serial',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isPresent ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Student Roll ID & Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          student.studentId,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isPresent ? const Color(0xFF15803D) : AppColors.textPrimary,
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
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primarySky,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.fullName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPresent ? const Color(0xFF1E293B) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Toggle Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPresent ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent ? Icons.check_rounded : Icons.close_rounded,
                      size: 16,
                      color: isPresent ? Colors.white : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPresent ? 'Present' : 'Absent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPresent ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom Persistent Action Bar
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Summary count
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Session',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$_presentCount / ${_students.length} Present',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(width: MediaQuery.sizeOf(context).width < 380 ? 10 : 16),

            // Save & Copy SMS Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySky,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                    Icons.send_to_mobile_rounded,
                    size: MediaQuery.sizeOf(context).width < 380 ? 17 : 20,
                  ),
                  label: Text(
                    MediaQuery.sizeOf(context).width < 380 ? 'Copy SMS' : 'Save & Copy SMS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: MediaQuery.sizeOf(context).width < 380 ? 13 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _students.isEmpty ? null : _saveAndShowSmsModal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
