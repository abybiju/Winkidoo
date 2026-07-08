import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/character_preset.dart';
import 'package:winkidoo/models/scene_pack.dart';
import 'package:winkidoo/models/scene_session.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/scene_party_service.dart';

final scenePartyServiceProvider = Provider<ScenePartyService>((ref) {
  return ScenePartyService(ref.watch(supabaseClientProvider));
});

/// Active, in-season packs for the browser.
final scenePacksProvider = FutureProvider<List<ScenePack>>((ref) async {
  return ref.watch(scenePartyServiceProvider).getActivePacks();
});

final scenePackBySlugProvider =
    FutureProvider.family<ScenePack?, String>((ref, slug) async {
  return ref.watch(scenePartyServiceProvider).getPackBySlug(slug);
});

final scenePackByIdProvider =
    FutureProvider.family<ScenePack?, String>((ref, id) async {
  return ref.watch(scenePartyServiceProvider).getPackById(id);
});

final scenePackCharactersProvider =
    FutureProvider.family<List<SceneCharacter>, String>((ref, packId) async {
  return ref.watch(scenePartyServiceProvider).getPackCharacters(packId);
});

final scenePackActsProvider =
    FutureProvider.family<List<SceneActTemplate>, String>((ref, packId) async {
  return ref.watch(scenePartyServiceProvider).getPackActs(packId);
});

/// The scene session for a room (null = plain chat room, not a scene).
/// Realtime updates are pushed in via [apply] from SceneRealtimeService.
final sceneSessionProvider = AsyncNotifierProvider.family<SceneSessionNotifier,
    SceneSession?, String>(SceneSessionNotifier.new);

class SceneSessionNotifier extends AsyncNotifier<SceneSession?> {
  SceneSessionNotifier(this.roomId);

  final String roomId;

  @override
  Future<SceneSession?> build() async {
    return ref.watch(scenePartyServiceProvider).fetchSession(roomId);
  }

  /// Realtime push: replace state with the authoritative server row.
  void apply(SceneSession session) {
    state = AsyncData(session);
  }
}

/// Cast roster for a room's scene (empty for non-scene rooms).
final sceneCastProvider =
    FutureProvider.family<List<SceneCastMember>, String>((ref, roomId) async {
  return ref.watch(scenePartyServiceProvider).fetchCast(roomId);
});

/// The caller's claimed character as a CharacterPreset for the transform
/// pipeline (null when unclaimed or not a scene).
final myClaimedCharacterProvider =
    FutureProvider.family<CharacterPreset?, String>((ref, roomId) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  final cast = await ref.watch(sceneCastProvider(roomId).future);
  SceneCastMember? mine;
  for (final member in cast) {
    if (member.userId == userId) {
      mine = member;
      break;
    }
  }
  if (mine == null) return null;
  final session =
      await ref.watch(sceneSessionProvider(roomId).future);
  if (session == null) return null;
  final characters = await ref
      .watch(scenePackCharactersProvider(session.packId).future);
  for (final c in characters) {
    if (c.id == mine.characterId) return c.toCharacterPreset();
  }
  return null;
});
