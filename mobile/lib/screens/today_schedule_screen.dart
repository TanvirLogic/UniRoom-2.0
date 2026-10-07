import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/schedule_slot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/notification_provider.dart';
import '../services/schedule_service.dart';
import 'free_rooms_screen.dart';
import 'notifications_screen.dart';

class TodayScheduleScreen extends StatefulWidget {
  final VoidCallback? onNavigateToWeekly;

  const TodayScheduleScreen({super.key, this.onNavigateToWeekly});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ScheduleProvider>().syncWithUser(user);
      }
      final todaySlots = context.read<ScheduleProvider>().todaySlots;
      if (todaySlots.isNotEmpty) {
        context.read<NotificationProvider>().syncScheduleAlerts(todaySlots);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final user = auth.user;
    final unreadCount = notificationProvider.unreadCount;

    final todayName = ScheduleService.getDayOfWeekString(schedule.currentTime);
    final todaySlots = schedule.todaySlots;
    final running = schedule.runningClass;
    final upcoming = schedule.upcomingClass;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Today\'s Schedule'),
        actions: [
          IconButton(
            tooltip: 'Free Rooms',
            icon: const Icon(Icons.door_front_door_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FreeRoomsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh_rounded,
              color: schedule.isLoading ? AppColors.primarySky : AppColors.textSecondary,
            ),
            onPressed: schedule.isLoading
                ? null
                : () async {
                    await schedule.loadSchedules();
                    if (context.mounted) {
                      context.read<NotificationProvider>().syncScheduleAlerts(schedule.todaySlots);
                    }
                  },
          ),
          // Notification Bell Icon with Live Badge
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.error,
              offset: const Offset(-4, 4),
              child: IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 24),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primarySky,
        onRefresh: () => schedule.loadSchedules(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 380 ? 14 : 20,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Cohort Header Banner
              _buildHeaderBanner(user, todayName),
              const SizedBox(height: 18),

              // Running Class Hero Card (If Active Now)
              if (running != null) ...[
                _buildSectionHeader('Happening Right Now', Icons.play_circle_fill_rounded, AppColors.success),
                const SizedBox(height: 8),
                _buildRunningHeroCard(running, schedule.currentTime),
                const SizedBox(height: 20),
              ],

              // Next Upcoming Class Card
              if (upcoming != null && upcoming.id != running?.id) ...[
                _buildSectionHeader('Up Next Today', Icons.access_time_filled_rounded, AppColors.warning),
                const SizedBox(height: 8),
                _buildUpcomingCard(upcoming, schedule.currentTime),
                const SizedBox(height: 20),
              ],

              // Today's Complete Schedule Timeline
              _buildSectionHeader('Today\'s Full Routine ($todayName)', Icons.calendar_today_rounded, AppColors.primarySky),
              const SizedBox(height: 10),

              if (schedule.isLoading && todaySlots.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primarySky)),
                )
              else if (todaySlots.isEmpty)
                _buildEmptyState()
              else
                ...todaySlots.map((slot) => _buildTimelineSlotCard(slot, schedule.currentTime, user)),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(dynamic user, String todayName) {
    final cohortText = user?.isFaculty == true
        ? 'Teacher Code: ${user?.facultyId ?? "N/A"}'
        : '${user?.departmentName ?? "CSE"} • Batch ${user?.batch ?? "68"} • Section ${user?.section ?? "A"}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              user?.isFaculty == true
                  ? Icons.person_rounded
                  : (user?.isCr == true ? Icons.stars_rounded : Icons.school_rounded),
              color: AppColors.primarySky,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user?.fullName ?? 'Campus User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user?.isCr == true ? const Color(0xFFFEF3C7) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user?.isCr == true ? 'CR' : (user?.isFaculty == true ? 'FACULTY' : 'STUDENT'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: user?.isCr == true ? const Color(0xFFD97706) : AppColors.primarySky,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  cohortText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRunningHeroCard(ScheduleSlotModel slot, DateTime now) {
    final remaining = slot.getMinutesRemaining(now);

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE CLASS NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${remaining > 0 ? remaining : 0} mins left',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        slot.effectiveRoomNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (slot.isRescheduled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'RESCHEDULED',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${slot.buildingName ?? "Permanent Campus"} • Floor ${slot.floor ?? "TBA"}',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.courseCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    slot.courseName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Faculty: ${slot.facultyInitials}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(ScheduleSlotModel slot, DateTime now) {
    final minsUntil = slot.getMinutesUntilStart(now);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                const SizedBox(height: 4),
                Text(
                  minsUntil > 0 ? '$minsUntil m' : 'Soon',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              slot.effectiveRoomNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (slot.isRescheduled) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'SHIFTED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${slot.effectiveStartTime} - ${slot.effectiveEndTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${slot.courseCode} • ${slot.courseName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Teacher: ${slot.facultyInitials} • Floor ${slot.floor ?? "TBA"}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primarySky),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSlotCard(ScheduleSlotModel slot, DateTime now, dynamic user) {
    final isCancelled = slot.isCancelled;
    final isRescheduled = slot.isRescheduled;
    final state = slot.getTimingState(now);
    final isDone = !isCancelled && state == SlotTimingState.completed;
    final isLive = !isCancelled && state == SlotTimingState.runningNow;
    final isCrOrFaculty = user?.isCr == true || user?.isFaculty == true;

    Color badgeColor = AppColors.primaryLight;
    Color textColor = AppColors.primarySky;
    String statusLabel = 'UPCOMING';

    if (isCancelled) {
      badgeColor = const Color(0xFFFEE2E2);
      textColor = AppColors.error;
      statusLabel = 'CANCELLED';
    } else if (isRescheduled) {
      badgeColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      statusLabel = isLive ? 'LIVE (MOVED)' : 'RESCHEDULED';
    } else if (isLive) {
      badgeColor = const Color(0xFFDCFCE7);
      textColor = AppColors.success;
      statusLabel = 'RUNNING';
    } else if (isDone) {
      badgeColor = AppColors.surfaceVariant;
      textColor = AppColors.textMuted;
      statusLabel = 'COMPLETED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCancelled
            ? const Color(0xFFFFF1F2)
            : (isDone ? const Color(0xFFFAFAFA) : AppColors.surface),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCancelled
              ? const Color(0xFFFECDD3)
              : (isRescheduled
                  ? const Color(0xFFFDE68A)
                  : (isLive ? AppColors.primarySky : AppColors.border)),
          width: (isLive || isRescheduled || isCancelled) ? 1.5 : 1,
        ),
        boxShadow: isLive ? AppColors.softShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Column
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 380 ? 70 : 82,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.effectiveStartTime,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                        color: isCancelled
                            ? AppColors.error
                            : (isRescheduled
                                ? const Color(0xFFD97706)
                                : (isDone ? AppColors.textMuted : AppColors.textPrimary)),
                      ),
                    ),
                    Text(
                      slot.effectiveEndTime,
                      style: TextStyle(
                        fontSize: 11,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                        color: isCancelled ? AppColors.error : AppColors.textMuted,
                      ),
                    ),
                    if (isRescheduled) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Orig: ${slot.startTime}',
                        style: const TextStyle(
                          fontSize: 9,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Divider
              Container(
                width: 1.5,
                height: 55,
                color: isCancelled
                    ? const Color(0xFFFECDD3)
                    : (isRescheduled
                        ? const Color(0xFFFDE68A)
                        : (isLive ? AppColors.primarySky : AppColors.border)),
              ),
              const SizedBox(width: 14),
              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            slot.courseCode,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                              color: isCancelled
                                  ? AppColors.error
                                  : (isDone ? AppColors.textMuted : AppColors.textPrimary),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCancelled ? const Color(0xFFFEE2E2) : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            slot.facultyInitials,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCancelled ? AppColors.error : AppColors.primarySky,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slot.courseName,
                      style: TextStyle(
                        fontSize: 12,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                        color: isCancelled
                            ? AppColors.textMuted
                            : (isDone ? AppColors.textMuted : AppColors.textSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.room_outlined,
                          size: 14,
                          color: isCancelled
                              ? AppColors.error
                              : (isDone ? AppColors.textMuted : AppColors.primarySky),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${slot.effectiveRoomNumber} • Floor ${slot.floor ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                              color: isCancelled
                                  ? AppColors.error
                                  : (isRescheduled
                                      ? const Color(0xFFD97706)
                                      : (isDone ? AppColors.textMuted : AppColors.textSecondary)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Cancelled Notice Banner
          if (isCancelled) ...[
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      slot.overrideReason?.isNotEmpty == true
                          ? 'Cancelled: ${slot.overrideReason}'
                          : 'Class suspended for today by faculty/CR',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Rescheduled Notice Banner
          if (isRescheduled) ...[
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      slot.overrideReason?.isNotEmpty == true
                          ? 'Shift Notice: ${slot.overrideReason} (Orig: ${slot.startTime} - ${slot.endTime})'
                          : 'Time adjusted for today (Original: ${slot.startTime} - ${slot.endTime})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Highlight for Completed Class if user is CR / Faculty: Option to reschedule if class was delayed!
          if (isDone && isCrOrFaculty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showRescheduleSheet(slot),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Class Didn\'t Happen Yet? Shift Time for Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
          ],

          // CR Quick Action Bar
          if (isCrOrFaculty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _showCrSlotActionSheet(slot),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 12, color: AppColors.primarySky),
                        SizedBox(width: 4),
                        Text(
                          'CR Action',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primarySky,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCrSlotActionSheet(ScheduleSlotModel slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primarySky, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${slot.courseCode} - Quick Actions',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${slot.courseName} (${slot.startTime} - ${slot.endTime})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (slot.isCancelled || slot.isRescheduled) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.restore_rounded, color: AppColors.primarySky),
                label: const Text('Undo & Restore Regular Schedule'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primarySky),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  final success = await context.read<ScheduleProvider>().undoTodayOverride(slotId: slot.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Routine restored to regular schedule.' : 'Failed to undo override.'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            if (!slot.isCancelled) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel Class for Today'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showCancelSheet(slot);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('Change Time / Reschedule for Today'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF3C7),
                  foregroundColor: const Color(0xFFD97706),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showRescheduleSheet(slot);
                },
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showCancelSheet(ScheduleSlotModel slot) {
    final reasonCtrl = TextEditingController();
    bool freeRoom = true;
    final commonReasons = [
      'Faculty informed on leave',
      'Faculty unable to attend today',
      'Department / Varsity event',
      'Class will be taken online',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_busy_rounded, color: AppColors.error, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancel ${slot.courseCode} for Today',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${slot.courseName} • ${slot.startTime} - ${slot.endTime}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Select Cancellation Reason:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonReasons.map((r) {
                    final isSel = reasonCtrl.text.trim() == r;
                    return ChoiceChip(
                      label: Text(r, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                      selected: isSel,
                      selectedColor: const Color(0xFFFEE2E2),
                      backgroundColor: AppColors.surfaceVariant,
                      side: BorderSide(color: isSel ? AppColors.error : AppColors.border),
                      labelStyle: TextStyle(color: isSel ? AppColors.error : AppColors.textSecondary),
                      onSelected: (_) => setSheetState(() => reasonCtrl.text = r),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cancellation Details / Note',
                    hintText: 'e.g. Faculty informed on WhatsApp...',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                SwitchListTile.adaptive(
                  value: freeRoom,
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.success,
                  title: const Text(
                    'Release classroom for other batches',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    'Frees Room ${slot.effectiveRoomNumber} so other CRs can claim it',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) => setSheetState(() => freeRoom = val),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: const Text('Confirm & Broadcast Cancellation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (reasonCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please provide a cancellation reason.')),
                      );
                      return;
                    }

                    Navigator.pop(sheetCtx);
                    final success = await context.read<ScheduleProvider>().cancelTodayClass(
                          slotId: slot.id,
                          reason: reasonCtrl.text.trim(),
                          freeRoom: freeRoom,
                        );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Class cancelled for today and students alerted via push!'
                              : 'Failed to cancel class.',
                        ),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRescheduleSheet(ScheduleSlotModel slot) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    int parseMinutes(String t) {
      try {
        final p = t.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      } catch (_) {
        return 0;
      }
    }

    final slotStartMinutes = parseMinutes(slot.effectiveStartTime);

    TimeOfDay selectedStart;
    TimeOfDay selectedEnd;

    // If slot has already ended or passed in the morning, default to an upcoming hour today!
    if (slotStartMinutes <= currentMinutes) {
      final nextHour = (now.hour + 1).clamp(0, 22);
      selectedStart = TimeOfDay(hour: nextHour, minute: 0);
      final endM = nextHour * 60 + 80; // 80 mins default
      selectedEnd = TimeOfDay(hour: (endM ~/ 60).clamp(0, 23), minute: endM % 60);
    } else {
      try {
        final parts = slot.effectiveStartTime.split(':');
        selectedStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final endParts = slot.effectiveEndTime.split(':');
        selectedEnd = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      } catch (_) {
        selectedStart = const TimeOfDay(hour: 14, minute: 0);
        selectedEnd = const TimeOfDay(hour: 15, minute: 30);
      }
    }

    final roomCtrl = TextEditingController(text: slot.effectiveRoomNumber);
    final reasonCtrl = TextEditingController(text: 'Morning class was delayed; shifting to afternoon');

    final commonReasons = [
      'Morning class was delayed; shifting to afternoon',
      'Faculty requested afternoon timing',
      'Faculty requested morning timing',
      'Extra quiz / preparation session',
      'Class delayed due to bad weather/traffic',
    ];

    String formatTimeOfDay(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reschedule ${slot.courseCode} Today',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Regular: ${slot.startTime} - ${slot.endTime}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: selectedStart);
                            if (picked != null) {
                              setSheetState(() {
                                selectedStart = picked;
                                final endM = picked.hour * 60 + picked.minute + 80;
                                selectedEnd = TimeOfDay(hour: (endM ~/ 60).clamp(0, 23), minute: endM % 60);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('New Start Time', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  formatTimeOfDay(selectedStart),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: selectedEnd);
                            if (picked != null) setSheetState(() => selectedEnd = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('New End Time', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  formatTimeOfDay(selectedEnd),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: roomCtrl,
                    decoration: InputDecoration(
                      labelText: 'Classroom Number (Optional)',
                      hintText: 'e.g. 504 (or leave unchanged)',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Select or Type Reschedule Reason:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: commonReasons.map((r) {
                      final isSel = reasonCtrl.text.trim() == r;
                      return ChoiceChip(
                        label: Text(r, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                        selected: isSel,
                        selectedColor: const Color(0xFFFEF3C7),
                        backgroundColor: AppColors.surfaceVariant,
                        side: BorderSide(color: isSel ? const Color(0xFFD97706) : AppColors.border),
                        labelStyle: TextStyle(color: isSel ? const Color(0xFFD97706) : AppColors.textSecondary),
                        onSelected: (_) => setSheetState(() => reasonCtrl.text = r),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      labelText: 'Reason Details',
                      hintText: 'e.g. Faculty requested afternoon timing',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text('Save & Broadcast Shift (${formatTimeOfDay(selectedStart)} - ${formatTimeOfDay(selectedEnd)})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      final isSameRoom = roomCtrl.text.trim().isEmpty ||
                          roomCtrl.text.trim() == slot.effectiveRoomNumber ||
                          roomCtrl.text.trim() == slot.roomNumber;
                      final success = await context.read<ScheduleProvider>().rescheduleTodayClass(
                            slotId: slot.id,
                            newStartTime: formatTimeOfDay(selectedStart),
                            newEndTime: formatTimeOfDay(selectedEnd),
                            newRoomId: isSameRoom ? null : roomCtrl.text.trim(),
                            reason: reasonCtrl.text.trim().isEmpty
                                ? 'Morning class was delayed; shifting to afternoon'
                                : reasonCtrl.text.trim(),
                          );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Class rescheduled for today and section notified!'
                                : 'Failed to reschedule: ${context.read<ScheduleProvider>().errorMessage ?? "Unknown error"}',
                          ),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration_rounded, size: 48, color: AppColors.primarySky),
          const SizedBox(height: 12),
          const Text(
            'No Classes Scheduled Today!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'You are completely free today or all classes have finished.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onNavigateToWeekly,
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text('View Weekly Routine'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
