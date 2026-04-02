import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/models/chat_room.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';

class ChatRoomsScreen extends ConsumerWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(myRoomsProvider);
    final brightness = Theme.of(context).brightness;

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
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Character Chat',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: brightness == Brightness.dark
                              ? AppTheme.homeTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                    _ActionButton(
                      icon: PhosphorIconsBold.userPlus,
                      onTap: () => context.push('/shell/chat/add-friends'),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: PhosphorIconsBold.plusCircle,
                      onTap: () => context.push('/shell/chat/create-room'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: roomsAsync.when(
                  data: (rooms) {
                    if (rooms.isEmpty) return _EmptyState(brightness: brightness);
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _ChatRoomCard(
                          room: rooms[index],
                          onTap: () => context
                              .push('/shell/chat/${rooms[index].id}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  ),
                  error: (err, __) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Failed to load chats',
                            style: GoogleFonts.inter(
                              color: brightness == Brightness.dark
                                  ? AppTheme.homeTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$err',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.red.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.glassFill,
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsFill.chatTeardropDots,
                size: 64,
                color: AppTheme.primaryOrange.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: brightness == Brightness.dark
                    ? AppTheme.homeTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends or create a group to start chatting as your favorite characters!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: brightness == Brightness.dark
                    ? AppTheme.homeTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  const _ChatRoomCard({required this.room, required this.onTap});
  final ChatRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final displayName = room.name ?? _typeLabel(room.type);
    final icon = _typeIcon(room.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : Colors.white.withValues(alpha: 0.70),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorder
                : AppTheme.lightGlassBorder,
          ),
          boxShadow: AppTheme.elevation1(brightness),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    AppTheme.primaryOrange.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: AppTheme.primaryOrange, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (room.lastMessage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      room.lastMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: brightness == Brightness.dark
                            ? AppTheme.homeTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.primaryOrange, size: 22),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'couple':
        return 'Partner Chat';
      case 'group':
        return 'Group Chat';
      default:
        return 'Chat';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'couple':
        return PhosphorIconsFill.heart;
      case 'group':
        return PhosphorIconsFill.usersThree;
      default:
        return PhosphorIconsFill.chatTeardropDots;
    }
  }
}
