import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/schedule_slot_model.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';

class WeeklyRoutineScreen extends StatefulWidget {
  const WeeklyRoutineScreen({super.key});

  @override
  State<WeeklyRoutineScreen> createState() => _WeeklyRoutineScreenState();
}

class _WeeklyRoutineScreenState extends State<WeeklyRoutineScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final schedule = context.watch<ScheduleProvider>();
    final user = auth.user;

    final filteredSlots = schedule.filteredSlotsForSelectedDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Weekly Routine'),
        actions: [
          IconButton(
            tooltip: 'Reload Routine',
            icon: Icon(
              Icons.refresh_rounded,
              color: schedule.isLoading ? AppColors.primarySky : AppColors.textSecondary,
            ),
            onPressed: schedule.isLoading ? null : () => schedule.loadSchedules(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cohort Sub-header & Search Bar Container
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cohort Indicator Pill
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user?.isFaculty == true
                                ? 'Faculty: ${user?.facultyId ?? "N/A"}'
                                : '${user?.effectiveDepartmentCode ?? user?.departmentName ?? "SWE"} • Batch ${user?.batch ?? "68"} • Sec ${user?.section ?? "B"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primarySky,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${filteredSlots.length} class${filteredSlots.length == 1 ? "" : "es"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // In-Memory Instant Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => schedule.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search course code, faculty (e.g. DNS)...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              schedule.setSearchQuery('');
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
              ],
            ),
          ),

          // Day Selection Pill Bar
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = _days[index];
                final isSelected = schedule.selectedDay == day;

                return ChoiceChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: (_) => schedule.setSelectedDay(day),
                  selectedColor: AppColors.primarySky,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primarySky : AppColors.border,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Slot Cards List
          Expanded(
            child: schedule.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primarySky))
                : filteredSlots.isEmpty
                    ? _buildEmptyState(schedule.selectedDay)
                    : RefreshIndicator(
                        color: AppColors.primarySky,
                        onRefresh: () => schedule.loadSchedules(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: filteredSlots.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildRoutineCard(filteredSlots[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(ScheduleSlotModel slot) {
    return Container(
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
          // Top Time & Room Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primarySky),
                    const SizedBox(width: 5),
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primarySky,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sec ${slot.section}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Course Code & Title
          Text(
            slot.courseCode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            slot.courseName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(color: AppColors.border, height: 20),

          // Physical Room & Faculty Info Footer
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.primarySky),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${slot.roomNumber ?? "Room TBA"} (Fl. ${slot.floor ?? "N/A"})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Faculty: ${slot.facultyInitials}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primarySky,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String day) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.weekend_rounded, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              'No Classes on $day',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no classes scheduled for this day in your section\'s master routine.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
