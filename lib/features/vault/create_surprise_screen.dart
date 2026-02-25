import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
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
  String _surpriseType = 'text';
  XFile? _photoFile;
  Uint8List? _photoBytes;
  String? _voicePath;
  bool _isRecording = false;
  final AudioRecorder _recorder = AudioRecorder();
  String _unlockMethod = AppConstants.unlockPersuade;
  String _judgePersona = AppConstants.personaSassyCupid;
  int _difficulty = 2;
  int _autoDeleteHours = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceRecord() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (mounted) setState(() {
        _isRecording = false;
        _voicePath = path;
      });
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission || !mounted) return;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (mounted) setState(() {
        _isRecording = true;
        _voicePath = null;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() {
        _photoFile = file;
        _photoBytes = Uint8List.fromList(bytes);
      });
    }
  }

  Future<void> _submit() async {
    if (_surpriseType == 'text') {
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
      await _submitText(content);
    } else if (_surpriseType == 'photo') {
      if (_photoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pick a photo to hide!'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      await _submitPhoto();
    } else {
      if (_voicePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record a voice note to hide!'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      await _submitVoice();
    }
  }

  Future<void> _submitText(String content) async {
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
        'surprise_type': 'text',
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

  Future<void> _submitPhoto() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final couple = ref.read(coupleProvider).value;
      final userId = ref.read(currentUserProvider)?.id;
      if (couple == null || userId == null) throw Exception('Not linked');

      final id = const Uuid().v4();
      final path = '${couple.id}/$id.jpg';
      final bytes = _photoBytes ?? await _photoFile!.readAsBytes();
      await client.storage.from(AppConstants.surpriseStorageBucket).uploadBinary(
            path,
            bytes,
          );

      DateTime? autoDeleteAt;
      if (_autoDeleteHours > 0) {
        autoDeleteAt = DateTime.now().add(Duration(hours: _autoDeleteHours));
      }

      await client.from('surprises').insert({
        'id': id,
        'couple_id': couple.id,
        'creator_id': userId,
        'content_encrypted': '',
        'unlock_method': _unlockMethod,
        'judge_persona': _judgePersona,
        'difficulty_level': _difficulty,
        'auto_delete_at': autoDeleteAt?.toUtc().toIso8601String(),
        'is_unlocked': false,
        'surprise_type': 'photo',
        'content_storage_path': path,
      });

      ref.invalidate(surprisesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo surprise locked! Your partner will see it.'),
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

  Future<void> _submitVoice() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final couple = ref.read(coupleProvider).value;
      final userId = ref.read(currentUserProvider)?.id;
      if (couple == null || userId == null) throw Exception('Not linked');
      final file = File(_voicePath!);
      if (!await file.exists()) throw Exception('Recording not found');

      final id = const Uuid().v4();
      final path = '${couple.id}/$id.m4a';
      final bytes = await file.readAsBytes();
      await client.storage.from(AppConstants.surpriseStorageBucket).uploadBinary(
            path,
            bytes,
          );

      DateTime? autoDeleteAt;
      if (_autoDeleteHours > 0) {
        autoDeleteAt = DateTime.now().add(Duration(hours: _autoDeleteHours));
      }

      await client.from('surprises').insert({
        'id': id,
        'couple_id': couple.id,
        'creator_id': userId,
        'content_encrypted': '',
        'unlock_method': _unlockMethod,
        'judge_persona': _judgePersona,
        'difficulty_level': _difficulty,
        'auto_delete_at': autoDeleteAt?.toUtc().toIso8601String(),
        'is_unlocked': false,
        'surprise_type': 'voice',
        'content_storage_path': path,
      });

      ref.invalidate(surprisesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice surprise locked! Your partner will hear it.'),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Surprise type',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label:
                      'Surprise type: Text, Photo, or Voice. ${_surpriseType == 'text' ? 'Text' : _surpriseType == 'photo' ? 'Photo' : 'Voice'} selected.',
                  child: Row(
                    children: [
                      _ChoiceChip(
                        label: 'Text',
                        selected: _surpriseType == 'text',
                        onSelected: () =>
                            setState(() => _surpriseType = 'text'),
                      ),
                      const SizedBox(width: 12),
                      _ChoiceChip(
                        label: 'Photo',
                        selected: _surpriseType == 'photo',
                        onSelected: () =>
                            setState(() => _surpriseType = 'photo'),
                      ),
                      const SizedBox(width: 12),
                      _ChoiceChip(
                        label: 'Voice',
                        selected: _surpriseType == 'voice',
                        onSelected: () =>
                            setState(() => _surpriseType = 'voice'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_surpriseType == 'text') ...[
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
                ] else if (_surpriseType == 'photo') ...[
                  Text(
                    'Pick a photo to hide',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: _photoFile == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to pick from gallery or camera',
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _photoBytes != null
                                  ? Image.memory(
                                      _photoBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                    ),
                  ),
                  if (_photoFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Change photo'),
                      ),
                    ),
                ] else if (_surpriseType == 'voice') ...[
                  Text(
                    'Record a voice note to hide',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        IconButton.filled(
                          onPressed: _isLoading ? null : _toggleVoiceRecord,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          style: IconButton.styleFrom(
                            backgroundColor: _isRecording ? AppTheme.error : AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRecording ? 'Recording... tap to stop' : (_voicePath != null ? 'Recorded! Tap mic to re-record' : 'Tap mic to record'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                Builder(
                  builder: (context) {
                    final couple = ref.watch(coupleProvider).value;
                    final isWinkPlus = couple?.isWinkPlus ?? false;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PersonaChip(
                          id: AppConstants.personaSassyCupid,
                          label: 'Sassy Cupid',
                          selected: _judgePersona == AppConstants.personaSassyCupid,
                          onSelected: () =>
                              setState(() => _judgePersona = AppConstants.personaSassyCupid),
                          isWinkPlusLocked: false,
                        ),
                        _PersonaChip(
                          id: AppConstants.personaPoeticRomantic,
                          label: 'Poetic',
                          selected: _judgePersona == AppConstants.personaPoeticRomantic,
                          onSelected: () =>
                              setState(() => _judgePersona = AppConstants.personaPoeticRomantic),
                          isWinkPlusLocked: false,
                        ),
                        _PersonaChip(
                          id: AppConstants.personaChaosGremlin,
                          label: 'Chaos Gremlin',
                          selected: _judgePersona == AppConstants.personaChaosGremlin,
                          onSelected: () =>
                              setState(() => _judgePersona = AppConstants.personaChaosGremlin),
                          isWinkPlusLocked: !isWinkPlus,
                        ),
                        _PersonaChip(
                          id: AppConstants.personaTheEx,
                          label: 'The Ex',
                          selected: _judgePersona == AppConstants.personaTheEx,
                          onSelected: () =>
                              setState(() => _judgePersona = AppConstants.personaTheEx),
                          isWinkPlusLocked: !isWinkPlus,
                        ),
                        _PersonaChip(
                          id: AppConstants.personaDrLove,
                          label: 'Dr. Love',
                          selected: _judgePersona == AppConstants.personaDrLove,
                          onSelected: () =>
                              setState(() => _judgePersona = AppConstants.personaDrLove),
                          isWinkPlusLocked: !isWinkPlus,
                        ),
                      ],
                    );
                  },
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
                Semantics(
                  label: 'Create surprise',
                  button: true,
                  child: ElevatedButton(
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
    this.isWinkPlusLocked = false,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool isWinkPlusLocked;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = isWinkPlusLocked ? '$label (Wink+)' : label;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinkPlusLocked) ...[
            Icon(Icons.lock, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(effectiveLabel),
        ],
      ),
      selected: selected,
      onSelected: isWinkPlusLocked
          ? null
          : (_) => onSelected(),
      selectedColor: AppTheme.primary,
    );
  }
}
