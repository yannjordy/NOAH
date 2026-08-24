import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoUtils {
  static const _salt = 'noah::2026::aes-256-cbc';

  static enc.Key _deriveKey(String userSeed) {
    final hash = sha256.convert(utf8.encode('$_salt::$userSeed'));
    return enc.Key.fromUtf8(hash.toString().substring(0, 32));
  }

  static String encrypt(String plainText, {String userSeed = 'default'}) {
    if (plainText.isEmpty) return plainText;
    try {
      final key = _deriveKey(userSeed);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return base64.encode(iv.bytes + encrypted.bytes);
    } catch (_) {
      // Degraded mode: base64 only (NOT encrypted). Marked for detection.
      return 'PLAIN:${base64.encode(utf8.encode(plainText))}';
    }
  }

  static String decrypt(String cipherText, {String userSeed = 'default'}) {
    if (cipherText.isEmpty) return cipherText;
    // Detect degraded-mode plaintext
    if (cipherText.startsWith('PLAIN:')) {
      try {
        return utf8.decode(base64.decode(cipherText.substring(6)));
      } catch (_) {
        return cipherText;
      }
    }
    try {
      final combined = base64.decode(cipherText);
      if (combined.length <= 16) return cipherText;
      final iv = enc.IV(combined.sublist(0, 16));
      final data = enc.Encrypted(combined.sublist(16));
      final key = _deriveKey(userSeed);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(data, iv: iv);
    } catch (_) {
      try {
        return utf8.decode(base64.decode(cipherText));
      } catch (_) {
        return cipherText;
      }
    }
  }
}
