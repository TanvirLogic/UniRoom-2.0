import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../services/notification_service.dart';
import 'today_schedule_screen.dart';
import 'weekly_routine_screen.dart';
import 'cr_command_screen.dart';
import 'cr_attendance_screen.dart';
import 'free_rooms_screen.dart';
import 'faculty_schedule_screen.dart';
import 'cohort_profile_screen.dart';

/// MainNavigationShell
/// Renders a role-tailored bottom navigation shell for Student, CR, and Faculty.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  StreamSubscription<RemoteMessage>? _notificationSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ScheduleProvider>().syncWithUser(user);
        NotificationService().syncUserCohortTopics(
          department: user.effectiveDepartmentCode,
          batch: user.batch ?? '',
          section: user.section ?? '',
          isCr: user.isCr,
          facultyInitials: user.facultyId,
        );
      }
    });

    // Listen for foreground FCM push notifications and show alert toast
    _notificationSub = NotificationService().onForegroundMessage.listen((msg) {
      if (mounted) {
        final title = msg.notification?.title ?? 'Classroom Update';
        final body = msg.notification?.body ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primarySky,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                      if (body.isNotEmpty)
                        Text(body, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final isCr = user?.isCr == true;
    final isFaculty = user?.isFaculty == true;

    // Define items and pages based on user role
    final List<Widget> pages;
    final List<NavigationDestination> destinations;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;

    if (isCr) {
      // CR View: Today Schedule, Attendance, CR Action, Weekly Routine, Free Rooms, Profile
      pages = [
        TodayScheduleScreen(onNavigateToWeekly: () => _switchTab(3)),
        const CrAttendanceScreen(),
        const CrCommandScreen(),
        const WeeklyRoutineScreen(),
        const FreeRoomsScreen(),
        const CohortProfileScreen(),
      ];

      destinations = [
        const NavigationDestination(
          icon: Icon(Icons.today_outlined),
          selectedIcon: Icon(Icons.today_rounded),
          label: 'Today',
        ),
        NavigationDestination(
          icon: const Icon(Icons.checklist_rtl_outlined),
          selectedIcon: const Icon(Icons.checklist_rtl_rounded),
          label: isCompact ? 'Attend' : 'Attendance',
        ),
        const NavigationDestination(
          icon: Icon(Icons.flash_on_outlined),
          selectedIcon: Icon(Icons.flash_on_rounded),
          label: 'Action',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Routine',
        ),
        const NavigationDestination(
          icon: Icon(Icons.door_front_door_outlined),
          selectedIcon: Icon(Icons.door_front_door_rounded),
          label: 'Rooms',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    } else if (isFaculty) {
      // Faculty View: Teaching Hub, Weekly Routine, Free Rooms, Profile
      pages = [
        const FacultyScheduleScreen(),
        const WeeklyRoutineScreen(),
        const FreeRoomsScreen(),
        const CohortProfileScreen(),
      ];

      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school_rounded),
          label: 'Lectures',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Routine',
        ),
        NavigationDestination(
          icon: Icon(Icons.door_front_door_outlined),
          selectedIcon: Icon(Icons.door_front_door_rounded),
          label: 'Rooms',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    } else {
      // Student View: Today, Weekly Routine, Free Rooms, Profile
      pages = [
        TodayScheduleScreen(onNavigateToWeekly: () => _switchTab(1)),
        const WeeklyRoutineScreen(),
        const FreeRoomsScreen(),
        const CohortProfileScreen(),
      ];

      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.today_outlined),
          selectedIcon: Icon(Icons.today_rounded),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Routine',
        ),
        NavigationDestination(
          icon: Icon(Icons.door_front_door_outlined),
          selectedIcon: Icon(Icons.door_front_door_rounded),
          label: 'Rooms',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    }

    // Safety check if index exceeds array after role change
    final safeIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primarySky.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 60,
            indicatorColor: AppColors.primarySky.withValues(alpha: 0.12),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: isCompact ? 9.5 : 10.0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primarySky : AppColors.textSecondary,
                letterSpacing: isCompact ? -0.4 : -0.2,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: isCompact ? 19 : 20,
                color: isSelected ? AppColors.primarySky : AppColors.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            height: 60,
            selectedIndex: safeIndex,
            onDestinationSelected: _switchTab,
            destinations: destinations,
            backgroundColor: AppColors.surface,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ),
      ),
    );
  }
}
