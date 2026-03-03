import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

enum HomeAvatarType { regular, invite, premiumLocked }

class HomeAvatarOption {
  const HomeAvatarOption({
    required this.label,
    required this.type,
    this.color = const Color(0xFFFFB459),
    this.badge,
    this.isHot = false,
  });

  final String label;
  final HomeAvatarType type;
  final Color color;
  final String? badge;
  final bool isHot;
}

class AvatarSelector extends StatelessWidget {
  const AvatarSelector({
    super.key,
    required this.items,
    this.onTap,
    this.showLabels = false,
    this.showHint = true,
    this.homeCompactMode = true,
    this.hintText = 'Tap an avatar to challenge!',
  });

  final List<HomeAvatarOption> items;
  final ValueChanged<HomeAvatarOption>? onTap;
  final bool showLabels;
  final bool showHint;
  final bool homeCompactMode;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final listHeight = showLabels ? 108.0 : (homeCompactMode ? 78.0 : 88.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            separatorBuilder: (_, __) =>
                SizedBox(width: homeCompactMode ? 10 : 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final label = item.label;
              final isInvite = item.type == HomeAvatarType.invite;
              final isLocked = item.type == HomeAvatarType.premiumLocked;
              final avatarSize = homeCompactMode ? 66.0 : 72.0;

              return InkWell(
                onTap: onTap == null ? null : () => onTap!(item),
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: showLabels ? 78 : avatarSize + 4,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isInvite
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF5E2B85),
                                        Color(0xFF3D1C61)
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        item.color,
                                        AppTheme.homeGlowPink,
                                      ],
                                    ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.84),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isInvite ? AppTheme.plum : item.color)
                                      .withValues(alpha: 0.26),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _AvatarInner(
                              isInvite: isInvite,
                              isLocked: isLocked,
                              label: label,
                              compact: homeCompactMode,
                            ),
                          ),
                          if (item.badge != null)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: _DotBadge(text: item.badge!, isHot: false),
                            ),
                          if (item.isHot)
                            const Positioned(
                              right: -2,
                              top: -2,
                              child: _DotBadge(text: '', isHot: true),
                            ),
                          if (isLocked)
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF26143A),
                                  border: Border.all(
                                    color: AppTheme.premiumBorder30(
                                      Theme.of(context).brightness,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 7),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (showHint) ...[
          const SizedBox(height: 8),
          Align(
            child: Text(
              hintText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DotBadge extends StatelessWidget {
  const _DotBadge({required this.text, required this.isHot});

  final String text;
  final bool isHot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isHot ? const Color(0xFFE95060) : const Color(0xFFE85060),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: isHot
          ? const Icon(Icons.local_fire_department_rounded,
              size: 11, color: Color(0xFFFFE58A))
          : Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}

class _AvatarInner extends StatelessWidget {
  const _AvatarInner({
    required this.isInvite,
    required this.isLocked,
    required this.label,
    required this.compact,
  });

  final bool isInvite;
  final bool isLocked;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isInvite) {
      return Icon(Icons.add_rounded,
          size: compact ? 36 : 40, color: Colors.white);
    }

    if (isLocked) {
      return const Icon(
        Icons.auto_awesome_rounded,
        size: 26,
        color: Color(0xFFFFE58F),
      );
    }

    return Text(
      label.isEmpty ? '?' : label[0].toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: compact ? 24 : 26,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}
