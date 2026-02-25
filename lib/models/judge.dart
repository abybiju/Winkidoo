/// Judge metadata (avatar, accent, seasonal). Persona ID is the source of truth; this is optional UI data.
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

  factory Judge.fromJson(Map<String, dynamic> json) {
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
    };
  }
}
