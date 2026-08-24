import 'dart:async';

class NotificationEvent {
  final String title;
  final String body;
  final String? tag;
  NotificationEvent({required this.title, required this.body, this.tag});
}

class NotificationStream {
  static final _instance = NotificationStream._();
  static NotificationStream get instance => _instance;
  NotificationStream._();

  final _controller = StreamController<NotificationEvent>.broadcast();
  Stream<NotificationEvent> get stream => _controller.stream;
  void add(NotificationEvent event) => _controller.add(event);
}
