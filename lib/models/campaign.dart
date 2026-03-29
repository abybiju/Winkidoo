class Campaign {
  const Campaign({
    required this.id,
    this.packId,
    required this.slug,
    required this.title,
    this.subtitle,
    this.description,
    this.coverAssetPath,
    required this.totalChapters,
    required this.judgePersona,
    required this.difficultyCurve,
    required this.isActive,
    required this.isPremium,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String? packId;
  final String slug;
  final String title;
  final String? subtitle;
  final String? description;
  final String? coverAssetPath;
  final int totalChapters;
  final String judgePersona;
  final String difficultyCurve;
  final bool isActive;
  final bool isPremium;
  final int sortOrder;
  final DateTime createdAt;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      packId: json['pack_id'] as String?,
      slug: json['slug'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      coverAssetPath: json['cover_asset_path'] as String?,
      totalChapters: json['total_chapters'] as int? ?? 5,
      judgePersona: json['judge_persona'] as String,
      difficultyCurve: (json['difficulty_curve'] as String?) ?? 'linear',
      isActive: json['is_active'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pack_id': packId,
      'slug': slug,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'cover_asset_path': coverAssetPath,
      'total_chapters': totalChapters,
      'judge_persona': judgePersona,
      'difficulty_curve': difficultyCurve,
      'is_active': isActive,
      'is_premium': isPremium,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
