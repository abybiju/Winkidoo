import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/services/ai_judge_service.dart';

/// Communication DNA analysis from battle transcripts.
class ForensicsService {
  ForensicsService(this._client, this._ai);

  final SupabaseClient _client;
  final AiJudgeService _ai;

  /// Generates and stores a forensics report for a battle.
  /// Returns the parsed report or null on failure.
  Future<ForensicsReport?> generateReport({
    required String surpriseId,
    required String coupleId,
    required List<BattleMessage> messages,
  }) async {
    try {
      // Build transcript
      final transcript = messages
          .map((m) => '${m.senderType.toUpperCase()}: ${m.content}')
          .join('\n');

      // Call AI
      final reportJson = await _ai.generateForensicsReport(transcript);
      if (reportJson == null) return null;

      // Parse
      final dna = reportJson['communication_dna'] as Map<String, dynamic>? ??
          {};
      final signals = (reportJson['hidden_signals'] as List?)
              ?.map((s) => s.toString())
              .toList() ??
          [];
      final growthEdge = reportJson['growth_edge'] as String?;
      final superpower = reportJson['superpower'] as String?;

      // Store
      await _client.from('forensics_reports').insert({
        'surprise_id': surpriseId,
        'couple_id': coupleId,
        'communication_dna': dna,
        'hidden_signals': signals,
        'growth_edge': growthEdge,
        'superpower': superpower,
        'report_json': reportJson,
      });

      return ForensicsReport(
        communicationDna: CommunicationDna.fromJson(dna),
        hiddenSignals: signals,
        growthEdge: growthEdge ?? '',
        superpower: superpower ?? 'Unknown',
      );
    } catch (e) {
      debugPrint('[ForensicsService] Error generating report: $e');
      return null;
    }
  }

  /// Fetches all forensics reports for a couple (for dashboard).
  Future<List<ForensicsReport>> fetchReports(String coupleId) async {
    final rows = await _client
        .from('forensics_reports')
        .select()
        .eq('couple_id', coupleId)
        .order('created_at', ascending: false);

    return rows.map((r) {
      final dna = r['communication_dna'] as Map<String, dynamic>? ?? {};
      final signals = (r['hidden_signals'] as List?)
              ?.map((s) => s.toString())
              .toList() ??
          [];
      return ForensicsReport(
        communicationDna: CommunicationDna.fromJson(dna),
        hiddenSignals: signals,
        growthEdge: r['growth_edge'] as String? ?? '',
        superpower: r['superpower'] as String? ?? 'Unknown',
      );
    }).toList();
  }
}

/// Communication style percentages.
class CommunicationDna {
  const CommunicationDna({
    this.logical = 0,
    this.emotional = 0,
    this.humorous = 0,
    this.poetic = 0,
  });

  final int logical;
  final int emotional;
  final int humorous;
  final int poetic;

  String get dominant {
    final map = {'Logical': logical, 'Emotional': emotional, 'Humorous': humorous, 'Poetic': poetic};
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  factory CommunicationDna.fromJson(Map<String, dynamic> json) {
    return CommunicationDna(
      logical: (json['logical'] as num?)?.toInt() ?? 0,
      emotional: (json['emotional'] as num?)?.toInt() ?? 0,
      humorous: (json['humorous'] as num?)?.toInt() ?? 0,
      poetic: (json['poetic'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A full forensics report.
class ForensicsReport {
  const ForensicsReport({
    required this.communicationDna,
    required this.hiddenSignals,
    required this.growthEdge,
    required this.superpower,
  });

  final CommunicationDna communicationDna;
  final List<String> hiddenSignals;
  final String growthEdge;
  final String superpower;
}
