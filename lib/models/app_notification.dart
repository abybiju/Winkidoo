enum NotificationType {
  surpriseNew,
  battleUpdate,
  dare,
  dareResult,
  miniGame,
  miniGameResult,
  campaign,
  customJudgeReady,
  seasonLaunch,
  unknown;

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'surprise_new':
        return surpriseNew;
      case 'battle_update':
        return battleUpdate;
      case 'dare':
        return dare;
      case 'dare_result':
        return dareResult;
      case 'mini_game':
        return miniGame;
      case 'mini_game_result':
        return miniGameResult;
      case 'campaign':
        return campaign;
      case 'custom_judge_ready':
        return customJudgeReady;
      case 'season_launch':
        return seasonLaunch;
      default:
        return unknown;
    }
  }

  String get dbValue {
    switch (this) {
      case surpriseNew:
        return 'surprise_new';
      case battleUpdate:
        return 'battle_update';
      case dare:
        return 'dare';
      case dareResult:
        return 'dare_result';
      case miniGame:
        return 'mini_game';
      case miniGameResult:
        return 'mini_game_result';
      case campaign:
        return 'campaign';
      case customJudgeReady:
        return 'custom_judge_ready';
      case seasonLaunch:
        return 'season_launch';
      case unknown:
        return 'unknown';
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.dbValue,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
