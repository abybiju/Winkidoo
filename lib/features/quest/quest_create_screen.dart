import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/pill_cta.dart';
import 'package:winkidoo/core/widgets/profile_completion_sheet.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/quest_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

/// Screen to create a new Love Quest (co-op surprise chain).
class QuestCreateScreen extends ConsumerStatefulWidget {
  const QuestCreateScreen({super.key});

  @override
  ConsumerState<QuestCreateScreen> createState() => _QuestCreateScreenState();
}

class _QuestCreateScreenState extends ConsumerState<QuestCreateScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int _totalSteps = 3;
  String _judgePersona = AppConstants.personaSassyCupid;
  int _difficultyStart = 1;
  int _difficultyEnd = 3;
  bool _isLoading = false;

  static const _questTemplates = [
    ('Our Story', 'Relive your relationship milestones together'),
    ('Why I Love You', 'Share reasons you love each other, one per day'),
    ('Date Night Puzzle', 'Build clues toward a surprise date'),
    ('Memory Lane', 'Exchange favorite memories from your time together'),
    ('Future Dreams', 'Share your hopes and dreams for your future'),
    ('Custom', 'Create your own quest theme'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await ensureProfileComplete(context, ref);
      if (!mounted || !ok) context.pop();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createQuest() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your quest a title!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);
      final couple = ref.read(coupleProvider).value;
      if (user == null || couple == null) return;

      final questId = const Uuid().v4();
      await client.from('quests').insert({
        'id': questId,
        'couple_id': couple.id,
        'creator_id': user.id,
        'title': title,
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'total_steps': _totalSteps,
        'judge_persona': _judgePersona,
        'difficulty_start': _difficultyStart,
        'difficulty_end': _difficultyEnd,
      });

      ref.invalidate(questsListProvider);

      if (mounted) {
        context.go('/shell/quest/$questId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create quest: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.homeBackgroundGradient(brightness),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Love Quest',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Quick templates
                      Text(
                        'Choose a theme',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _questTemplates.map((t) {
                          final selected = _titleController.text == t.$1 &&
                              t.$1 != 'Custom';
                          return GestureDetector(
                            onTap: () {
                              if (t.$1 == 'Custom') {
                                _titleController.clear();
                                _descController.clear();
                              } else {
                                _titleController.text = t.$1;
                                _descController.text = t.$2;
                              }
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: selected
                                    ? AppTheme.primaryPink.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primaryPink
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                t.$1,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      // Title input
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Quest Title',
                          labelStyle: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Description input
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                          labelStyle: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Steps slider
                      Text(
                        'Number of Steps: $_totalSteps',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Slider(
                        value: _totalSteps.toDouble(),
                        min: AppConstants.questMinSteps.toDouble(),
                        max: AppConstants.questMaxSteps.toDouble(),
                        divisions: AppConstants.questMaxSteps -
                            AppConstants.questMinSteps,
                        label: '$_totalSteps steps',
                        activeColor: AppTheme.primaryPink,
                        onChanged: (v) =>
                            setState(() => _totalSteps = v.round()),
                      ),
                      const SizedBox(height: 8),
                      // Difficulty range
                      Text(
                        'Difficulty: $_difficultyStart \u{2192} $_difficultyEnd',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Starts easy and escalates to the boss battle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      RangeSlider(
                        values: RangeValues(
                          _difficultyStart.toDouble(),
                          _difficultyEnd.toDouble(),
                        ),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        labels: RangeLabels(
                          'Lvl $_difficultyStart',
                          'Lvl $_difficultyEnd',
                        ),
                        activeColor: AppTheme.primaryPink,
                        onChanged: (v) {
                          setState(() {
                            _difficultyStart = v.start.round();
                            _difficultyEnd = v.end.round();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      // Judge persona selector
                      Text(
                        'Quest Judge',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This judge will remember your entire quest journey',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _personaChip(AppConstants.personaSassyCupid,
                              'Sassy Cupid'),
                          _personaChip(AppConstants.personaPoeticRomantic,
                              'Poetic Romantic'),
                          _personaChip(AppConstants.personaChaosGremlin,
                              'Chaos Gremlin'),
                          _personaChip(
                              AppConstants.personaTheEx, 'The Ex'),
                          _personaChip(
                              AppConstants.personaDrLove, 'Dr. Love'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Create button
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppTheme.primaryPink)
                            : PillCta(
                                label: 'Start Quest \u{2694}\u{FE0F}',
                                onTap: () => _createQuest(),
                              ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personaChip(String id, String label) {
    final selected = _judgePersona == id;
    final isWinkPlus = ref.watch(effectiveWinkPlusProvider);
    final isPremium = !AppConstants.freePersonas.contains(id);
    final locked = isPremium && !isWinkPlus;

    return GestureDetector(
      onTap: locked
          ? null
          : () => setState(() => _judgePersona = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppTheme.primaryPink.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: locked ? 0.03 : 0.08),
          border: Border.all(
            color: selected
                ? AppTheme.primaryPink
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.lock_rounded, size: 14, color: Colors.white38),
              ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: locked ? Colors.white38 : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
