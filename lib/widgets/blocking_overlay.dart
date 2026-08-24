import 'dart:ui';
import 'package:flutter/material.dart';

enum BlockReason { update, banned }

class BlockingOverlay extends StatelessWidget {
  final BlockReason reason;
  final String? email;

  const BlockingOverlay({super.key, required this.reason, this.email});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F4EE);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.fromRGBO(30, 30, 30, 0.85)
                      : Color.fromRGBO(255, 255, 255, 0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: reason == BlockReason.banned
                            ? const Color(0xFFE07060).withValues(alpha: 0.15)
                            : accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        reason == BlockReason.banned
                            ? Icons.block
                            : Icons.system_update,
                        size: 36,
                        color: reason == BlockReason.banned
                            ? const Color(0xFFE07060)
                            : accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      reason == BlockReason.banned
                          ? 'Compte banni'
                          : 'Mise à jour requise',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: t0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reason == BlockReason.banned
                          ? 'Votre compte a été désactivé par l\'administration.\n'
                              'Contactez le support pour plus d\'informations.'
                          : 'Une nouvelle version de NOAH est disponible.\n'
                              'Téléchargez la dernière mise à jour pour continuer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: t2, height: 1.5),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        email!,
                        style: TextStyle(fontSize: 12, color: t2),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (reason == BlockReason.update)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Télécharger la mise à jour',
                            style:
                                TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
