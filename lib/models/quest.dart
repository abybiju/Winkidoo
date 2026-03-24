/// A Love Quest: a chain of 3-7 linked surprises forming a narrative arc.
/// Both partners alternate as creator/seeker. Difficulty escalates.
/// The AI Judge remembers across the chain.
class Quest {
  const Quest({
    required this.id,
    required this.coupleId,
    required this.creatorId,
    required this.title,
    this.description,
    required this.totalSteps,
    this.currentStep = 0,
    this.status = 'active',
    required this.judgePersona,
    this.difficultyStart = 1,
    this.difficultyEnd = 3,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String coupleId;
  final String creatorId;
  final String title;
  final String? description;
  final int totalSteps;
  final int currentStep;

  /// active | completed | abandoned
  final String status;
  final String judgePersona;
  final int difficultyStart;
  final int difficultyEnd;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isBossBattle => currentStep == totalSteps - 1;

  /// Progress as a fraction 0.0–1.0.
  double get progress =>
      totalSteps > 0 ? currentStep / totalSteps : 0.0;

  /// Interpolated difficulty for the current step.
  int get currentDifficulty {
    if (totalSteps <= 1) return difficultyStart;
    final t = currentStep / (totalSteps - 1);
    return (difficultyStart + (difficultyEnd - difficultyStart) * t).round().clamp(1, 5);
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      totalSteps: json['total_steps'] as int? ?? 3,
      currentStep: json['current_step'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      judgePersona: json['judge_persona'] as String? ?? 'sassy_cupid',
      difficultyStart: json['difficulty_start'] as int? ?? 1,
      difficultyEnd: json['difficulty_end'] as int? ?? 3,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'total_steps': totalSteps,
      'current_step': currentStep,
      'status': status,
      'judge_persona': judgePersona,
      'difficulty_start': difficultyStart,
      'difficulty_end': difficultyEnd,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
