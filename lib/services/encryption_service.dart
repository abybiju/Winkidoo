import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// Client-side encryption for surprise content.
/// Server only stores ciphertext. Key is derived from couple id via SHA-256;
/// true E2E with shared secret can be added later.
class EncryptionService {
  static const _salt = 'winkidoo-v1-surprise-vault';
  static const _legacySalt = 'winkidoo-v1';

  static String _keyFromCoupleId(String coupleId) {
    final digest = sha256.convert(utf8.encode('$coupleId:$_salt'));
    return base64Encode(digest.bytes);
  }

  /// Legacy key derivation for decrypting data encrypted before the SHA-256 upgrade.
  static String _legacyKeyFromCoupleId(String coupleId) {
    final key = coupleId + _legacySalt;
    final input = utf8.encode(key);
    final padded = List<int>.filled(32, 0);
    for (var i = 0; i < input.length && i < 32; i++) {
      padded[i] = input[i];
    }
    return base64Encode(padded);
  }

  static Future<String> encrypt(String plainText, {String? coupleId}) async {
    final keyString = coupleId != null
        ? _keyFromCoupleId(coupleId)
        : 'default-key-for-mvp-32bytes!!';
    final key = Key.fromBase64(keyString);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static Future<String> decrypt(String cipherText, {String? coupleId}) async {
    final parts = cipherText.split(':');
    if (parts.length != 2) return cipherText;

    // Try current key first, then fall back to legacy for pre-upgrade data
    for (final keyString in _decryptionKeys(coupleId)) {
      try {
        final key = Key.fromBase64(keyString);
        final iv = IV.fromBase64(parts[0]);
        final encrypter = Encrypter(AES(key));
        return encrypter.decrypt64(parts[1], iv: iv);
      } catch (_) {
        continue;
      }
    }
    return cipherText;
  }

  static List<String> _decryptionKeys(String? coupleId) {
    if (coupleId == null) return ['default-key-for-mvp-32bytes!!'];
    return [_keyFromCoupleId(coupleId), _legacyKeyFromCoupleId(coupleId)];
  }
}
