import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final surprises = ref.watch(surprisesListProvider).value ?? [];
    final effectiveWinkPlus = ref.watch(effectiveWinkPlusProvider);

    final created = surprises.where((s) => s.creatorId == user?.id).length;
    final unlocked = surprises.where((s) => s.isUnlocked).length;
    final interventions = surprises.fold<int>(0, (sum, s) => sum + s.creatorDefenseCount);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UserHeader(user: user),
                const SizedBox(height: 24),
                _StatsCard(
                  created: created,
                  unlocked: unlocked,
                  interventions: interventions,
                ),
                const SizedBox(height: 16),
                _TreasureArchiveCard(onTap: () => context.push('/shell/treasure-archive')),
                const SizedBox(height: 16),
                _SubscriptionCard(
                  isWinkPlus: effectiveWinkPlus,
                  onTap: () => context.push('/shell/wink-plus'),
                ),
                const SizedBox(height: 16),
                _SettingsCard(),
                const SizedBox(height: 24),
                _LogoutButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
          child: Text(
            initial,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email.isNotEmpty ? email : 'Signed in',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Winkidoo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.created,
    required this.unlocked,
    required this.interventions,
  });

  final int created;
  final int unlocked;
  final int interventions;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relationship stats',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _StatRow(label: 'Surprises created', value: created),
            _StatRow(label: 'Unlocked', value: unlocked),
            _StatRow(label: 'Creator interventions', value: interventions),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureArchiveCard extends StatelessWidget {
  const _TreasureArchiveCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
        title: Text(
          'View Treasure Archive',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.isWinkPlus,
    required this.onTap,
  });

  final bool isWinkPlus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isWinkPlus
          ? AppTheme.primary.withValues(alpha: 0.2)
          : AppTheme.surface.withValues(alpha: 0.8),
      child: ListTile(
        leading: Icon(
          isWinkPlus ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isWinkPlus ? AppTheme.accent : AppTheme.textSecondary,
        ),
        title: Text(
          isWinkPlus ? 'Wink+ active' : 'Free tier',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          isWinkPlus ? 'Premium benefits' : 'Upgrade for more',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined, color: AppTheme.textSecondary, size: 22),
              title: Text(
                'Theme',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Light / Dark / System',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text('Log out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.error,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
