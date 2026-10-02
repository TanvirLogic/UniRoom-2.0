import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/room_model.dart';
import 'auth_service.dart';

/// RoomService
/// Interacts with the backend physical rooms and OCC live availability engine.
class RoomService {
  final AuthService _authService;

  RoomService({AuthService? authService})
      : _authService = authService ?? AuthService();

  /// Fetch all physical rooms
  Future<List<RoomModel>> getRooms({
    String? status,
    String? departmentId,
    String? buildingId,
    String? universityId,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (departmentId != null && departmentId.isNotEmpty) queryParams['departmentId'] = departmentId;
    if (buildingId != null && buildingId.isNotEmpty) queryParams['buildingId'] = buildingId;
    if (universityId != null && universityId.isNotEmpty) queryParams['universityId'] = universityId;

    final uri = Uri.parse(ApiConstants.rooms).replace(queryParameters: queryParams);
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
      dynamic data = decoded;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        data = decoded['data'];
      }
      List roomsList = [];
      if (data is Map<String, dynamic> && data['rooms'] is List) {
        roomsList = data['rooms'];
      } else if (data is List) {
        roomsList = data;
      }
      return roomsList
          .whereType<Map<String, dynamic>>()
          .map((item) => RoomModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load classrooms (Status: ${response.statusCode})');
    }
  }

  /// 1-Tap "Find Free Rooms Now"
  Future<List<RoomModel>> getFreeRoomsNow({int minMinutes = 30}) async {
    final uri = Uri.parse(ApiConstants.freeRoomsNow).replace(queryParameters: {
      'durationMinutes': minMinutes.toString(),
    });
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
      dynamic raw = decoded;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        raw = decoded['data'];
      }

      List list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        if (raw['results'] is List) {
          list = raw['results'];
        } else if (raw['rooms'] is List) {
          list = raw['rooms'];
        }
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => RoomModel.fromJson(item))
          .where((r) => r.id.isNotEmpty || r.roomNumber.isNotEmpty)
          .where((r) => r.currentStatus == 'AVAILABLE')
          .toList();
    } else {
      // Fallback to getRooms with status=AVAILABLE if free-now endpoint requires specific parameters
      return getRooms(status: 'AVAILABLE');
    }
  }

  /// Update Room Status with Optimistic Concurrency Control (OCC)
  /// Used by CRs to make a room free or report cancellation.
  Future<RoomModel> updateRoomStatus({
    required String roomId,
    required String status,
    required int version,
    String? note,
  }) async {
    final cleanId = roomId.trim();
    if (cleanId.isEmpty) {
      throw Exception('Invalid Room ID: Cannot update room state without a valid ID or room number.');
    }

    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Authentication token missing. Please log in.');

    final uri = Uri.parse(ApiConstants.roomStatus(cleanId));
    final body = {
      'status': status,
      'version': version,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      dynamic data = decoded;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        data = decoded['data'];
      }
      Map<String, dynamic> roomMap = {};
      if (data is Map<String, dynamic>) {
        if (data.containsKey('room') && data['room'] is Map<String, dynamic>) {
          roomMap = data['room'];
        } else {
          roomMap = data;
        }
      }
      return RoomModel.fromJson(roomMap);
    } else if (response.statusCode == 409) {
      throw Exception('Room status conflict. Another user updated this room simultaneously. Please refresh.');
    } else {
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map && decoded.containsKey('message') ? decoded['message'] : 'Failed to update room state';
      throw Exception(msg);
    }
  }

  /// Book a Free Room for an Extra Class
  /// Claims the room and dispatches FCM push notifications to all students of the cohort.
  Future<RoomModel> bookExtraClass({
    required String roomId,
    required int version,
    required String courseName,
    required String batch,
    required String section,
    String? teacherInitials,
    int durationMinutes = 90,
    String? note,
  }) async {
    final cleanId = roomId.trim();
    if (cleanId.isEmpty) {
      throw Exception('Invalid Room ID: Cannot book room without a valid ID or room number.');
    }

    final token = await _authService.getAccessToken();
    if (token == null) throw Exception('Authentication token missing. Please log in.');

    final uri = Uri.parse('${ApiConstants.rooms}/$cleanId/book-extra-class');
    final body = {
      'version': version,
      'courseName': courseName.trim(),
      'batch': batch.trim(),
      'section': section.trim(),
      if (teacherInitials != null && teacherInitials.trim().isNotEmpty)
        'teacherInitials': teacherInitials.trim(),
      'durationMinutes': durationMinutes,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      dynamic data = decoded;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        data = decoded['data'];
      }
      Map<String, dynamic> roomMap = {};
      if (data is Map<String, dynamic>) {
        if (data.containsKey('room') && data['room'] is Map<String, dynamic>) {
          roomMap = data['room'];
        } else {
          roomMap = data;
        }
      }
      return RoomModel.fromJson(roomMap);
    } else if (response.statusCode == 409) {
      throw Exception('OCC Conflict: Another user just modified this room. Please refresh.');
    } else {
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map && decoded.containsKey('message') ? decoded['message'] : 'Failed to book extra class';
      throw Exception(msg);
    }
  }
}
