import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

class CacheService {
  final StorageService _storage;
  String? _cacheDir;

  CacheService(this._storage);

  Future<String> get _dir async {
    if (_cacheDir != null) return _cacheDir!;
    if (!kIsWeb) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _cacheDir = '${appDir.path}/noah_cache';
        await Directory(_cacheDir!).create(recursive: true);
      } catch (_) {
        _cacheDir = '/tmp/noah_cache';
      }
    } else {
      _cacheDir = 'noah_cache';
    }
    return _cacheDir!;
  }

  Future<int> getCacheSize() async {
    int total = 0;
    final sessions = _storage.getSessions();
    for (final s in sessions) {
      for (final m in s.msgs) {
        if (m.imageBase64 != null) {
          final raw = m.imageBase64!.contains(',')
              ? m.imageBase64!.split(',').last
              : m.imageBase64!;
          total += base64Decode(raw).lengthInBytes;
        }
      }
    }
    return total;
  }

  int getImageCount() {
    int count = 0;
    final sessions = _storage.getSessions();
    for (final s in sessions) {
      for (final m in s.msgs) {
        if (m.imageBase64 != null) count++;
      }
    }
    return count;
  }

  Future<void> clearCache() async {
    final sessions = _storage.getSessions();
    for (final s in sessions) {
      s.msgs = s.msgs.map((m) {
        if (m.imageBase64 != null) {
          return m.copyWith(imageBase64: null);
        }
        return m;
      }).toList();
    }
    _storage.saveSessions(sessions);

    if (!kIsWeb) {
      try {
        final d = await _dir;
        if (await Directory(d).exists()) {
          await Directory(d).delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / 1048576).toStringAsFixed(1)} Mo';
  }
}
