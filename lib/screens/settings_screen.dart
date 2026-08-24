import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/providers.dart';
import '../services/market_service.dart';
import '../services/cache_service.dart';
import '../services/storage_service.dart';
import '../services/local_notification_service.dart';
import '../services/background_service.dart';
import '../theme/noah_theme.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsProvider settings;
  final AuthProvider auth;
  final ChatProvider chat;
  final MarketService? market;
  final CacheService cache;
  final StorageService storage;
  final void Function(int) openLogin;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.auth,
    required this.chat,
    this.market,
    required this.cache,
    required this.storage,
    required this.openLogin,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _cacheSize = 0;
  int _imageCount = 0;
  bool _loadingCache = true;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    final size = await widget.cache.getCacheSize();
    final count = widget.cache.getImageCount();
    if (mounted) {
      setState(() {
        _cacheSize = size;
        _imageCount = count;
        _loadingCache = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
          final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
          final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
          final bg3 = isDark ? const Color(0xFF323232) : const Color(0xFFE8E3D8);
          final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
          final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
          final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
          final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
          final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
          final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
          return Container(
            color: bg0,
            child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Account card
          _section('Compte', bg1, border, accent, t2, isDark, [
            _infoRow('Nom', widget.auth.displayName, '$t0', accent, bg2, borderMd),
            _infoRow('Email', widget.auth.displayEmail, '$t0', accent, bg2, borderMd),
          ]),
          // Appearance card
          _section('Apparence', bg1, border, accent, t2, isDark, [
            _profileIconRow(widget.settings, accent, bg3, t0, t2, bg2, borderMd, isDark),
            _sectionLine(bg3),
            _themeRow(widget.settings, accent, bg3, t0, t2, isDark),
            _modeRow('Mode réel / Démo', widget.settings, widget.auth, widget.chat, widget.market, accent, bg3, t0, t2, bg2, borderMd, widget.openLogin, context),
            _sectionLine(bg3),
            _fontRow(widget.settings, accent, bg3, t0, t2, bg2, borderMd, isDark),
            _toggleRow('Texte en gras', 'Gras', '', widget.settings.useBold, widget.settings, accent, bg3, t0, t2, onChanged: (v) => widget.settings.setUseBold(v)),
          ]),
          // IA Configuration card
          _section('IA Configuration', bg1, border, accent, t2, isDark, [
            _selectRow('IA par défaut', widget.settings.defaultModel, ['DeepSeek', 'OpenAI', 'Claude'], bg2, borderMd, t0, t2, onChanged: (v) => widget.settings.setDefaultModel(v)),
            _selectRow('Mode réponse', widget.settings.responseMode, ['Précis (recommandé)', 'Rapide'], bg2, borderMd, t0, t2, onChanged: (v) => widget.settings.setResponseMode(v)),
          ]),
          // Security card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg1,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: border),
              boxShadow: NoahTheme.shadow(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Sécurité', accent, t2),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 14, color: t1),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '🔒 Toutes les clés API sont chiffrées en transit et au repos via Keychain/Keystore.',
                          style: TextStyle(fontSize: 11, color: t1, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _adminPasswordRow(widget.storage, accent, bg2, borderMd, t0, t2),
                const SizedBox(height: 12),
                _manualLockRow(accent, bg2, borderMd, t0, t2),
              ],
            ),
          ),
          // Cache card
          _section('Cache', bg1, border, accent, t2, isDark, [
            _cacheRow(bg2, borderMd, t0, t2, accent, isDark),
          ]),
          // Notifications card
          _section('Notifications', bg1, border, accent, t2, isDark, [
            _toggleRow('Trades exécutés', 'Notifications', '', widget.settings.notifyTrades, widget.settings, accent, bg3, t0, t2, onChanged: (v) => widget.settings.setNotifyTrades(v)),
            _toggleRow('Signaux IA', 'Notifications', '', widget.settings.notifySignals, widget.settings, accent, bg3, t0, t2, onChanged: (v) => widget.settings.setNotifySignals(v)),
            _toggleRow('Alertes de risque', 'Notifications', '', widget.settings.notifyRisk, widget.settings, accent, bg3, t0, t2, onChanged: (v) => widget.settings.setNotifyRisk(v)),
            _sectionLine(bg3),
            _toggleRow('Vibration', 'Notifications', '', widget.settings.notifyVibrate, widget.settings, accent, bg3, t0, t2, onChanged: (v) { widget.settings.setNotifyVibrate(v); LocalNotificationService.vibrateEnabled = v; }),
            _toggleRow('Son', 'Notifications', '', widget.settings.notifySound, widget.settings, accent, bg3, t0, t2, onChanged: (v) { widget.settings.setNotifySound(v); LocalNotificationService.soundEnabled = v; }),
          ]),
          // Trading card
          _section('Trading', bg1, border, accent, t2, isDark, [
            _profitDisplayRow(accent, bg3, t0, t2, bg2, borderMd),
            _sectionLine(bg3),
            _profitThresholdRow(widget.settings, accent, bg3, t0, t2, bg2, borderMd),
          ]),
          // Arrière-plan card
          _section('Arrière-plan', bg1, border, accent, t2, isDark, [
            _toggleRow('Surveillance continue', '', '', BackgroundService.isRunning, widget.settings, accent, bg3, t0, t2, onChanged: (v) {
              if (v) {
                BackgroundService.start();
              } else {
                BackgroundService.stop();
              }
              setState(() {});
            }),
            _batteryOptRow(context, bg2, borderMd, t0, t2, accent),
          ]),
          ],
        ),
      );
        },
      );
  }

  Widget _section(String title, Color bg1, Color border, Color accent, Color t2, bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: border),
        boxShadow: NoahTheme.shadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, accent, t2),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color accent, Color t2) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _sectionLine(Color bg3) {
    return Container(height: 1, color: bg3.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(vertical: 4));
  }

  Widget _infoRow(String label, String value, String _, Color accent, Color bg2, Color borderMd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF1C1C1C))),
              if (label == 'Nom')
                Text("Nom d'affichage", style: TextStyle(fontSize: 10, color: const Color(0xFF9C9C9C))),
            ],
          ),
          Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
        ],
      ),
    );
  }

  static const _fonts = [
    'Inter',
    'PlayfairDisplay',
    'JetBrainsMono',
  ];

  String _fontLabel(String f) {
    return switch (f) {
      'PlayfairDisplay' => 'Playfair Display',
      'JetBrainsMono' => 'JetBrains Mono',
      _ => f,
    };
  }

  Widget _fontRow(SettingsProvider settings, Color accent, Color bg3, Color t0, Color t2, Color bg2, Color borderMd, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Police', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderMd),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.fontFamily,
                style: TextStyle(fontSize: 12, color: t0),
                items: _fonts.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(_fontLabel(f), style: TextStyle(fontFamily: f)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) settings.setFontFamily(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profitDisplayRow(Color accent, Color bg3, Color t0, Color t2, Color bg2, Color borderMd) {
    final portfolio = widget.chat.portfolio;
    final totalValue = portfolio?.data.totalValue ?? 0;
    final locked = portfolio?.data.totalDeposits ?? 0;
    final profit = totalValue - locked;
    final profitPct = locked > 0 ? (profit / locked * 100) : 0.0;
    final isProfit = profit >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bénéfice actuel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
              Text("Depuis le début", style: TextStyle(fontSize: 9, color: t2)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isProfit ? const Color(0x144CAF8E) : const Color(0x14EF5350),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: isProfit ? const Color(0x2E4CAF8E) : const Color(0x2EEF5350)),
            ),
            child: Text(
              '${isProfit ? '+' : ''}${profitPct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isProfit ? const Color(0xFF4CAF8E) : const Color(0xFFEF5350),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profitThresholdRow(SettingsProvider settings, Color accent, Color bg3, Color t0, Color t2, Color bg2, Color borderMd) {
    final thresholds = [0, ...List.generate(50, (i) => i + 1)];
    final current = settings.profitOnlyThreshold.round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Capital protégé", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
              Text("Ne trader que le surplus au-dessus de ce seuil", style: TextStyle(fontSize: 9, color: t2)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(30), border: Border.all(color: borderMd)),
            child: DropdownButton<int>(
              value: current,
              underline: const SizedBox(),
              dropdownColor: bg2,
              style: TextStyle(fontSize: 12, color: t0),
              items: thresholds.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t == 0 ? 'Désactivé' : '$t%'),
              )).toList(),
              onChanged: (v) => settings.setProfitThreshold(v!.toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeRow(SettingsProvider settings, Color accent, Color bg3, Color t0, Color t2, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thème', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text('Clair / Sombre', style: TextStyle(fontSize: 10, color: t2)),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.light_mode, size: 16, color: isDark ? t2.withValues(alpha: 0.4) : accent),
              const SizedBox(width: 6),
              Switch(
                value: isDark,
                onChanged: (_) => settings.toggleDark(),
                activeColor: accent,
                inactiveTrackColor: bg3,
              ),
              const SizedBox(width: 6),
              Icon(Icons.dark_mode, size: 16, color: isDark ? accent : t2.withValues(alpha: 0.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, String value, String sub, bool isOn, SettingsProvider settings, Color accent, Color bg3, Color t0, Color t2, {ValueChanged<bool>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
              if (sub.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(sub, style: TextStyle(fontSize: 10, color: t2)),
                ),
            ],
          ),
          Row(
            children: [
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent, fontFamily: 'JetBrainsMono')),
              const SizedBox(width: 8),
              Switch(
                value: isOn,
                onChanged: onChanged,
                activeColor: accent,
                inactiveTrackColor: bg3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, SettingsProvider settings, AuthProvider auth, ChatProvider chat, Color accent, Color bg3, Color t0, Color t2, Color bg2, Color borderMd, void Function(int) openLogin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 36, color: const Color(0xFFD4A84B)),
            const SizedBox(height: 8),
            Text('Mode Réel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t0)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avant d\'activer le trading réel, confirme les points suivants :',
                  style: TextStyle(fontSize: 12, color: t0, height: 1.5)),
              const SizedBox(height: 12),
              _termsLine('Tu engages de l\'argent réel — pas de valeur fictive.', t0, t2),
              _termsLine('NOAH est un assistant IA, pas un conseiller financier.', t0, t2),
              _termsLine('Tu assumes l\'entière responsabilité de tes trades.', t0, t2),
              _termsLine('Une API Binance avec permissions trading doit être configurée.', t0, t2),
              _termsLine('Tu peux retourner en mode Démo à tout moment dans les réglages.', t0, t2),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x1AD4A84B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x2ED4A84B)),
                ),
                child: Text(
                  'Le mode réel nécessite que l\'API Binance soit connectée dans la page Connexions.',
                  style: TextStyle(fontSize: 10, color: const Color(0xFFD4A84B), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: t2)),
          ),
          GestureDetector(
            onTap: () {
              settings.acceptTerms();
              settings.toggleMode();
              Navigator.pop(ctx);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(16)),
              child: Text('Accepter & Activer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsLine(String text, Color t0, Color t2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: const Color(0xFF4CAF8E)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: t0, height: 1.4))),
        ],
      ),
    );
  }

  Widget _modeRow(String label, SettingsProvider settings, AuthProvider auth, ChatProvider chat, MarketService? market, Color accent, Color bg3, Color t0, Color t2, Color bg2, Color borderMd, void Function(int) openLogin, BuildContext context) {
    final isLive = market?.status == MarketStatus.live;
    final binanceOk = chat.binanceConnected && chat.binanceWorking;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
                  Text(!settings.isDemo ? '🔴 Argent réel engagé' : '⚠️ Argent fictif', style: TextStyle(fontSize: 10, color: !settings.isDemo ? const Color(0xFFE55353) : t2)),
                ],
              ),
              Switch(
                value: !settings.isDemo,
                onChanged: (v) {
                  if (!v) {
                    settings.toggleMode();
                    return;
                  }
                  if (!auth.isLoggedIn) {
                    openLogin(0);
                    return;
                  }
                  if (!chat.binanceConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Connectez d\'abord votre compte Binance dans Connexions'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  if (!chat.binanceWorking) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('La connexion Binance n\'est pas vérifiée. Testez-la dans Connexions.'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  if (!settings.hasAcceptedTerms) {
                    _showTermsDialog(context, settings, auth, chat, accent, bg3, t0, t2, bg2, borderMd, openLogin);
                    return;
                  }
                  settings.toggleMode();
                },
                activeColor: accent,
                inactiveTrackColor: bg3,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: binanceOk ? const Color(0x144CAF8E) : const Color(0x14E55353),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  binanceOk ? Icons.check_circle : Icons.error_outline,
                  size: 10,
                  color: binanceOk ? const Color(0xFF4CAF8E) : const Color(0xFFE55353),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    binanceOk
                        ? '✅ Binance connecté et vérifié'
                        : chat.binanceConnected
                            ? '⚠️ Clés Binance présentes — test de connexion requis'
                            : '❌ Binance non connecté — allez dans Connexions',
                    style: TextStyle(fontSize: 9, color: binanceOk ? const Color(0xFF4CAF8E) : const Color(0xFFE55353)),
                  ),
                ),
              ],
            ),
          ),
          if (!settings.isDemo) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLive ? const Color(0x144CAF8E) : const Color(0x14E55353),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLive ? Icons.check_circle : Icons.error_outline,
                    size: 10,
                    color: isLive ? const Color(0xFF4CAF8E) : const Color(0xFFE55353),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isLive ? 'Données marché en direct' : 'Données simulées',
                      style: TextStyle(fontSize: 9, color: isLive ? const Color(0xFF4CAF8E) : const Color(0xFFE55353)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectRow(String label, String value, List<String> options, Color bg2, Color borderMd, Color t0, Color t2, {void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderMd),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                style: TextStyle(fontSize: 12, color: t0),
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) { if (v != null && onChanged != null) onChanged(v); },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _batteryOptRow(BuildContext context, Color bg2, Color borderMd, Color t0, Color t2, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Optimisation batterie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text('Désactiver l\'optimisation pour la fiabilité', style: TextStyle(fontSize: 10, color: t2)),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _openBatterySettings(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.battery_std, size: 13, color: accent),
                  const SizedBox(width: 4),
                  Text('Paramètres', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openBatterySettings(BuildContext context) {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('noah/battery_settings');
        channel.invokeMethod('openBatterySettings');
      } catch (_) {}
    }
  }

  Widget _cacheRow(Color bg2, Color borderMd, Color t0, Color t2, Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Images du chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
                  Text(_loadingCache ? 'Calcul...' : '${widget.cache.formatSize(_cacheSize)} — $_imageCount image(s)', style: TextStyle(fontSize: 10, color: t2)),
                ],
              ),
              GestureDetector(
                onTap: _imageCount > 0 ? () => _showClearCacheDialog(isDark, accent, bg2, t0, t2, borderMd) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _imageCount > 0 ? const Color(0xFFE55353).withValues(alpha: 0.15) : bg2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _imageCount > 0 ? const Color(0xFFE55353).withValues(alpha: 0.3) : borderMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 13, color: _imageCount > 0 ? const Color(0xFFE55353) : t2),
                      const SizedBox(width: 4),
                      Text('Vider', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _imageCount > 0 ? const Color(0xFFE55353) : t2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(bool isDark, Color accent, Color bg2, Color t0, Color t2, Color borderMd) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 36, color: const Color(0xFFD4A84B)),
            const SizedBox(height: 8),
            Text('Vider le cache', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t0)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Toutes les images échangées dans les conversations seront supprimées définitivement.',
                style: TextStyle(fontSize: 12, color: t0, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1AD4A84B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x2ED4A84B)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: const Color(0xFFD4A84B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ En vidant le cache, les agents perdront l\'expérience visuelle '
                        'qu\'ils ont acquise depuis la première conversation. '
                        'Les messages texte et l\'historique des trades restent conservés.',
                        style: TextStyle(fontSize: 11, color: const Color(0xFFD4A84B), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: t2)),
          ),
          GestureDetector(
            onTap: () async {
              await widget.cache.clearCache();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                setState(() {
                  _cacheSize = 0;
                  _imageCount = 0;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(color: const Color(0xFFE55353), borderRadius: BorderRadius.circular(16)),
              child: Text('Vider le cache', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminPasswordRow(StorageService storage, Color accent, Color bg2, Color borderMd, Color t0, Color t2) {
    final currentPassword = storage.getAdminPassword() ?? '';
    final hasPassword = currentPassword.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 14, color: accent),
              const SizedBox(width: 6),
              Text('Accès Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Définissez un mot de passe pour accéder rapidement à l\'application via l\'option "Accès Admin" sur l\'écran de connexion.',
            style: TextStyle(fontSize: 10, color: t2, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderMd),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasPassword ? (_showPassword ? currentPassword : '••••••••') : 'Aucun mot de passe défini',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                            color: hasPassword ? t0 : t2,
                          ),
                        ),
                      ),
                      if (hasPassword)
                        GestureDetector(
                          onTap: () => setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            size: 16,
                            color: t2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showAdminPasswordDialog(storage, accent, bg2, t0, t2, borderMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    hasPassword ? 'Modifier' : 'Définir',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _manualLockRow(Color accent, Color bg2, Color borderMd, Color t0, Color t2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verrouillage manuel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text('Verrouiller l\'application maintenant', style: TextStyle(fontSize: 10, color: t2)),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              // Lock the app - this will be handled by a callback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Application verrouillée'),
                  backgroundColor: const Color(0xFF4CAF8E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 13, color: accent),
                  const SizedBox(width: 4),
                  Text('Verrouiller', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileIconRow(SettingsProvider settings, Color accent, Color bg3, Color t0, Color t2, Color bg2, Color borderMd, bool isDark) {
    const avatars = [
      'assets/icons/icon-noire-admin.jpg',
      'assets/icons/icon-or-admin.jpg',
      'assets/icons/icon-rouge-admin.jpg',
      'assets/icons/icon-argent-admin.jpg',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avatar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: avatars.map((iconPath) {
              final isSelected = settings.profileIcon == iconPath;
              return GestureDetector(
                onTap: () => settings.setProfileIcon(iconPath),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accent : borderMd,
                      width: isSelected ? 2 : 1,
                    ),
                    image: DecorationImage(
                      image: AssetImage(iconPath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAdminPasswordDialog(StorageService storage, Color accent, Color bg2, Color t0, Color t2, Color borderMd) {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = storage.hasAdminPassword();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: bg2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            showCurrent ? 'Modifier le mot de passe admin' : 'Définir le mot de passe admin',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCurrent) ...[
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe actuel',
                    filled: true,
                    fillColor: bg2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  style: TextStyle(fontSize: 14, color: t0),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: showCurrent ? confirmCtrl : passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: showCurrent ? 'Nouveau mot de passe' : 'Mot de passe admin',
                  filled: true,
                  fillColor: bg2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                style: TextStyle(fontSize: 14, color: t0),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: TextStyle(color: t2)),
            ),
            GestureDetector(
              onTap: () {
                final newPass = showCurrent ? confirmCtrl.text : passwordCtrl.text;
                if (newPass.isEmpty) return;
                storage.setAdminPassword(newPass);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(showCurrent ? 'Mot de passe admin modifié' : 'Mot de passe admin défini'),
                    backgroundColor: const Color(0xFF4CAF8E),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Enregistrer',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
