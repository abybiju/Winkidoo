import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/core/widgets/cosmic_empty_state.dart';
import 'package:winkidoo/core/widgets/glass_container.dart';
import 'package:winkidoo/features/notifications/notification_router.dart';
import 'package:winkidoo/models/app_notification.dart';
import 'package:winkidoo/providers/notification_provider.dart';
import 'package:winkidoo/router/app_router.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final notificationsAsync = ref.watch(notificationsListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.glassFill,
                          border: Border.all(
                            color: AppTheme.glassBorder,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: brightness == Brightness.dark
                              ? AppTheme.textPrimary
                              : AppTheme.lightTextPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: brightness == Brightness.dark
                            ? AppTheme.textPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (unreadCount > 0)
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(notificationsNotifierProvider.notifier)
                              .markAllAsRead();
                        },
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: notificationsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load notifications',
                      style: GoogleFonts.inter(
                        color: brightness == Brightness.dark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return const CosmicEmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'No notifications yet',
                        subtitle:
                            'You\'ll see updates here when something happens in your vault.',
                      );
                    }
                    return RefreshIndicator(
                      color: AppTheme.primaryOrange,
                      onRefresh: () async {
                        ref.invalidate(notificationsListProvider);
                        await ref.read(notificationsListProvider.future);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _NotificationTile(
                            notification: notif,
                            onTap: () => _onNotificationTap(
                                context, ref, notif),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    if (!notif.isRead) {
      ref
          .read(notificationsNotifierProvider.notifier)
          .markAsRead(notif.id);
    }
    final router = ref.read(goRouterProvider);
    NotificationRouter.navigate(router, {
      'type': notif.type.dbValue,
      ...notif.data,
    });
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GlassContainer(
      onTap: onTap,
      tint: notification.isRead ? null : AppTheme.primaryOrange,
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _iconColor(notification.type).withValues(alpha: 0.12),
            ),
            child: Icon(
              _icon(notification.type),
              size: 20,
              color: _iconColor(notification.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight:
                        notification.isRead ? FontWeight.w500 : FontWeight.w700,
                    color: brightness == Brightness.dark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: brightness == Brightness.dark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeTime(notification.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: (brightness == Brightness.dark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.surpriseNew:
        return Icons.card_giftcard_rounded;
      case NotificationType.battleUpdate:
        return Icons.shield_rounded;
      case NotificationType.dare:
        return Icons.local_fire_department_rounded;
      case NotificationType.dareResult:
        return Icons.emoji_events_rounded;
      case NotificationType.miniGame:
        return Icons.sports_esports_rounded;
      case NotificationType.miniGameResult:
        return Icons.leaderboard_rounded;
      case NotificationType.campaign:
        return Icons.menu_book_rounded;
      case NotificationType.customJudgeReady:
        return Icons.theater_comedy_rounded;
      case NotificationType.seasonLaunch:
        return Icons.auto_awesome_rounded;
      case NotificationType.friendRequest:
        return Icons.person_add_rounded;
      case NotificationType.friendAccepted:
        return Icons.how_to_reg_rounded;
      case NotificationType.chatJoinRequest:
        return Icons.group_add_rounded;
      case NotificationType.chatJoinApproved:
        return Icons.check_circle_rounded;
      case NotificationType.unknown:
        return Icons.notifications_rounded;
    }
  }

  static Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.surpriseNew:
        return AppTheme.primaryOrange;
      case NotificationType.battleUpdate:
        return const Color(0xFF64B5F6);
      case NotificationType.dare:
        return const Color(0xFFFF7043);
      case NotificationType.dareResult:
        return const Color(0xFFFFD54F);
      case NotificationType.miniGame:
        return const Color(0xFF81C784);
      case NotificationType.miniGameResult:
        return const Color(0xFF81C784);
      case NotificationType.campaign:
        return const Color(0xFFBA68C8);
      case NotificationType.customJudgeReady:
        return const Color(0xFFE57373);
      case NotificationType.seasonLaunch:
        return const Color(0xFFFFD700);
      case NotificationType.friendRequest:
        return AppTheme.primaryOrange;
      case NotificationType.friendAccepted:
        return const Color(0xFF81C784);
      case NotificationType.chatJoinRequest:
        return AppTheme.primaryOrange;
      case NotificationType.chatJoinApproved:
        return const Color(0xFF81C784);
      case NotificationType.unknown:
        return AppTheme.primaryOrange;
    }
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
