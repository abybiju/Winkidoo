import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/services/encryption_service.dart';

class AddCollabPieceScreen extends ConsumerStatefulWidget {
  const AddCollabPieceScreen({super.key, required this.surpriseId});
  final String surpriseId;

  @override
  ConsumerState<AddCollabPieceScreen> createState() =>
      _AddCollabPieceScreenState();
}

class _AddCollabPieceScreenState extends ConsumerState<AddCollabPieceScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write your piece first!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final couple = ref.read(coupleProvider).value;
      if (couple == null) return;

      final encrypted =
          await EncryptionService.encrypt(text, coupleId: couple.id);

      await client.from('surprises').update({
        'collab_partner_piece_encrypted': encrypted,
        'collab_partner_status': 'added',
      }).eq('id', widget.surpriseId);

      ref.invalidate(surprisesListProvider);
      ref.invalidate(surpriseByIdProvider(widget.surpriseId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your piece is in! Time to battle 🔥'),
            backgroundColor: AppTheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error),
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
            colors: AppTheme.gradientColors(brightness),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color:
                              Theme.of(context).colorScheme.onSurface),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Your Piece',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryPink.withValues(alpha: 0.1),
                          border: Border.all(
                              color: AppTheme.primaryPink
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '🤫 Your partner already added their piece. Now add yours — neither of you will see the combined result until you WIN the battle together.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your piece',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        maxLines: 6,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Write your part of the surprise...',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppTheme.primaryPink)
                            : ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30)),
                                ),
                                child: Text(
                                  'Lock My Piece 🔒',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                              ),
                      ),
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
}
