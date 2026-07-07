import 'package:flutter_test/flutter_test.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/services/ai_judge_service.dart';

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

const _builtInPersonas = [
  AppConstants.personaSassyCupid,
  AppConstants.personaPoeticRomantic,
  AppConstants.personaChaosGremlin,
  AppConstants.personaTheEx,
  AppConstants.personaDrLove,
];

void main() {
  group('buildBattleStateBlock', () {
    final messages = [
      _msg('judge', 'Show me a real memory.'),
      _msg('seeker', 'Remember the beach trip?'),
      _msg('judge', 'Better. Now make me laugh.'),
    ];

    test('contains turn, meter, stage, judge lines, and demand rules', () {
      final block = AiJudgeService.buildBattleStateBlock(
        messages: messages,
        meterProgress: 0.6,
        turnNumber: 3,
      );
      expect(block, contains('turn 3'));
      expect(block, contains('60%'));
      expect(block, contains('INTRIGUED'));
      expect(block, contains('Show me a real memory.'));
      expect(block, contains('Better. Now make me laugh.'));
      expect(block, contains('never ask for it again'));
      expect(block, contains('ACTIVE-DEMAND RULES'));
    });

    test('returns empty string when there is nothing to say', () {
      final block = AiJudgeService.buildBattleStateBlock(
        messages: [_msg('seeker', 'hello')],
        meterProgress: null,
        turnNumber: null,
      );
      expect(block, isEmpty);
    });

    test('omits meter lines when meterProgress is null but lists judge lines',
        () {
      final block = AiJudgeService.buildBattleStateBlock(
        messages: messages,
        meterProgress: null,
        turnNumber: null,
      );
      expect(block, isNot(contains('Persuasion meter')));
      expect(block, contains('Show me a real memory.'));
      expect(block, contains('ACTIVE-DEMAND RULES'));
    });

    test('excludes seeker/creator/verdict content from the do-not-repeat list',
        () {
      final block = AiJudgeService.buildBattleStateBlock(
        messages: [
          _msg('seeker', 'seeker-words'),
          _msg('creator', 'creator-words'),
          _msg('judge', 'verdict-words', isVerdict: true),
          _msg('judge', 'judge-words'),
        ],
        meterProgress: 0.1,
        turnNumber: 1,
      );
      expect(block, contains('judge-words'));
      expect(block, isNot(contains('seeker-words')));
      expect(block, isNot(contains('creator-words')));
      expect(block, isNot(contains('verdict-words')));
    });
  });

  group('persona character sheets', () {
    test('every built-in persona has a full character sheet', () {
      for (final persona in _builtInPersonas) {
        final sheet = AiJudgeService.personaPromptsForTest[persona];
        expect(sheet, isNotNull, reason: 'missing sheet for $persona');
        expect(sheet, contains('CHARACTER SHEET'),
            reason: '$persona lost its sheet header');
        expect(sheet, contains('NEVER'),
            reason: '$persona lost its banned-lines section');
        expect(sheet, contains('Example lines'),
            reason: '$persona lost its style-reference examples');
      }
    });
  });

  group('opening angles', () {
    test('every built-in persona has at least 4 angles', () {
      for (final persona in _builtInPersonas) {
        expect(AiJudgeService.openingAnglesForTest[persona], isNotNull);
        expect(
            AiJudgeService.openingAnglesForTest[persona]!.length,
            greaterThanOrEqualTo(4),
            reason: '$persona opening pool too small for variety');
      }
    });

    test('generic pool (custom/pack judges) is non-empty', () {
      expect(AiJudgeService.genericOpeningAnglesForTest, isNotEmpty);
    });
  });
}
