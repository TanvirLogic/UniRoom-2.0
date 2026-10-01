import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/schedule_slot_model.dart';
import '../models/user_model.dart';
import '../services/schedule_service.dart';

/// ScheduleProvider
/// Manages real-time daily routine slots, running class calculation,
/// weekly routine matrix, and cohort synchronization for students, CRs, and faculty.
class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _scheduleService = ScheduleService();

  List<ScheduleSlotModel> _allWeeklySlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedDay = 'MON';
  String _searchQuery = '';
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  // Active Cohort Scope
  String? _currentDept;
  String? _currentBatch;
  String? _currentSection;
  String? _currentFacultyCode;
  String? _userRole;

  ScheduleProvider() {
    // Set initial day to current device weekday
    _selectedDay = ScheduleService.getDayOfWeekString(DateTime.now());

    // Update real-time clock every 30 seconds to recalculate running class pulse
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Getters
  List<ScheduleSlotModel> get allWeeklySlots => _allWeeklySlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedDay => _selectedDay;
  String get searchQuery => _searchQuery;
  DateTime get currentTime => _currentTime;

  /// Today's slots matching current day of week
  List<ScheduleSlotModel> get todaySlots {
    final todayStr = ScheduleService.getDayOfWeekString(_currentTime);
    final slots = _allWeeklySlots.where((s) => s.dayOfWeek == todayStr).toList();
    slots.sort((a, b) => a.effectiveStartTime.compareTo(b.effectiveStartTime));
    return slots;
  }

  /// Current running class right now (if any)
  ScheduleSlotModel? get runningClass {
    for (final slot in todaySlots) {
      if (slot.getTimingState(_currentTime) == SlotTimingState.runningNow) {
        return slot;
      }
    }
    return null;
  }

  /// Next upcoming class today
  ScheduleSlotModel? get upcomingClass {
    for (final slot in todaySlots) {
      final state = slot.getTimingState(_currentTime);
      if (state == SlotTimingState.upcomingSoon || state == SlotTimingState.laterToday) {
        return slot;
      }
    }
    return null;
  }

  /// Completed classes today
  List<ScheduleSlotModel> get completedClasses {
    return todaySlots
        .where((s) => s.getTimingState(_currentTime) == SlotTimingState.completed)
        .toList();
  }

  /// Filtered weekly slots for the selected day tab & search query
  List<ScheduleSlotModel> get filteredSlotsForSelectedDay {
    var slots = _allWeeklySlots.where((s) => s.dayOfWeek == _selectedDay).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      slots = slots.where((s) {
        return s.courseCode.toLowerCase().contains(q) ||
            s.courseName.toLowerCase().contains(q) ||
            s.facultyInitials.toLowerCase().contains(q) ||
            (s.roomNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    slots.sort((a, b) => a.effectiveStartTime.compareTo(b.effectiveStartTime));
    return slots;
  }

  /// Clear loaded schedules (e.g. on logout or user switch)
  void clearSchedules() {
    _allWeeklySlots = [];
    _currentDept = null;
    _currentBatch = null;
    _currentSection = null;
    _currentFacultyCode = null;
    _userRole = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Load or synchronize schedules matching the authenticated user profile
  Future<void> syncWithUser(UserModel user, {bool force = false}) async {
    final deptCode = (user.departmentCode?.isNotEmpty == true)
        ? user.departmentCode!
        : (user.departmentId.isNotEmpty ? user.departmentId : (user.departmentName ?? 'SWE'));
    final batch = user.batch;
    final section = user.section;
    final facultyId = user.facultyId;
    final role = user.role;

    // Check if cohort changed
    final changed = deptCode != _currentDept ||
        batch != _currentBatch ||
        section != _currentSection ||
        facultyId != _currentFacultyCode ||
        role != _userRole;

    if (!changed && !force && _allWeeklySlots.isNotEmpty) return;

    _currentDept = deptCode;
    _currentBatch = batch;
    _currentSection = section;
    _currentFacultyCode = facultyId;
    _userRole = role;

    await loadSchedules();
  }

  /// Fetch schedules from backend API
  Future<void> loadSchedules() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_userRole == 'FACULTY' && _currentFacultyCode != null) {
        // Faculty: Load classes assigned to teacher initials
        _allWeeklySlots = await _scheduleService.getSchedules(
          facultyCode: _currentFacultyCode,
        );
      } else {
        // Student / CR: Load classes for department, batch, and section
        _allWeeklySlots = await _scheduleService.getSchedules(
          department: _currentDept ?? 'CSE',
          batch: _currentBatch,
          section: _currentSection,
        );
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Action: CR or Faculty cancels today's class slot
  Future<bool> cancelTodayClass({
    required String slotId,
    required String reason,
    bool freeRoom = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _scheduleService.cancelTodaySlot(
        slotId: slotId,
        reason: reason,
        freeRoom: freeRoom,
      );
      await loadSchedules();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Action: CR or Faculty reschedules today's class slot
  Future<bool> rescheduleTodayClass({
    required String slotId,
    required String newStartTime,
    required String newEndTime,
    String? newRoomId,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _scheduleService.rescheduleTodaySlot(
        slotId: slotId,
        newStartTime: newStartTime,
        newEndTime: newEndTime,
        newRoomId: newRoomId,
        reason: reason,
      );
      await loadSchedules();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Action: CR or Faculty reverts today's override back to normal routine
  Future<bool> undoTodayOverride({required String slotId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _scheduleService.undoTodayOverride(slotId: slotId);
      await loadSchedules();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
