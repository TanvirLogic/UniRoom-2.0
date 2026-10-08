import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/notification_item_model.dart';
import '../providers/notification_provider.dart';

/// NotificationsScreen
/// Displays in-app notification center with real-time alerts,
/// unread indicators, category badges, and quick actions.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              notifications.isEmpty
                  ? 'No alerts'
                  : '$unreadCount unread • ${notifications.length} total',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primarySky),
              onPressed: () {
                context.read<NotificationProvider>().markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          if (notifications.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
              onPressed: () => _confirmClearAll(context),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final item = notifications[index];
                return _buildNotificationCard(context, item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppColors.primarySky,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No new notifications or routine alerts for your section right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItemModel item) {
    final style = _resolveStyle(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!item.isRead) {
              context.read<NotificationProvider>().markAsRead(item.id);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.isRead ? AppColors.surface : AppColors.iceBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isRead ? AppColors.border : AppColors.borderSky,
                width: item.isRead ? 1 : 1.4,
              ),
              boxShadow: item.isRead ? null : AppColors.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.iconColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Tag + Time + Unread Dot
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: style.badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              style.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: style.iconColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatRelativeTime(item.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primarySky,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      // Body
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.body,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will remove all notification history from your device.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dCtx);
              context.read<NotificationProvider>().clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && dt.day == now.day - 1)) {
      return 'Yesterday';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]}';
    }
  }

  _TypeStyle _resolveStyle(String type) {
    switch (type.toLowerCase()) {
      case 'cancellation':
      case 'cancelled':
        return _TypeStyle(
          label: 'Cancelled',
          icon: Icons.event_busy_rounded,
          iconColor: AppColors.error,
          bgColor: const Color(0xFFFEE2E2),
          badgeColor: const Color(0xFFFEE2E2),
        );
      case 'reschedule':
      case 'rescheduled':
        return _TypeStyle(
          label: 'Rescheduled',
          icon: Icons.update_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
          badgeColor: const Color(0xFFFEF3C7),
        );
      case 'room':
        return _TypeStyle(
          label: 'Room Allocation',
          icon: Icons.meeting_room_outlined,
          iconColor: AppColors.primarySky,
          bgColor: AppColors.primaryLight,
          badgeColor: AppColors.primaryLight,
        );
      case 'classroom_notice':
      case 'notice':
        return _TypeStyle(
          label: 'Classroom Notice',
          icon: Icons.campaign_rounded,
          iconColor: AppColors.primarySky,
          bgColor: AppColors.primaryLight,
          badgeColor: AppColors.primaryLight,
        );
      case 'classroom_lecture':
      case 'lecture':
        return _TypeStyle(
          label: 'Lecture Material',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF0284C7),
          bgColor: const Color(0xFFE0F2FE),
          badgeColor: const Color(0xFFE0F2FE),
        );
      case 'announcement':
      case 'emergency':
        return _TypeStyle(
          label: 'Campus Broadcast',
          icon: Icons.campaign_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFEDE9FE),
          badgeColor: const Color(0xFFEDE9FE),
        );
      default:
        return _TypeStyle(
          label: 'Routine Update',
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.primarySky,
          bgColor: AppColors.primaryLight,
          badgeColor: AppColors.primaryLight,
        );
    }
  }
}

class _TypeStyle {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color badgeColor;

  _TypeStyle({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.badgeColor,
  });
}
