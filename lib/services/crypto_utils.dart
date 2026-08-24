import 'dart:convert';
import 'package:crypto/crypto.dart';

String hmacSha256(String secret, String data) {
  final key = utf8.encode(secret);
  final bytes = utf8.encode(data);
  final hmac = Hmac(sha256, key);
  return hmac.convert(bytes).toString();
}

String sha256Hash(String data) {
  final bytes = utf8.encode(data);
  return sha256.convert(bytes).toString();
}
