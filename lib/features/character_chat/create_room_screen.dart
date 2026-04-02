import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/models/user_friend.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _selectedFriendIds = <String>{};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isCreating = true);

    try {
      final service = ref.read(characterChatServiceProvider);
      final isGroup = _selectedFriendIds.length > 1 ||
          (_selectedFriendIds.isEmpty &&
              _nameController.text.trim().isNotEmpty);
      final type = isGroup ? 'group' : 'friend';
      final name = _nameController.text.trim();

      final roomId = await service.createRoom(
        type: type,
        name: name.isNotEmpty ? name : null,
        memberIds: [user.id, ..._selectedFriendIds],
        createdBy: user.id,
      );

      ref.invalidate(myRoomsProvider);
      if (mounted) {
        context.pop();
        context.push('/shell/chat/$roomId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final friendsAsync = ref.watch(friendsListProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'New Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: brightness == Brightness.dark
                            ? AppTheme.homeTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chat room name
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: brightness == Brightness.dark
                        ? AppTheme.glassFillHover
                        : Colors.white.withValues(alpha: 0.80),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Chat name (e.g. "Squad Chat")',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.homeTextSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Friend selection header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Add friends (optional — share the invite code later)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: brightness == Brightness.dark
                        ? AppTheme.homeTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: friendsAsync.when(
                  data: (friends) {
                    final accepted =
                        friends.where((f) => f.isAccepted).toList();
                    if (accepted.isEmpty) {
                      return Center(
                        child: Text(
                          'No friends added yet — no worries!\nCreate the chat and share the invite code.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.homeTextSecondary,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: accepted.length,
                      itemBuilder: (context, index) {
                        final friend = accepted[index];
                        final friendUserId =
                            friend.friendId(user?.id ?? '');
                        final isSelected =
                            _selectedFriendIds.contains(friendUserId);

                        return _FriendTile(
                          friend: friend,
                          friendUserId: friendUserId,
                          isSelected: isSelected,
                          brightness: brightness,
                          onToggle: () {
                            setState(() {
                              if (isSelected) {
                                _selectedFriendIds.remove(friendUserId);
                              } else {
                                _selectedFriendIds.add(friendUserId);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Failed to load friends',
                      style: GoogleFonts.inter(
                          color: AppTheme.homeTextSecondary),
                    ),
                  ),
                ),
              ),

              // Create button — always enabled
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: GestureDetector(
                  onTap: _isCreating ? null : _createRoom,
                  child: AnimatedContainer(
                    duration: AppTheme.microDuration,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusPill),
                      color: AppTheme.primaryOrange,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _selectedFriendIds.isEmpty
                                ? 'Create Chat'
                                : 'Create Chat (${_selectedFriendIds.length} selected)',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.friendUserId,
    required this.isSelected,
    required this.brightness,
    required this.onToggle,
  });

  final UserFriend friend;
  final String friendUserId;
  final bool isSelected;
  final Brightness brightness;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: isSelected
              ? AppTheme.primaryOrange.withValues(alpha: 0.12)
              : (brightness == Brightness.dark
                  ? AppTheme.glassFill
                  : Colors.white.withValues(alpha: 0.70)),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange.withValues(alpha: 0.4)
                : (brightness == Brightness.dark
                    ? AppTheme.glassBorder
                    : AppTheme.lightGlassBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    AppTheme.primaryOrange.withValues(alpha: 0.15),
              ),
              child: const Icon(PhosphorIconsFill.user,
                  color: AppTheme.primaryOrange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.friendDisplayName ?? friend.friendEmail ?? 'Friend',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: brightness == Brightness.dark
                      ? AppTheme.homeTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppTheme.microDuration,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.primaryOrange
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryOrange
                      : (brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.2)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
