import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../providers/providers.dart';

class AccountSheet extends StatelessWidget {
  final bool isOpen;
  final double animValue;
  final AuthProvider auth;
  final SettingsProvider settings;
  final VoidCallback onClose;

  const AccountSheet({
    super.key,
    required this.isOpen,
    this.animValue = 0.0,
    required this.auth,
    required this.settings,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final bg4 = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFDDD6C8);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final accentBg = isDark ? const Color(0x1AC2A878) : const Color(0x1AB08D57);
    final accentBorder = isDark ? const Color(0x2EC2A878) : const Color(0x33B08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final greenBg = isDark ? const Color(0x144CAF8E) : const Color(0x142E7D5E);
    final greenBorder = isDark ? const Color(0x2E4CAF8E) : const Color(0x2E2E7D5E);
    final amber = isDark ? const Color(0xFFD4A84B) : const Color(0xFFA67C2E);
    final amberBg = isDark ? const Color(0x14D4A84B) : const Color(0x14A67C2E);
    final amberBorder = isDark ? const Color(0x2ED4A84B) : const Color(0x2EA67C2E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
    final redBg = isDark ? const Color(0x14E07060) : const Color(0x14B8453A);
    final redBorder = isDark ? const Color(0x2EE07060) : const Color(0x2EB8453A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      transform: isOpen ? Matrix4.identity() : Matrix4.translationValues(0, 500, 0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity( 0.1), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x331E1E1E)
                  : const Color(0x33FFFFFF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x22000000),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4, margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(color: bg4, borderRadius: BorderRadius.circular(2)),
                  ),
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
                    child: Row(
                      children: [
                        Text('Compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t0)),
                        const Spacer(),
                        GestureDetector(onTap: onClose, child: Icon(Icons.close, size: 20, color: t2)),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _row(
                          icon: Icon(Icons.person, size: 18, color: accent),
                          iconBg: accentBg,
                          iconBorder: accentBorder,
                          label: 'Nom du trader',
                          desc: "Nom d'affichage",
                          value: auth.displayName,
                          valueColor: accent,
                        ),
                        _row(
                          icon: Icon(Icons.email_outlined, size: 18, color: t2),
                          iconBg: bg2,
                          iconBorder: borderMd,
                          label: 'Email',
                          desc: 'Adresse email liée',
                          value: auth.displayEmail,
                          valueColor: accent,
                        ),
                        _row(
                          icon: const Text('⚡', style: TextStyle(fontSize: 16)),
                          iconBg: bg2,
                          iconBorder: borderMd,
                          label: 'Statut',
                          desc: 'Mode de trading actif',
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: auth.isLoggedIn ? greenBg : amberBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: auth.isLoggedIn ? greenBorder : amberBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  auth.isLoggedIn ? Icons.check_circle_outline : Icons.star_border,
                                  size: 12,
                                  color: auth.isLoggedIn ? green : amber,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  auth.isLoggedIn ? 'CONNECTÉ' : 'INVITÉ',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: auth.isLoggedIn ? green : amber),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            if (auth.isLoggedIn) {
                              auth.logout();
                              onClose();
                            } else {
                              onClose();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: redBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: redBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  auth.isLoggedIn ? Icons.logout : Icons.login,
                                  size: 16,
                                  color: red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  auth.isLoggedIn ? 'Se déconnecter' : 'Se connecter',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row({
    required Widget icon,
    required Color iconBg,
    required Color iconBorder,
    required String label,
    required String desc,
    String? value,
    Color? valueColor,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: iconBorder),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF000000))),
                const SizedBox(height: 1),
                Text(desc, style: TextStyle(fontSize: 11, color: const Color(0xFF9C9C9C))),
              ],
            ),
          ),
          valueWidget ??
              Text(value ?? '', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
