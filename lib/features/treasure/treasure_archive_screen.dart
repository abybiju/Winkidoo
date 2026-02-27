import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/treasure_archive.dart';
import 'package:winkidoo/providers/treasure_archive_provider.dart';

class TreasureArchiveScreen extends ConsumerWidget {
  const TreasureArchiveScreen({super.key});

  static String _personaDisplayName(String id) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = ref.watch(treasureArchiveListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treasure Archive'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: archive.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 64,
                        color: AppTheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No treasures yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep battles in Treasure after you win to revisit them here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final item = list[i];
                return _ArchiveCard(
                  item: item,
                  onTap: () {},
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load archive',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(treasureArchiveListProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.item, required this.onTap});

  final TreasureArchive item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.emoji_events_rounded, color: AppTheme.accent),
        title: Text(
          TreasureArchiveScreen._personaDisplayName(item.judgePersona),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${item.attemptsCount} attempts · ${item.creatorInterventionsCount} interventions',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Text(
          _formatDate(item.archivedAt),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
