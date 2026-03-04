import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/judge.dart';

class JudgeAssetResolver {
  JudgeAssetResolver._();

  static String resolveAvatarPath({
    required Judge judge,
    required String userGender,
  }) {
    final resolved = resolvePersonaAssetPath(
      personaId: judge.personaId,
      userGender: userGender,
    );
    return resolved.isNotEmpty
        ? resolved
        : _normalizeAsset(judge.avatarAssetPath);
  }

  static String resolvePersonaAssetPath({
    required String personaId,
    required String userGender,
  }) {
    final variants = _personaAssets[personaId];
    if (variants == null) return '';
    final g = userGender.toLowerCase();
    if (g == 'male') {
      return variants.female ?? variants.male ?? variants.neutral ?? '';
    }
    if (g == 'female') {
      return variants.male ?? variants.female ?? variants.neutral ?? '';
    }
    return variants.neutral ?? variants.female ?? variants.male ?? '';
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
