import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/schedule_slot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/schedule_service.dart';

class FacultyScheduleScreen extends StatefulWidget {
  const FacultyScheduleScreen({super.key});

  @override
  State<FacultyScheduleScreen> createState() => _FacultyScheduleScreenState();
}

class _FacultyScheduleScreenState extends State<FacultyScheduleScreen> {
  final List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  String _selectedDay = ScheduleService.getDayOfWeekString(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ScheduleProvider>().syncWithUser(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final user = auth.user;

    final teacherCode = user?.facultyId ?? 'DNS';
    final allSlots = schedule.allWeeklySlots;
    final daySlots = allSlots.where((s) => s.dayOfWeek == _selectedDay).toList();
    daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    final running = schedule.runningClass;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Faculty Teaching Hub'),
        actions: [
          IconButton(
            tooltip: 'Refresh Schedule',
            icon: Icon(
              Icons.refresh_rounded,
              color: schedule.isLoading ? AppColors.primarySky : AppColors.textSecondary,
            ),
            onPressed: schedule.isLoading ? null : () => schedule.loadSchedules(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Teacher Profile Card
            _buildTeacherCard(user, teacherCode, allSlots.length),
            const SizedBox(height: 18),

            // Class Starting Reminder Notification Banner
            _buildNotificationCard(),
            const SizedBox(height: 20),

            // Live Lecture Happening Right Now (If any)
            if (running != null) ...[
              _buildSectionHeader('Your Current Active Lecture', Icons.play_circle_fill_rounded, AppColors.success),
              const SizedBox(height: 8),
              _buildLiveLectureCard(running),
              const SizedBox(height: 20),
            ],

            // Day Selector Pills
            _buildSectionHeader('Weekly Schedule by Day', Icons.calendar_month_rounded, AppColors.primarySky),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final isSelected = _selectedDay == day;
                  return ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedDay = day),
                    selectedColor: AppColors.primarySky,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primarySky : AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Day's Teaching Slots
            if (schedule.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primarySky)),
              )
            else if (daySlots.isEmpty)
              _buildNoClassCard(_selectedDay)
            else
              ...daySlots.map((slot) => _buildFacultySlotCard(slot)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(dynamic user, String code, int totalWeekly) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.skyHeroGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user?.fullName ?? 'Faculty Professor',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primarySky),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.departmentName ?? "Computer Science & Engineering"}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalWeekly weekly assigned lectures in routine',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.iceBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSky),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: AppColors.primarySky, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Start Alerts Active',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primarySky),
                ),
                Text(
                  'You will receive notifications 15m prior to class start with assigned room numbers.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildLiveLectureCard(ScheduleSlotModel slot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.skyHeroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVE LECTURE NOW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              Text('${slot.startTime} - ${slot.endTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            slot.roomNumber ?? 'Room TBA',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text('Floor ${slot.floor ?? "N/A"} • ${slot.buildingName ?? "Permanent Campus"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${slot.courseCode} • ${slot.courseName}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Batch ${slot.batch} (${slot.section})',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacultySlotCard(ScheduleSlotModel slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primarySky),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Batch ${slot.batch} (Sec ${slot.section})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            slot.courseCode,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          Text(
            slot.courseName,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(color: AppColors.border, height: 18),
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.primarySky),
              const SizedBox(width: 6),
              Text(
                '${slot.roomNumber ?? "Room TBA"} • Floor ${slot.floor ?? "N/A"}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoClassCard(String day) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.event_available_rounded, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              'No Classes Assigned on $day',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enjoy your research and free day.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
