import 'dart:math';
import 'dart:ui' show Color;
import 'blocks.dart';
export 'blocks.dart';

class UserAccount {
  final String email;
  final String password;
  final String name;
  final int date;
  final bool google;

  UserAccount({
    required this.email,
    required this.password,
    this.name = '',
    int? date,
    this.google = false,
  }) : date = date ?? DateTime.now().millisecondsSinceEpoch;

  UserAccount.fromJson(Map<String, dynamic> json)
      : email = json['email'] as String,
        password = json['password'] as String? ?? '',
        name = json['name'] as String? ?? (json['email'] as String).split('@').first,
        date = json['date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        google = json['google'] as bool? ?? false;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'date': date,
        'google': google,
      };
}

class ChatMessage {
  final String id;
  final String role; // 'user' or 'noah'
  final String text;
  final int time;
  final Signal? signal;
  final bool isTyping;
  final String? imageBase64;
  final List<MessageBlock> blocks;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    int? time,
    this.signal,
    this.isTyping = false,
    this.imageBase64,
    this.blocks = const [],
  }) : time = time ?? DateTime.now().millisecondsSinceEpoch;

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    int? time,
    Signal? signal,
    bool? isTyping,
    String? imageBase64,
    List<MessageBlock>? blocks,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      time: time ?? this.time,
      signal: signal ?? this.signal,
      isTyping: isTyping ?? this.isTyping,
      imageBase64: imageBase64 ?? this.imageBase64,
      blocks: blocks ?? this.blocks,
    );
  }

  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(time);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class ChatSession {
  final String id;
  String title;
  int date;
  List<ChatMessage> msgs;

  ChatSession({
    required this.id,
    this.title = 'Nouvelle conversation',
    int? date,
    List<ChatMessage>? msgs,
  })  : date = date ?? DateTime.now().millisecondsSinceEpoch,
        msgs = msgs ?? [];

  ChatSession.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        title = json['title'] as String? ?? 'Nouvelle conversation',
        date = json['date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        msgs = (json['msgs'] as List<dynamic>?)
                ?.map((m) => ChatMessage(
                      id: m['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      role: m['role'] as String? ?? '',
                      text: m['text'] as String? ?? '',
                      time: m['time'] as int?,
                      signal: m['signal'] != null ? Signal.fromJson(m['signal'] as Map<String, dynamic>) : null,
                      imageBase64: m['imageBase64'] as String?,
                      blocks: (m['blocks'] as List<dynamic>?)
                              ?.map((b) => MessageBlock.fromJson(b as Map<String, dynamic>))
                              .toList() ??
                          const [],
                    ))
                .toList() ??
            [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'msgs': msgs
            .map((m) => {
                  'id': m.id,
                  'role': m.role,
                  'text': m.text,
                  'time': m.time,
                  if (m.signal != null) 'signal': m.signal!.toJson(),
                  if (m.imageBase64 != null) 'imageBase64': m.imageBase64,
                  if (m.blocks.isNotEmpty) 'blocks': m.blocks.map((b) => b.toJson()).toList(),
                })
            .toList(),
      };
}

class Signal {
  final String type; // BUY, SELL, HOLD
  final String sym;
  final double conf;

  Signal({required this.type, required this.sym, required this.conf});

  Signal.fromJson(Map<String, dynamic> json)
      : type = json['type'] as String? ?? '',
        sym = json['sym'] as String? ?? '',
        conf = (json['conf'] as num?)?.toDouble() ?? 0.0;

  Map<String, dynamic> toJson() => {'type': type, 'sym': sym, 'conf': conf};

  factory Signal.parse(String text) {
    final regex = RegExp(r'SIGNAL\s*:\s*(BUY|SELL|HOLD)\|([\w]+)\|([\d.]+)');
    final m = regex.firstMatch(text);
    if (m == null) throw const FormatException('No signal found');
    return Signal(
      type: m.group(1)!,
      sym: m.group(2)!,
      conf: double.parse(m.group(3)!),
    );
  }
}

class Position {
  String sym;
  double qty;
  double entry;
  double? stopLoss;
  double? takeProfit;
  String icon;
  String color;

  Position({
    required this.sym,
    required this.qty,
    required this.entry,
    this.stopLoss,
    this.takeProfit,
    String? icon,
    this.color = 'accent',
  }) : icon = (icon ?? sym.substring(0, 1));

  double currentValue(String sym) => qty * (prices[sym] ?? 0);
  double pnl(String sym) => qty * ((prices[sym] ?? 0) - entry);
  double pnlPct(String sym) => entry > 0 ? ((prices[sym]! - entry) / entry) * 100 : 0;
  Map<String, dynamic> toJson() => {
    'sym': sym, 'qty': qty, 'entry': entry,
    'stopLoss': stopLoss, 'takeProfit': takeProfit,
    'icon': icon, 'color': color,
  };
  factory Position.fromJson(Map<String, dynamic> j) => Position(
    sym: j['sym'] ?? '', qty: (j['qty'] ?? 0).toDouble(),
    entry: (j['entry'] ?? 0).toDouble(),
    stopLoss: j['stopLoss']?.toDouble(),
    takeProfit: j['takeProfit']?.toDouble(),
    icon: j['icon'], color: j['color'] ?? 'accent',
  );
}