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
  bool _isSearching = false;
  String? _statusMessage;
  List<Map<String, dynamic>> _results = [];
  final Set<String> _requested = {};

  @override
  void dispose() {
    _searchController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final res = await ref.read(friendServiceProvider).searchUsers(q);
      if (mounted) setState(() => _results = res);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendRequest(String toUserId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _requested.add(toUserId));
    try {
      await ref
          .read(friendServiceProvider)
          .sendFriendRequest(user.id, toUserId);
      ref.invalidate(pendingFriendRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requested.remove(toUserId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send request: $e')),
        );
      }
    }
  }

  Future<void> _accept(String friendshipId) async {
    try {
      await ref.read(friendServiceProvider).acceptFriendRequest(friendshipId);
      ref.invalidate(incomingFriendRequestsProvider);
      ref.invalidate(pendingFriendRequestsProvider);
      ref.invalidate(friendsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept request: $e')),
        );
      }
    }
  }

  Future<void> _decline(String friendshipId) async {
    try {
      await ref.read(friendServiceProvider).removeFriend(friendshipId);
      ref.invalidate(incomingFriendRequestsProvider);
      ref.invalidate(pendingFriendRequestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decline request: $e')),
        );
      }
    }
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

  String _nameFor(String userId, Map<String, Map<String, dynamic>> dir) {
    final p = dir[userId];
    final name = (p?['display_name'] as String?)?.trim();
    return (name != null && name.isNotEmpty) ? name : 'Winkidoo user';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final friendsAsync = ref.watch(friendsListProvider);
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final directory = ref.watch(friendDirectoryProvider).value ?? {};
    final myId = ref.watch(currentUserProvider)?.id ?? '';

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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Friends',
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

                // Find friends by name
                _SectionCard(
                  brightness: brightness,
                  icon: PhosphorIconsFill.magnifyingGlass,
                  title: 'Find friends',
                  child: Column(
                    children: [
                      _GlassField(
                        brightness: brightness,
                        controller: _searchController,
                        hint: 'Search by name...',
                        onChanged: (_) => _search(),
                        suffix: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryOrange),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      ..._results.map((r) {
                        final uid = r['user_id'] as String;
                        final name = (r['display_name'] as String?) ?? 'User';
                        final already = _requested.contains(uid);
                        return _PersonRow(
                          brightness: brightness,
                          name: name,
                          trailing: TextButton(
                            onPressed: already ? null : () => _sendRequest(uid),
                            child: Text(already ? 'Sent' : 'Add'),
                          ),
                        );
                      }),
                      if (_results.isEmpty &&
                          _searchController.text.trim().length >= 2 &&
                          !_isSearching)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('No users found',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.homeTextSecondary)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Incoming requests
                incomingAsync.maybeWhen(
                  data: (reqs) => reqs.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SectionCard(
                            brightness: brightness,
                            icon: PhosphorIconsFill.userPlus,
                            title: 'Requests (${reqs.length})',
                            child: Column(
                              children: reqs.map((f) {
                                final other = f.friendId(myId);
                                return _PersonRow(
                                  brightness: brightness,
                                  name: _nameFor(other, directory),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle,
                                            color: AppTheme.primaryOrange),
                                        onPressed: () => _accept(f.id),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.cancel,
                                            color: AppTheme.homeTextSecondary),
                                        onPressed: () => _decline(f.id),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),

                // Friends list
                _SectionCard(
                  brightness: brightness,
                  icon: PhosphorIconsFill.users,
                  title: 'Your friends',
                  child: friendsAsync.when(
                    data: (friends) {
                      if (friends.isEmpty) {
                        return Text(
                          'No friends yet. Search by name above and send a request!',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppTheme.homeTextSecondary),
                        );
                      }
                      return Column(
                        children: friends.map((f) {
                          return _PersonRow(
                            brightness: brightness,
                            name: _nameFor(f.friendId(myId), directory),
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
                    error: (_, __) => Text('Failed to load friends',
                        style:
                            GoogleFonts.inter(color: AppTheme.homeTextSecondary)),
                  ),
                ),
                const SizedBox(height: 16),

                // Join a chat by code (chat is open to anyone with the code)
                _SectionCard(
                  brightness: brightness,
                  icon: PhosphorIconsFill.linkSimple,
                  title: 'Join a chat by code',
                  child: Column(
                    children: [
                      _GlassField(
                        brightness: brightness,
                        controller: _inviteCodeController,
                        hint: 'Paste chat code...',
                      ),
                      if (_statusMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_statusMessage!,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.redAccent)),
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
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Join Chat',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                        ),
                      ),
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
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.brightness,
    required this.name,
    this.trailing,
  });

  final Brightness brightness;
  final String name;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryOrange.withValues(alpha: 0.15),
            ),
            child: const Icon(PhosphorIconsFill.user,
                color: AppTheme.primaryOrange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: brightness == Brightness.dark
                    ? AppTheme.homeTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.brightness,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.suffix,
  });

  final Brightness brightness;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: brightness == Brightness.dark
            ? AppTheme.glassFillHover
            : Colors.white.withValues(alpha: 0.80),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: brightness == Brightness.dark
              ? AppTheme.homeTextPrimary
              : AppTheme.lightTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 15, color: AppTheme.homeTextSecondary),
          border: InputBorder.none,
          suffixIcon: suffix,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
