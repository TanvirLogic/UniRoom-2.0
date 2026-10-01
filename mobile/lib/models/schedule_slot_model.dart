/// ScheduleSlotModel
/// Strongly-typed Dart model for Master Timetable slots returned by /api/v1/schedules.
class ScheduleSlotModel {
  final String id;
  final String departmentId;
  final String roomId;
  final String facultyInitials;
  final String batch;
  final String section;
  final String courseCode;
  final String courseName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;
  final String? roomNumber;
  final String? buildingName;
  final int? floor;
  final int? capacity;
  final String? roomStatus;
  final int? roomVersion;
  final String? facultyName;
  final bool isCancelled;
  final bool isRescheduled;
  final String? rescheduledStartTime;
  final String? rescheduledEndTime;
  final String? rescheduledRoomNumber;
  final String? overrideReason;
  final String? overrideAction;

  ScheduleSlotModel({
    required this.id,
    required this.departmentId,
    required this.roomId,
    required this.facultyInitials,
    required this.batch,
    required this.section,
    required this.courseCode,
    required this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.roomNumber,
    this.buildingName,
    this.floor,
    this.capacity,
    this.roomStatus,
    this.roomVersion,
    this.facultyName,
    this.isCancelled = false,
    this.isRescheduled = false,
    this.rescheduledStartTime,
    this.rescheduledEndTime,
    this.rescheduledRoomNumber,
    this.overrideReason,
    this.overrideAction,
  });

  factory ScheduleSlotModel.fromJson(Map<String, dynamic> json) {
    String? rNumber;
    String? bName;
    int? rFloor;
    int? rCapacity;
    String? rStatus;
    int? rVersion;

    String? rId;
    if (json['room'] is Map<String, dynamic>) {
      final r = json['room'];
      rId = r['id']?.toString();
      rNumber = r['roomNumber'];
      rFloor = r['floor'];
      rCapacity = r['capacity'];
      rStatus = r['currentStatus'];
      rVersion = r['version'];

      if (r['building'] is Map<String, dynamic>) {
        bName = r['building']['name'];
      }
    }

    String? fName;
    if (json['facultyUser'] is Map<String, dynamic>) {
      fName = json['facultyUser']['fullName'];
    }

    // Check if any override cancelled or rescheduled this slot
    bool cancelled = false;
    bool rescheduled = false;
    String? newStart;
    String? newEnd;
    String? newRoomNum;
    String? reason;
    String? action;

    if (json['overrides'] is List && (json['overrides'] as List).isNotEmpty) {
      final latest = (json['overrides'] as List).first;
      if (latest is Map<String, dynamic>) {
        action = latest['action']?.toString();
        reason = latest['reason']?.toString();
        if (action == 'CANCELLED') {
          cancelled = true;
        } else if (action == 'RESCHEDULED') {
          rescheduled = true;
          newStart = latest['newStartTime']?.toString();
          newEnd = latest['newEndTime']?.toString();
          if (latest['newRoom'] is Map<String, dynamic>) {
            newRoomNum = latest['newRoom']['roomNumber']?.toString();
          }
        }
      }
    }

    final resolvedRoomId = (json['roomId'] != null && json['roomId'].toString().isNotEmpty)
        ? json['roomId'].toString()
        : (rId ?? '');

    return ScheduleSlotModel(
      id: json['id'] ?? '',
      departmentId: json['departmentId'] ?? '',
      roomId: resolvedRoomId,
      facultyInitials: json['facultyInitials'] ?? '',
      batch: json['batch'] ?? '',
      section: json['section'] ?? '',
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 'MON',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isActive: json['isActive'] ?? true,
      roomNumber: rNumber ?? json['roomNumber'],
      buildingName: bName ?? json['buildingName'],
      floor: rFloor ?? json['floor'],
      capacity: rCapacity ?? json['capacity'],
      roomStatus: rStatus ?? json['roomStatus'],
      roomVersion: rVersion ?? json['roomVersion'] ?? 1,
      facultyName: fName ?? json['facultyName'],
      isCancelled: cancelled,
      isRescheduled: rescheduled,
      rescheduledStartTime: newStart,
      rescheduledEndTime: newEnd,
      rescheduledRoomNumber: newRoomNum,
      overrideReason: reason,
      overrideAction: action,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departmentId': departmentId,
      'roomId': roomId,
      'facultyInitials': facultyInitials,
      'batch': batch,
      'section': section,
      'courseCode': courseCode,
      'courseName': courseName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'roomNumber': roomNumber,
      'buildingName': buildingName,
      'floor': floor,
      'capacity': capacity,
      'roomStatus': roomStatus,
      'roomVersion': roomVersion,
      'facultyName': facultyName,
      'isCancelled': isCancelled,
      'isRescheduled': isRescheduled,
      'rescheduledStartTime': rescheduledStartTime,
      'rescheduledEndTime': rescheduledEndTime,
      'rescheduledRoomNumber': rescheduledRoomNumber,
      'overrideReason': overrideReason,
      'overrideAction': overrideAction,
    };
  }

  /// Effective display start time (rescheduled if active for today)
  String get effectiveStartTime =>
      (isRescheduled && rescheduledStartTime != null && rescheduledStartTime!.isNotEmpty)
          ? rescheduledStartTime!
          : startTime;

  /// Effective display end time (rescheduled if active for today)
  String get effectiveEndTime =>
      (isRescheduled && rescheduledEndTime != null && rescheduledEndTime!.isNotEmpty)
          ? rescheduledEndTime!
          : endTime;

  /// Effective display room number (rescheduled room if active for today)
  String get effectiveRoomNumber =>
      (isRescheduled && rescheduledRoomNumber != null && rescheduledRoomNumber!.isNotEmpty)
          ? rescheduledRoomNumber!
          : (roomNumber ?? 'Room TBA');

  /// Calculates slot state relative to a given TimeOfDay or DateTime
  SlotTimingState getTimingState(DateTime now) {
    if (isCancelled) return SlotTimingState.cancelled;

    final startMinutes = _parseMinutes(effectiveStartTime);
    final endMinutes = _parseMinutes(effectiveEndTime);
    final currentMinutes = now.hour * 60 + now.minute;

    if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
      return SlotTimingState.runningNow;
    } else if (currentMinutes < startMinutes) {
      final diff = startMinutes - currentMinutes;
      if (diff <= 30) {
        return SlotTimingState.upcomingSoon;
      }
      return SlotTimingState.laterToday;
    } else {
      return SlotTimingState.completed;
    }
  }

  int getMinutesUntilStart(DateTime now) {
    final startMinutes = _parseMinutes(effectiveStartTime);
    final currentMinutes = now.hour * 60 + now.minute;
    return startMinutes - currentMinutes;
  }

  int getMinutesRemaining(DateTime now) {
    final endMinutes = _parseMinutes(effectiveEndTime);
    final currentMinutes = now.hour * 60 + now.minute;
    return endMinutes - currentMinutes;
  }

  static int _parseMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (_) {}
    return 0;
  }
}

enum SlotTimingState {
  runningNow,
  upcomingSoon,
  laterToday,
  completed,
  cancelled,
}
