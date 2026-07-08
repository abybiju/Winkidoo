import 'package:flutter_test/flutter_test.dart';
import 'package:winkidoo/models/character_chat_message.dart';
import 'package:winkidoo/models/scene_pack.dart';
import 'package:winkidoo/models/scene_session.dart';

void main() {
  group('CharacterChatMessage back-compat', () {
    test('row without message_type parses as user message', () {
      final msg = CharacterChatMessage.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'original_content': 'hello',
        'created_at': '2026-07-08T10:00:00Z',
      });
      expect(msg.messageType, 'user');
      expect(msg.isUserMessage, isTrue);
      expect(msg.isDirector, isFalse);
      expect(msg.senderId, 'u1');
      expect(msg.payload, isNull);
    });

    test('director row with null sender parses', () {
      final msg = CharacterChatMessage.fromJson({
        'id': 'm2',
        'room_id': 'r1',
        'sender_id': null,
        'original_content': 'ACT 1 — the lights go out.',
        'message_type': 'director',
        'payload': {'type': 'act_open', 'act': 1},
        'created_at': '2026-07-08T10:00:00Z',
      });
      expect(msg.senderId, isNull);
      expect(msg.isDirector, isTrue);
      expect(msg.isUserMessage, isFalse);
      expect(msg.payload?['act'], 1);
    });

    test('castmate/game_card/system getters dispatch correctly', () {
      CharacterChatMessage of(String type) => CharacterChatMessage.fromJson({
            'id': 'm-$type',
            'room_id': 'r1',
            'sender_id': null,
            'original_content': 'x',
            'message_type': type,
            'created_at': '2026-07-08T10:00:00Z',
          });
      expect(of('castmate').isCastmate, isTrue);
      expect(of('game_card').isGameCard, isTrue);
      expect(of('system').isSystem, isTrue);
    });
  });

  group('ScenePack', () {
    final json = {
      'id': 'p1',
      'slug': 'haunted-mansion',
      'name': 'Haunted Mansion',
      'tagline': 'Something walks the halls',
      'emoji': '👻',
      'act_count': 3,
      'min_players': 1,
      'max_players': 6,
      'is_premium': false,
      'season_start': null,
      'season_end': null,
      'sort_order': 1,
    };

    test('parses and reports non-seasonal', () {
      final pack = ScenePack.fromJson(json);
      expect(pack.slug, 'haunted-mansion');
      expect(pack.actCount, 3);
      expect(pack.isSeasonal, isFalse);
      expect(pack.daysRemaining, isNull);
    });

    test('seasonal pack computes days remaining, floored at 0', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final past = DateTime.now().subtract(const Duration(days: 3));
      final live = ScenePack.fromJson(
          {...json, 'season_end': future.toIso8601String()});
      final over = ScenePack.fromJson(
          {...json, 'season_end': past.toIso8601String()});
      expect(live.isSeasonal, isTrue);
      expect(live.daysRemaining, inInclusiveRange(9, 10));
      expect(over.daysRemaining, 0);
    });
  });

  group('SceneCharacter', () {
    test('toCharacterPreset bridges into the transform pipeline', () {
      final character = SceneCharacter.fromJson({
        'id': 'c1',
        'pack_id': 'p1',
        'slug': 'dramatic-ghost',
        'name': 'The Dramatic Ghost',
        'emoji': '👻',
        'voice_prompt': 'Speak in theatrical wails.',
        'is_lead': true,
      });
      final preset = character.toCharacterPreset();
      expect(preset.id, 'scene:dramatic-ghost');
      expect(preset.name, 'The Dramatic Ghost');
      expect(preset.systemPrompt, 'Speak in theatrical wails.');
      expect(preset.isBuiltIn, isFalse);
    });
  });

  group('SceneSession', () {
    test('parses status and busy lease', () {
      final session = SceneSession.fromJson({
        'id': 's1',
        'room_id': 'r1',
        'pack_id': 'p1',
        'status': 'live',
        'current_act': 2,
        'user_msgs_in_act': 5,
        'version': 7,
        'director_busy_until':
            DateTime.now().add(const Duration(seconds: 20)).toIso8601String(),
        'created_by': 'u1',
      });
      expect(session.isLive, isTrue);
      expect(session.currentAct, 2);
      expect(session.version, 7);
      expect(session.directorBusy, isTrue);
    });

    test('unknown status falls back to casting; stale lease is not busy', () {
      final session = SceneSession.fromJson({
        'id': 's1',
        'room_id': 'r1',
        'pack_id': 'p1',
        'status': 'bogus',
        'created_by': 'u1',
        'director_busy_until': DateTime.now()
            .subtract(const Duration(seconds: 5))
            .toIso8601String(),
      });
      expect(session.status, SceneStatus.casting);
      expect(session.directorBusy, isFalse);
    });
  });

  group('SceneCastMember', () {
    test('parses AI and human rows; secret goal only when present', () {
      final ai = SceneCastMember.fromJson({
        'cast_id': 'c1',
        'character_id': 'ch1',
        'character_slug': 'nervous-butler',
        'character_name': 'The Nervous Butler',
        'user_id': null,
        'is_ai': true,
      });
      final human = SceneCastMember.fromJson({
        'cast_id': 'c2',
        'character_id': 'ch2',
        'character_slug': 'occult-aunt',
        'character_name': 'The Occult Aunt',
        'user_id': 'u9',
        'is_ai': false,
        'display_name': 'Maya',
        'secret_goal': 'You suspect the portrait.',
      });
      expect(ai.isAi, isTrue);
      expect(ai.playerLabel, 'AI castmate');
      expect(human.playerLabel, 'Maya');
      expect(human.secretGoal, 'You suspect the portrait.');
    });
  });
}
