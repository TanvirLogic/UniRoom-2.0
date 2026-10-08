import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/room_model.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../providers/schedule_provider.dart';

class FreeRoomsScreen extends StatefulWidget {
  const FreeRoomsScreen({super.key});

  @override
  State<FreeRoomsScreen> createState() => _FreeRoomsScreenState();
}

class _FreeRoomsScreenState extends State<FreeRoomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedBuilding = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadFreeRoomsNow();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomProv = context.watch<RoomProvider>();
    final freeRooms = roomProv.freeRooms;

    // Filter by building & search text
    final filtered = freeRooms.where((r) {
      final matchesBldg = _selectedBuilding == 'ALL' || r.buildingName == _selectedBuilding;
      final q = _searchController.text.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          r.roomNumber.toLowerCase().contains(q) ||
          (r.buildingName?.toLowerCase().contains(q) ?? false) ||
          r.floor.toString().contains(q);
      return matchesBldg && matchesSearch;
    }).toList();

    // Extract unique buildings
    final buildings = ['ALL', ...freeRooms.map((r) => r.buildingName).where((b) => b != null).toSet().cast<String>()];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Free Rooms Now'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh_rounded,
              color: roomProv.isLoading ? AppColors.primarySky : AppColors.textSecondary,
            ),
            onPressed: roomProv.isLoading ? null : () => roomProv.loadFreeRoomsNow(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search room number (e.g. 5030, Lab)...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primarySky, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 10),

                // Building Filter Chips
                if (buildings.length > 1)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: buildings.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final bldg = buildings[index];
                        final isSel = _selectedBuilding == bldg;
                        return ChoiceChip(
                          label: Text(bldg == 'ALL' ? 'All Buildings' : bldg),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedBuilding = bldg),
                          selectedColor: AppColors.primaryLight,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primarySky : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          side: BorderSide(color: isSel ? AppColors.primarySky : AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Count Bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 380 ? 14 : 20,
              vertical: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Available Room${filtered.length == 1 ? "" : "s"}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          MediaQuery.sizeOf(context).width < 380 ? 'Free for study' : 'Free for study / extra class',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Room Cards Grid / List
          Expanded(
            child: roomProv.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primarySky))
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primarySky,
                        onRefresh: () => roomProv.loadFreeRoomsNow(),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            MediaQuery.sizeOf(context).width < 380 ? 14 : 20,
                            8,
                            MediaQuery.sizeOf(context).width < 380 ? 14 : 20,
                            24,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildFreeRoomCard(filtered[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeRoomCard(RoomModel room) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSky, width: 1.2),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.door_front_door_rounded, color: AppColors.success, size: isCompact ? 24 : 28),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.roomNumber,
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AVAILABLE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${room.buildingName ?? "Main Building"} • Floor ${room.floor}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${room.capacity} seats capacity',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        room.freeMinutesRemaining != null
                            ? 'Free for ${room.freeMinutesRemaining}m+'
                            : 'Open Now',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primarySky),
                      ),
                    ),
                  ],
                ),
                // CR Book Extra Class Action Button
                if (context.watch<AuthProvider>().user?.isCr == true) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primarySky),
                      label: Text(
                        isCompact ? 'Book for My Section' : 'Book for My Section Class',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primarySky,
                        side: const BorderSide(color: AppColors.primarySky),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showBookExtraClassSheet(context, room),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookExtraClassSheet(BuildContext context, RoomModel room) {
    final authUser = context.read<AuthProvider>().user;
    final courseCtrl = TextEditingController(text: 'Extra Class');
    final teacherCtrl = TextEditingController();
    final batchCtrl = TextEditingController(text: authUser?.batch ?? '');
    final sectionCtrl = TextEditingController(text: authUser?.section ?? '');
    int durationMinutes = 90;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.primarySky, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Room ${room.roomNumber}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${room.buildingName ?? "Main Building"} • Capacity: ${room.capacity}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: courseCtrl,
                  decoration: InputDecoration(
                    labelText: 'Course Name / Code',
                    hintText: 'e.g. SWE-321 Software Architecture',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: batchCtrl,
                        decoration: InputDecoration(
                          labelText: 'Batch',
                          hintText: 'e.g. 68',
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
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teacherCtrl,
                  decoration: InputDecoration(
                    labelText: 'Faculty Initial (Optional)',
                    hintText: 'e.g. DNS',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Class Duration:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [45, 90, 120].map((d) {
                    final isSel = durationMinutes == d;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$d mins'),
                        selected: isSel,
                        onSelected: (_) => setSheetState(() => durationMinutes = d),
                        selectedColor: AppColors.primarySky,
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Confirm Booking & Send Push Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySky,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (courseCtrl.text.trim().isEmpty ||
                        batchCtrl.text.trim().isEmpty ||
                        sectionCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill course, batch, and section.')),
                      );
                      return;
                    }

                    Navigator.pop(sheetCtx);
                    final targetRoomId = room.id.trim().isNotEmpty ? room.id.trim() : room.roomNumber.trim();
                    final success = await context.read<RoomProvider>().bookExtraClass(
                          roomId: targetRoomId,
                          version: room.version,
                          courseName: courseCtrl.text.trim(),
                          batch: batchCtrl.text.trim(),
                          section: sectionCtrl.text.trim(),
                          teacherInitials: teacherCtrl.text.trim().isEmpty ? null : teacherCtrl.text.trim(),
                          durationMinutes: durationMinutes,
                          department: authUser?.effectiveDepartmentCode ?? 'CSE',
                        );

                    if (context.mounted) {
                      if (success) {
                        context.read<ScheduleProvider>().loadSchedules();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text(
                              'Room ${room.roomNumber} booked! Push notification broadcasted to Batch ${batchCtrl.text.trim()} (${sectionCtrl.text.trim()}).',
                            ),
                          ),
                        );
                      } else {
                        final err = context.read<RoomProvider>().errorMessage ?? 'Failed to book room';
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.meeting_room_outlined, size: 50, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Free Rooms Found Right Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'All classrooms currently have scheduled classes or are undergoing maintenance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
