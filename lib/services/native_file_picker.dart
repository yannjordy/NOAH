import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('noah/file_picker');

class NativeFileResult {
  final String name;
  final String mime;
  final List<int> bytes;

  NativeFileResult({required this.name, required this.mime, required this.bytes});
}

Future<NativeFileResult?> pickNativeFile({String mime = '*/*'}) async {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      final result = await _channel.invokeMethod<Map>('pickFile', {'mime': mime});
      if (result == null) return null;
      final name = result['name'] as String? ?? 'file';
      final mimeType = result['mime'] as String? ?? 'application/octet-stream';
      final data = result['data'] as String? ?? '';
      final bytes = base64Decode(data);
      return NativeFileResult(name: name, mime: mimeType, bytes: bytes);
    } catch (_) {
      return null;
    }
  }
  return null;
}
