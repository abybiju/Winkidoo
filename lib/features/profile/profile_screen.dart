import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/constants/achievement_icons.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/profile/achievement_unlocked_dialog.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/providers/achievements_provider.dart';
import 'package:winkidoo/services/achievement_storage_service.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/couple_stats_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/streak_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final surprises = ref.watch(surprisesListProvider).value ?? [];
    final effectiveWinkPlus = ref.watch(effectiveWinkPlusProvider);

    final created = surprises.where((s) => s.creatorId == user?.id).length;
    final unlocked = surprises.where((s) => s.isUnlocked).length;
    final interventions =
        surprises.fold<int>(0, (sum, s) => sum + s.creatorDefenseCount);

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
                const _GameProfileCard(),
                const SizedBox(height: 16),
                _StatsCard(
                  created: created,
                  unlocked: unlocked,
                  interventions: interventions,
                ),
                const SizedBox(height: 16),
                const _YourDynamicSection(),
                const SizedBox(height: 16),
                const _ConnectionStreakSection(),
                const SizedBox(height: 16),
                const _AchievementsSection(),
                const SizedBox(height: 16),
                _TreasureArchiveCard(
                    onTap: () => context.push('/shell/treasure-archive')),
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

class _GameProfileCard extends ConsumerStatefulWidget {
  const _GameProfileCard();

  @override
  ConsumerState<_GameProfileCard> createState() => _GameProfileCardState();
}

class _GameProfileCardState extends ConsumerState<_GameProfileCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  final _formKey = GlobalKey<FormState>();
  String _gender = 'na';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final meta = ref.read(userProfileMetaProvider);
    _nameController = TextEditingController(text: meta.name);
    _ageController = TextEditingController(text: meta.age?.toString() ?? '');
    _gender = (meta.gender == 'male' ||
            meta.gender == 'female' ||
            meta.gender == 'na')
        ? meta.gender
        : 'na';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final age = int.parse(_ageController.text.trim());
      final merged = Map<String, dynamic>.from(user.userMetadata ?? const {});
      merged['name'] = _nameController.text.trim();
      merged['age'] = age;
      merged['gender'] = _gender;

      await Supabase.instance.client.auth
          .updateUser(UserAttributes(data: merged));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game profile updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = ref.watch(missingProfileFieldsProvider);
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Game Profile',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (missing.isNotEmpty)
                    Text(
                      'Missing: ${missing.join(', ')}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter name'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  final age = int.tryParse((value ?? '').trim());
                  if (age == null) return 'Enter valid age';
                  if (age < 13 || age > 120) return 'Age must be 13-120';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(
                      value: 'na', child: Text('Prefer not to say')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? 'na'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: Text(_saving ? 'Saving...' : 'Save game profile'),
                ),
              ),
            ],
          ),
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

class _YourDynamicSection extends ConsumerWidget {
  const _YourDynamicSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(coupleStatsProvider);

