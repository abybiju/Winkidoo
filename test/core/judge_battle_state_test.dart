import 'package:flutter_test/flutter_test.dart';
import 'package:winkidoo/core/utils/judge_battle_state.dart';
import 'package:winkidoo/models/battle_message.dart';

BattleMessage _msg(String senderType, String content, {bool isVerdict = false}) {
  return BattleMessage(
    id: 'id-$content',
    surpriseId: 's1',
    senderType: senderType,
    senderId: null,
    content: content,
    isVerdict: isVerdict,
    verdictScore: null,
    verdictUnlocked: null,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('stageFromProgress', () {
    test('maps progress bands to the blueprint ladder', () {
      expect(JudgeBattleState.stageFromProgress(0.0), JudgeStage.cold);
      expect(JudgeBattleState.stageFromProgress(0.24), JudgeStage.cold);
      expect(JudgeBattleState.stageFromProgress(0.25), JudgeStage.curious);
      expect(JudgeBattleState.stageFromProgress(0.49), JudgeStage.curious);
      expect(JudgeBattleState.stageFromProgress(0.50), JudgeStage.intrigued);
      expect(JudgeBattleState.stageFromProgress(0.74), JudgeStage.intrigued);
      expect(JudgeBattleState.stageFromProgress(0.75), JudgeStage.cracking);
      expect(JudgeBattleState.stageFromProgress(0.99), JudgeStage.cracking);
      expect(JudgeBattleState.stageFromProgress(1.0), JudgeStage.cracking);
    });

    test('clamps out-of-range input', () {
      expect(JudgeBattleState.stageFromProgress(-0.5), JudgeStage.cold);
      expect(JudgeBattleState.stageFromProgress(3.0), JudgeStage.cracking);
    });
  });

  group('stageDirective', () {
    test('every stage returns non-empty text with the scoring firewall', () {
      for (final stage in JudgeStage.values) {
        final directive = JudgeBattleState.stageDirective(stage);
        expect(directive, isNotEmpty);
        expect(directive, contains(JudgeBattleState.scoringFirewall),
            reason: 'stage $stage must never authorize score changes');
      }
    });
  });

  group('recentJudgeLines', () {
    test('keeps only non-verdict judge lines, in order', () {
      final lines = JudgeBattleState.recentJudgeLines([
        _msg('judge', 'opener'),
        _msg('seeker', 'plea'),
        _msg('judge', 'retort'),
        _msg('creator', 'defense'),
        _msg('judge', 'verdict speech', isVerdict: true),
        _msg('judge', 'final tease'),
      ]);
      expect(lines, ['opener', 'retort', 'final tease']);
    });

    test('respects limit by keeping the most recent lines', () {
      final messages = List.generate(10, (i) => _msg('judge', 'line$i'));
      final lines = JudgeBattleState.recentJudgeLines(messages, limit: 3);
      expect(lines, ['line7', 'line8', 'line9']);
    });

    test('truncates long lines', () {
      final long = 'x' * 500;
      final lines = JudgeBattleState.recentJudgeLines([_msg('judge', long)]);
      expect(lines.single.length, 201); // 200 chars + ellipsis
      expect(lines.single.endsWith('…'), isTrue);
    });

    test('empty input yields empty list', () {
      expect(JudgeBattleState.recentJudgeLines([]), isEmpty);
    });
  });

  group('trimHistory', () {
    test('returns everything untrimmed when at or under max', () {
      final messages = List.generate(40, (i) => _msg('seeker', 'm$i'));
      final result = JudgeBattleState.trimHistory(messages);
      expect(result.kept, hasLength(40));
      expect(result.omitted, 0);
    });

    test('keeps head and tail and counts omitted when over max', () {
      final messages = List.generate(50, (i) => _msg('seeker', 'm$i'));
      final result = JudgeBattleState.trimHistory(messages);
      expect(result.kept, hasLength(32)); // head 2 + tail 30
      expect(result.omitted, 18);
      expect(result.kept.first.content, 'm0');
      expect(result.kept[1].content, 'm1');
      expect(result.kept[2].content, 'm20'); // tail starts at 50-30
      expect(result.kept.last.content, 'm49');
    });
  });
}
