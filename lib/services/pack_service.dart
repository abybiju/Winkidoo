import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/judge_pack.dart';
import 'package:winkidoo/models/pack_judge_override.dart';

/// Service for themed battle packs.
class PackService {
  /// Fetches all active packs (within season window or permanent).
  static Future<List<JudgePack>> getActivePacks(SupabaseClient client) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await client
          .from('judge_packs')
          .select()
          .eq('is_active', true)
          .or('season_start.is.null,and(season_start.lte.$now,season_end.gte.$now)')
          .order('sort_order');
      return (rows as List).map((r) => JudgePack.fromJson(r)).toList();
    } catch (e) {
      debugPrint('PackService.getActivePacks: $e');
      return [];
    }
  }

  /// Fetches a single pack by ID.
  static Future<JudgePack?> getPackById(
      SupabaseClient client, String packId) async {
    try {
      final row = await client
          .from('judge_packs')
          .select()
          .eq('id', packId)
          .maybeSingle();
      return row != null ? JudgePack.fromJson(row) : null;
    } catch (e) {
      debugPrint('PackService.getPackById: $e');
      return null;
    }
  }

  /// Fetches a single pack by slug.
  static Future<JudgePack?> getPackBySlug(
      SupabaseClient client, String slug) async {
    try {
      final row = await client
          .from('judge_packs')
          .select()
          .eq('slug', slug)
          .maybeSingle();
      return row != null ? JudgePack.fromJson(row) : null;
    } catch (e) {
      debugPrint('PackService.getPackBySlug: $e');
      return null;
    }
  }

  /// Fetches judge overrides for a pack, keyed by persona ID.
  static Future<Map<String, PackJudgeOverride>> getPackJudgeOverrides(
      SupabaseClient client, String packId) async {
    try {
      final rows = await client
          .from('judge_pack_judges')
          .select()
          .eq('pack_id', packId)
          .order('sort_order');
      final map = <String, PackJudgeOverride>{};
      for (final row in rows) {
        final override = PackJudgeOverride.fromJson(row);
        map[override.judgePersona] = override;
      }
      return map;
    } catch (e) {
      debugPrint('PackService.getPackJudgeOverrides: $e');
      return {};
    }
  }

  /// Fetches dare templates for a pack.
  static Future<List<({String category, String promptHint})>>
      getPackDareTemplates(SupabaseClient client, String packId) async {
    try {
      final rows = await client
          .from('pack_dare_templates')
          .select('category, prompt_hint')
          .eq('pack_id', packId)
          .order('sort_order');
      return (rows as List)
          .map((r) => (
                category: r['category'] as String,
                promptHint: r['prompt_hint'] as String,
              ))
          .toList();
    } catch (e) {
      debugPrint('PackService.getPackDareTemplates: $e');
      return [];
    }
  }

  /// Gets the couple's currently active pack ID (or null).
  static Future<String?> getCoupleActivePackId(
      SupabaseClient client, String coupleId) async {
    try {
      final row = await client
          .from('couple_active_pack')
          .select('pack_id')
          .eq('couple_id', coupleId)
          .maybeSingle();
      return row?['pack_id'] as String?;
    } catch (e) {
      debugPrint('PackService.getCoupleActivePackId: $e');
      return null;
    }
  }

  /// Sets or clears the couple's active pack.
  /// Uses upsert for both activate and deactivate (sets pack_id to null).
  static Future<void> setCoupleActivePack(
    SupabaseClient client,
    String coupleId,
    String? packId,
  ) async {
    try {
      await client.from('couple_active_pack').upsert({
        'couple_id': coupleId,
        'pack_id': packId,
        'activated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('PackService.setCoupleActivePack: $e');
    }
  }
}
