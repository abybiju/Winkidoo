import 'package:winkidoo/models/character_preset.dart';

/// A Scene Party theme pack — server-side content (scene_packs table).
class ScenePack {
  const ScenePack({
    required this.id,
    required this.slug,
    required this.name,
    this.tagline,
    this.description,
    this.emoji,
    this.primaryColorHex,
    this.secondaryColorHex,
    required this.actCount,
    this.minPlayers = 1,
    this.maxPlayers = 6,
    this.isPremium = false,
    this.seasonStart,
    this.seasonEnd,
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final String name;
  final String? tagline;
  final String? description;
  final String? emoji;
  final String? primaryColorHex;
  final String? secondaryColorHex;
  final int actCount;
  final int minPlayers;
  final int maxPlayers;
  final bool isPremium;
  final DateTime? seasonStart;
  final DateTime? seasonEnd;
  final int sortOrder;

  bool get isSeasonal => seasonStart != null || seasonEnd != null;

  int? get daysRemaining {
    if (seasonEnd == null) return null;
    final d = seasonEnd!.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  factory ScenePack.fromJson(Map<String, dynamic> json) {
    return ScenePack(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String?,
      description: json['description'] as String?,
      emoji: json['emoji'] as String?,
      primaryColorHex: json['primary_color_hex'] as String?,
      secondaryColorHex: json['secondary_color_hex'] as String?,
      actCount: json['act_count'] as int? ?? 3,
      minPlayers: json['min_players'] as int? ?? 1,
      maxPlayers: json['max_players'] as int? ?? 6,
      isPremium: json['is_premium'] as bool? ?? false,
      seasonStart: json['season_start'] != null
          ? DateTime.parse(json['season_start'] as String)
          : null,
      seasonEnd: json['season_end'] != null
          ? DateTime.parse(json['season_end'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

/// A claimable character within a pack (scene_characters table).
class SceneCharacter {
  const SceneCharacter({
    required this.id,
    required this.packId,
    required this.slug,
    required this.name,
    this.emoji,
    this.colorHex,
    this.tagline,
    required this.voicePrompt,
    this.isLead = false,
    this.sortOrder = 0,
  });

  final String id;
  final String packId;
  final String slug;
  final String name;
  final String? emoji;
  final String? colorHex;
  final String? tagline;

  /// Voice-transformation instruction (castmate_prompt stays server-side).
  final String voicePrompt;
  final bool isLead;
  final int sortOrder;

  /// Bridges into the existing transform pipeline.
  CharacterPreset toCharacterPreset() => CharacterPreset(
        id: 'scene:$slug',
        name: name,
        emoji: emoji ?? '🎭',
        systemPrompt: voicePrompt,
        isBuiltIn: false,
      );

  factory SceneCharacter.fromJson(Map<String, dynamic> json) {
    return SceneCharacter(
      id: json['id'] as String,
      packId: json['pack_id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      colorHex: json['color_hex'] as String?,
      tagline: json['tagline'] as String?,
      voicePrompt: json['voice_prompt'] as String? ?? '',
      isLead: json['is_lead'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
