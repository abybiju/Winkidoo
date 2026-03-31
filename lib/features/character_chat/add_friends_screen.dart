import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';

class AddFriendsScreen extends ConsumerStatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  ConsumerState<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends ConsumerState<AddFriendsScreen> {
  final _searchController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isSending = false;
  String? _statusMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinByCode() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isSending = true;
      _statusMessage = null;
    });

    try {
      final service = ref.read(characterChatServiceProvider);
      final roomId = await service.joinRoomByCode(code, user.id);
      if (roomId != null) {
        ref.invalidate(myRoomsProvider);
        if (mounted) {
          context.pop();
          context.push('/shell/chat/$roomId');
        }
      } else {
        setState(() => _statusMessage = 'Invalid invite code');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Failed to join chat');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Friends',
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
                const SizedBox(height: 24),

                // Join by invite code
                _SectionCard(
                  brightness: brightness,
                  icon: PhosphorIconsFill.linkSimple,
                  title: 'Join via Invite Code',
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: brightness == Brightness.dark
                              ? AppTheme.glassFillHover
                              : Colors.white.withValues(alpha: 0.80),
                        ),
                        child: TextField(
                          controller: _inviteCodeController,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: brightness == Brightness.dark
                                ? AppTheme.homeTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Paste invite code...',
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
                      if (_statusMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _statusMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _isSending ? null : _joinByCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                            color: AppTheme.primaryOrange,
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Join Chat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Friends list
                _SectionCard(
                  brightness: brightness,
                  icon: PhosphorIconsFill.users,
                  title: 'Your Friends',
                  child: friendsAsync.when(
                    data: (friends) {
                      if (friends.isEmpty) {
                        return Text(
                          'No friends yet. Share an invite code from a chat room to connect!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.homeTextSecondary,
                          ),
                        );
                      }
                      return Column(
                        children: friends.map((f) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primaryOrange
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(
                                    PhosphorIconsFill.user,
                                    color: AppTheme.primaryOrange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    f.friendDisplayName ?? f.friendEmail ?? 'Friend',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: brightness == Brightness.dark
                                          ? AppTheme.homeTextPrimary
                                          : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                if (f.isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusPill),
                                      color: AppTheme.premiumAmber
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: Text(
                                      'Pending',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.premiumAmber,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 40,
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primaryOrange),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Failed to load friends',
                      style: GoogleFonts.inter(color: AppTheme.homeTextSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.brightness,
    required this.icon,
    required this.title,
    required this.child,
  });

  final Brightness brightness;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: brightness == Brightness.dark
                      ? AppTheme.homeTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
