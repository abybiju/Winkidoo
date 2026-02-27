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
      premiumFlag: json['premium_flag'] as bool? ?? false,
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
    };
  }

  /// Static registry for Judge Selection 2.0. Order: Cupid, Poetic, Gremlin, Ex, Dr. Love.
  /// Aura colors: Cupid pink/red, Poetic violet, Gremlin green, Ex dark red, Dr. Love gold.
  static const List<Judge> selectionList = [
    Judge(
      id: 'sassy_cupid',
      personaId: 'sassy_cupid',
      name: 'Sassy Cupid',
      accentColorHex: 'FF6B9D',
      primaryColorHex: 'FF6B9D',
      premiumFlag: false,
      tagline: 'Love is a battlefield.',
      difficultyLevel: 2,
      chaosLevel: 1,
      toneTags: ['Romantic', 'Strict'],
      previewQuotes: [
        'Bring your A-game.',
        'I\'ve seen better.',
        'Try again, sweetheart.',
      ],
    ),
    Judge(
      id: 'poetic_romantic',
      personaId: 'poetic_romantic',
      name: 'Poetic Romantic',
      accentColorHex: 'C44569',
      primaryColorHex: '6B4C7A',
      premiumFlag: false,
      tagline: 'Where words become magic.',
      difficultyLevel: 2,
      chaosLevel: 1,
      toneTags: ['Romantic', 'Poetic'],
      previewQuotes: [
        'Speak from the heart.',
        'More feeling, less logic.',
        'Romance me with your words.',
      ],
    ),
    Judge(
      id: 'chaos_gremlin',
      personaId: 'chaos_gremlin',
      name: 'Chaos Gremlin',
      accentColorHex: 'F8B500',
      primaryColorHex: '7CB342',
      premiumFlag: true,
      tagline: 'Convince me… if you dare.',
      difficultyLevel: 4,
      chaosLevel: 5,
      toneTags: ['Chaotic'],
      previewQuotes: [
        'Beg harder.',
        'That was cute.',
        'You think that\'ll work?',
      ],
    ),
    Judge(
      id: 'the_ex',
      personaId: 'the_ex',
      name: 'The Ex',
      accentColorHex: '8B5A6B',
      primaryColorHex: '8B0000',
      premiumFlag: true,
      tagline: 'I\'ve heard it all before.',
      difficultyLevel: 3,
      chaosLevel: 3,
      toneTags: ['Strict'],
      previewQuotes: [
        'Prove it.',
        'Actions speak louder.',
        'Don\'t waste my time.',
      ],
    ),
    Judge(
      id: 'dr_love',
      personaId: 'dr_love',
      name: 'Dr. Love',
      accentColorHex: '6B9D7A',
      primaryColorHex: 'D4A574',
      premiumFlag: true,
      tagline: 'Science meets romance.',
      difficultyLevel: 2,
      chaosLevel: 2,
      toneTags: ['Analytical', 'Romantic'],
      previewQuotes: [
        'Data doesn\'t lie.',
        'Show me the chemistry.',
        'Logical love wins.',
      ],
    ),
  ];

  /// Resolves a Judge from a surprise's judgePersona. Fallback to first if unknown.
  static Judge forPersonaId(String personaId) {
    for (final j in selectionList) {
      if (j.personaId == personaId) return j;
    }
    return selectionList.first;
  }
}
