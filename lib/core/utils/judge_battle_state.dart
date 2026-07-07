import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/battle_message.dart';

/// Blueprint emotional ladder: Cold → Curious → Intrigued → Cracking (Unlock = verdict).
enum JudgeStage { cold, curious, intrigued, cracking }

/// Pure per-turn battle-state logic fed into the judge prompt: which emotional
/// stage the battle is at, what the judge already said (the "do not repeat"
/// list), and a bounded transcript. Tone only — never touches scoring math.
class JudgeBattleState {
  JudgeBattleState._();

  /// Guard phrase every stage directive must carry so escalating tone can
  /// never be read as permission to change scoring. Tests assert its presence.
  static const String scoringFirewall =
      'This stage affects TONE ONLY — score exactly per the scoring rules; '
      'never inflate or deflate score_delta because of your emotional stage.';

  /// Maps persuasion-meter progress (seekerScore / resistance, 0..1) to a stage.
  static JudgeStage stageFromProgress(double progress) {
    final p = progress.clamp(0.0, 1.0);
    if (p < AppConstants.stageCuriousThreshold) return JudgeStage.cold;
    if (p < AppConstants.stageIntriguedThreshold) return JudgeStage.curious;
    if (p < AppConstants.stageCrackingThreshold) return JudgeStage.intrigued;
    return JudgeStage.cracking;
  }

  /// Persona-agnostic stage direction, rendered in the judge's own voice by the
  /// model — so built-in, custom, and pack personas all benefit.
  static String stageDirective(JudgeStage stage) {
    switch (stage) {
      case JudgeStage.cold:
        return 'You are UNIMPRESSED so far. Probe playfully, set the bar, make '
            'them earn a reaction — but stay curious enough to keep them '
            'swinging. $scoringFirewall';
      case JudgeStage.curious:
        return 'Something they said caught your eye — NAME it specifically and '
            'concede that small point out loud, then press with ONE pointed '
            'follow-up in your voice. $scoringFirewall';
      case JudgeStage.intrigued:
        return 'You are visibly warming up and it shows. Admit out loud what is '
            'working on you, then issue ONE NEW specific counter-challenge that '
            'builds on what they already gave — never a repeat of an earlier '
            'demand. $scoringFirewall';
      case JudgeStage.cracking:
        return 'Your defenses are CRUMBLING and you cannot fully hide it — '
            'flustered, resisting but barely. React to their latest push; do '
            'not restate old demands. Let them feel how close they are. '
            '$scoringFirewall';
    }
  }

  /// The judge's own recent non-verdict lines, oldest→newest — the programmatic
  /// "do not repeat these" list (same shape as generateDare's recentDareTexts).
  static List<String> recentJudgeLines(
    List<BattleMessage> messages, {
    int limit = AppConstants.judgeRecentRepliesWindow,
    int maxChars = 200,
  }) {
    final judgeLines = messages
        .where((m) => m.senderType == 'judge' && !m.isVerdict)
        .map((m) => m.content.length > maxChars
            ? '${m.content.substring(0, maxChars)}…'
            : m.content)
        .toList();
    return judgeLines.length <= limit
        ? judgeLines
        : judgeLines.sublist(judgeLines.length - limit);
  }

  /// Bounded transcript: under [max] messages returns everything; otherwise
  /// keeps the first [head] (judge opener + first move) and last [tail]
  /// messages and reports how many in between were omitted.
  static ({List<BattleMessage> kept, int omitted}) trimHistory(
    List<BattleMessage> messages, {
    int max = AppConstants.battleHistoryMaxMessages,
    int head = AppConstants.battleHistoryHeadKeep,
    int tail = AppConstants.battleHistoryTailKeep,
  }) {
    if (messages.length <= max) return (kept: messages, omitted: 0);
    final kept = [
      ...messages.take(head),
      ...messages.sublist(messages.length - tail),
    ];
    return (kept: kept, omitted: messages.length - kept.length);
  }
}
