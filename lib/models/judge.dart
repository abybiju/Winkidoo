import 'package:flutter/material.dart';

/// Judge metadata (avatar, accent, seasonal). Persona ID is the source of truth.
/// Extended with UI-only fields for Judge Selection 2.0 (tagline, difficulty, chaos, quotes, colors).
class Judge {
  const Judge({
    required this.id,
    required this.personaId,
    required this.name,
    this.accentColorHex,
    this.avatarAssetPath,
    this.unlockAnimationType,
    this.seasonStart,
    this.seasonEnd,
    this.premiumFlag = false,
    this.tagline,
    this.difficultyLevel = 2,
    this.chaosLevel = 1,
    this.toneTags = const [],
    this.previewQuotes = const [],
    this.primaryColorHex,
    this.createdAt,
    this.isNew = true,
  });

  final String id;
  final String personaId;
  final String name;
  final String? accentColorHex;
  final String? avatarAssetPath;
  final String? unlockAnimationType;
  final DateTime? seasonStart;
  final DateTime? seasonEnd;
  final bool premiumFlag;
  final String? tagline;
  final int difficultyLevel;
  final int chaosLevel;
  final List<String> toneTags;
  final List<String> previewQuotes;
  final String? primaryColorHex;
  final DateTime? createdAt;
  final bool isNew;

  Color get primaryColor {
    final hex = primaryColorHex ?? accentColorHex ?? 'FF6B9D';
    return _hexToColor(hex);
  }

  Color get accentColor {
    final hex = accentColorHex ?? primaryColorHex ?? 'F8B500';
    return _hexToColor(hex);
  }

  static Color _hexToColor(String hex) {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }

  factory Judge.fromJson(Map<String, dynamic> json) {
    final toneTagsJson = json['tone_tags'];
    final previewQuotesJson = json['preview_quotes'];
    return Judge(
      id: json['id'] as String,
      personaId: json['persona_id'] as String,
      name: json['name'] as String,
      accentColorHex: json['accent_color_hex'] as String?,
      avatarAssetPath: json['avatar_asset_path'] as String?,
      unlockAnimationType: json['unlock_animation_type'] as String?,
      seasonStart: json['season_start'] != null
          ? DateTime.parse(json['season_start'] as String)
          : null,
      seasonEnd: json['season_end'] != null
          ? DateTime.parse(json['season_end'] as String)
          : null,
      premiumFlag: json['is_premium'] as bool? ?? json['premium_flag'] as bool? ?? false,
      tagline: json['tagline'] as String?,
      difficultyLevel: (json['difficulty_level'] as int?) ?? 2,
      chaosLevel: (json['chaos_level'] as int?) ?? 1,
      toneTags: toneTagsJson is List
          ? (toneTagsJson as List).map((e) => e.toString()).toList()
          : const [],
      previewQuotes: previewQuotesJson is List
          ? (previewQuotesJson as List).map((e) => e.toString()).toList()
          : const [],
      primaryColorHex: json['primary_color_hex'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isNew: json['is_new'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'persona_id': personaId,
      'name': name,
      'accent_color_hex': accentColorHex,
      'avatar_asset_path': avatarAssetPath,
      'unlock_animation_type': unlockAnimationType,
      'season_start': seasonStart?.toIso8601String(),
      'season_end': seasonEnd?.toIso8601String(),
      'premium_flag': premiumFlag,
      if (tagline != null) 'tagline': tagline,
      if (difficultyLevel != 2) 'difficulty_level': difficultyLevel,
      if (chaosLevel != 1) 'chaos_level': chaosLevel,
      if (toneTags.isNotEmpty) 'tone_tags': toneTags,
      if (previewQuotes.isNotEmpty) 'preview_quotes': previewQuotes,
      if (primaryColorHex != null) 'primary_color_hex': primaryColorHex,
      'is_new': isNew,
    };
  }

  /// Fallback when DB lookup fails (e.g. judge removed or network error). Used for battle/reveal.
  static Judge placeholder(String personaId) {
    final name = _placeholderNames[personaId] ?? _humanizePersonaId(personaId);
    return Judge(
      id: personaId,
      personaId: personaId,
      name: name,
      accentColorHex: 'FF6B9D',
      primaryColorHex: 'FF6B9D',
      premiumFlag: false,
      difficultyLevel: 2,
      chaosLevel: 1,
      isNew: false,
    );
  }

  static const Map<String, String> _placeholderNames = {
    'sassy_cupid': 'Sassy Cupid',
    'poetic_romantic': 'Poetic Romantic',
    'chaos_gremlin': 'Chaos Gremlin',
    'the_ex': 'The Ex',
    'dr_love': 'Dr. Love',
  };

  static String _humanizePersonaId(String id) {
    if (id.isEmpty) return 'Judge';
    return id.split('_').map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}').join(' ');
  }
}
