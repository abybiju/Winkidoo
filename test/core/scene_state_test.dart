import 'package:flutter_test/flutter_test.dart';
import 'package:winkidoo/core/utils/scene_state.dart';

/// Mirrors decideTick in supabase/functions/scene-director/index.ts —
/// thresholds and precedence must stay in sync with the server.
void main() {
  SceneTurn? decide({
    int userMsgsInAct = 0,
    int msgsSinceDirector = 0,
    int msgsSinceCastmate = 0,
    int castmateMsgsInAct = 0,
    int minUserMessages = 12,
    int aiCastCount = 3,
  }) =>
      SceneState.decideTick(
        userMsgsInAct: userMsgsInAct,
        msgsSinceDirector: msgsSinceDirector,
        msgsSinceCastmate: msgsSinceCastmate,
        castmateMsgsInAct: castmateMsgsInAct,
        minUserMessages: minUserMessages,
        aiCastCount: aiCastCount,
      );

  group('decideTick precedence', () {
    test('nothing due on a quiet fresh act', () {
      expect(decide(msgsSinceCastmate: 1), isNull);
    });

    test('castmate reply due after threshold', () {
      expect(decide(msgsSinceCastmate: 2), SceneTurn.castmateReply);
    });

    test('director beat outranks castmate', () {
      expect(
        decide(msgsSinceDirector: 6, msgsSinceCastmate: 6),
        SceneTurn.directorBeat,
      );
    });

    test('act close outranks everything', () {
      expect(
        decide(
          userMsgsInAct: 12,
          msgsSinceDirector: 10,
          msgsSinceCastmate: 10,
        ),
        SceneTurn.actClose,
      );
    });
  });

  group('decideTick caps', () {
    test('no castmate reply without AI cast', () {
      expect(decide(msgsSinceCastmate: 5, aiCastCount: 0), isNull);
    });

    test('castmate silenced at per-act cap', () {
      expect(
        decide(msgsSinceCastmate: 5, castmateMsgsInAct: 8),
        isNull,
      );
      expect(
        decide(msgsSinceCastmate: 5, castmateMsgsInAct: 7),
        SceneTurn.castmateReply,
      );
    });

    test('act closes exactly at the act threshold', () {
      expect(decide(userMsgsInAct: 11), isNull);
      expect(decide(userMsgsInAct: 12), SceneTurn.actClose);
    });

    test('custom act threshold respected', () {
      expect(
        decide(userMsgsInAct: 10, minUserMessages: 10),
        SceneTurn.actClose,
      );
    });
  });

  group('actProgress', () {
    test('progresses linearly and clamps', () {
      expect(
        SceneState.actProgress(userMsgsInAct: 0, minUserMessages: 12),
        0.0,
      );
      expect(
        SceneState.actProgress(userMsgsInAct: 6, minUserMessages: 12),
        closeTo(0.5, 0.001),
      );
      expect(
        SceneState.actProgress(userMsgsInAct: 20, minUserMessages: 12),
        1.0,
      );
    });

    test('degenerate zero threshold is full', () {
      expect(
        SceneState.actProgress(userMsgsInAct: 0, minUserMessages: 0),
        1.0,
      );
    });
  });
}
