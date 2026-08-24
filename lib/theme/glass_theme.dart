import 'dart:ui';
import 'package:flutter/material.dart';

/// Glass morphism design system — 2026 pro standard
class GlassTheme {
  GlassTheme._();

  // ─── Glass Container ──────────────────────────────
  static Widget card({
    required BuildContext context,
    required Widget child,
    double borderRadius = 24,
    double blur = 20,
    double opacity = 0.12,
    EdgeInsets padding = const EdgeInsets.all(16),
    EdgeInsets? margin,
    bool showBorder = true,
    bool showShadow = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity( isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity( isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _glassColor(isDark, opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: _glassBorder(isDark),
                      width: 1,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ─── Glass Card (no clip) ─────────────────────────
  static Widget cardFlat({
    required BuildContext context,
    required Widget child,
    double borderRadius = 24,
    double opacity = 0.08,
    EdgeInsets padding = const EdgeInsets.all(16),
    EdgeInsets? margin,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: _glassColor(isDark, opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: _glassBorder(isDark),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── Glass Button ──────────────────────────────────
  static Widget button({
    required BuildContext context,
    required VoidCallback onTap,
    required Widget child,
    bool isPrimary = false,
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isPrimary
                  ? accent.withOpacity( 0.9)
                  : _glassColor(isDark, 0.15),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isPrimary
                    ? accent.withOpacity( 0.5)
                    : _glassBorder(isDark),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ─── Glass Chip ────────────────────────────────────
  static Widget chip({
    required BuildContext context,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? accent.withOpacity( 0.15)
              : _glassColor(isDark, 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? accent.withOpacity( 0.4)
                : _glassBorder(isDark),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? accent : t1,
          ),
        ),
      ),
    );
  }

  // ─── Glass Modal Bottom Sheet ──────────────────────
  static Future<T?> showModal<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    double borderRadius = 32,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: _glassColor(isDark, 0.25),
              borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
              border: Border.all(
                color: _glassBorder(isDark),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _glassBorder(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Glass AppBar ──────────────────────────────────
  static PreferredSizeWidget appBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    bool showBack = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _glassColor(isDark, 0.2),
              border: Border(
                bottom: BorderSide(color: _glassBorder(isDark), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 18, color: t2),
                    onPressed: () => Navigator.pop(context),
                  ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: t0,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (actions != null) ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────
  static Color _glassColor(bool isDark, double opacity) {
    return isDark
        ? Colors.white.withOpacity( opacity)
        : Colors.white.withOpacity( opacity * 1.5);
  }

  static Color _glassBorder(bool isDark) {
    return isDark
        ? Colors.white.withOpacity( 0.12)
        : Colors.black.withOpacity( 0.06);
  }
}
