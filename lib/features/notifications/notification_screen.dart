import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/notifications/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_rounded, color: AppTheme.accentGold),
            tooltip: 'Clear Notifications',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  title: Text('Clear All?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                  content: const Text('This will permanently delete all your notifications.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(notificationServiceProvider).clearAll();
                ref.invalidate(notificationsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications cleared')),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyNotifications(isDark: isDark);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _PremiumNotificationTile(
              notification: notifications[index],
              isDark: isDark,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  final bool isDark;
  const _EmptyNotifications({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumNotificationTile extends ConsumerWidget {
  final Map<String, dynamic> notification;
  final bool isDark;

  const _PremiumNotificationTile(
      {required this.notification, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isUnread = !(notification['is_read'] ?? true);
    final String type = notification['type'] ?? 'info';
    final DateTime createdAt =
        DateTime.parse(notification['created_at'] ?? DateTime.now().toString());
    final String timeAgo = DateFormat.MMMd().add_jm().format(createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? AppTheme.primaryTeal.withAlpha(50)
              : (isDark ? Colors.white10 : Colors.black.withAlpha(5)),
          width: 1.5,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ListTile(
        onTap: isUnread
            ? () async {
                await ref.read(notificationServiceProvider).markAsRead(notification['id']);
                ref.invalidate(notificationsProvider);
              }
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (type == 'upload' ? Colors.teal : Colors.amber).withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            type == 'upload'
                ? Icons.upload_file_rounded
                : Icons.info_outline_rounded,
            color: type == 'upload' ? Colors.teal : Colors.amber,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification['title'] ?? 'Notification',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeAgo,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
