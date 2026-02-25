import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/vault/create_surprise_screen.dart';
import 'package:winkidoo/features/vault/wink_plus_screen.dart';
import 'package:winkidoo/features/battle/battle_chat_screen.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/winks_provider.dart';

class VaultListScreen extends ConsumerStatefulWidget {
  const VaultListScreen({super.key});

  @override
  ConsumerState<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends ConsumerState<VaultListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(surprisesListProvider);
      ref.invalidate(coupleProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime?>(partnerAddedSurpriseAtProvider, (prev, next) {
      if (next != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your partner added a surprise'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(partnerAddedSurpriseAtProvider.notifier).state = null;
      }
    });

    final surprisesAsync = ref.watch(surprisesListProvider);
    final winksAsync = ref.watch(winksBalanceProvider);
    final user = ref.watch(currentUserProvider);
    final coupleAsync = ref.watch(coupleProvider);
    final couple = coupleAsync.value;
    final showWaitingBanner =
        couple != null && !couple.isLinked;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const WinkPlusScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: couple?.isWinkPlus == true
                                  ? AppTheme.accent.withValues(alpha: 0.3)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              couple?.isWinkPlus == true ? 'Wink+ ✓' : 'Wink+',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        winksAsync.when(
                          data: (w) => Text(
                            '${w?.balance ?? 0} 😉',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: AppTheme.accent,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showWaitingBanner) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WaitingForPartnerBanner(inviteCode: couple.inviteCode),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: surprisesAsync.when(
                  data: (surprises) {
                    final forMe = surprises
                        .where((s) =>
                            s.creatorId != user?.id &&
                            !s.isUnlocked)
                        .toList();
                    final myVault = surprises
                        .where((s) => s.creatorId == user?.id)
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        if (forMe.isNotEmpty) ...[
                          Text(
                            'Waiting for you',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...forMe.map((s) => _SurpriseCard(
                                surprise: s,
                                isForMe: true,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BattleChatScreen(
                                      surpriseId: s.id,
                                    ),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Your vault',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...myVault.map((s) => _MyVaultCard(surprise: s)),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Could not load surprises',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateSurpriseScreen(),
          ),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Hide a surprise'),
      ),
    );
  }
}

class _MyVaultCard extends ConsumerWidget {
  const _MyVaultCard({required this.surprise});

  final Surprise surprise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBattle = ref.watch(hasActiveBattleProvider(surprise.id));

    return hasBattle.when(
      data: (active) => _SurpriseCard(
        surprise: surprise,
        isForMe: false,
        subtitle: active ? 'Battle in progress — tap to join' : null,
        onTap: active
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BattleChatScreen(surpriseId: surprise.id),
                  ),
                )
            : () {},
      ),
      loading: () => _SurpriseCard(
        surprise: surprise,
        isForMe: false,
        onTap: () {},
      ),
      error: (_, __) => _SurpriseCard(
        surprise: surprise,
        isForMe: false,
        onTap: () {},
      ),
    );
  }
}

class _WaitingForPartnerBanner extends StatelessWidget {
  const _WaitingForPartnerBanner({required this.inviteCode});

  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Waiting for your partner',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with your partner:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      inviteCode,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurpriseCard extends StatelessWidget {
  const _SurpriseCard({
    required this.surprise,
    required this.isForMe,
    required this.onTap,
    this.subtitle,
  });

  final Surprise surprise;
  final bool isForMe;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final personaLabel = _personaLabel(surprise.judgePersona);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isForMe ? '🎁' : '🔒',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isForMe ? 'Unlock this!' : 'Your surprise',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ?? 'Judge: $personaLabel',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtitle != null
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isForMe || subtitle != null)
                const Icon(Icons.chevron_right, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  String _personaLabel(String id) {
    switch (id) {
      case AppConstants.personaSassyCupid:
        return 'Sassy Cupid';
      case AppConstants.personaPoeticRomantic:
        return 'Poetic Romantic';
      case AppConstants.personaChaosGremlin:
        return 'Chaos Gremlin';
      case AppConstants.personaTheEx:
        return 'The Ex';
      case AppConstants.personaDrLove:
        return 'Dr. Love';
      default:
        return id;
    }
  }
}
