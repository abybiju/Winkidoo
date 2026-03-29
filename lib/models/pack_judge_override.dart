class PackJudgeOverride {
  const PackJudgeOverride({
    required this.id,
    required this.packId,
    required this.judgePersona,
    this.overrideName,
    this.overrideTagline,
    this.overrideAvatarPath,
    this.overridePrimaryColorHex,
    this.overridePersonaPrompt,
    this.overrideHowToImpress,
    required this.sortOrder,
  });

  final String id;
  final String packId;
  final String judgePersona;
  final String? overrideName;
  final String? overrideTagline;
  final String? overrideAvatarPath;
  final String? overridePrimaryColorHex;
  final String? overridePersonaPrompt;
  final String? overrideHowToImpress;
  final int sortOrder;

  factory PackJudgeOverride.fromJson(Map<String, dynamic> json) {
    return PackJudgeOverride(
      id: json['id'] as String,
      packId: json['pack_id'] as String,
      judgePersona: json['judge_persona'] as String,
      overrideName: json['override_name'] as String?,
      overrideTagline: json['override_tagline'] as String?,
      overrideAvatarPath: json['override_avatar_path'] as String?,
      overridePrimaryColorHex: json['override_primary_color_hex'] as String?,
      overridePersonaPrompt: json['override_persona_prompt'] as String?,
      overrideHowToImpress: json['override_how_to_impress'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pack_id': packId,
      'judge_persona': judgePersona,
      'override_name': overrideName,
      'override_tagline': overrideTagline,
      'override_avatar_path': overrideAvatarPath,
      'override_primary_color_hex': overridePrimaryColorHex,
      'override_persona_prompt': overridePersonaPrompt,
      'override_how_to_impress': overrideHowToImpress,
      'sort_order': sortOrder,
    };
  }
}
