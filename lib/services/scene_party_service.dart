import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/scene_pack.dart';
import 'package:winkidoo/models/scene_session.dart';

/// Data access for Scene Party: packs (server-side content), sessions, cast.
/// All writes go through SECURITY DEFINER RPCs (migration 058) — the client
/// never inserts/updates scene tables directly.
class ScenePartyService {
  ScenePartyService(this._client);

  final SupabaseClient _client;

  /// Active packs, season-window filtered, seasonal-first (judge_packs pattern).
  Future<List<ScenePack>> getActivePacks() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('scene_packs')
          .select()
          .eq('is_active', true)
          .or('season_start.is.null,season_start.lte.$now')
          .or('season_end.is.null,season_end.gte.$now')
          .order('sort_order')
          .order('name');
      return (rows as List)
          .map((r) => ScenePack.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ScenePartyService.getActivePacks: $e');
      return [];
    }
  }

  Future<ScenePack?> getPackBySlug(String slug) async {
    try {
      final row = await _client
          .from('scene_packs')
          .select()
          .eq('slug', slug)
          .maybeSingle();
      return row == null ? null : ScenePack.fromJson(row);
    } catch (e) {
      debugPrint('ScenePartyService.getPackBySlug: $e');
      return null;
    }
  }

  Future<ScenePack?> getPackById(String id) async {
    try {
      final row =
          await _client.from('scene_packs').select().eq('id', id).maybeSingle();
      return row == null ? null : ScenePack.fromJson(row);
    } catch (e) {
      debugPrint('ScenePartyService.getPackById: $e');
      return null;
    }
  }

  Future<List<SceneCharacter>> getPackCharacters(String packId) async {
    try {
      final rows = await _client
          .from('scene_characters')
          .select(
              'id, pack_id, slug, name, emoji, color_hex, tagline, voice_prompt, is_lead, sort_order')
          .eq('pack_id', packId)
          .order('sort_order')
          .order('name');
      return (rows as List)
          .map((r) => SceneCharacter.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ScenePartyService.getPackCharacters: $e');
      return [];
    }
  }

  Future<List<SceneActTemplate>> getPackActs(String packId) async {
    try {
      final rows = await _client
          .from('scene_act_templates')
          .select('act_number, title, min_user_messages')
          .eq('pack_id', packId)
          .order('act_number');
      return (rows as List)
          .map((r) => SceneActTemplate.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ScenePartyService.getPackActs: $e');
      return [];
    }
  }

  /// Creates room + session + all-AI cast. Returns the new room id.
  /// Throws on PREMIUM_REQUIRED / pack-inactive so the UI can react.
  Future<String> createSceneSession({
    required String packId,
    String? name,
    required List<String> memberIds,
  }) async {
    final roomId = await _client.rpc('create_scene_session', params: {
      'p_pack_id': packId,
      'p_name': name,
      'p_member_ids': memberIds,
    });
    return roomId as String;
  }

  /// Claims a character (releases the caller's previous claim).
  /// Throws with CHARACTER_TAKEN when a human already holds it.
  Future<void> claimCharacter({
    required String roomId,
    required String characterId,
  }) async {
    await _client.rpc('claim_scene_character', params: {
      'p_room_id': roomId,
      'p_character_id': characterId,
    });
  }

  Future<SceneSession?> fetchSession(String roomId) async {
    try {
      final row = await _client
          .from('scene_sessions')
          .select()
          .eq('room_id', roomId)
          .maybeSingle();
      return row == null ? null : SceneSession.fromJson(row);
    } catch (e) {
      debugPrint('ScenePartyService.fetchSession: $e');
      return null;
    }
  }

  Future<List<SceneCastMember>> fetchCast(String roomId) async {
    try {
      final rows = await _client
          .rpc('get_scene_cast', params: {'p_room_id': roomId});
      return (rows as List)
          .map((r) => SceneCastMember.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ScenePartyService.fetchCast: $e');
      return [];
    }
  }
}