    return statsAsync.when(
      loading: () => Card(
        color: AppTheme.surface.withValues(alpha: 0.8),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child:
              Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ),
      error: (_, __) => Card(
        color: AppTheme.surface.withValues(alpha: 0.8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '—',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
      data: (stats) {
        if (stats.totalBattles == 0) {
          return Card(
            color: AppTheme.surface.withValues(alpha: 0.8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Complete a battle to see your dynamic',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Dynamic',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _DynamicStatCard(
                  value: '${stats.totalBattles}',
                  subtitle: 'Total Battles',
                ),
                _DynamicStatCard(
                  value: '${stats.unlockRate.toStringAsFixed(1)}%',
                  subtitle: 'Unlock Rate',
                ),
                _ToughestJudgeCard(personaId: stats.toughestJudgePersonaId),
                _DynamicStatCard(
                  value: stats.avgPersuasion.toStringAsFixed(1),
                  subtitle: 'Avg Persuasion',
                ),
                _DynamicStatCard(
                  value: stats.creatorDefenseRatio.toStringAsFixed(1),
                  subtitle: 'Creator interventions per battle',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MonthlyBarChart(monthlyBattles: stats.monthlyBattles),
          ],
        );
      },
    );
  }
}

class _DynamicStatCard extends StatelessWidget {
  const _DynamicStatCard({
    required this.value,
    required this.subtitle,
  });

  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToughestJudgeCard extends ConsumerWidget {
  const _ToughestJudgeCard({required this.personaId});

  final String personaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final judgeAsync = personaId.isEmpty
        ? null
        : ref.watch(judgeByPersonaIdProvider(personaId)).value;
    final judge =
        personaId.isEmpty ? null : (judgeAsync ?? Judge.placeholder(personaId));
    final name = judge?.name ?? '—';
    final gender = ref.watch(userProfileMetaProvider).gender;
    final judgeAsset = judge == null
        ? ''
        : JudgeAssetResolver.resolveAvatarPath(
            judge: judge, userGender: gender);

    return Card(
      color: AppTheme.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              clipBehavior: Clip.antiAlias,
              child: judgeAsset.isNotEmpty
                  ? Image.asset(
                      judgeAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.gavel_rounded),
                    )
                  : const Icon(Icons.gavel_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toughest Judge',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Month abbreviations for chart labels.
const _monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.monthlyBattles});

  final Map<String, int> monthlyBattles;

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 80.0;
    const minBarHeight = 4.0;

    final orderedKeys = monthlyBattles.keys.toList();
    if (orderedKeys.isEmpty) return const SizedBox.shrink();

    final maxCount = monthlyBattles.values.fold<int>(
      0,
      (a, b) => a > b ? a : b,
    );

    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Monthly activity',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: maxBarHeight + 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: orderedKeys.map((key) {
                  final count = monthlyBattles[key] ?? 0;
                  final height = maxCount > 0
                      ? (count / maxCount).clamp(0.0, 1.0) * maxBarHeight
                      : minBarHeight;
                  final effectiveHeight =
                      height >= minBarHeight ? height : minBarHeight;
                  final parts = key.split('-');
                  final monthIndex =
                      parts.length >= 2 ? (int.tryParse(parts[1]) ?? 1) - 1 : 0;
                  final label = monthIndex >= 0 && monthIndex < 12
                      ? _monthLabels[monthIndex]
                      : key;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: effectiveHeight,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStreakSection extends ConsumerWidget {
  const _ConnectionStreakSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      loading: () => Card(
        color: AppTheme.surface.withValues(alpha: 0.8),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child:
              Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ),
      error: (_, __) => Card(
        color: AppTheme.surface.withValues(alpha: 0.8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '—',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 20,
                color: Colors.deepOrange.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                'Connection Streak',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ConnectionStreakCard(stats: stats),
        ],
      ),
    );
  }
}

class _ConnectionStreakCard extends StatelessWidget {
  const _ConnectionStreakCard({required this.stats});

  final StreakStats stats;

  @override
  Widget build(BuildContext context) {
    final hasGlow = stats.currentStreak >= 3;
    final weekLabel = stats.currentStreak == 1 ? 'week' : 'weeks';
    final longestLabel = stats.longestStreak == 1 ? 'week' : 'weeks';

    return Card(
      elevation: hasGlow ? 2 : 0,
      shadowColor: Colors.deepOrange.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasGlow
            ? BorderSide(
                color: Colors.deepOrange.withValues(alpha: 0.5),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade100.withValues(alpha: 0.5),
              Colors.deepOrange.shade100.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${stats.currentStreak} $weekLabel',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep the spark alive.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Longest streak: ${stats.longestStreak} $longestLabel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (!stats.activeThisWeek) ...[
                const SizedBox(height: 12),
                Text(
                  'Play a battle this week to continue your streak.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementsSection extends ConsumerStatefulWidget {
  const _AchievementsSection();

  @override
  ConsumerState<_AchievementsSection> createState() =>
      _AchievementsSectionState();
}

class _AchievementsSectionState extends ConsumerState<_AchievementsSection> {
  bool _checkedAchievements = false;

  Future<void> _checkNewUnlocks(
      BuildContext context, List<Achievement> achievements) async {
    final seen = await AchievementStorageService.getSeenAchievements();
    final newlyUnlocked =
        achievements.where((a) => a.unlocked && !seen.contains(a.id)).toList();
    final firstNew = newlyUnlocked.isEmpty ? null : newlyUnlocked.first;
    if (firstNew == null || !context.mounted) return;
    final icon = achievementIcons[firstNew.id] ?? Icons.emoji_events_rounded;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) =>
          AchievementUnlockedDialog(achievement: firstNew, icon: icon),
    );
    if (context.mounted)
      await AchievementStorageService.markAsSeen(firstNew.id);
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      loading: () => Card(
        color: AppTheme.surface.withValues(alpha: 0.8),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child:
              Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ),
      error: (_, __) => Card(
        color: AppTheme.surface.withValues(alpha: 0.8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Achievements',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
      data: (achievements) {
        if (achievements.isEmpty) return const SizedBox.shrink();
        if (!_checkedAchievements) {
          _checkedAchievements = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkNewUnlocks(context, achievements);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Achievements',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final a = achievements[index];
                  return _AchievementBadge(
                    achievement: a,
                    onTap: () => _showAchievementSheet(context, a),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

void _showAchievementSheet(BuildContext context, Achievement a) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.surface.withValues(alpha: 0.98),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              a.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              a.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.achievement,
    required this.onTap,
  });

  final Achievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = achievementIcons[achievement.id] ?? Icons.emoji_events_rounded;
    final unlocked = achievement.unlocked;

    Widget circle = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unlocked
            ? AppTheme.primary.withValues(alpha: 0.2)
            : AppTheme.surface.withValues(alpha: 0.6),
        border: Border.all(
          color: unlocked
              ? AppTheme.primary
              : AppTheme.textSecondary.withValues(alpha: 0.4),
          width: unlocked ? 2 : 1,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 28,
        color: unlocked
            ? AppTheme.primary
            : AppTheme.textSecondary.withValues(alpha: 0.6),
      ),
    );

    if (!unlocked) {
      circle = Stack(
        alignment: Alignment.center,
        children: [
          circle,
          Icon(Icons.lock_rounded, size: 18, color: Colors.grey.shade700),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: circle,
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
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textSecondary),
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
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textSecondary),
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
              leading: const Icon(Icons.palette_outlined,
                  color: AppTheme.textSecondary, size: 22),
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
