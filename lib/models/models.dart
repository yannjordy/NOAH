import 'dart:math';
import 'dart:ui' show Color;
import 'blocks.dart';
export 'blocks.dart';

// ─── Global State ─────────────────────────────────────
final Map<String, double> prices = {};
final Map<String, double> pcts = {};
final List<String> symbols = [
  'BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'DOGE', 'ADA', 'AVAX',
  'DOT', 'MATIC', 'LINK', 'UNI', 'SHIB', 'LTC', 'ATOM',
];
bool isMarketConnected = false;
DateTime lastPriceUpdate = DateTime.fromMillisecondsSinceEpoch(0);

bool isDataFresh({int maxAgeSeconds = 30}) {
  return DateTime.now().difference(lastPriceUpdate).inSeconds < maxAgeSeconds;
}

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

class Kline {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTime;

  Kline({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
  });

  factory Kline.fromBinance(List data) => Kline(
    openTime: data[0] as int,
    open: double.parse(data[1].toString()),
    high: double.parse(data[2].toString()),
    low: double.parse(data[3].toString()),
    close: double.parse(data[4].toString()),
    volume: double.parse(data[5].toString()),
    closeTime: data[6] as int,
  );

  bool get isUp => close >= open;
}

class TradeOrder {
  final String side;
  final String sym;
  final double qty;
  final double price;
  final double? pnl;
  final String time;

  TradeOrder({
    required this.side,
    required this.sym,
    required this.qty,
    required this.price,
    this.pnl,
    String? time,
  }) : time = time ?? DateTime.now().toString().substring(0, 16);
}

class WalletTransaction {
  final String type;
  final double amount;
  final String label;
  final int time;

  WalletTransaction({
    required this.type,
    required this.amount,
    this.label = '',
    int? time,
  }) : time = time ?? DateTime.now().millisecondsSinceEpoch;
}

class PortfolioData {
  double usdt = 10000;
  double totalDeposits = 10000;
  double initialUsdt = 10000;
  double peakCapital = 10000;
  List<Position> positions = [];
  List<TradeOrder> history = [];
  List<WalletTransaction> walletHistory = [];

  double get positionsValue => positions.fold(0.0, (s, p) {
    final price = prices[p.sym] ?? 0;
    return s + p.qty * price;
  });

  double get totalValue => usdt + positionsValue;

  double get pnl => totalValue - totalDeposits;

  double get pnlPct => totalDeposits > 0 ? (pnl / totalDeposits * 100) : 0;

  double get winRate {
    if (history.isEmpty) return 0.5;
    final wins = history.where((t) => (t.pnl ?? 0) > 0).length;
    return wins / history.length;
  }

  double get bestTrade {
    if (history.isEmpty) return 0;
    return history.map((t) => t.pnl ?? 0).fold(0.0, (a, b) => a > b ? a : b);
  }

  double get worstTrade {
    if (history.isEmpty) return 0;
    return history.map((t) => t.pnl ?? 0).fold(0.0, (a, b) => a < b ? a : b);
  }

  List<double> get dailyReturns {
    if (history.length < 2) return [];
    final dailyPnl = <String, double>{};
    for (final t in history) {
      final day = t.time.length >= 10 ? t.time.substring(0, 10) : t.time;
      dailyPnl[day] = (dailyPnl[day] ?? 0) + (t.pnl ?? 0);
    }
    return dailyPnl.values.toList();
  }

  PortfolioData();

