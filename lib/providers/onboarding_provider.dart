import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingComplete = 'onboarding_complete';
const String _keyCreateFirstSurprisePrompt = 'create_first_surprise_prompt_seen';

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingCompleteNotifier, bool>((ref) {
  return OnboardingCompleteNotifier();
});

class OnboardingCompleteNotifier extends StateNotifier<bool> {
  OnboardingCompleteNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setComplete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }
}

final createFirstSurprisePromptSeenProvider =
    StateNotifierProvider<CreateFirstSurprisePromptNotifier, bool>((ref) {
  return CreateFirstSurprisePromptNotifier();
});

class CreateFirstSurprisePromptNotifier extends StateNotifier<bool> {
  CreateFirstSurprisePromptNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyCreateFirstSurprisePrompt) ?? false;
  }

  Future<void> setSeen() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCreateFirstSurprisePrompt, true);
  }
}
