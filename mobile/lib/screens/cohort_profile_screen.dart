import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/registration_options_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class CohortProfileScreen extends StatefulWidget {
  const CohortProfileScreen({super.key});

  @override
  State<CohortProfileScreen> createState() => _CohortProfileScreenState();
}

class _CohortProfileScreenState extends State<CohortProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadRegistrationOptions();
    });
  }

  void _openEditCohortSheet(BuildContext context, dynamic user) {
    final auth = context.read<AuthProvider>();
    final options = auth.registrationOptions;

    final nameController = TextEditingController(text: user.fullName);
    final idController = TextEditingController(text: user.studentId ?? '');

    String? selectedDeptId = user.departmentId;
    String? selectedBatch = user.batch;
    String? selectedSection = user.section;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Find matching department batches across all universities
          final depts = options?.universities.expand((u) => u.departments).toList() ?? [];
          final deptObj = depts.firstWhere(
            (d) => d.id == selectedDeptId,
            orElse: () => depts.isNotEmpty
                ? depts.first
                : DepartmentOption(id: selectedDeptId ?? '', code: 'CSE', name: 'Computer Science and Engineering', batches: []),
          );

          final availableBatches = deptObj.batches.isNotEmpty
              ? deptObj.batches.map((b) => b.name).toList()
              : ['68', '67', '66', '65', '64', '63', '62', '61', '60', '59'];

          final batchObj = deptObj.batches.firstWhere(
            (b) => b.name == selectedBatch,
            orElse: () => deptObj.batches.isNotEmpty
                ? deptObj.batches.first
                : AcademicBatchOption(id: '68', name: selectedBatch ?? '68', sections: ['A', 'B', 'C', 'D', 'E']),
          );

          final availableSections = batchObj.sections.isNotEmpty
              ? batchObj.sections
              : ['A', 'B', 'C', 'D', 'E'];

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab Bar
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Update Cohort & Identity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Changing your section or batch automatically aligns your classes and room numbers.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Student ID
                  if (user.role != 'FACULTY') ...[
                    const Text('Student ID / Registration Roll', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: idController,
                      decoration: InputDecoration(
                        hintText: 'e.g. 2241081422',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Academic Batch Dropdown
                    const Text('Academic Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableBatches.contains(selectedBatch) ? selectedBatch : availableBatches.firstOrNull,
                          isExpanded: true,
                          items: availableBatches.map((b) {
                            return DropdownMenuItem(value: b, child: Text('Batch $b'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedBatch = val;
                                // Reset section if not available in new batch
                                final newBatchObj = deptObj.batches.firstWhere(
                                  (b) => b.name == val,
                                  orElse: () => AcademicBatchOption(id: val, name: val, sections: ['A']),
                                );
                                if (!newBatchObj.sections.contains(selectedSection)) {
                                  selectedSection = newBatchObj.sections.firstOrNull ?? 'A';
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section Dropdown
                    const Text('Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableSections.contains(selectedSection) ? selectedSection : availableSections.firstOrNull,
                          isExpanded: true,
                          items: availableSections.map((s) {
                            return DropdownMenuItem(value: s, child: Text('Section $s'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedSection = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final scheduleProvider = context.read<ScheduleProvider>();

                      Navigator.pop(sheetCtx);

                      final success = await auth.updateProfile(
                        fullName: nameController.text.trim(),
                        studentId: idController.text.trim(),
                        departmentId: selectedDeptId,
                        batch: selectedBatch,
                        section: selectedSection,
                      );

                      if (success && auth.user != null) {
                        // Immediately re-sync schedule provider and FCM push topics with new cohort
                        await scheduleProvider.syncWithUser(auth.user!, force: true);
                        final dept = auth.user!.departmentName ?? auth.user!.departmentId;
                        await NotificationService().syncUserCohortTopics(
                          department: dept,
                          batch: auth.user!.batch ?? '',
                          section: auth.user!.section ?? '',
                          isCr: auth.user!.isCr,
                          facultyInitials: auth.user!.facultyId,
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Cohort updated! Today\'s schedule and routine are now synchronized.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(auth.errorMessage ?? 'Failed to update cohort'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySky,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save & Synchronize Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out from UniRoom-Live?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await NotificationService().unsubscribeAll();
              if (!context.mounted) return;
              context.read<ScheduleProvider>().clearSchedules();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primarySky)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile & Cohort'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Profile Card
            _buildProfileHero(user),
            const SizedBox(height: 20),

            // Academic Cohort Overview Card
            _buildCohortCard(user),
            const SizedBox(height: 20),

            // Edit Cohort Button
            ElevatedButton.icon(
              onPressed: () => _openEditCohortSheet(context, user),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Edit Cohort (Section, Batch, Dept)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 28),

            // Notification Settings Card
            _buildNotificationCard(),
            const SizedBox(height: 24),

            // Sign Out Button
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              label: const Text('Sign Out from UniRoom-Live', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              user.isFaculty ? Icons.person_rounded : (user.isCr ? Icons.stars_rounded : Icons.school_rounded),
              color: AppColors.primarySky,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: user.isCr ? const Color(0xFFFEF3C7) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isCr ? 'CLASS REPRESENTATIVE' : (user.isFaculty ? 'FACULTY' : 'STUDENT'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: user.isCr ? const Color(0xFFD97706) : AppColors.primarySky,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Cohort Configuration',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const Divider(color: AppColors.border, height: 20),
          _buildInfoRow('University', user.universityName ?? 'Uttara University'),
          _buildInfoRow('Department', user.departmentName ?? 'CSE'),
          if (!user.isFaculty) ...[
            _buildInfoRow('Academic Batch', 'Batch ${user.batch ?? "68"}'),
            _buildInfoRow('Current Section', 'Section ${user.section ?? "A"}'),
            _buildInfoRow('Student ID', user.studentId ?? 'Not set'),
          ] else ...[
            _buildInfoRow('Faculty Initials', user.facultyId ?? 'DNS'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.iceBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSky),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: AppColors.primarySky, size: 24),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automated Routine Notifications',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Classroom reminders, teacher codes, and CR room freed alerts are automatically delivered.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
