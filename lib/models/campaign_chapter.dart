class CampaignChapter {
  const CampaignChapter({
    required this.id,
    required this.campaignId,
    required this.chapterNumber,
    required this.title,
    this.introDialogue,
    this.outroDialogue,
    this.personaMoodOverride,
    required this.questCount,
    required this.difficultyStart,
    required this.difficultyEnd,
  });

  final String id;
  final String campaignId;
  final int chapterNumber;
  final String title;
  final String? introDialogue;
  final String? outroDialogue;
  final String? personaMoodOverride;
  final int questCount;
  final int difficultyStart;
  final int difficultyEnd;

  factory CampaignChapter.fromJson(Map<String, dynamic> json) {
    return CampaignChapter(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      chapterNumber: json['chapter_number'] as int,
      title: json['title'] as String,
      introDialogue: json['intro_dialogue'] as String?,
      outroDialogue: json['outro_dialogue'] as String?,
      personaMoodOverride: json['persona_mood_override'] as String?,
      questCount: json['quest_count'] as int? ?? 3,
      difficultyStart: json['difficulty_start'] as int? ?? 1,
      difficultyEnd: json['difficulty_end'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'chapter_number': chapterNumber,
      'title': title,
      'intro_dialogue': introDialogue,
      'outro_dialogue': outroDialogue,
      'persona_mood_override': personaMoodOverride,
      'quest_count': questCount,
      'difficulty_start': difficultyStart,
      'difficulty_end': difficultyEnd,
    };
  }
}
