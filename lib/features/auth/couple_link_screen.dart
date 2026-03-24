import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/models/couple.dart';
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

      // Check for an existing unlinked couple where this user is the creator
      final existing = await client
          .from('couples')
          .select()
          .eq('user_a_id', user.id)
          .isFilter('user_b_id', null)
          .maybeSingle();

      Couple couple;
      if (existing is Map<String, dynamic>) {
        // Reuse the existing unlinked couple
        couple = Couple.fromJson(existing);
        debugPrint('createCouple: reusing existing code ${couple.inviteCode}');
      } else {
        // Create a new couple
        final inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();
        final result = await client.from('couples').insert({
          'user_a_id': user.id,
          'invite_code': inviteCode,
        }).select().single();
        couple = Couple.fromJson(result as Map<String, dynamic>);
        debugPrint('createCouple: created new code ${couple.inviteCode}');
      }

      ref.read(coupleProvider.notifier).setCouple(couple);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your code: ${couple.inviteCode} — Share with your partner!'),
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

      final raw = await client.rpc('join_couple_by_code', params: {
        'p_invite_code': code,
        'p_user_id': user.id,
      });

      debugPrint('joinCouple: code="$code" rawType=${raw.runtimeType} raw=$raw');

      Map<String, dynamic>? res;
      final r = raw as Object?;
      if (r is Map<String, dynamic>) {
        res = r;
      } else if (r is String) {
        try {
          final decoded = Map<String, dynamic>.from(
            (const JsonDecoder().convert(r)) as Map,
          );
          res = decoded;
        } catch (_) {}
      }

      if (res == null) {
        debugPrint('joinCouple: unexpected response');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong. Try again.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      if (res['error'] != null) {
        final err = res['error'] as String;
        final msg = switch (err) {
          'not_found' => 'Code not found. Check the code and try again.',
          'already_used' || 'expired' => 'This code is already used.',
          'own_code' => 'This is your invite code — share it with your partner.',
          _ => 'Something went wrong ($err).',
        };
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
          );
        }
        return;
      }

      final couple = Couple.fromJson(res);
      ref.read(coupleProvider.notifier).setCouple(couple);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You\'re linked! Welcome to Winkidoo.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('joinCouple error: $e');
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
      body: CosmicBackground(
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: coupleAsync.when(
            data: (couple) {
              if (couple != null && couple.isLinked) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/shell/vault');
                });
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
            loading: () => _CoupleLinkLoadingBody(),
            error: (_, __) => const Center(
              child: Text('Something went wrong', style: TextStyle(color: AppTheme.error)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading state with timeout: after [kCoupleLoadTimeout] shows retry.
class _CoupleLinkLoadingBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CoupleLinkLoadingBody> createState() => _CoupleLinkLoadingBodyState();
}

const Duration kCoupleLoadTimeout = Duration(seconds: 8);

class _CoupleLinkLoadingBodyState extends ConsumerState<_CoupleLinkLoadingBody> {
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(kCoupleLoadTimeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    ref.invalidate(coupleProvider);
    setState(() => _timedOut = false);
    _timer?.cancel();
    _timer = Timer(kCoupleLoadTimeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Taking too long?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }
}
