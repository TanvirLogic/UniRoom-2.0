import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/schedule_slot_model.dart';
import 'auth_service.dart';

/// ScheduleService
/// Fetches master routine slots and active daily schedules from backend.
class ScheduleService {
  final AuthService _authService;

  ScheduleService({AuthService? authService})
      : _authService = authService ?? AuthService();

  /// Fetch schedule slots with flexible parameters
  Future<List<ScheduleSlotModel>> getSchedules({
    String? university,
    String? department,
    String? batch,
    String? section,
    String? courseCode,
    String? dayOfWeek,
    String? facultyCode,
    String? roomId,
  }) async {
    final queryParams = <String, String>{};
    if (university != null && university.isNotEmpty) queryParams['university'] = university;
    if (department != null && department.isNotEmpty) queryParams['department'] = department;
    if (batch != null && batch.isNotEmpty) queryParams['batch'] = batch;
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (courseCode != null && courseCode.isNotEmpty) queryParams['courseCode'] = courseCode;
    if (dayOfWeek != null && dayOfWeek.isNotEmpty && dayOfWeek != 'ALL') queryParams['dayOfWeek'] = dayOfWeek;
    if (facultyCode != null && facultyCode.isNotEmpty) queryParams['facultyCode'] = facultyCode;
    if (roomId != null && roomId.isNotEmpty) queryParams['roomId'] = roomId;

    final uri = Uri.parse(ApiConstants.schedules).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final token = await _authService.getAccessToken();

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final List list = decoded is Map && decoded.containsKey('data') ? decoded['data'] : (decoded is List ? decoded : []);
      return list.map((item) => ScheduleSlotModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load routine slots (Status: ${response.statusCode})');
    }
  }

  /// Cancel Today's Class Slot (Emergency CR / Faculty control)
  Future<bool> cancelTodaySlot({
    required String slotId,
    required String reason,
    bool freeRoom = true,
  }) async {
    var token = await _authService.getAccessToken();
    if (token == null) throw Exception('Authentication required. Please log in.');

    final uri = Uri.parse(ApiConstants.cancelSlotToday(slotId));
    final body = {
      'reason': reason.trim(),
      'freeRoom': freeRoom,
    };

    var response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final freshToken = await _authService.refreshToken();
      if (freshToken != null) {
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $freshToken',
          },
          body: jsonEncode(body),
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map && decoded.containsKey('message')
          ? decoded['message']
          : 'Failed to cancel class for today';
      throw Exception(msg);
    }
  }

  /// Reschedule Today's Class Slot to a new time and optional room
  Future<bool> rescheduleTodaySlot({
    required String slotId,
    required String newStartTime,
    required String newEndTime,
    String? newRoomId,
    required String reason,
  }) async {
    var token = await _authService.getAccessToken();
    if (token == null) throw Exception('Authentication required. Please log in.');

    final uri = Uri.parse(ApiConstants.rescheduleSlotToday(slotId));
    final body = {
      'newStartTime': newStartTime.trim(),
      'newEndTime': newEndTime.trim(),
      if (newRoomId != null && newRoomId.trim().isNotEmpty) 'newRoomId': newRoomId.trim(),
      'reason': reason.trim(),
    };

    var response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final freshToken = await _authService.refreshToken();
      if (freshToken != null) {
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $freshToken',
          },
          body: jsonEncode(body),
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map && decoded.containsKey('message')
          ? decoded['message']
          : 'Failed to reschedule class for today';
      throw Exception(msg);
    }
  }

  /// Undo / Revert Today's Override on a Class Slot
  Future<bool> undoTodayOverride({required String slotId}) async {
    var token = await _authService.getAccessToken();
    if (token == null) throw Exception('Authentication required. Please log in.');

    final uri = Uri.parse(ApiConstants.undoSlotOverrideToday(slotId));
    var response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      final freshToken = await _authService.refreshToken();
      if (freshToken != null) {
        response = await http.delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $freshToken',
          },
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map && decoded.containsKey('message')
          ? decoded['message']
          : 'Failed to revert schedule override';
      throw Exception(msg);
    }
  }

  /// Helper to convert standard DateTime weekday into 3-letter DayOfWeek enum
  static String getDayOfWeekString(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'MON';
      case DateTime.tuesday:
        return 'TUE';
      case DateTime.wednesday:
        return 'WED';
      case DateTime.thursday:
        return 'THU';
      case DateTime.friday:
        return 'FRI';
      case DateTime.saturday:
        return 'SAT';
      case DateTime.sunday:
        return 'SUN';
      default:
        return 'MON';
    }
  }
}
