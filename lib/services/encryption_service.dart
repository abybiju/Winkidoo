import 'dart:convert';

import 'package:encrypt/encrypt.dart';

/// Client-side encryption for surprise content.
/// Server only stores ciphertext. Key is derived from couple id for MVP;
/// true E2E with shared secret can be added later.
class EncryptionService {
  static const _salt = 'winkidoo-v1';

  static String _keyFromCoupleId(String coupleId) {
    final key = coupleId + _salt;
    final input = utf8.encode(key);
    final padded = List<int>.filled(32, 0);
    for (var i = 0; i < input.length && i < 32; i++) padded[i] = input[i];
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
    final keyString = coupleId != null
        ? _keyFromCoupleId(coupleId)
        : 'default-key-for-mvp-32bytes!!';
    final key = Key.fromBase64(keyString);
    final iv = IV.fromBase64(parts[0]);
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt64(parts[1], iv: iv);
  }
}
