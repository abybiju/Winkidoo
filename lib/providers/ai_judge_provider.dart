import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/services/ai_judge_service.dart';

final aiJudgeServiceProvider = Provider<AiJudgeService>((ref) {
  // Gemini calls are proxied server-side via the gemini-proxy Edge Function;
  // no API key ships in the client. See lib/services/gemini_proxy_client.dart.
  return AiJudgeService();
});
