import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/campaign.dart';
import 'package:winkidoo/models/campaign_chapter.dart';
import 'package:winkidoo/models/campaign_progress.dart';
import 'package:winkidoo/services/xp_service.dart';

/// Service for Story Mode campaigns.
class CampaignService {
  static const int pointsCampaignChapter = 15;
  static const int pointsCampaignCompleted = 50;
  static const int xpCampaignCompleted = 500;

  /// Fetches all active campaigns.
  static Future<List<Campaign>> getActiveCampaigns(
      SupabaseClient client) async {
    try {
      final rows = await client
          .from('campaigns')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return (rows as List).map((r) => Campaign.fromJson(r)).toList();
    } catch (e) {
      debugPrint('CampaignService.getActiveCampaigns: $e');
      return [];
    }
  }

  /// Fetches a campaign with all its chapters ordered by chapter_number.
  static Future<(Campaign, List<CampaignChapter>)?> getCampaignWithChapters(
    SupabaseClient client,
    String campaignId,
  ) async {
    try {
      final row = await client
          .from('campaigns')
          .select()
          .eq('id', campaignId)
          .maybeSingle();
      if (row == null) return null;

      final chapterRows = await client
          .from('campaign_chapters')
          .select()
          .eq('campaign_id', campaignId)
          .order('chapter_number');

      final campaign = Campaign.fromJson(row);
      final chapters = (chapterRows as List)
          .map((r) => CampaignChapter.fromJson(r))
          .toList();

      return (campaign, chapters);
    } catch (e) {
      debugPrint('CampaignService.getCampaignWithChapters: $e');
      return null;
    }
  }

  /// Gets the couple's progress on a campaign (or null if not started).
  static Future<CampaignProgress?> getCoupleProgress(
    SupabaseClient client,
    String coupleId,
    String campaignId,
  ) async {
    try {
      final row = await client
          .from('couple_campaign_progress')
          .select()
          .eq('couple_id', coupleId)
          .eq('campaign_id', campaignId)
          .maybeSingle();
      return row != null ? CampaignProgress.fromJson(row) : null;
    } catch (e) {
      debugPrint('CampaignService.getCoupleProgress: $e');
      return null;
    }
  }

  /// Gets all active campaign progresses for a couple.
  static Future<List<CampaignProgress>> getActiveProgresses(
    SupabaseClient client,
    String coupleId,
  ) async {
    try {
      final rows = await client
          .from('couple_campaign_progress')
          .select()
          .eq('couple_id', coupleId)
          .eq('status', 'active');
      return (rows as List)
          .map((r) => CampaignProgress.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('CampaignService.getActiveProgresses: $e');
      return [];
    }
  }

  /// Starts a campaign for the couple.
  static Future<CampaignProgress?> startCampaign(
    SupabaseClient client,
    String coupleId,
    String campaignId,
  ) async {
    try {
      final row = await client
          .from('couple_campaign_progress')
          .upsert(
            {
              'couple_id': coupleId,
              'campaign_id': campaignId,
              'current_chapter': 1,
              'status': 'active',
            },
            onConflict: 'couple_id,campaign_id',
          )
          .select()
          .single();
      return CampaignProgress.fromJson(row);
    } catch (e) {
      debugPrint('CampaignService.startCampaign: $e');
      return null;
    }
  }

  /// Advances to the next chapter. If last chapter, marks campaign as completed
  /// and awards completion rewards.
  static Future<CampaignProgress?> advanceChapter(
    SupabaseClient client,
    String coupleId,
    String campaignId,
    int totalChapters,
  ) async {
    try {
      final current = await getCoupleProgress(client, coupleId, campaignId);
      if (current == null) return null;

      final nextChapter = current.currentChapter + 1;
      final isComplete = nextChapter > totalChapters;

      final now = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'current_chapter': isComplete ? totalChapters : nextChapter,
        'status': isComplete ? 'completed' : 'active',
      };
      if (isComplete) updates['completed_at'] = now;

      final row = await client
          .from('couple_campaign_progress')
          .update(updates)
          .eq('couple_id', coupleId)
          .eq('campaign_id', campaignId)
          .select()
          .single();

      // Award completion XP if campaign is done
      if (isComplete) {
        await XpService.awardXp(client, coupleId, xpCampaignCompleted);
      }

      return CampaignProgress.fromJson(row);
    } catch (e) {
      debugPrint('CampaignService.advanceChapter: $e');
      return null;
    }
  }

  /// Fetches campaign rewards.
  static Future<List<Map<String, dynamic>>> getCampaignRewards(
    SupabaseClient client,
    String campaignId, {
    int? chapterNumber,
  }) async {
    try {
      var query = client
          .from('campaign_rewards')
          .select()
          .eq('campaign_id', campaignId);
      if (chapterNumber != null) {
        query = query.eq('chapter_number', chapterNumber);
      }
      return List<Map<String, dynamic>>.from(await query);
    } catch (e) {
      debugPrint('CampaignService.getCampaignRewards: $e');
      return [];
    }
  }
}
