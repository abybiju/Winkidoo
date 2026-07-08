/// Scene Party session state for a room (scene_sessions table).
enum SceneStatus { casting, live, ended }

class SceneSession {
  const SceneSession({
    required this.id,
    required this.roomId,
    required this.packId,
    required this.status,
    required this.currentAct,
    this.actStartedAt,
    this.userMsgsInAct = 0,
    this.version = 0,
    this.directorBusyUntil,
    required this.createdBy,
    this.endedAt,
  });

  final String id;
  final String roomId;
  final String packId;
  final SceneStatus status;
  final int currentAct;
  final DateTime? actStartedAt;
  final int userMsgsInAct;
  final int version;
  final DateTime? directorBusyUntil;
  final String createdBy;
  final DateTime? endedAt;

  bool get isCasting => status == SceneStatus.casting;
  bool get isLive => status == SceneStatus.live;
  bool get isEnded => status == SceneStatus.ended;

  bool get directorBusy =>
      directorBusyUntil != null && directorBusyUntil!.isAfter(DateTime.now());

  factory SceneSession.fromJson(Map<String, dynamic> json) {
    return SceneSession(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      packId: json['pack_id'] as String,
      status: SceneStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'casting'),
        orElse: () => SceneStatus.casting,
      ),
      currentAct: json['current_act'] as int? ?? 0,
      actStartedAt: json['act_started_at'] != null
          ? DateTime.parse(json['act_started_at'] as String)
          : null,
      userMsgsInAct: json['user_msgs_in_act'] as int? ?? 0,
      version: json['version'] as int? ?? 0,
      directorBusyUntil: json['director_busy_until'] != null
          ? DateTime.parse(json['director_busy_until'] as String)
          : null,
      createdBy: json['created_by'] as String,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }
}

/// One cast slot: a pack character claimed by a player or played by the AI.
/// Shape matches the get_scene_cast RPC.
class SceneCastMember {
  const SceneCastMember({
    required this.castId,
    required this.characterId,
    required this.characterSlug,
    required this.characterName,
    this.characterEmoji,
    this.characterColorHex,
    this.characterTagline,
    this.isLead = false,
    this.sortOrder = 0,
    this.userId,
    required this.isAi,
    this.displayName,
    this.bestPerformanceCount = 0,
    this.gamePoints = 0,
    this.secretGoal,
  });

  final String castId;
  final String characterId;
  final String characterSlug;
  final String characterName;
  final String? characterEmoji;
  final String? characterColorHex;
  final String? characterTagline;
  final bool isLead;
  final int sortOrder;
  final String? userId;
  final bool isAi;
  final String? displayName;
  final int bestPerformanceCount;
  final int gamePoints;

  /// Only present on the caller's own row (server-enforced).
  final String? secretGoal;

  String get playerLabel => isAi ? 'AI castmate' : (displayName ?? 'Friend');

  factory SceneCastMember.fromJson(Map<String, dynamic> json) {
    return SceneCastMember(
      castId: json['cast_id'] as String,
      characterId: json['character_id'] as String,
      characterSlug: json['character_slug'] as String,
      characterName: json['character_name'] as String,
      characterEmoji: json['character_emoji'] as String?,
      characterColorHex: json['character_color_hex'] as String?,
      characterTagline: json['character_tagline'] as String?,
      isLead: json['is_lead'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      userId: json['user_id'] as String?,
      isAi: json['is_ai'] as bool? ?? true,
      displayName: json['display_name'] as String?,
      bestPerformanceCount: json['best_performance_count'] as int? ?? 0,
      gamePoints: json['game_points'] as int? ?? 0,
      secretGoal: json['secret_goal'] as String?,
    );
  }
}
