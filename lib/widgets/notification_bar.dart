import 'package:flutter/material.dart';

enum NotificationState { normal, tradingActive, networkLost, reconnected }

class NotificationBar extends StatefulWidget {
  final bool tradingEnabled;
  final bool backendOnline;
  final bool showReconnected;
  final bool isDark;

  const NotificationBar({
    super.key,
    required this.tradingEnabled,
    required this.backendOnline,
    required this.showReconnected,
    required this.isDark,
  });

  @override
  State<NotificationBar> createState() => _NotificationBarState();
}

class _NotificationBarState extends State<NotificationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  NotificationState get _state {
    if (!widget.backendOnline) return NotificationState.networkLost;
    if (widget.tradingEnabled) return NotificationState.tradingActive;
    if (widget.showReconnected) return NotificationState.reconnected;
    return NotificationState.normal;
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (_state == NotificationState.tradingActive) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant NotificationBar old) {
    super.didUpdateWidget(old);
    if (_state == NotificationState.tradingActive &&
        !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (_state != NotificationState.tradingActive &&
        _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == NotificationState.normal) return const SizedBox(height: 3);

    Color barColor;
    Color textColor;
    String label;
    IconData icon;
    bool pulse;

    switch (state) {
      case NotificationState.tradingActive:
        barColor = widget.isDark
            ? const Color(0xFF4CAF8E)
            : const Color(0xFF2E7D5E);
        textColor = barColor;
        label = 'Trading IA Actif';
        icon = Icons.auto_awesome;
        pulse = true;
      case NotificationState.networkLost:
        barColor = widget.isDark
            ? const Color(0xFFE07060)
            : const Color(0xFFB8453A);
        textColor = barColor;
        label = 'Réseau perdu';
        icon = Icons.wifi_off;
        pulse = false;
      case NotificationState.reconnected:
        barColor = widget.isDark
            ? const Color(0xFF4CAF8E)
            : const Color(0xFF2E7D5E);
        textColor = barColor;
        label = 'Réseau rétabli';
        icon = Icons.wifi;
        pulse = false;
      default:
        return const SizedBox(height: 3);
    }

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final opacity = pulse ? _pulseAnim.value : 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin colored strip
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 3,
              color: barColor.withValues(alpha: opacity),
            ),
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: barColor.withValues(alpha: pulse ? 0.08 * opacity : 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: barColor.withValues(alpha: pulse ? 0.15 * opacity : 0.15),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: textColor.withValues(alpha: opacity)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: opacity),
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (state == NotificationState.tradingActive) ...[
                    const SizedBox(width: 6),
                    _dot(textColor, opacity),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dot(Color color, double opacity) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 0.5),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
