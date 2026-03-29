import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/models/custom_judge.dart';
import 'package:winkidoo/providers/custom_judge_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/custom_judge_service.dart';

class MyJudgesScreen extends ConsumerWidget {
  const MyJudgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final judgesAsync = ref.watch(myCustomJudgesProvider);

    return Scaffold(
      body: CosmicBackground(
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text('My Judges',
                        style: GoogleFonts.inter(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppTheme.homeTextPrimary,
                        )),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: AppTheme.primaryOrange),
                      onPressed: () => context.push('/shell/create-judge'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Manage your custom judges. Toggle "In Battle" to add them to your judge selection.',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.homeTextSecondary, height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: judgesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                  ),
                  error: (_, __) => Center(
                    child: Text('Could not load judges.',
                        style: GoogleFonts.inter(color: AppTheme.textMuted)),
                  ),
                  data: (judges) {
                    if (judges.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎭', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No custom judges yet.',
                                style: GoogleFonts.inter(color: AppTheme.textMuted)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => context.push('/shell/create-judge'),
                              icon: const Icon(Icons.add_rounded,
                                  color: AppTheme.primaryOrange),
                              label: Text('Create Your First Judge',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: judges.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _MyJudgeCard(
                        judge: judges[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyJudgeCard extends ConsumerStatefulWidget {
  const _MyJudgeCard({required this.judge});

  final CustomJudge judge;

  @override
  ConsumerState<_MyJudgeCard> createState() => _MyJudgeCardState();
}

class _MyJudgeCardState extends ConsumerState<_MyJudgeCard> {
  bool _loading = false;

  Future<void> _toggleBattlefield() async {
    setState(() => _loading = true);
    final client = ref.read(supabaseClientProvider);
    final newVal = !(widget.judge.isActiveForBattle);
    await client
        .from('custom_judges')
        .update({'is_active_for_battle': newVal})
        .eq('id', widget.judge.id);
    ref.invalidate(myCustomJudgesProvider);
    ref.invalidate(availableCustomJudgesProvider);
    setState(() => _loading = false);
    HapticFeedback.lightImpact();
  }

  Future<void> _togglePublish() async {
    final client = ref.read(supabaseClientProvider);
    if (widget.judge.isPublished) {
      await CustomJudgeService.unpublishJudge(client, widget.judge.id);
    } else {
      final success = await CustomJudgeService.publishJudgeUnique(
          client, widget.judge.id, widget.judge.personalityName);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This personality already exists in the marketplace.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }
    ref.invalidate(myCustomJudgesProvider);
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 400, imageQuality: 85);
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id ?? 'unknown';
    final path = 'custom_judges/$userId/${widget.judge.id}.jpg';
    await client.storage.from('surprises').uploadBinary(path, bytes,
        fileOptions: const FileOptions(upsert: true));
    await client
        .from('custom_judges')
        .update({'avatar_storage_path': path})
        .eq('id', widget.judge.id);
    ref.invalidate(myCustomJudgesProvider);
  }

  Future<void> _deleteJudge() async {
    if (widget.judge.isPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unpublish the judge first before deleting.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface2,
        title: Text('Delete ${widget.judge.personalityName}?',
            style: GoogleFonts.inter(color: AppTheme.homeTextPrimary)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.inter(color: AppTheme.homeTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final client = ref.read(supabaseClientProvider);
    await CustomJudgeService.deleteJudge(client, widget.judge.id);
    ref.invalidate(myCustomJudgesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final j = widget.judge;
    final moods = j.mood.split('+');
    final moodLabel = moods.map((m) => m[0].toUpperCase() + m.substring(1)).join(' + ');
    final hasAvatar = j.avatarStoragePath != null && j.avatarStoragePath!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        color: brightness == Brightness.dark
            ? AppTheme.glassFill
            : AppTheme.lightGlassFill,
        border: Border.all(
          color: j.isActiveForBattle
              ? AppTheme.primaryOrange.withValues(alpha: 0.4)
              : (brightness == Brightness.dark
                  ? AppTheme.glassBorder
                  : AppTheme.lightGlassBorder),
          width: j.isActiveForBattle ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + moods
          Row(
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.glassFillHover,
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: hasAvatar
                      ? FutureBuilder<String>(
                          future: Supabase.instance.client.storage
                              .from('surprises')
                              .createSignedUrl(j.avatarStoragePath!, 3600),
                          builder: (ctx, snap) {
                            if (!snap.hasData) {
                              return Center(
                                child: Text(j.avatarEmoji,
                                    style: const TextStyle(fontSize: 24)),
                              );
                            }
                            return ClipOval(
                              child: Image.network(snap.data!,
                                  width: 48, height: 48, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(j.avatarEmoji,
                                        style: const TextStyle(fontSize: 24)),
                                  )),
                            );
                          },
                        )
                      : Center(
                          child: Text(j.avatarEmoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.personalityName,
                        style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppTheme.homeTextPrimary,
                        )),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(moodLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textOrangeAccent,
                              fontWeight: FontWeight.w500,
                            )),
                        if (j.isPublished) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('PUBLIC',
                                style: GoogleFonts.poppins(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  color: AppTheme.success,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action row
          Row(
            children: [
              // In Battle toggle
              Expanded(
                child: GestureDetector(
                  onTap: _loading ? null : _toggleBattlefield,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: j.isActiveForBattle
                          ? AppTheme.primaryOrange.withValues(alpha: 0.15)
                          : AppTheme.glassFill,
                      border: Border.all(
                        color: j.isActiveForBattle
                            ? AppTheme.primaryOrange
                            : AppTheme.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          j.isActiveForBattle
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 16,
                          color: j.isActiveForBattle
                              ? AppTheme.primaryOrange
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          j.isActiveForBattle ? 'In Battle' : 'Add to Battle',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: j.isActiveForBattle
                                ? AppTheme.primaryOrange
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Publish toggle
              _ActionIcon(
                icon: j.isPublished
                    ? Icons.public_off_rounded
                    : Icons.public_rounded,
                color: j.isPublished ? AppTheme.textMuted : AppTheme.success,
                tooltip: j.isPublished ? 'Unpublish' : 'Publish',
                onTap: _togglePublish,
              ),
              const SizedBox(width: 6),
              // Change avatar
              _ActionIcon(
                icon: Icons.camera_alt_rounded,
                color: AppTheme.textMuted,
                tooltip: 'Change Photo',
                onTap: _changeAvatar,
              ),
              const SizedBox(width: 6),
              // Delete
              _ActionIcon(
                icon: Icons.delete_outline_rounded,
                color: j.isPublished ? AppTheme.glassBorder : AppTheme.error,
                tooltip: 'Delete',
                onTap: _deleteJudge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon, required this.color,
    required this.tooltip, required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.glassFill,
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
