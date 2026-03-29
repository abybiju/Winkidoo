class CampaignProgress {
  const CampaignProgress({
    required this.id,
    required this.coupleId,
    required this.campaignId,
    required this.currentChapter,
    required this.status,
    required this.startedAt,
    this.completedAt,
  });

  final String id;
  final String coupleId;
  final String campaignId;
  final int currentChapter;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  factory CampaignProgress.fromJson(Map<String, dynamic> json) {
    return CampaignProgress(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      campaignId: json['campaign_id'] as String,
      currentChapter: json['current_chapter'] as int? ?? 1,
      status: (json['status'] as String?) ?? 'active',
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'campaign_id': campaignId,
      'current_chapter': currentChapter,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
