import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/mini_game_provider.dart';

class MiniGameCard extends ConsumerStatefulWidget {
  const MiniGameCard({
    super.key,
    required this.onPlay,
    required this.onViewResult,
    this.height,
    this.compact = false,
  });

  final VoidCallback onPlay;
  final VoidCallback onViewResult;
  final double? height;
  final bool compact;

  @override
  ConsumerState<MiniGameCard> createState() => _MiniGameCardState();
}

class _MiniGameCardState extends ConsumerState<MiniGameCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(miniGameProvider);

    return gameAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (gameState) {
        if (gameState.phase == MiniGamePhase.unavailable ||
            gameState.phase == MiniGamePhase.loading ||
            gameState.phase == MiniGamePhase.error) {
          return const SizedBox.shrink();
        }
        return _buildCard(context, gameState);
      },
    );
  }

  Widget _buildCard(BuildContext context, MiniGameState gameState) {
    final brightness = Theme.of(context).brightness;
    final game = gameState.game;
    if (game == null) return const SizedBox.shrink();

    final targetHeight = widget.height ?? (widget.compact ? 176 : 196);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppTheme.microDuration,
        curve: AppTheme.standardCurve,
        transform:
            Matrix4.translationValues(0.0, _hovered ? -1.5 : 0.0, 0.0),
        constraints: BoxConstraints(minHeight: targetHeight),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.vaultHeroGradient(brightness),
          ),
          border: Border.all(color: AppTheme.premiumBorder30(brightness)),
          boxShadow: AppTheme.elevation3(brightness),
        ),
        child: Stack(
          children: [
            // Violet glow from bottom (distinguish from orange dare)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppTheme.secondaryViolet.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.vaultDramaVignette.withValues(
                          alpha: brightness == Brightness.dark ? 0.36 : 0.16,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  18, widget.compact ? 14 : 18, 18, widget.compact ? 14 : 18),
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _overlineForPhase(gameState.phase),
                          style: AppTheme.overline(brightness).copyWith(
                            color: AppTheme.homeTextSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          game.gameTypeDisplayName,
                          style: GoogleFonts.inter(
                            fontSize: widget.compact ? 19 : 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppTheme.homeTextPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gameState.phase == MiniGamePhase.graded
                              ? (game.gradeCommentary ?? '')
                              : game.gamePrompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: widget.compact ? 13 : 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.homeTextSecondary,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: widget.compact ? 12 : 14),
                        _buildCta(context, gameState, brightness),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 9,
                    child: _GameIconBlock(
                      phase: gameState.phase,
                      gameType: game.gameType,
                      score: game.gradeScore,
                      emoji: game.gradeEmoji,
                      compact: widget.compact,
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

  String _overlineForPhase(MiniGamePhase phase) {
    return switch (phase) {
      MiniGamePhase.graded => 'GAME GRADED',
      MiniGamePhase.myTurn => 'YOUR TURN',
      MiniGamePhase.waitingForPartner => 'WAITING',
      MiniGamePhase.grading => 'GRADING...',
      MiniGamePhase.expired => 'EXPIRED',
      _ => 'MINI-GAME',
    };
  }

  Widget _buildCta(
    BuildContext context,
    MiniGameState gameState,
    Brightness brightness,
  ) {
    switch (gameState.phase) {
      case MiniGamePhase.pending:
        return _GameActionButton(
          label: 'Play Now',
          icon: Icons.play_arrow_rounded,
          onTap: widget.onPlay,
          compact: widget.compact,
        );
      case MiniGamePhase.myTurn:
        return _GameActionButton(
          label: 'Your Turn!',
          icon: Icons.flash_on_rounded,
          onTap: widget.onPlay,
          compact: widget.compact,
        );
      case MiniGamePhase.waitingForPartner:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 14 : 16,
            vertical: widget.compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            color: brightness == Brightness.dark
                ? AppTheme.glassFill
                : AppTheme.lightGlassFill,
            border: Border.all(
              color: brightness == Brightness.dark
                  ? AppTheme.glassBorder
                  : AppTheme.lightGlassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 16),
              const SizedBox(width: 6),
              Text(
                'Waiting for partner...',
                style: GoogleFonts.poppins(
                  fontSize: widget.compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: AppTheme.homeTextPrimary,
                ),
              ),
            ],
          ),
        );
      case MiniGamePhase.grading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.secondaryViolet,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Grading...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.homeTextSecondary,
              ),
            ),
          ],
        );
      case MiniGamePhase.graded:
        return _GameActionButton(
          label: 'View Result',
          icon: Icons.emoji_events_rounded,
          onTap: widget.onViewResult,
          compact: widget.compact,
        );
      case MiniGamePhase.expired:
        return Text(
          'New game tomorrow!',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.homeTextSecondary,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _GameIconBlock extends StatelessWidget {
  const _GameIconBlock({
    required this.phase,
    required this.gameType,
    this.score,
    this.emoji,
    this.compact = false,
  });

  final MiniGamePhase phase;
  final String gameType;
  final int? score;
  final String? emoji;
  final bool compact;

  IconData get _gameIcon => switch (gameType) {
        'would_you_rather' => Icons.compare_arrows_rounded,
        'love_trivia' => Icons.quiz_rounded,
        'caption_this' => Icons.subtitles_rounded,
        'finish_my_sentence' => Icons.edit_note_rounded,
        _ => Icons.videogame_asset_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: compact ? 100 : 118,
        height: compact ? 100 : 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : const Color(0x0A000000),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorderSubtle
                : const Color(0x14000000),
          ),
        ),
        child: Center(
          child: phase == MiniGamePhase.graded && score != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null)
                      Text(emoji!, style: const TextStyle(fontSize: 28)),
                    Text(
                      '$score',
                      style: GoogleFonts.inter(
                        fontSize: compact ? 28 : 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.secondaryViolet,
                      ),
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: brightness == Brightness.dark
                            ? AppTheme.glassFill
                            : const Color(0x0A000000),
                      ),
                    ),
                    Icon(
                      _gameIcon,
                      size: 32,
                      color: brightness == Brightness.dark
                          ? AppTheme.textMuted
                          : AppTheme.lightTextMuted,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GameActionButton extends StatefulWidget {
  const _GameActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_GameActionButton> createState() => _GameActionButtonState();
}

class _GameActionButtonState extends State<_GameActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppTheme.microDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.04);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9B7DFF), Color(0xFF7C5CFC)],
            ),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryViolet.withValues(alpha: 0.40),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppTheme.secondaryViolet.withValues(alpha: 0.30),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 18 : 20,
              vertical: widget.compact ? 10 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: widget.compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white,
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
