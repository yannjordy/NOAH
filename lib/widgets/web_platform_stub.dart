import 'dart:async';

class WebPlatform {
  static bool get hasSpeechRecognition => false;

  static dynamic createSpeechRecognition() => null;

  static Stream<List<dynamic>> onEvent(dynamic target, String event) {
    return const Stream.empty();
  }

  static dynamic createFileInput(String accept, bool capture) => null;

  static Future<dynamic> onFileSelected(dynamic input) async => null;

  static Future<String> readAsDataUrl(dynamic file) async => '';

  static Future<String> readAsText(dynamic file) async => '';
}
