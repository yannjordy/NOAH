import 'package:flutter/material.dart';
import '../theme/noah_theme.dart';

enum ErrorKind {
  offline,
  error,
  bug,
  warning,
}

class ErrorState extends StatelessWidget {
  final ErrorKind kind;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorState({
    super.key,
    this.kind = ErrorKind.error,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  String _title() {
    if (title != null) return title!;
    switch (kind) {
      case ErrorKind.offline:
        return 'Hors connexion';
      case ErrorKind.error:
        return 'Une erreur est survenue';
      case ErrorKind.bug:
        return 'Problème technique';
      case ErrorKind.warning:
        return 'Attention';
    }
  }

  String _message() {
    if (message != null) return message!;
    switch (kind) {
      case ErrorKind.offline:
        return 'Vérifiez votre connexion réseau\net réessayez.';
      case ErrorKind.error:
        return 'Quelque chose s\'est mal passé.\nVeuillez réessayer plus tard.';
      case ErrorKind.bug:
        return 'Un comportement inattendu a été détecté.\nSi le problème persiste, contactez le support.';
      case ErrorKind.warning:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = C();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo2.png',
              width: 100,
              height: 100,
              color: kind == ErrorKind.offline
                  ? c.t2
                  : kind == ErrorKind.warning
                      ? c.amber
                      : c.red,
            ),
            const SizedBox(height: 20),
            Text(
              _title(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.t0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _message(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: c.t1,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
