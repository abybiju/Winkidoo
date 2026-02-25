import 'package:flutter_test/flutter_test.dart';
import 'package:winkidoo/models/surprise.dart';

void main() {
  group('Surprise', () {
    test('fromJson parses text surprise', () {
      final json = {
        'id': 'id1',
        'couple_id': 'c1',
        'creator_id': 'u1',
        'content_encrypted': 'enc',
        'unlock_method': 'persuade',
        'judge_persona': 'sassy_cupid',
        'difficulty_level': 2,
        'auto_delete_at': null,
        'is_unlocked': false,
        'unlocked_at': null,
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final s = Surprise.fromJson(json);
      expect(s.id, 'id1');
      expect(s.surpriseType, 'text');
      expect(s.isPhoto, false);
      expect(s.isVoice, false);
    });

    test('fromJson parses photo surprise with storage path', () {
      final json = {
        'id': 'id2',
        'couple_id': 'c1',
        'creator_id': 'u1',
        'content_encrypted': '',
        'unlock_method': 'collaborate',
        'judge_persona': 'poetic_romantic',
        'difficulty_level': 3,
        'is_unlocked': false,
        'created_at': '2026-01-01T00:00:00.000Z',
        'surprise_type': 'photo',
        'content_storage_path': 'c1/id2.jpg',
      };
      final s = Surprise.fromJson(json);
      expect(s.surpriseType, 'photo');
      expect(s.isPhoto, true);
      expect(s.contentStoragePath, 'c1/id2.jpg');
    });
  });
}
