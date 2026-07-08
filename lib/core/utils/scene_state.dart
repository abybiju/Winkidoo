/// Pure Scene Party turn-policy logic — the Dart mirror of the decision
/// function in supabase/functions/scene-director/index.ts. The server is
/// authoritative; the client uses this only to predict UI states ("Director
/// is about to speak", act progress) without waiting for realtime.
///
/// Thresholds MUST stay in sync with the edge function:
///   directorBeatEvery = 6, castmateReplyEvery = 2, castmateMaxPerAct = 8.
library;

enum SceneTurn { actClose, directorBeat, castmateReply }

class SceneState {
  SceneState._();

  static const int directorBeatEvery = 6;
  static const int castmateReplyEvery = 2;
  static const int castmateMaxPerAct = 8;

  /// Which unit of work the Director engine will run on the next tick.
  /// Priority: act close > director beat > castmate reply. Null = nothing due.
  static SceneTurn? decideTick({
    required int userMsgsInAct,
    required int msgsSinceDirector,
    required int msgsSinceCastmate,
    required int castmateMsgsInAct,
    required int minUserMessages,
    required int aiCastCount,
  }) {
    if (userMsgsInAct >= minUserMessages) return SceneTurn.actClose;
    if (msgsSinceDirector >= directorBeatEvery) return SceneTurn.directorBeat;
    if (msgsSinceCastmate >= castmateReplyEvery &&
        aiCastCount > 0 &&
        castmateMsgsInAct < castmateMaxPerAct) {
      return SceneTurn.castmateReply;
    }
    return null;
  }

  /// Progress through the current act (0..1) for the header meter.
  static double actProgress({
    required int userMsgsInAct,
    required int minUserMessages,
  }) {
    if (minUserMessages <= 0) return 1.0;
    return (userMsgsInAct / minUserMessages).clamp(0.0, 1.0);
  }
}
