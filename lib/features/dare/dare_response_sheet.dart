import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/daily_dare.dart';
import 'package:winkidoo/providers/daily_dare_provider.dart';

/// Modal bottom sheet for submitting a dare response (text, photo, or voice).
class DareResponseSheet extends ConsumerStatefulWidget {
  const DareResponseSheet({super.key, required this.dare});

  final DailyDare dare;

  @override
  ConsumerState<DareResponseSheet> createState() => _DareResponseSheetState();
}

class _DareResponseSheetState extends ConsumerState<DareResponseSheet> {
  final _controller = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  String _responseType = 'text'; // text | photo | voice
  bool _submitting = false;

  // Photo state
  Uint8List? _photoBytes;

  // Voice state
  bool _isRecording = false;
  String? _voicePath;

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
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
    final file =
        await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      setState(() {
        _photoBytes = bytes;
      });
    }
  }

  Future<void> _toggleVoiceRecord() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (mounted) setState(() { _isRecording = false; _voicePath = path; });
    } else {
      final hasPermission = await _recorder.hasPermission(request: true);
      if (!hasPermission || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/dare_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      try {
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        if (mounted) setState(() { _isRecording = true; _voicePath = null; });
      } catch (e) {
        debugPrint('Voice record error: $e');
      }
    }
  }

  bool get _canSubmit {
    if (_submitting) return false;
    switch (_responseType) {
      case 'photo': return _photoBytes != null;
      case 'voice': return _voicePath != null && !_isRecording;
      default: return _controller.text.trim().isNotEmpty;
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    String content;
    String type = _responseType;

    switch (_responseType) {
      case 'photo':
        // Upload photo to Supabase Storage, store the path as the "content"
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id ?? 'unknown';
        final storagePath = 'dare_photos/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await client.storage.from('surprises').uploadBinary(storagePath, _photoBytes!);
        content = storagePath;
      case 'voice':
        // Upload voice file to Supabase Storage
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id ?? 'unknown';
        final storagePath = 'dare_voices/$userId/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final bytes = await File(_voicePath!).readAsBytes();
        await client.storage.from('surprises').uploadBinary(storagePath, bytes);
        content = storagePath;
      default:
        content = _controller.text.trim();
    }

    await ref.read(dailyDareProvider.notifier).submitResponse(content, type: type);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final personaName =
        HomeScreen.personaDisplayName(widget.dare.judgePersona);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? AppTheme.surface2
              : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
                color: AppTheme.primaryOrange.withValues(alpha: 0.2)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrangeLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.primaryOrangeLight.withValues(alpha: 0.3)),
                      ),
                      child: Text('DAILY DARE',
                          style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 0.8, color: AppTheme.primaryOrangeLight,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Text(personaName,
                        style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: AppTheme.textOrangeAccent,
                        )),
                  ],
                ),
                const SizedBox(height: 12),

                // Dare text
                Text(widget.dare.dareText,
                    style: GoogleFonts.caveat(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: brightness == Brightness.dark
                          ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                      height: 1.3,
                    )),
                const SizedBox(height: 16),

                // Response type picker
                Row(
                  children: [
                    _TypeChip(label: 'Text', icon: Icons.edit_rounded,
                        selected: _responseType == 'text',
                        onTap: () => setState(() => _responseType = 'text')),
                    const SizedBox(width: 8),
                    _TypeChip(label: 'Photo', icon: Icons.camera_alt_rounded,
                        selected: _responseType == 'photo',
                        onTap: () => setState(() => _responseType = 'photo')),
                    const SizedBox(width: 8),
                    _TypeChip(label: 'Voice', icon: Icons.mic_rounded,
                        selected: _responseType == 'voice',
                        onTap: () => setState(() => _responseType = 'voice')),
                  ],
                ),
                const SizedBox(height: 16),

                // Input area based on type
                if (_responseType == 'text')
                  TextField(
                    controller: _controller,
                    maxLines: 4, maxLength: 500, autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: brightness == Brightness.dark
                          ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your response...',
                      hintStyle: GoogleFonts.poppins(fontSize: 15, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: brightness == Brightness.dark
                          ? AppTheme.surfaceInput : AppTheme.lightSurfaceElevated,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.glassBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.glassBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.5))),
                      counterStyle: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                else if (_responseType == 'photo')
                  _PhotoInput(
                    photoBytes: _photoBytes,
                    onPick: _pickPhoto,
                  )
                else
                  _VoiceInput(
                    isRecording: _isRecording,
                    hasRecording: _voicePath != null,
                    onToggle: _toggleVoiceRecord,
                  ),
                const SizedBox(height: 16),

                // Submit CTA
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                          colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB]),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ctaOuterGlow.withValues(alpha: 0.4),
                          blurRadius: 12, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: MaterialButton(
                      onPressed: _canSubmit ? _submit : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      child: _submitting
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Text('Submit Response',
                              style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                    ),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppTheme.primaryOrange.withValues(alpha: 0.15)
              : AppTheme.glassFill,
          border: Border.all(
            color: selected
                ? AppTheme.primaryOrange
                : AppTheme.glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: selected ? AppTheme.primaryOrange : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.primaryOrange : AppTheme.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

class _PhotoInput extends StatelessWidget {
  const _PhotoInput({this.photoBytes, required this.onPick});

  final Uint8List? photoBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    if (photoBytes != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(photoBytes!, height: 160, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('Retake', style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.glassFill,
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_rounded,
                color: AppTheme.textMuted, size: 32),
            const SizedBox(height: 8),
            Text('Tap to take or choose a photo',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _VoiceInput extends StatelessWidget {
  const _VoiceInput({
    required this.isRecording, required this.hasRecording,
    required this.onToggle,
  });

  final bool isRecording;
  final bool hasRecording;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isRecording
              ? AppTheme.error.withValues(alpha: 0.1)
              : AppTheme.glassFill,
          border: Border.all(
            color: isRecording ? AppTheme.error : AppTheme.glassBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
              color: isRecording ? AppTheme.error : AppTheme.textMuted,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              isRecording
                  ? 'Recording... tap to stop'
                  : hasRecording
                      ? 'Recorded! Tap to re-record'
                      : 'Tap to record a voice note',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isRecording ? AppTheme.error : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
