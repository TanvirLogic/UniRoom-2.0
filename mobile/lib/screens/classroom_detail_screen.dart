import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../models/section_student_model.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';
import 'student_classrooms_screen.dart';

/// ClassroomDetailScreen
/// Dedicated virtual classroom hub for a course:
/// - Course notice board / notes at the top
/// - Enrolled section classmates & Class Representatives
class ClassroomDetailScreen extends StatefulWidget {
  final ClassroomCourse classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AttendanceService _attendanceService = AttendanceService();

  List<SectionStudentModel> _classmates = [];
  bool _isLoadingClassmates = true;
  String _classmateSearch = '';

  List<Map<String, dynamic>> _notes = [];
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadClassmates();
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _notesStorageKey =>
      'uniroom_classroom_notes_${widget.classroom.courseCode.toUpperCase()}';

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

  Future<void> _loadClassmates() async {
    setState(() => _isLoadingClassmates = true);
    final user = context.read<AuthProvider>().user;
    final dept = user?.effectiveDepartmentCode ?? 'CSE';
    final batch = user?.batch ?? '61';
    final section = user?.section ?? 'D';

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

  void _addNoteDialog() {
    _noteCtrl.clear();
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Classroom Notice / Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: _noteCtrl,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Midterm exam on Chapter 3 & 4.\nAssignment due this Sunday.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                final newNote = {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'text': text,
                  'createdAt': DateTime.now().toIso8601String(),
                };
                setState(() => _notes.insert(0, newNote));
                _saveNotes();
              }
              Navigator.pop(dCtx);
            },
            child: const Text('Post Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: [
            Tab(
              icon: const Icon(Icons.campaign_outlined, size: 20),
              text: 'Notice Board (${_notes.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_alt_outlined, size: 20),
              text: 'Classmates (${_classmates.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Card
          _buildHeroHeader(course),

          // Tab View: Notice Board first, then Classmates
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNoticesTab(),
                _buildClassmatesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primarySky,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Notice'),
              onPressed: _addNoteDialog,
            )
          : null,
    );
  }

  Widget _buildHeroHeader(ClassroomCourse course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              fontSize: 17,
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
        ],
      ),
    );
  }

  Widget _buildClassmatesTab() {
    if (_isLoadingClassmates) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primarySky));
    }

    final filtered = _classmateSearch.trim().isEmpty
        ? _classmates
        : _classmates.where((s) {
            final q = _classmateSearch.toLowerCase().trim();
            return s.studentId.toLowerCase().contains(q) ||
                s.fullName.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
          child: TextField(
            onChanged: (v) => setState(() => _classmateSearch = v),
            decoration: InputDecoration(
              hintText: 'Search classmate by roll or name...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No classmates found in section roster.',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                )
              : ListView.separated(
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
                ),
        ),
      ],
    );
  }

  Widget _buildNoticesTab() {
    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sticky_note_2_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'No notes or notices yet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add reminders, assignment deadlines, or syllabus updates for this classroom.',
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
                onPressed: _addNoteDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add First Notice'),
              ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Course Notice', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primarySky)),
                  ),
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
              Text(
                note['text'] ?? '',
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }
}
