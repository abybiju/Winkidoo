import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:uuid/uuid.dart';

class CoupleLinkScreen extends ConsumerStatefulWidget {
  const CoupleLinkScreen({super.key});

  @override
  ConsumerState<CoupleLinkScreen> createState() => _CoupleLinkScreenState();
}

class _CoupleLinkScreenState extends ConsumerState<CoupleLinkScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _showCreate = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createCouple() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();
      await client.from('couples').insert({
        'user_a_id': user.id,
        'invite_code': inviteCode,
      });
      ref.invalidate(coupleProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your code: $inviteCode — Share with your partner!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        setState(() => _showCreate = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinCouple() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your partner\'s code'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final raw = await client
          .from('couples')
          .select()
          .eq('invite_code', code)
          .maybeSingle();

      final res = raw is Map<String, dynamic> ? raw : null;
      if (res == null || res['user_b_id'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or already used code'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      final coupleId = res['id'];
      if (coupleId == null) return;

      await client.from('couples').update({
        'user_b_id': user.id,
        'linked_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', coupleId);

      ref.invalidate(coupleProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You\'re linked! Welcome to Winkidoo.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(supabaseClientProvider).auth.signOut();
    ref.invalidate(coupleProvider);
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundStart,
              AppTheme.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: coupleAsync.when(
            data: (couple) {
              if (couple != null && couple.isLinked) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Link with your partner',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a couple or enter your partner\'s code.',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!_showCreate) ...[
                      TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Partner code',
                          hintText: 'e.g. ABC12XYZ',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _joinCouple,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Join with code'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _showCreate = true),
                        child: const Text(
                          'Create a new couple link',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'You\'ll get a code to share. Your partner enters it to link.',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createCouple,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create couple link'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _showCreate = false),
                        child: const Text(
                          'I have a code',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ],
                    const Spacer(),
                    TextButton(
                      onPressed: _signOut,
                      child: const Text(
                        'Sign out',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            error: (_, __) => const Center(
              child: Text('Something went wrong', style: TextStyle(color: AppTheme.error)),
            ),
          ),
        ),
      ),
    );
  }
}
