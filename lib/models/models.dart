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
  double pnlPct(String sym) => entry > 0 ? (((prices[sym] ?? 0) - entry) / entry) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'sym': sym,
    'qty': qty,
    'entry': entry,
    'stopLoss': stopLoss,
    'takeProfit': takeProfit,
    'icon': icon,
    'color': color,
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    sym: json['sym'] as String,
    qty: (json['qty'] as num).toDouble(),
    entry: (json['entry'] as num).toDouble(),
    stopLoss: (json['stopLoss'] as num?)?.toDouble(),
    takeProfit: (json['takeProfit'] as num?)?.toDouble(),
  );
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
    this.time = "À l'instant",
  });

  Map<String, dynamic> toJson() => {
    'side': side,
    'sym': sym,
    'qty': qty,
    'price': price,
    'pnl': pnl,
    'time': time,
  };

  factory TradeOrder.fromJson(Map<String, dynamic> json) => TradeOrder(
    side: json['side'] as String,
    sym: json['sym'] as String,
    qty: (json['qty'] as num).toDouble(),
    price: (json['price'] as num).toDouble(),
    pnl: (json['pnl'] as num?)?.toDouble(),
    time: json['time'] as String? ?? "À l'instant",
  );
}

class WalletTransaction {
  final String type; // 'deposit', 'withdraw'
  final double amount;
  final String label;
  final String time;

  WalletTransaction({
    required this.type,
    required this.amount,
    required this.label,
    this.time = "À l'instant",
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    'label': label,
    'time': time,
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    type: json['type'] as String,
    amount: (json['amount'] as num).toDouble(),
    label: json['label'] as String? ?? '',
    time: json['time'] as String? ?? "À l'instant",
  );
}

class PortfolioData {
  double usdt;
  double initialUsdt;
  double totalDeposits;
  List<Position> positions;
  List<TradeOrder> history;
  List<WalletTransaction> walletHistory;
  List<double> dailyReturns;
  double peakCapital;
  double totalFees;

  PortfolioData({
    double? usdt,
    double? initialUsdt,
    double? totalDeposits,
    List<Position>? positions,
    List<TradeOrder>? history,
    List<WalletTransaction>? walletHistory,
    List<double>? dailyReturns,
    double? peakCapital,
    double? totalFees,
  })  : usdt = usdt ?? 0.0,
        initialUsdt = initialUsdt ?? 0.0,
        totalDeposits = totalDeposits ?? 0.0,
        positions = positions ?? [],
        history = history ?? [],
        walletHistory = walletHistory ?? [],
        dailyReturns = dailyReturns ?? [],
        peakCapital = peakCapital ?? 0.0,
        totalFees = totalFees ?? 0.0;

  double get positionsValue {
    return positions.fold(0.0, (s, p) => s + p.qty * (prices[p.sym] ?? 0));
  }

  double get totalValue => usdt + positionsValue;

  double get pnl {
    return positions.fold(0.0, (s, p) => s + p.qty * ((prices[p.sym] ?? 0) - p.entry));
  }

  double get pnlPct => positionsValue > 0 ? (pnl / positionsValue) * 100 : 0;

  double get maxDrawdown {
    if (peakCapital <= 0) return 0;
    return ((peakCapital - totalValue) / peakCapital * 100).clamp(0, 100);
  }

  double get bestTrade {
    if (history.isEmpty) return 0;
    return history.map((t) => t.pnl ?? 0).reduce(max);
  }

  double get worstTrade {
    if (history.isEmpty) return 0;
    return history.map((t) => t.pnl ?? 0).reduce(min);
  }

  int get winningTrades => history.where((t) => (t.pnl ?? 0) > 0).length;
  int get losingTrades => history.where((t) => (t.pnl ?? 0) < 0).length;
  double get winRate => history.isNotEmpty ? winningTrades / history.length : 0;

  double get profitFactor {
    final grossProfit = history.where((t) => (t.pnl ?? 0) > 0).fold(0.0, (s, t) => s + t.pnl!);
    final grossLoss = history.where((t) => (t.pnl ?? 0) < 0).fold(0.0, (s, t) => s + t.pnl!.abs());
    return grossLoss > 0 ? grossProfit / grossLoss : 0;
  }

