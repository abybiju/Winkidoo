import 'dart:math';

import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/judge.dart';

class JudgeAssetResolver {
  JudgeAssetResolver._();

  static final Random _random = Random();
  static final Map<String, bool> _sessionRandomUseFemale = {};

  static String resolveAvatarPath({
    required Judge judge,
    required String userGender,
  }) {
    final persona = judge.personaId;
    final variants = _personaAssets[persona];
    if (variants == null) {
      return _normalizeAsset(judge.avatarAssetPath);
    }

    final g = userGender.toLowerCase();
    if (g == 'male') {
      return variants.female ??
          variants.male ??
          variants.neutral ??
          _normalizeAsset(judge.avatarAssetPath);
    }
    if (g == 'female') {
      return variants.male ??
          variants.female ??
          variants.neutral ??
          _normalizeAsset(judge.avatarAssetPath);
    }

    final useFemale =
        _sessionRandomUseFemale.putIfAbsent(persona, () => _random.nextBool());
    return useFemale
        ? (variants.female ??
            variants.male ??
            variants.neutral ??
            _normalizeAsset(judge.avatarAssetPath))
        : (variants.male ??
            variants.female ??
            variants.neutral ??
            _normalizeAsset(judge.avatarAssetPath));
  }

  static String _normalizeAsset(String? path) => (path ?? '').trim();

  static const Map<String, _JudgeAssetVariants> _personaAssets = {
    AppConstants.personaPoeticRomantic: _JudgeAssetVariants(
      neutral: 'assets/images/judge wizard .png',
      male: 'assets/images/judge wizard .png',
      female: 'assets/images/judge wizard .png',
    ),
    AppConstants.personaSassyCupid: _JudgeAssetVariants(
      male: 'assets/images/sassy judge male.png',
      female: 'assets/images/sassy judge - female.png',
    ),
    AppConstants.personaChaosGremlin: _JudgeAssetVariants(
      neutral: 'assets/images/Chaos Gremlin judge.png',
      male: 'assets/images/Chaos Gremlin judge.png',
      female: 'assets/images/Chaos Gremlin judge.png',
    ),
    AppConstants.personaTheEx: _JudgeAssetVariants(
      male: 'assets/images/The Ex male version.png',
      female: 'assets/images/The Ex female version.png',
    ),
    AppConstants.personaDrLove: _JudgeAssetVariants(
      male: 'assets/images/Dr. Love Judge.png',
      female: 'assets/images/Dr. Love Female.png',
    ),
  };
}

class _JudgeAssetVariants {
  const _JudgeAssetVariants({this.male, this.female, this.neutral});

  final String? male;
  final String? female;
  final String? neutral;
}
