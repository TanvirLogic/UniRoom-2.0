/// RoomModel
/// Strongly-typed Dart representation of physical classroom or laboratory.
class RoomModel {
  final String id;
  final String roomNumber;
  final int floor;
  final int capacity;
  final String currentStatus; // AVAILABLE, RUNNING_CLASS, RESERVED, MAINTENANCE
  final int version;
  final String? buildingId;
  final String? buildingName;
  final String? campusName;
  final String? departmentId;
  final String? departmentCode;
  final int? freeMinutesRemaining;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.capacity,
    required this.currentStatus,
    required this.version,
    this.buildingId,
    this.buildingName,
    this.campusName,
    this.departmentId,
    this.departmentCode,
    this.freeMinutesRemaining,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> target = json;
    int? freeMins = json['freeMinutesRemaining'] ?? json['minutesUntilNextClass'];

    // Unpack if response is wrapped as { room: { ... }, freeMinutesRemaining: 60 }
    if (json.containsKey('room') && json['room'] is Map<String, dynamic>) {
      target = json['room'] as Map<String, dynamic>;
      freeMins ??= target['freeMinutesRemaining'] ?? target['minutesUntilNextClass'];
    }

    String? bName;
    String? cName;
    if (target['building'] is Map<String, dynamic>) {
      bName = target['building']['name'];
      cName = target['building']['campusName'];
    }

    String? dCode;
    if (target['department'] is Map<String, dynamic>) {
      dCode = target['department']['code'];
    }

    final rawId = target['id']?.toString() ?? '';
    final rawNumber = target['roomNumber']?.toString() ?? '';

    return RoomModel(
      id: rawId.isNotEmpty ? rawId : rawNumber,
      roomNumber: rawNumber.isNotEmpty ? rawNumber : rawId,
      floor: (target['floor'] is num) ? (target['floor'] as num).toInt() : 0,
      capacity: (target['capacity'] is num) ? (target['capacity'] as num).toInt() : 0,
      currentStatus: target['currentStatus']?.toString() ?? 'AVAILABLE',
      version: (target['version'] is num) ? (target['version'] as num).toInt() : 1,
      buildingId: target['buildingId']?.toString(),
      buildingName: bName ?? target['buildingName']?.toString(),
      campusName: cName ?? target['campusName']?.toString(),
      departmentId: target['departmentId']?.toString(),
      departmentCode: dCode ?? target['departmentCode']?.toString(),
      freeMinutesRemaining: freeMins,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'floor': floor,
      'capacity': capacity,
      'currentStatus': currentStatus,
      'version': version,
      'buildingId': buildingId,
      'buildingName': buildingName,
      'campusName': campusName,
      'departmentId': departmentId,
      'departmentCode': departmentCode,
      'freeMinutesRemaining': freeMinutesRemaining,
    };
  }

  bool get isAvailable => currentStatus == 'AVAILABLE';
  bool get isRunningClass => currentStatus == 'RUNNING_CLASS';
  bool get isReserved => currentStatus == 'RESERVED';
  bool get isMaintenance => currentStatus == 'MAINTENANCE';
}