  PortfolioData.fromJson(Map<String, dynamic> json)
      : usdt = (json['usdt'] ?? 10000).toDouble(),
        totalDeposits = (json['totalDeposits'] ?? 10000).toDouble(),
        initialUsdt = (json['initialUsdt'] ?? 10000).toDouble(),
        peakCapital = (json['peakCapital'] ?? 10000).toDouble(),
        positions = (json['positions'] as List<dynamic>?)
                ?.map((p) => Position.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        history = (json['history'] as List<dynamic>?)
                ?.map((t) => TradeOrder(
                      side: t['side'] ?? '',
                      sym: t['sym'] ?? '',
                      qty: (t['qty'] ?? 0).toDouble(),
                      price: (t['price'] ?? 0).toDouble(),
                      pnl: (t['pnl'] ?? 0).toDouble(),
                      time: t['time'],
                    ))
                .toList() ??
            [],
        walletHistory = (json['walletHistory'] as List<dynamic>?)
                ?.map((w) => WalletTransaction(
                      type: w['type'] ?? '',
                      amount: (w['amount'] ?? 0).toDouble(),
                      label: w['label'] ?? '',
                      time: w['time'],
                    ))
                .toList() ??
            [];

  Map<String, dynamic> toJson() => {
    'usdt': usdt,
    'totalDeposits': totalDeposits,
    'initialUsdt': initialUsdt,
    'peakCapital': peakCapital,
    'positions': positions.map((p) => p.toJson()).toList(),
    'history': history.map((t) => {
      'side': t.side, 'sym': t.sym, 'qty': t.qty,
      'price': t.price, 'pnl': t.pnl, 'time': t.time,
    }).toList(),
    'walletHistory': walletHistory.map((w) => {
      'type': w.type, 'amount': w.amount, 'label': w.label, 'time': w.time,
    }).toList(),
  };
}

class PerformanceAnalyzer {
  final List<TradeOrder> history;
  final double initialUsdt;

  PerformanceAnalyzer(this.history, this.initialUsdt);

  double get totalPnl => history.fold(0.0, (s, t) => s + (t.pnl ?? 0));
  int get totalTrades => history.length;
  int get wins => history.where((t) => (t.pnl ?? 0) > 0).length;
  int get losses => history.where((t) => (t.pnl ?? 0) <= 0).length;
  double get winRate => totalTrades > 0 ? wins / totalTrades : 0;

  double get avgWin {
    final winTrades = history.where((t) => (t.pnl ?? 0) > 0).toList();
    if (winTrades.isEmpty) return 0;
    return winTrades.fold(0.0, (s, t) => s + (t.pnl ?? 0)) / winTrades.length;
  }

  double get avgLoss {
    final lossTrades = history.where((t) => (t.pnl ?? 0) < 0).toList();
    if (lossTrades.isEmpty) return 0;
    return lossTrades.fold(0.0, (s, t) => s + (t.pnl ?? 0)).abs() / lossTrades.length;
  }

  double get profitFactor {
    final grossProfit = history.where((t) => (t.pnl ?? 0) > 0).fold(0.0, (s, t) => s + (t.pnl ?? 0));
    final grossLoss = history.where((t) => (t.pnl ?? 0) < 0).fold(0.0, (s, t) => s + (t.pnl ?? 0)).abs();
    return grossLoss > 0 ? grossProfit / grossLoss : grossProfit > 0 ? double.infinity : 0;
  }

  double get expectancy => totalTrades > 0 ? totalPnl / totalTrades : 0;

  double get sharpeRatio {
    if (history.length < 2) return 0;
    final returns = history.map((t) => (t.pnl ?? 0) / initialUsdt).toList();
    final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
    final variance = returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / returns.length;
    final std = variance > 0 ? _sqrt(variance) : 0;
    return std > 0 ? mean / std : 0;
  }

  double get sortinoRatio {
    if (history.length < 2) return 0;
    final returns = history.map((t) => (t.pnl ?? 0) / initialUsdt).toList();
    final mean = returns.fold(0.0, (a, b) => a + b) / returns.length;
    final downVar = returns.where((r) => r < 0).map((r) => r * r).fold(0.0, (a, b) => a + b);
    final downCount = returns.where((r) => r < 0).length;
    final downStd = downCount > 0 ? _sqrt(downVar / downCount) : 0;
    return downStd > 0 ? mean / downStd : 0;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}