import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/campaign.dart';
import 'package:winkidoo/models/campaign_chapter.dart';
import 'package:winkidoo/models/campaign_progress.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/campaign_service.dart';

/// All active campaigns.
final activeCampaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  return CampaignService.getActiveCampaigns(client);
});

/// Campaign detail with chapters.
final campaignDetailProvider =
    FutureProvider.family<(Campaign, List<CampaignChapter>)?, String>(
        (ref, campaignId) async {
  final client = ref.read(supabaseClientProvider);
  return CampaignService.getCampaignWithChapters(client, campaignId);
});

/// Couple's progress on a specific campaign.
final campaignProgressProvider =
    FutureProvider.family<CampaignProgress?, String>(
        (ref, campaignId) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return null;
  final client = ref.read(supabaseClientProvider);
  return CampaignService.getCoupleProgress(client, couple.id, campaignId);
});

/// All active campaign progresses for the couple (for home screen banner).
final activeCampaignProgressesProvider =
    FutureProvider<List<CampaignProgress>>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return [];
  final client = ref.read(supabaseClientProvider);
  return CampaignService.getActiveProgresses(client, couple.id);
});
