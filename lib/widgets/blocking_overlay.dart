import 'package:flutter/material.dart';

enum BlockReason { update, banned }

class BlockingOverlay extends StatelessWidget {
  final BlockReason reason;
  final String? email;
  final VoidCallback? onBypass;

  const BlockingOverlay({super.key, required this.reason, this.email, this.onBypass});

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
                    onPressed: () {
                      // Open GitHub releases page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Télécharger la mise à jour',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (reason == BlockReason.update && onBypass != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onBypass,
                    child: Text(
                      'Continuer quand même',
                      style: TextStyle(fontSize: 12, color: t2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
