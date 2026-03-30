import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/core/widgets/stagger_entrance.dart';
import 'package:winkidoo/models/custom_judge.dart';
import 'package:winkidoo/features/judges/custom_judge_audition_sheet.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/custom_judge_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/custom_judge_service.dart';
import 'package:winkidoo/services/rate_limit_service.dart';

const _geminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
const _tavilyApiKey =
    String.fromEnvironment('TAVILY_API_KEY', defaultValue: '');

class CreateCustomJudgeScreen extends ConsumerStatefulWidget {
  const CreateCustomJudgeScreen({super.key});

  @override
  ConsumerState<CreateCustomJudgeScreen> createState() =>
      _CreateCustomJudgeScreenState();
}

class _CreateCustomJudgeScreenState
    extends ConsumerState<CreateCustomJudgeScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedMoods = {'funny'};
  Uint8List? _avatarBytes;
  int _step = 0; // 0=name, 1=mood, 2=generating, 3=preview, 4=saved
  String _generatingStatus = ''; // searching, generating, ready
  CustomJudge? _createdJudge;
  String? _error;
  int _remainingToday = 3;

  @override
  void initState() {
    super.initState();
    _checkRateLimit();
  }

  Future<void> _checkRateLimit() async {
    final couple = ref.read(coupleProvider).value;
    if (couple == null) return;
    final client = ref.read(supabaseClientProvider);
    final (_, remaining) =
        await RateLimitService.canCreateCustomJudge(client, couple.id);
    if (mounted) setState(() => _remainingToday = remaining);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 400, imageQuality: 85);
    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      setState(() => _avatarBytes = bytes);

      // Upload to Supabase Storage if judge already created
      if (_createdJudge != null) {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id ?? 'unknown';
        final path = '$userId/${_createdJudge!.id}.jpg';
        await client.storage.from('judge-avatars').uploadBinary(path, bytes,
            fileOptions: const FileOptions(upsert: true));
        final storagePath = 'judge-avatars:$path';
        await client
            .from('custom_judges')
            .update({'avatar_storage_path': storagePath})
            .eq('id', _createdJudge!.id);
        ref.invalidate(myCustomJudgesProvider);
      }
    }
  }

  Future<void> _deleteJudge() async {
    if (_createdJudge == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface2,
        title: Text('Delete Judge?',
            style: GoogleFonts.inter(color: AppTheme.homeTextPrimary)),
        content: Text('This will permanently delete ${_createdJudge!.personalityName}.',
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
    await CustomJudgeService.deleteJudge(client, _createdJudge!.id);
    ref.invalidate(myCustomJudgesProvider);
    if (mounted) context.pop();
  }

  void _showPublishDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        return Container(
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? AppTheme.surface2
                : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Share with the community?',
                      style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppTheme.homeTextPrimary,
                      )),
                  const SizedBox(height: 6),
                  Text('Let other couples use your ${_createdJudge?.personalityName ?? ''} judge!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.homeTextSecondary,
                      )),
                  const SizedBox(height: 24),
                  // Add to Marketplace
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                            colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB]),
                      ),
                      child: MaterialButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final client = ref.read(supabaseClientProvider);
                          final success = await CustomJudgeService.publishJudgeUnique(
                              client, _createdJudge!.id, _createdJudge!.personalityName);
                          ref.invalidate(myCustomJudgesProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Published to marketplace!'
                                    : 'This personality already exists in the marketplace.'),
                                backgroundColor: success ? AppTheme.success : AppTheme.error,
                              ),
                            );
                            context.pop();
                          }
                        },
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        child: Text('Add to Marketplace',
                            style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: const Color(0xFF4A2800),
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Maybe Later
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text('Maybe Later',
                          style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: AppTheme.homeTextPrimary,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final couple = ref.read(coupleProvider).value;
    if (couple == null) {
      setState(() { _error = 'No couple found.'; });
      return;
    }

    // Rate limit check
    final client = ref.read(supabaseClientProvider);
    final (canCreate, remaining) =
        await RateLimitService.canCreateCustomJudge(client, couple.id);
    if (!canCreate) {
      setState(() {
        _error = 'Daily limit reached (3 per day). Try again tomorrow!';
        _remainingToday = 0;
      });
      return;
    }

    setState(() { _step = 2; _error = null; _generatingStatus = 'searching'; });
    HapticFeedback.lightImpact();

    final judge = await CustomJudgeService.createJudge(
      client,
      _geminiApiKey,
      coupleId: couple.id,
      personalityName: name,
      mood: _selectedMoods.join('+'),
      tavilyApiKey: _tavilyApiKey,
      onStatusUpdate: (status) {
        if (mounted) setState(() => _generatingStatus = status);
      },
    );

    if (judge == null) {
      setState(() {
        _step = 0;
        _error = 'Could not create this judge. Try a different personality.';
      });
      return;
    }

    ref.invalidate(myCustomJudgesProvider);
    setState(() {
      _createdJudge = judge;
      _step = 3;
      _remainingToday = remaining - 1;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 16),

                // Title
                Center(
                  child: Column(
                    children: [
                      Text('Create Your Judge',
                          style: GoogleFonts.inter(
                            fontSize: 26, fontWeight: FontWeight.w800,
                            color: AppTheme.homeTextPrimary, letterSpacing: -0.5,
                          )),
                      const SizedBox(height: 4),
                      Text('Any personality. Any mood.',
                          style: GoogleFonts.inter(
                            fontSize: 15, color: AppTheme.homeTextSecondary,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.error.withValues(alpha: 0.1),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.error)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Step 0: Name input
                if (_step <= 1) ...[
                  StaggerEntrance(
                    index: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHO SHOULD JUDGE YOU?',
                            style: AppTheme.overline(brightness).copyWith(
                              color: AppTheme.homeTextSecondary,
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w600,
                            color: brightness == Brightness.dark
                                ? AppTheme.textPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Gordon Ramsay, Taylor Swift...',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 16, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: brightness == Brightness.dark
                                ? AppTheme.surfaceInput
                                : AppTheme.lightSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppTheme.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppTheme.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.5)),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            'Gordon Ramsay', 'Trump', 'Drake', 'Oprah',
                            'Taylor Swift',
                          ]
                              .map((name) => GestureDetector(
                                    onTap: () {
                                      _nameController.text = name;
                                      setState(() {});
                                    },
                                    child: Chip(
                                      label: Text(name,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.textMuted)),
                                      backgroundColor: AppTheme.glassFill,
                                      side: BorderSide(
                                          color: AppTheme.glassBorder),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step 1: Mood selector
                  StaggerEntrance(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PICK MOODS (one or more)',
                            style: AppTheme.overline(brightness).copyWith(
                              color: AppTheme.homeTextSecondary,
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _moodOptions
                              .map((m) => _MoodChip(
                                    mood: m.mood,
                                    label: m.label,
                                    emoji: m.emoji,
                                    color: m.color,
                                    selected: _selectedMoods.contains(m.mood),
                                    onTap: () => setState(() {
                                      if (_selectedMoods.contains(m.mood)) {
                                        if (_selectedMoods.length > 1) {
                                          _selectedMoods.remove(m.mood);
                                        }
                                      } else {
                                        _selectedMoods.add(m.mood);
                                      }
                                    }),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Generate CTA
                  StaggerEntrance(
                    index: 2,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: _nameController.text.trim().isNotEmpty
                              ? const LinearGradient(colors: [
                                  AppTheme.ctaOrangeA, AppTheme.ctaOrangeB,
                                ])
                              : null,
                          color: _nameController.text.trim().isEmpty
                              ? AppTheme.glassFill
                              : null,
                          boxShadow:
                              _nameController.text.trim().isNotEmpty
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.ctaOuterGlow
                                            .withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                        ),
                        child: MaterialButton(
                          onPressed: _nameController.text.trim().isNotEmpty
                              ? _generate
                              : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                          child: Text('Generate Judge',
                              style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: _nameController.text.trim().isNotEmpty
                                    ? const Color(0xFF4A2800)
                                    : AppTheme.textMuted,
                              )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '$_remainingToday of ${RateLimitService.maxCustomJudgesPerDay} creations remaining today',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],

                // Step 2: Generating with progress stages
                if (_step == 2)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: AppTheme.primaryOrange),
                          const SizedBox(height: 20),
                          Text(
                            _generatingStatus == 'searching'
                                ? '🔍 Searching the web for ${_nameController.text.trim()}...'
                                : _generatingStatus == 'generating'
                                    ? '🧠 Building personality from research...'
                                    : '✅ Almost ready...',
                            style: GoogleFonts.inter(
                              fontSize: 16, color: AppTheme.homeTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _generatingStatus == 'searching'
                                ? 'Finding quotes, mannerisms, and style...'
                                : 'Creating your custom judge...',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Step 3: Preview
                if (_step == 3 && _createdJudge != null) ...[
                  _JudgePreview(
                    judge: _createdJudge!,
                    avatarBytes: _avatarBytes,
                  ),
                  const SizedBox(height: 16),

                  // Photo picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppTheme.glassFill,
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _avatarBytes != null
                                  ? Icons.check_circle_rounded
                                  : Icons.add_photo_alternate_rounded,
                              size: 18,
                              color: _avatarBytes != null
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _avatarBytes != null
                                  ? 'Change Photo'
                                  : 'Add Photo from Gallery',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.homeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Test This Judge CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(colors: [
                          AppTheme.ctaOrangeA, AppTheme.ctaOrangeB,
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.ctaOuterGlow.withValues(alpha: 0.4),
                            blurRadius: 14, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: MaterialButton(
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => CustomJudgeAuditionSheet(
                                judge: _createdJudge!),
                          );
                        },
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Color(0xFF4A2800), size: 20),
                            const SizedBox(width: 8),
                            Text('Test This Judge',
                                style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4A2800),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save (triggers publish dialog)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _showPublishDialog,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                      child: Text('Save Judge',
                          style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: AppTheme.homeTextPrimary,
                          )),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Try Again / Delete row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _step = 0;
                            _createdJudge = null;
                            _avatarBytes = null;
                          });
                        },
                        child: Text('Try Again',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.textMuted,
                            )),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _deleteJudge,
                        child: Text('Delete',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.error,
                            )),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _moodOptions = [
  (mood: 'funny', label: 'Funny', emoji: '😂', color: Color(0xFFFFD166)),
  (mood: 'savage', label: 'Savage', emoji: '🔥', color: Color(0xFFFF6B6B)),
  (mood: 'romantic', label: 'Romantic', emoji: '💕', color: Color(0xFFFF6B9D)),
  (mood: 'strict', label: 'Strict', emoji: '📋', color: Color(0xFF7C5CFC)),
  (mood: 'chaotic', label: 'Chaotic', emoji: '💀', color: Color(0xFF7CB342)),
  (mood: 'chill', label: 'Chill', emoji: '😎', color: Color(0xFF87CEEB)),
];

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood, required this.label, required this.emoji,
    required this.color, required this.selected, required this.onTap,
  });

  final String mood, label, emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? color.withValues(alpha: 0.15) : AppTheme.glassFill,
          border: Border.all(
            color: selected ? color : AppTheme.glassBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? color : AppTheme.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

class _JudgePreview extends StatelessWidget {
  const _JudgePreview({required this.judge, this.avatarBytes});

  final CustomJudge judge;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final moods = judge.mood.split('+');
    final moodColor = _moodOptions
        .firstWhere((m) => moods.contains(m.mood),
            orElse: () => _moodOptions.first)
        .color;

    return Column(
      children: [
        // Avatar: photo if available, emoji fallback
        if (avatarBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.memory(avatarBytes!, width: 80, height: 80,
                fit: BoxFit.cover),
          )
        else
          Text(judge.avatarEmoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(judge.personalityName,
            style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: AppTheme.homeTextPrimary,
            )),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: moodColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: moodColor.withValues(alpha: 0.3)),
          ),
          child: Text(
              moods.map((m) => m[0].toUpperCase() + m.substring(1)).join(' + '),
              style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: moodColor,
              )),
        ),
        const SizedBox(height: 20),

        // Sample quotes
        Text('SAMPLE QUOTES',
            style: AppTheme.overline(brightness).copyWith(
              color: AppTheme.homeTextSecondary, letterSpacing: 1.2,
            )),
        const SizedBox(height: 10),
        ...judge.previewQuotes.map((quote) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: brightness == Brightness.dark
                    ? AppTheme.glassFill
                    : AppTheme.lightGlassFill,
                border: Border.all(
                  color: brightness == Brightness.dark
                      ? AppTheme.glassBorder
                      : AppTheme.lightGlassBorder,
                ),
              ),
              child: Text('"$quote"',
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.homeTextPrimary, height: 1.5,
                  )),
            )),

        // Stats
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatPill(label: 'Difficulty', value: '${judge.difficultyLevel}/5'),
            const SizedBox(width: 12),
            _StatPill(label: 'Chaos', value: '${judge.chaosLevel}/5'),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.glassFill,
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(width: 6),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppTheme.homeTextPrimary,
              )),
        ],
      ),
    );
  }
}
