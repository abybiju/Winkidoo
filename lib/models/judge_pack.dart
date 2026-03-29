class JudgePack {
  const JudgePack({
    required this.id,
    required this.slug,
    required this.name,
    this.tagline,
    this.description,
    this.coverAssetPath,
    this.primaryColorHex,
    this.secondaryColorHex,
    required this.isActive,
    required this.isPremium,
    this.seasonStart,
    this.seasonEnd,
    required this.bpMultiplier,
    required this.sortOrder,
    this.brandPartner,
    this.brandMetadata = const {},
    required this.createdAt,
  });

  final String id;
  final String slug;
  final String name;
  final String? tagline;
  final String? description;
  final String? coverAssetPath;
  final String? primaryColorHex;
  final String? secondaryColorHex;
  final bool isActive;
  final bool isPremium;
  final DateTime? seasonStart;
  final DateTime? seasonEnd;
  final double bpMultiplier;
  final int sortOrder;
  final String? brandPartner;
  final Map<String, dynamic> brandMetadata;
  final DateTime createdAt;

  bool get isSeasonal => seasonStart != null && seasonEnd != null;

  bool get isInSeason {
    if (!isSeasonal) return true;
    final now = DateTime.now().toUtc();
    return now.isAfter(seasonStart!) && now.isBefore(seasonEnd!);
  }

  int get daysRemaining {
    if (seasonEnd == null) return -1;
    return seasonEnd!.difference(DateTime.now().toUtc()).inDays;
  }

  factory JudgePack.fromJson(Map<String, dynamic> json) {
    return JudgePack(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String?,
      description: json['description'] as String?,
      coverAssetPath: json['cover_asset_path'] as String?,
      primaryColorHex: json['primary_color_hex'] as String?,
      secondaryColorHex: json['secondary_color_hex'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      seasonStart: json['season_start'] != null
          ? DateTime.parse(json['season_start'] as String)
          : null,
      seasonEnd: json['season_end'] != null
          ? DateTime.parse(json['season_end'] as String)
          : null,
      bpMultiplier: (json['bp_multiplier'] as num?)?.toDouble() ?? 1.0,
      sortOrder: json['sort_order'] as int? ?? 0,
      brandPartner: json['brand_partner'] as String?,
      brandMetadata: json['brand_metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'tagline': tagline,
      'description': description,
      'cover_asset_path': coverAssetPath,
      'primary_color_hex': primaryColorHex,
      'secondary_color_hex': secondaryColorHex,
      'is_active': isActive,
      'is_premium': isPremium,
      'season_start': seasonStart?.toIso8601String(),
      'season_end': seasonEnd?.toIso8601String(),
      'bp_multiplier': bpMultiplier,
      'sort_order': sortOrder,
      'brand_partner': brandPartner,
      'brand_metadata': brandMetadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
