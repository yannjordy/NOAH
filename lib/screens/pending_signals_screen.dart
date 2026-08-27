import 'package:flutter/material.dart';
import '../services/signal_service.dart';
import '../services/notification_service.dart';
import '../theme/noah_theme.dart';

class PendingSignalsScreen extends StatefulWidget {
  final SignalService signalService;

  const PendingSignalsScreen({super.key, required this.signalService});

  @override
  State<PendingSignalsScreen> createState() => _PendingSignalsScreenState();
}

class _PendingSignalsScreenState extends State<PendingSignalsScreen> {
  @override
  void initState() {
    super.initState();
    widget.signalService.pendingSignals.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final signals = widget.signalService.currentPending;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E17) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Signaux en attente',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (signals.isNotEmpty)
            TextButton(
              onPressed: () {
                widget.signalService.clearAll();
              },
              child: Text('Tout rejeter', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
            ),
        ],
      ),
      body: signals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun signal en attente',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les opportunités apparaîtront ici',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: signals.length,
              itemBuilder: (context, index) {
                final signal = signals[index];
                final isBuy = signal.action == 'BUY';
                final signalAccent = isBuy ? const Color(0xFF4CAF8E) : const Color(0xFFE07060);
                final timeAgo = DateTime.now().difference(signal.createdAt);
                final timeStr = timeAgo.inSeconds < 60
                    ? '${timeAgo.inSeconds}s'
                    : '${timeAgo.inMinutes}min';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: signalAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: signalAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              signal.action,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: signalAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            signal.symbol,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: signalAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(signal.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: signalAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Reason
                      Text(
                        signal.reason,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Technical indicators
                      if (signal.technicals.isNotEmpty) ...[
                        Row(
                          children: [
                            _techBadge('RSI', '${(signal.technicals['rsi'] as double? ?? 50).toStringAsFixed(0)}', signal.technicals['rsiSignal'] as String? ?? 'NEUTRAL', isDark),
                            const SizedBox(width: 6),
                            _techBadge('MACD', signal.technicals['macdSignal'] as String? ?? 'NEUTRAL', '', isDark),
                            const SizedBox(width: 6),
                            _techBadge('Bollinger', signal.technicals['bollingerSignal'] as String? ?? 'NEUTRAL', '', isDark),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                widget.signalService.rejectSignal(signal);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close, size: 14, color: Colors.red),
                                    SizedBox(width: 4),
                                    Text('Rejeter', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                widget.signalService.approveSignal(signal);
                                NotificationService.showTradeAlert(
                                  symbol: signal.symbol,
                                  action: signal.action,
                                  confidence: signal.confidence,
                                  reason: 'Approuvé par l\'utilisateur',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: signalAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: signalAccent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check, size: 14, color: signalAccent),
                                    const SizedBox(width: 4),
                                    Text('Approuver', style: TextStyle(fontSize: 12, color: signalAccent, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _techBadge(String label, String value, String signal, bool isDark) {
    final signalColor = signal == 'OVERSOLD' || signal == 'BULLISH'
        ? const Color(0xFF4CAF8E)
        : signal == 'OVERBOUGHT' || signal == 'BEARISH'
            ? const Color(0xFFE07060)
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: signalColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 9, color: signalColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
