import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

final activePlayCardProvider = StateProvider<int>((ref) => 0);

class PlayCardMeta {
  const PlayCardMeta({
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
}

const playCardMetas = <PlayCardMeta>[
  PlayCardMeta(
    label: 'Daily Dare',
    icon: Icons.local_fire_department_rounded,
    accentColor: AppTheme.primaryOrange,
  ),
  PlayCardMeta(
    label: 'Mini Game',
    icon: Icons.videogame_asset_rounded,
    accentColor: AppTheme.secondaryViolet,
  ),
  PlayCardMeta(
    label: 'Battle Packs',
    icon: Icons.layers_rounded,
    accentColor: AppTheme.premiumAmber,
  ),
  PlayCardMeta(
    label: 'Story Mode',
    icon: Icons.auto_stories_rounded,
    accentColor: AppTheme.success,
  ),
  PlayCardMeta(
    label: 'Judges',
    icon: Icons.star_rounded,
    accentColor: AppTheme.homeGlowPink,
  ),
  PlayCardMeta(
    label: 'Character Chat',
    icon: PhosphorIconsFill.chatTeardropDots,
    accentColor: AppTheme.info,
  ),
];
