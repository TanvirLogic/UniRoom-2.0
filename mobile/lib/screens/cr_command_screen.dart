import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/schedule_slot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/schedule_provider.dart';
import 'free_rooms_screen.dart';

class CrCommandScreen extends StatefulWidget {
  const CrCommandScreen({super.key});

  @override
  State<CrCommandScreen> createState() => _CrCommandScreenState();
}

class _CrCommandScreenState extends State<CrCommandScreen> {
  final _releaseReasonController = TextEditingController();
  String _selectedReleaseReason = 'Faculty Absent / Class Cancelled';

  final List<String> _releaseReasons = [
    'Faculty Absent / Class Cancelled',
    'Class Ended Early',
    'Lab Shifted to Another Room',
    'Exam / Quiz Concluded Early',
    'Holiday / University Event',
  ];

  @override
  void dispose() {
    _releaseReasonController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 1. CANCEL TODAY'S CLASS BOTTOM SHEET
  // ===========================================================================
  void _showCancelClassSheet(BuildContext context, ScheduleSlotModel slot) {
    final reasonCtrl = TextEditingController(text: 'Faculty informed he will not take class today');
    bool freeRoom = true;
    final List<String> commonReasons = [
      'Faculty informed he will not take class today',
      'Faculty illness / personal emergency',
      'Lab session postponed to next week',
      'University event / campus rally',
      'Class shifted to online / Zoom',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
                const SizedBox(height: 18),

                // Title
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cancel Class for Today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${slot.courseCode} • ${slot.courseName}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scheduled: ${slot.startTime} - ${slot.endTime} (Room ${slot.roomNumber ?? "TBA"})\nThis only cancels today\'s slot. Weekly routine remains unchanged.',
                          style: const TextStyle(fontSize: 11, color: AppColors.error, height: 1.3),
                        ),
                      ),
                    ],
                  ),
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

                // Free room switch
                SwitchListTile.adaptive(
                  value: freeRoom,
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.success,
                  title: const Text(
                    'Release classroom for other batches',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    'Frees Room ${slot.roomNumber ?? ""} so other CRs can claim it',
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

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? AppColors.success : AppColors.error,
                          content: Text(
                            success
                                ? 'Class ${slot.courseCode} cancelled for today! Students notified.'
                                : 'Failed to cancel: ${context.read<ScheduleProvider>().errorMessage}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. RESCHEDULE TODAY'S CLASS BOTTOM SHEET
  // ===========================================================================
  void _showRescheduleClassSheet(BuildContext context, ScheduleSlotModel slot) {
    TimeOfDay parseTime(String t, TimeOfDay fallback) {
      try {
        final p = t.split(':');
        return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      } catch (_) {
        return fallback;
      }
    }

    String formatTime(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    final now = DateTime.now();
    final curMinutes = now.hour * 60 + now.minute;
    int parseMins(String s) {
      try {
        final p = s.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      } catch (_) {
        return 0;
      }
    }

    TimeOfDay startTime;
    TimeOfDay endTime;

    if (parseMins(slot.effectiveStartTime) <= curMinutes) {
      final nextHour = (now.hour + 1).clamp(0, 22);
      startTime = TimeOfDay(hour: nextHour, minute: 0);
      final endM = nextHour * 60 + 80;
      endTime = TimeOfDay(hour: (endM ~/ 60).clamp(0, 23), minute: endM % 60);
    } else {
      startTime = parseTime(slot.effectiveStartTime, const TimeOfDay(hour: 14, minute: 0));
      endTime = parseTime(slot.effectiveEndTime, const TimeOfDay(hour: 15, minute: 30));
    }

    final roomCtrl = TextEditingController(text: slot.effectiveRoomNumber);
    final reasonCtrl = TextEditingController(text: 'Morning class was delayed; shifting to afternoon');

    final List<String> commonReasons = [
      'Morning class was delayed; shifting to afternoon',
      'Faculty requested afternoon shift',
      'Faculty requested morning shift',
      'Extra quiz / preparation session',
      'Class delayed due to weather / traffic',
      'Mutual section timing exchange',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
                const SizedBox(height: 18),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.update_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Time for Today Only',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${slot.courseCode} • Original: ${slot.startTime} - ${slot.endTime}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Time Pickers Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('New Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: startTime);
                              if (picked != null) {
                                setSheetState(() {
                                  startTime = picked;
                                  // Default end time to 90 mins after start
                                  final totalMins = picked.hour * 60 + picked.minute + 90;
                                  endTime = TimeOfDay(hour: (totalMins ~/ 60) % 24, minute: totalMins % 60);
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatTime(startTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primarySky),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('New End Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: endTime);
                              if (picked != null) {
                                setSheetState(() => endTime = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatTime(endTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primarySky),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Room Input (Keep or Change)
                TextField(
                  controller: roomCtrl,
                  decoration: InputDecoration(
                    labelText: 'Classroom / Lab',
                    hintText: 'e.g. 5028 (506)',
                    prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Reason for Reschedule:',
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
                      selectedColor: const Color(0xFFFEF3C7),
                      backgroundColor: AppColors.surfaceVariant,
                      side: BorderSide(color: isSel ? const Color(0xFFD97706) : AppColors.border),
                      labelStyle: TextStyle(color: isSel ? const Color(0xFFD97706) : AppColors.textSecondary),
                      onSelected: (_) => setSheetState(() => reasonCtrl.text = r),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason Details',
                    hintText: 'e.g. Faculty requested afternoon shift...',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text('Confirm Reschedule (${formatTime(startTime)} - ${formatTime(endTime)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySky,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final startStr = formatTime(startTime);
                    final endStr = formatTime(endTime);

                    if (reasonCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reschedule reason.')),
                      );
                      return;
                    }

                    Navigator.pop(sheetCtx);
                    final isSameRoom = roomCtrl.text.trim().isEmpty ||
                        roomCtrl.text.trim() == slot.effectiveRoomNumber ||
                        roomCtrl.text.trim() == slot.roomNumber;
                    final success = await context.read<ScheduleProvider>().rescheduleTodayClass(
                          slotId: slot.id,
                          newStartTime: startStr,
                          newEndTime: endStr,
                          newRoomId: isSameRoom ? null : roomCtrl.text.trim(),
                          reason: reasonCtrl.text.trim(),
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? AppColors.success : AppColors.error,
                          content: Text(
                            success
                                ? 'Class moved to $startStr - $endStr! Students notified.'
                                : 'Failed to reschedule: ${context.read<ScheduleProvider>().errorMessage}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. UNDO / REVERT OVERRIDE CONFIRMATION
  // ===========================================================================
  void _confirmRestoreSchedule(BuildContext context, ScheduleSlotModel slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Original Schedule?'),
        content: Text(
          'Revert "${slot.courseCode}" back to regular timetable today (${slot.startTime} - ${slot.endTime} in Room ${slot.roomNumber ?? "TBA"})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySky, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ScheduleProvider>().undoTodayOverride(slotId: slot.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.success : AppColors.error,
                    content: Text(
                      success
                          ? 'Schedule restored to normal! Students notified.'
                          : 'Failed to restore: ${context.read<ScheduleProvider>().errorMessage}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Restore Original'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. RELEASE ROOM EARLY SHEET (When Class Finished Early)
  // ===========================================================================
  void _showReleaseRoomSheet(BuildContext context, ScheduleSlotModel slot, dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.meeting_room_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Release & Free Room Early',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Room ${slot.effectiveRoomNumber} • ${slot.effectiveStartTime} - ${slot.effectiveEndTime}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text('Select Reason:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),

              ..._releaseReasons.map((r) {
                final isSelected = _selectedReleaseReason == r;
                return InkWell(
                  onTap: () => setSheetState(() => _selectedReleaseReason = r),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primarySky : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),

              TextField(
                controller: _releaseReasonController,
                decoration: InputDecoration(
                  hintText: 'Optional additional note for other CRs...',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.broadcast_on_personal_rounded, size: 18),
                label: const Text('Confirm & Broadcast Room Available'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  Navigator.pop(bottomSheetCtx);
                  final note = _releaseReasonController.text.trim().isNotEmpty
                      ? '$_selectedReleaseReason: ${_releaseReasonController.text.trim()}'
                      : _selectedReleaseReason;

                  final success = await context.read<RoomProvider>().freeRoomByCr(
                        roomId: slot.roomId,
                        version: slot.roomVersion ?? 1,
                        roomNumber: slot.effectiveRoomNumber,
                        batch: 'Batch ${user?.batch ?? "68"}',
                        section: user?.section,
                        reason: note,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Room ${slot.effectiveRoomNumber} freed and broadcasted to all CRs!'
                              : 'Failed: ${context.read<RoomProvider>().errorMessage}',
                        ),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. SCHEDULE EXTRA CLASS BOTTOM SHEET
  // ===========================================================================
  void _openScheduleExtraClassSheet(BuildContext context) {
    final authUser = context.read<AuthProvider>().user;
    final scheduleProv = context.read<ScheduleProvider>();

    // Load available rooms immediately
    context.read<RoomProvider>().loadFreeRoomsNow();

    final courseCtrl = TextEditingController(text: 'Extra Class');
    final teacherCtrl = TextEditingController();
    final batchCtrl = TextEditingController(text: authUser?.batch ?? '68');
    final sectionCtrl = TextEditingController(text: authUser?.section ?? 'B');
    final customRoomCtrl = TextEditingController();

    TimeOfDay selectedStartTime = TimeOfDay.now();
    int durationMinutes = 90;
    String? selectedRoomId;
    int selectedRoomVersion = 1;

    final existingCourses = scheduleProv.allWeeklySlots
        .map((s) => s.courseCode)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Consumer<RoomProvider>(
        builder: (ctx, roomProv, _) => StatefulBuilder(
          builder: (ctx2, setSheetState) {
            final freeRooms = roomProv.freeRooms;
            final startFormatted =
                '${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}';

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
                    const SizedBox(height: 18),

                    // Sheet Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.alarm_add_rounded, color: AppColors.primarySky, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule Extra Class',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Notifies students & adds slot to Today\'s timetable',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Course Name / Code
                    TextField(
                      controller: courseCtrl,
                      decoration: InputDecoration(
                        labelText: 'Course Name / Code',
                        hintText: 'e.g. CSE-311 Database Systems',
                        prefixIcon: const Icon(Icons.menu_book_rounded, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    if (existingCourses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: existingCourses.take(5).map((code) {
                          return ActionChip(
                            label: Text(code, style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.surfaceVariant,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () {
                              setSheetState(() {
                                final slotMatch = scheduleProv.allWeeklySlots.firstWhere(
                                  (s) => s.courseCode == code,
                                  orElse: () => scheduleProv.allWeeklySlots.first,
                                );
                                courseCtrl.text = slotMatch.courseName.isNotEmpty
                                    ? '${slotMatch.courseCode} ${slotMatch.courseName}'.trim()
                                    : slotMatch.courseCode;
                                if (slotMatch.facultyInitials.isNotEmpty) {
                                  teacherCtrl.text = slotMatch.facultyInitials;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Batch & Section Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: batchCtrl,
                            decoration: InputDecoration(
                              labelText: 'Batch',
                              hintText: 'e.g. 68',
                              prefixIcon: const Icon(Icons.groups_rounded, size: 20),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sectionCtrl,
                            decoration: InputDecoration(
                              labelText: 'Section',
                              hintText: 'e.g. B',
                              prefixIcon: const Icon(Icons.class_rounded, size: 20),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Faculty Initials
                    TextField(
                      controller: teacherCtrl,
                      decoration: InputDecoration(
                        labelText: 'Faculty Initial (Optional)',
                        hintText: 'e.g. DNS or KTK',
                        prefixIcon: const Icon(Icons.person_rounded, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Classroom Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Classroom Selection:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.search_rounded, size: 14),
                          label: const Text('Search Free Rooms', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FreeRoomsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (roomProv.isLoading && freeRooms.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      )
                    else if (freeRooms.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedRoomId,
                            hint: const Text(
                              'Choose an available room',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            items: [
                              ...freeRooms.map((r) => DropdownMenuItem(
                                    value: r.id.isNotEmpty ? r.id : r.roomNumber,
                                    child: Text(
                                      'Room ${r.roomNumber} (${r.buildingName ?? "Main"} • Fl ${r.floor} • ${r.capacity} seats)',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  )),
                              const DropdownMenuItem(
                                value: '__custom__',
                                child: Text('Enter custom room number...', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                              ),
                            ],
                            onChanged: (val) {
                              setSheetState(() {
                                selectedRoomId = val;
                                if (val != null && val != '__custom__') {
                                  final matched = freeRooms.firstWhere(
                                    (r) => (r.id.isNotEmpty ? r.id : r.roomNumber) == val,
                                    orElse: () => freeRooms.first,
                                  );
                                  selectedRoomVersion = matched.version;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],

                    if (selectedRoomId == '__custom__' || freeRooms.isEmpty) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customRoomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Room Number',
                          hintText: 'e.g. 503 or Lab 4',
                          prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Timing & Duration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Time:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: sheetCtx,
                                    initialTime: selectedStartTime,
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedStartTime = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        startFormatted,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                      ),
                                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primarySky),
                                    ],
                                  ),
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
                              const Text(
                                'Duration:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [45, 60, 90, 120].map((d) {
                                  final isSel = durationMinutes == d;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: InkWell(
                                        onTap: () => setSheetState(() => durationMinutes = d),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSel ? AppColors.primarySky : AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${d}m',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isSel ? Colors.white : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Confirm Action Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Confirm & Broadcast Extra Class'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySky,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final course = courseCtrl.text.trim();
                        final batch = batchCtrl.text.trim();
                        final section = sectionCtrl.text.trim();
                        final teacher = teacherCtrl.text.trim();

                        final targetRoomId = (selectedRoomId != null && selectedRoomId != '__custom__')
                            ? selectedRoomId!
                            : customRoomCtrl.text.trim();

                        if (course.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a course name or code.')),
                          );
                          return;
                        }
                        if (targetRoomId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select or enter a classroom.')),
                          );
                          return;
                        }

                        Navigator.pop(sheetCtx);

                        final success = await roomProv.bookExtraClass(
                          roomId: targetRoomId,
                          version: selectedRoomVersion,
                          courseName: course,
                          batch: batch.isNotEmpty ? batch : (authUser?.batch ?? '68'),
                          section: section.isNotEmpty ? section : (authUser?.section ?? 'B'),
                          teacherInitials: teacher.isNotEmpty ? teacher : null,
                          durationMinutes: durationMinutes,
                          department: authUser?.effectiveDepartmentCode ?? 'CSE',
                          startTime: startFormatted,
                        );

                        if (context.mounted) {
                          if (success) {
                            context.read<ScheduleProvider>().loadSchedules();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text(
                                  'Extra Class scheduled ($startFormatted)! Push notification sent to Batch $batch ($section) and added to Today\'s timetable.',
                                ),
                              ),
                            );
                          } else {
                            final err = roomProv.errorMessage ?? 'Failed to book extra class';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: AppColors.error, content: Text(err)),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActionsToolbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          // 1. Search Free Rooms Button (Issue 5)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FreeRoomsScreen()),
                );
              },
              icon: const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.primarySky),
              label: const Text(
                'Search Free Rooms',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primarySky,
                side: const BorderSide(color: AppColors.primarySky, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 2. Take Extra Class Button (Issue 2)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openScheduleExtraClassSheet(context),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text(
                'Take Extra Class',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySky,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final roomProv = context.watch<RoomProvider>();
    final user = auth.user;

    final todaySlots = schedule.todaySlots;
    final broadcasts = roomProv.crBroadcasts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CR Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => schedule.loadSchedules(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => schedule.loadSchedules(),
        color: AppColors.primarySky,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 380 ? 14 : 20,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CR Authority Badge
              _buildCrBadgeCard(user),
              const SizedBox(height: 14),

              // Quick Actions Toolbar (Search Free Rooms + Take Extra Class)
              _buildQuickActionsToolbar(context),

              // Emergency Daily Class Control Section
              _buildSectionHeader(
                'Today\'s Classes & Faculty Emergency Controls',
                Icons.admin_panel_settings_rounded,
                AppColors.primarySky,
              ),
              const SizedBox(height: 4),
              const Text(
                'If a faculty cancels or changes timing for today, select below to notify your students and update room allocations.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              if (schedule.isLoading && todaySlots.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
              else if (todaySlots.isEmpty)
                _buildNoClassCard()
              else
                ...todaySlots.map((slot) => _buildClassControlCard(slot, user)),

              const SizedBox(height: 24),

              // CR Broadcast Feed Section
              _buildSectionHeader('Live Room Freeing Broadcasts', Icons.campaign_rounded, AppColors.accentBlue),
              const SizedBox(height: 10),
              _buildBroadcastFeed(broadcasts),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrBadgeCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFFD97706), size: 28),
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
                        user?.fullName ?? 'Class Representative',
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
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${user?.departmentName ?? "SWE"} • Batch ${user?.batch ?? "68"} • Section ${user?.section ?? "B"}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Authorized to cancel, reschedule, and release classrooms for this section.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. CLASS CONTROL CARD
  // ===========================================================================
  Widget _buildClassControlCard(ScheduleSlotModel slot, dynamic user) {
    final now = context.read<ScheduleProvider>().currentTime;
    final state = slot.getTimingState(now);
    final isLive = state == SlotTimingState.runningNow;
    final isDone = !slot.isCancelled && state == SlotTimingState.completed;
    final isCancelled = slot.isCancelled;
    final isRescheduled = slot.isRescheduled;

    Color borderColor = AppColors.border;
    if (isCancelled) {
      borderColor = const Color(0xFFFCA5A5);
    } else if (isRescheduled) {
      borderColor = const Color(0xFFFCD34D);
    } else if (isLive) {
      borderColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCancelled ? const Color(0xFFFEF2F2) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: (isCancelled || isRescheduled || isLive) ? 1.5 : 1),
        boxShadow: isLive ? AppColors.softShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Status badge and Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFEE2E2)
                        : (isRescheduled
                            ? const Color(0xFFFEF3C7)
                            : (isLive
                                ? const Color(0xFFDCFCE7)
                                : (isDone ? AppColors.surfaceVariant : AppColors.primaryLight))),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCancelled
                        ? 'CANCELLED'
                        : (isRescheduled
                            ? 'RESCHEDULED'
                            : (isLive ? 'RUNNING' : (isDone ? 'COMPLETED' : 'SCHEDULED'))),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isCancelled
                          ? AppColors.error
                          : (isRescheduled
                              ? const Color(0xFFD97706)
                              : (isLive
                                  ? AppColors.success
                                  : (isDone ? AppColors.textMuted : AppColors.primarySky))),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Row(
                children: [
                  if (isRescheduled) ...[
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${slot.effectiveStartTime} - ${slot.effectiveEndTime}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                    ),
                  ] else ...[
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCancelled ? AppColors.textMuted : AppColors.textSecondary,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Course info
          Text(
            '${slot.courseCode} • ${slot.courseName}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isCancelled ? AppColors.textMuted : AppColors.textPrimary,
              decoration: isCancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 4),

          // Teacher & Room
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Faculty: ${slot.facultyInitials}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.primarySky),
              const SizedBox(width: 4),
              Text(
                'Room: ${slot.effectiveRoomNumber}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isRescheduled ? const Color(0xFFD97706) : AppColors.primarySky,
                ),
              ),
            ],
          ),

          // Overrides Notice Box
          if (isCancelled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancelled: ${slot.overrideReason ?? "Faculty unavailable"}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmRestoreSchedule(context, slot),
                    icon: const Icon(Icons.undo_rounded, size: 14, color: AppColors.primarySky),
                    label: const Text('Undo', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isRescheduled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Moved to ${slot.effectiveStartTime}-${slot.effectiveEndTime} (${slot.overrideReason ?? ""})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmRestoreSchedule(context, slot),
                    icon: const Icon(Icons.undo_rounded, size: 14, color: AppColors.textSecondary),
                    label: const Text('Revert', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Completed Class Delayed Notice Banner
          if (isDone && !isRescheduled) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Class didn\'t happen? Tap "Reschedule" below to shift it to later today.',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons Row
          if (!isCancelled) ...[
            Row(
              children: [
                // Cancel Today Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelClassSheet(context, slot),
                    icon: const Icon(Icons.cancel_outlined, size: 15, color: AppColors.error),
                    label: Text(
                      MediaQuery.sizeOf(context).width < 380 ? 'Cancel' : 'Cancel Today',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Change Time Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRescheduleClassSheet(context, slot),
                    icon: const Icon(Icons.update_rounded, size: 15),
                    label: Text(
                      isRescheduled
                          ? 'Edit Time'
                          : (isDone ? 'Reschedule' : 'Change Time'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isRescheduled || isDone)
                          ? const Color(0xFFD97706)
                          : AppColors.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),

            if (isLive) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showReleaseRoomSheet(context, slot, user),
                  icon: const Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.success),
                  label: const Text(
                    'Class Ended Early? Release Room for Other CRs',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNoClassCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, color: AppColors.primarySky, size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Classes Scheduled Today',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 5),
          const Text(
            'Enjoy your off-day! Or if your section has a make-up, lab, or extra class, schedule it now below.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_task_rounded, size: 17),
            label: const Text('Take Extra Class Today'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySky,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _openScheduleExtraClassSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastFeed(List<dynamic> broadcasts) {
    if (broadcasts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No rooms freed recently.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: broadcasts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final b = broadcasts[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSky),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_outlined, color: AppColors.primarySky, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Room ${b.roomNumber} FREED',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AVAILABLE',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Freed by ${b.batch}${b.section != null ? ' (${b.section})' : ''}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primarySky),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.reason,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
