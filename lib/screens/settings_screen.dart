import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/providers.dart';
import '../services/market_service.dart';
import '../services/storage_service.dart';
import '../theme/glass_theme.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsProvider settings;
  final RiskProvider risk;
  final AuthProvider auth;
  final ChatProvider chat;
  final MarketService market;
  final StorageService storage;
  final VoidCallback openLogin;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.risk,
    required this.auth,
    required this.chat,
    required this.market,
    required this.storage,
    required this.openLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);

    return Container(
      color: bg0,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          GlassTheme.cardFlat(
            context: context,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('Paramètres', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),
                _settingRow('Mode Démonstration', settings.isDemo, (v) => settings.setDemo(v), t0, t2, accent),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassTheme.cardFlat(
            context: context,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('Notifications', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),
                _settingRow('Signaux Trading', settings.notifySignals, (v) => settings.setNotifySignals(v), t0, t2, accent),
                _settingRow('Exécution Trades', settings.notifyTrades, (v) => settings.setNotifyTrades(v), t0, t2, accent),
                _settingRow('Alertes Risque', settings.notifyRisk, (v) => settings.setNotifyRisk(v), t0, t2, accent),
                _settingRow('Vibrations', settings.notifyVibrate, (v) => settings.setNotifyVibrate(v), t0, t2, accent),
                _settingRow('Son', settings.notifySound, (v) => settings.setNotifySound(v), t0, t2, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(String label, bool value, ValueChanged<bool> onChanged, Color t0, Color t2, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
          ),
        ],
      ),
    );
  }
}
