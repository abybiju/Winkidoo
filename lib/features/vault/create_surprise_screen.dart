import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/services/encryption_service.dart';
import 'package:uuid/uuid.dart';

class CreateSurpriseScreen extends ConsumerStatefulWidget {
  const CreateSurpriseScreen({super.key});

  @override
  ConsumerState<CreateSurpriseScreen> createState() =>
      _CreateSurpriseScreenState();
}

class _CreateSurpriseScreenState extends ConsumerState<CreateSurpriseScreen> {
  final _contentController = TextEditingController();
  String _unlockMethod = AppConstants.unlockPersuade;
  String _judgePersona = AppConstants.personaSassyCupid;
  int _difficulty = 2;
  int _autoDeleteHours = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write something to hide!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final couple = ref.read(coupleProvider).value;
      final userId = ref.read(currentUserProvider)?.id;
      if (couple == null || userId == null) throw Exception('Not linked');

      final encrypted = await EncryptionService.encrypt(content, coupleId: couple.id);
      final id = const Uuid().v4();
      DateTime? autoDeleteAt;
      if (_autoDeleteHours > 0) {
        autoDeleteAt = DateTime.now().add(Duration(hours: _autoDeleteHours));
      }

      await client.from('surprises').insert({
        'id': id,
        'couple_id': couple.id,
        'creator_id': userId,
        'content_encrypted': encrypted,
        'unlock_method': _unlockMethod,
        'judge_persona': _judgePersona,
        'difficulty_level': _difficulty,
        'auto_delete_at': autoDeleteAt?.toUtc().toIso8601String(),
        'is_unlocked': false,
      });

      ref.invalidate(surprisesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surprise locked! Your partner will see it.'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hide a surprise'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your secret message',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write what you want to hide...',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Unlock method',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ChoiceChip(
                      label: 'Persuade',
                      selected: _unlockMethod == AppConstants.unlockPersuade,
                      onSelected: () =>
                          setState(() => _unlockMethod = AppConstants.unlockPersuade),
                    ),
                    const SizedBox(width: 12),
                    _ChoiceChip(
                      label: 'Collaborate',
                      selected: _unlockMethod == AppConstants.unlockCollaborate,
                      onSelected: () =>
                          setState(() => _unlockMethod = AppConstants.unlockCollaborate),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Judge persona',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PersonaChip(
                      id: AppConstants.personaSassyCupid,
                      label: 'Sassy Cupid',
                      selected: _judgePersona == AppConstants.personaSassyCupid,
                      onSelected: () =>
                          setState(() => _judgePersona = AppConstants.personaSassyCupid),
                    ),
                    _PersonaChip(
                      id: AppConstants.personaPoeticRomantic,
                      label: 'Poetic',
                      selected: _judgePersona == AppConstants.personaPoeticRomantic,
                      onSelected: () =>
                          setState(() => _judgePersona = AppConstants.personaPoeticRomantic),
                    ),
                    _PersonaChip(
                      id: AppConstants.personaChaosGremlin,
                      label: 'Chaos Gremlin',
                      selected: _judgePersona == AppConstants.personaChaosGremlin,
                      onSelected: () =>
                          setState(() => _judgePersona = AppConstants.personaChaosGremlin),
                    ),
                    _PersonaChip(
                      id: AppConstants.personaTheEx,
                      label: 'The Ex',
                      selected: _judgePersona == AppConstants.personaTheEx,
                      onSelected: () =>
                          setState(() => _judgePersona = AppConstants.personaTheEx),
                    ),
                    _PersonaChip(
                      id: AppConstants.personaDrLove,
                      label: 'Dr. Love',
                      selected: _judgePersona == AppConstants.personaDrLove,
                      onSelected: () =>
                          setState(() => _judgePersona = AppConstants.personaDrLove),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Difficulty (affects score needed)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final level = i + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$level'),
                        selected: _difficulty == level,
                        onSelected: (v) =>
                            setState(() => _difficulty = level),
                        selectedColor: AppTheme.primary,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text(
                  'Auto-delete',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChoiceChip(
                      label: 'After viewing',
                      selected: _autoDeleteHours == 0,
                      onSelected: () => setState(() => _autoDeleteHours = 0),
                    ),
                    _ChoiceChip(
                      label: '24h',
                      selected: _autoDeleteHours == 24,
                      onSelected: () => setState(() => _autoDeleteHours = 24),
                    ),
                    _ChoiceChip(
                      label: '48h',
                      selected: _autoDeleteHours == 48,
                      onSelected: () => setState(() => _autoDeleteHours = 48),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lock it!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.primary,
    );
  }
}

class _PersonaChip extends StatelessWidget {
  const _PersonaChip({
    required this.id,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTheme.primary,
    );
  }
}
