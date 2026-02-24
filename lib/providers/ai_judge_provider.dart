import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/services/ai_judge_service.dart';

final aiJudgeServiceProvider = Provider<AiJudgeService>((ref) {
  const apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  return AiJudgeService(apiKey: apiKey);
});
