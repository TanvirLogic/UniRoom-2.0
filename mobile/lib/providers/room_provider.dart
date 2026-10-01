import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

/// Broadcast Alert Model for CR Room Releases
class CrBroadcastAlert {
  final String id;
  final String roomNumber;
  final String batch;
  final String? section;
  final String reason;
  final DateTime timestamp;

  CrBroadcastAlert({
    required this.id,
    required this.roomNumber,
    required this.batch,
    this.section,
    required this.reason,
    required this.timestamp,
  });
}

/// RoomProvider
/// Manages physical rooms, live free room lookups, CR room release actions,
/// and real-time CR room broadcast notifications.
class RoomProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();

  List<RoomModel> _allRooms = [];
  List<RoomModel> _freeRooms = [];
  final List<CrBroadcastAlert> _crBroadcasts = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedBuildingFilter = 'ALL';

  RoomProvider() {
    // Add an initial sample broadcast so users immediately see how the CR broadcasting network operates
    _crBroadcasts.add(
      CrBroadcastAlert(
        id: 'initial-broadcast-1',
        roomNumber: '5030 (508)',
        batch: 'Batch 68',
        section: 'Sec A',
        reason: 'Algorithms class finished 30m early',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    );
  }

  // Getters
  List<RoomModel> get allRooms => _allRooms;
  List<RoomModel> get freeRooms => _freeRooms;
  List<CrBroadcastAlert> get crBroadcasts => List.unmodifiable(_crBroadcasts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedBuildingFilter => _selectedBuildingFilter;

  List<RoomModel> get filteredFreeRooms {
    if (_selectedBuildingFilter == 'ALL') return _freeRooms;
    return _freeRooms
        .where((r) => r.buildingName == _selectedBuildingFilter)
        .toList();
  }

  /// Load all campus rooms
  Future<void> loadRooms({String? departmentId, String? universityId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRooms = await _roomService.getRooms(
        departmentId: departmentId,
        universityId: universityId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load available rooms for 1-Tap Free Room Finder
  Future<void> loadFreeRoomsNow() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _freeRooms = await _roomService.getFreeRoomsNow();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Action: CR Frees a Room when class cancelled or ended
  Future<bool> freeRoomByCr({
    required String roomId,
    required int version,
    required String roomNumber,
    required String batch,
    String? section,
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final note = 'Freed by CR ($batch${section != null ? ' Sec $section' : ''}): ${reason ?? 'Class cancelled / ended'}';
      await _roomService.updateRoomStatus(
        roomId: roomId,
        status: 'AVAILABLE',
        version: version,
        note: note,
      );

      // Add to broadcast alert stream
      _crBroadcasts.insert(
        0,
        CrBroadcastAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          roomNumber: roomNumber,
          batch: batch,
          section: section,
          reason: reason ?? 'Class ended early',
          timestamp: DateTime.now(),
        ),
      );

      // Refresh room lists
      await loadFreeRoomsNow();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Action: CR or Faculty Claims / Books a Free Room for an Extra Class
  /// Automatically dispatches FCM push notifications to all cohort students.
  Future<bool> bookExtraClass({
    required String roomId,
    required int version,
    required String courseName,
    required String batch,
    required String section,
    String? teacherInitials,
    int durationMinutes = 90,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _roomService.bookExtraClass(
        roomId: roomId,
        version: version,
        courseName: courseName,
        batch: batch,
        section: section,
        teacherInitials: teacherInitials,
        durationMinutes: durationMinutes,
        note: note,
      );

      // Refresh room lists
      await loadFreeRoomsNow();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setBuildingFilter(String buildingName) {
    _selectedBuildingFilter = buildingName;
    notifyListeners();
  }
}