  Map<String, dynamic> toJson() => {
    'usdt': usdt,
    'initialUsdt': initialUsdt,
    'totalDeposits': totalDeposits,
    'positions': positions.map((p) => p.toJson()).toList(),
    'history': history.map((t) => t.toJson()).toList(),
    'walletHistory': walletHistory.map((w) => w.toJson()).toList(),
    'dailyReturns': dailyReturns,
    'peakCapital': peakCapital,
    'totalFees': totalFees,
  };

  factory PortfolioData.fromJson(Map<String, dynamic> json) => PortfolioData(
    usdt: (json['usdt'] as num?)?.toDouble() ?? 0.0,
    initialUsdt: (json['initialUsdt'] as num?)?.toDouble() ?? 0.0,
    totalDeposits: (json['totalDeposits'] as num?)?.toDouble() ?? 0.0,
    positions: (json['positions'] as List?)?.map((e) => Position.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    history: (json['history'] as List?)?.map((e) => TradeOrder.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    walletHistory: (json['walletHistory'] as List?)?.map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    dailyReturns: (json['dailyReturns'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    peakCapital: (json['peakCapital'] as num?)?.toDouble() ?? 0.0,
    totalFees: (json['totalFees'] as num?)?.toDouble() ?? 0.0,
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

  factory Kline.fromBinance(List<dynamic> arr) {
    return Kline(
      openTime: arr[0] as int,
      open: double.parse(arr[1].toString()),
      high: double.parse(arr[2].toString()),
      low: double.parse(arr[3].toString()),
      close: double.parse(arr[4].toString()),
      volume: double.parse(arr[5].toString()),
      closeTime: arr[6] as int,
    );
  }

  bool get isUp => close >= open;
  double get body => (close - open).abs();
  double get upperShadow => high - (isUp ? close : open);
  double get lowerShadow => (isUp ? open : close) - low;
}

enum AnnotationType { trendLine, horizontal, text, ray }

class ChartAnnotation {
  final String id;
  final AnnotationType type;
  final double x1, y1, x2, y2;
  final String? label;
  final Color color;

  ChartAnnotation({
    required this.id,
    required this.type,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.label,
    this.color = const Color(0xFFB08D57),
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2,
    'label': label,
    'color': color.value,
  };

  factory ChartAnnotation.fromJson(Map<String, dynamic> json) => ChartAnnotation(
    id: json['id'] as String,
    type: AnnotationType.values[json['type'] as int],
    x1: (json['x1'] as num).toDouble(),
    y1: (json['y1'] as num).toDouble(),
    x2: (json['x2'] as num).toDouble(),
    y2: (json['y2'] as num).toDouble(),
    label: json['label'] as String?,
    color: Color(json['color'] as int),
  );
}

const intervals = ['1m', '5m', '15m', '1h', '4h', '1d'];

const symbols = ['BTC', 'ETH', 'BNB', 'SOL', 'XRP', 'ADA', 'DOGE', 'AVAX', 'LINK', 'DOT', 'MATIC', 'UNI', 'SHIB', 'LTC', 'BCH', 'ATOM', 'ETC', 'XLM', 'FIL', 'APT', 'ARB', 'OP', 'SUI', 'INJ', 'TIA', 'SEI', 'PEPE', 'FLOKI', 'AAVE', 'MKR', 'CRV', 'COMP', 'SNX', 'LDO', 'RUNE', 'ALGO', 'NEAR', 'FLOW', 'SAND', 'MANA', 'AXS'];

const basePrices = {
  'BTC': 67840.0, 'ETH': 3210.0, 'BNB': 412.0, 'SOL': 182.0,
  'XRP': 0.62, 'ADA': 0.48, 'DOGE': 0.18, 'AVAX': 38.0,
  'LINK': 14.5, 'DOT': 7.2, 'MATIC': 0.72, 'UNI': 7.8,
  'SHIB': 0.000025, 'LTC': 72.0, 'BCH': 240.0, 'ATOM': 8.5,
  'ETC': 25.0, 'XLM': 0.11, 'FIL': 5.8, 'APT': 9.2,
  'ARB': 1.1, 'OP': 2.8, 'SUI': 1.6, 'INJ': 25.0,
  'TIA': 8.5, 'SEI': 0.55, 'PEPE': 0.000012, 'FLOKI': 0.00022,
  'AAVE': 95.0, 'MKR': 1500.0, 'CRV': 0.45, 'COMP': 45.0,
  'SNX': 3.2, 'LDO': 2.1, 'RUNE': 5.0, 'ALGO': 0.18,
  'NEAR': 4.5, 'FLOW': 0.85, 'SAND': 0.45, 'MANA': 0.48, 'AXS': 7.5,
};

final prices = Map<String, double>.from(basePrices);
final pcts = <String, double>{};
DateTime lastPriceUpdate = DateTime.now();
bool isMarketConnected = false;

bool isDataFresh({int maxAgeSeconds = 30}) {
  return DateTime.now().difference(lastPriceUpdate).inSeconds < maxAgeSeconds;
}

bool get isNetworkStable => isMarketConnected && isDataFresh(maxAgeSeconds: 15);

void simulatePrices() {
  final r = Random();
  for (final s in symbols) {
    final d = (r.nextDouble() - 0.49) * basePrices[s]! * 0.0025;
    prices[s] = (prices[s]! + d).clamp(basePrices[s]! * 0.7, basePrices[s]! * 1.3);
    pcts[s] = ((pcts[s] ?? 0) + (r.nextDouble() - 0.5) * 0.08).clamp(-8.0, 8.0);
  }
}

String fmt(double p) {
  if (p >= 1000) {
    final parts = p.toStringAsFixed(0);
    final buffer = StringBuffer('\$');
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
  if (p >= 1) return '\$${p.toStringAsFixed(2)}';
  return '\$${p.toStringAsFixed(4)}';
}

const aiResponses = {
  'Analyse BTC maintenant': '📊 **Analyse BTC en temps réel**\n\nLe BTC affiche une solide dynamique haussière avec +{BTC_PCT}% sur 24h. Le prix de {BTC_PRICE} se situe au-dessus de la SMA20 et SMA50, signal bull. Le RSI(14) autour de 58 indique une marge avant la zone de surachat (>70). Volume en hausse de 12% — confirme la tendance.\n\n**Point d\'entrée potentiel** : pullback vers \$66,500 (support SMA20). Stop loss suggéré : \$64,800 (-2.1%).\n\nSIGNAL : BUY|BTC|0.81',
  'Signal sur ETH': '⚡ **Signal Ethereum**\n\nETH/USDT à {ETH_PRICE} — consolidation dans un range \$3,100-\$3,280 depuis 36h. Le triangle symétrique qui se forme suggère une sortie imminente. Breakout haussier probable si le volume accompagne au-delà de \$3,285.\n\n**Catalyseurs** : adoption DeFi en hausse, staking yield attractif à 3.8%.\n\nSIGNAL : BUY|ETH|0.73',
  'Tendance du marché': '🌍 **Vue marché globale**\n\nDominance BTC : 52.3% (léger recul → altseason partielle). Total Market Cap : \$2.41T (+1.8%/24h).\n\n**Top performers 24h** : SOL +{SOL_PCT}%, DOGE +{DOGE_PCT}%\n**Underperformers** : XRP {XRP_PCT}%, AVAX {AVAX_PCT}%\n\nLe Fear & Greed Index est à 68 (Greed). Recommandation : positions core maintenues, réduire exposition sur les alts spéculatifs.\n\nSIGNAL : HOLD|BTC|0.65',
  'Évaluation des risques': '🛡 **Analyse des risques actuels**\n\n**Macro** : données inflation US vendredi — volatilité attendue +/-5%. Fed meeting dans 12 jours.\n\n**Techniques** : BTC résistance clé à \$69,500. Cassure = objectif \$74,000. Échec = pullback \$63,000.\n\n**Liquidations** : \$180M de longs liquidés hier — marché sain.\n\n**Recommandation** : stop loss sur toutes les positions, 20-30% en USDT.\n\nSIGNAL : HOLD|BTC|0.62',
};

final defaultResponses = [
  '📈 **Analyse en cours...**\n\nBasé sur les données de marché actuelles, le marché montre des signaux {DIR} avec une volatilité {VOL}. La structure de prix suggère {STRUCT}.\n\nPour une analyse plus précise, je prends en compte vos positions ouvertes et votre profil de risque.\n\nSIGNAL : HOLD|BTC|0.55',
  '🔍 **Réponse NOAH**\n\nBTC à {BTC_PRICE} — momentum {MOMO}. ETH montre une corrélation de 0.87 avec BTC à court terme.\n\nPrécisez votre horizon d\'investissement pour des recommandations plus fines.\n\nSIGNAL : HOLD|BTC|0.50',
];
