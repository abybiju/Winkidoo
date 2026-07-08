import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/scene_session.dart';
import 'package:winkidoo/providers/scene_party_provider.dart';

/// Pinned scene banner under the chat header: pack identity, act status,
/// cast row, and the "Director is on it…" pulse while a turn is running.
class SceneHeader extends ConsumerWidget {
  const SceneHeader({super.key, required this.roomId, required this.session});

  final String roomId;
  final SceneSession session;

  String _statusLabel(int actCount) {
    if (session.isCasting) return 'Casting';
    if (session.isEnded) return 'That\'s a wrap!';
    return 'Act ${session.currentAct}/$actCount';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = ref.watch(scenePackByIdProvider(session.packId)).value;
    final cast = ref.watch(sceneCastProvider(roomId)).value ?? const [];

    return GestureDetector(
      onTap: session.isCasting
          ? () => context.push('/shell/scenes/cast/$roomId')
          : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          children: [
            Text(pack?.emoji ?? '🎬', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pack?.name ?? 'Scene Party',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (session.directorBusy)
                    Text(
                      '🎬 Director is on it…',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.primaryOrange,
                      ),
                    )
                  else if (cast.isNotEmpty)
                    Text(
                      cast
                          .map((c) =>
                              '${c.characterEmoji ?? '🎭'}${c.isAi ? '' : ' ${c.displayName ?? ''}'}')
                          .join('  ')
                          .trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _statusLabel(pack?.actCount ?? 3),
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
            if (session.isCasting) ...[
              const SizedBox(width: 4),
              const Icon(PhosphorIconsBold.caretRight,
                  size: 12, color: Colors.white54),
            ],
          ],
        ),
      ),
    );
  }
}
