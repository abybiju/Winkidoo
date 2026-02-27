import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Optional sound hooks for battle UX and judge selection: pulse (vault reinforced),
/// unlock (resolution), and lock click (seal / subtle confirmation).
/// Add assets/sounds/pulse.mp3, sounds/unlock.mp3, and sounds/lock_click.mp3; otherwise no-op.
/// Haptic feedback is used as fallback when no sound assets are present.
class BattleSoundService {
  BattleSoundService() : _player = AudioPlayer();

  final AudioPlayer _player;

  static const String _pulseAsset = 'sounds/pulse.mp3';
  static const String _unlockAsset = 'sounds/unlock.mp3';
  static const String _lockClickAsset = 'sounds/lock_click.mp3';

  /// Soft "lock click" for judge seal and similar confirmations. Not dramatic; subtle.
  /// Call at ~300ms into a sealing/confirm animation.
  Future<void> playLockClick() async {
    try {
      await _player.play(AssetSource(_lockClickAsset));
    } catch (_) {}
  }

  /// Call when resistance increases (vault reinforced). Plays subtle sound if asset exists.
  Future<void> playPulse() async {
    if (!kIsWeb) HapticFeedback.lightImpact();
    try {
      await _player.play(AssetSource(_pulseAsset));
    } catch (_) {}
  }

  /// Call when battle resolves with unlock. Plays heavier sound if asset exists.
  /// [heavierHaptic] true for chaos judge (e.g. heavyImpact); else mediumImpact.
  Future<void> playUnlock({bool heavierHaptic = false}) async {
    if (!kIsWeb) {
      if (heavierHaptic) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    try {
      await _player.play(AssetSource(_unlockAsset));
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
