import 'dart:js' as js;
import 'dart:async';

class WebPlatform {
  static bool get hasSpeechRecognition {
    final sr = js.context['SpeechRecognition'] ?? js.context['webkitSpeechRecognition'];
    return sr != null;
  }

  static dynamic createSpeechRecognition() {
    final sr = js.context['SpeechRecognition'] ?? js.context['webkitSpeechRecognition'];
    return js.JsObject(sr);
  }

  static Stream<List<dynamic>> onEvent(dynamic target, String event) {
    final controller = StreamController<List<dynamic>>();
    target.callMethod('addEventListener', [
      event,
      (js.JsObject jsEvent) {
        final args = jsEvent.callMethod('toJsArray', []) as List<dynamic>;
        controller.add(args);
      },
    ]);
    return controller.stream;
  }

  static dynamic createFileInput(String accept, bool capture) {
    final doc = js.context['document'];
    final input = doc.callMethod('createElement', ['input']);
    input['type'] = 'file';
    input['accept'] = accept;
    input['capture'] = capture ? 'environment' : null;
    input['multiple'] = false;
    return input;
  }

  static Future<dynamic> onFileSelected(dynamic input) {
    final completer = Completer<dynamic>();
    input['onchange'] = () {
      final files = input['files'];
      final file = files != null && files['length'] > 0 ? files[0] : null;
      completer.complete(file);
    };
    return completer.future;
  }

  static Future<String> readAsDataUrl(dynamic file) {
    final completer = Completer<String>();
    final reader = js.JsObject(js.context['FileReader']);
    reader['onload'] = () => completer.complete(reader['result']);
    reader.callMethod('readAsDataURL', [file]);
    return completer.future;
  }

  static Future<String> readAsText(dynamic file) {
    final completer = Completer<String>();
    final reader = js.JsObject(js.context['FileReader']);
    reader['onload'] = () => completer.complete(reader['result']);
    reader.callMethod('readAsText', [file]);
    return completer.future;
  }
}
