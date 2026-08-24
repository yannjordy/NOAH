import 'dart:async';

enum NotificationType { trade, signal, risk, system }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.system,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class NotificationStream {
  NotificationStream._();
  static final _instance = NotificationStream._();
  static NotificationStream get instance => _instance;

  final _controller = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get stream => _controller.stream;

  void push(AppNotification notif) {
    _controller.add(notif);
  }

  void dispose() {
    _controller.close();
  }
}
