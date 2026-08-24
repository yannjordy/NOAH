import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/noah_theme.dart';
import '../theme/glass_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    return Container(
      color: bg0,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Hero
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Image.asset('assets/logo-remove.png', width: 120, errorBuilder: (_, __, ___) => const SizedBox()),
                const SizedBox(height: 18),
                Text('NOAH', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 26, color: accent, letterSpacing: 4)),
                const SizedBox(height: 4),
                Text('Neural Operator for Autonomous Holdings',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t2)),
              ],
            ),
          ),
          // Description card
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg1.withOpacity( isDark ? 0.5 : 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 13, height: 1.7, color: t1),
                        children: [
                          TextSpan(text: 'NOAH', style: TextStyle(fontWeight: FontWeight.bold, color: t0)),
                          const TextSpan(text: ' est votre copilote de trading IA. Conçu pour être aussi '),
                          TextSpan(text: 'simple que WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, color: t0)),
                          const TextSpan(text: ', aussi '),
                          TextSpan(text: 'élégant que Claude', style: TextStyle(fontWeight: FontWeight.bold, color: t0)),
                          const TextSpan(text: ', aussi '),
                          TextSpan(text: 'puissant que TradingView', style: TextStyle(fontWeight: FontWeight.bold, color: t0)),
                          const TextSpan(text: ', aussi '),
                          TextSpan(text: 'sécurisé qu\'un système bancaire', style: TextStyle(fontWeight: FontWeight.bold, color: t0)),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        'Notre mission : donner à chaque trader un assistant IA qui comprend les marchés, respecte le capital et prend des décisions éclairées — sans bruit, sans émotion, sans compromis.',
                        style: TextStyle(fontSize: 12, color: t2, height: 1.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        '"Calme. Précis. Analytique. Premium."',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // System info card
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg1.withOpacity( isDark ? 0.5 : 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: border),
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('Système', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 8),
                _sysRow('Version', '1.0.0', accent, t0, t2),
                _sysRow('Architecture', 'Multi-Agent', accent, t0, t2),
                _sysRow('IA Providers', 'DeepSeek + Fallback', accent, t0, t2),
                _sysRow('Exchange', 'Binance (CCXT)', accent, t0, t2),
              ],
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _sysRow(String label, String value, Color accent, Color t0, Color t2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t0)),
          Text(value, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
        ],
      ),
    );
  }
}
