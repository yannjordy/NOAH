import 'dart:ui';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════
///  NOAH GLASS MORPHISM 2026 — Design System
/// ═══════════════════════════════════════════════════════

class NoahGlass {
  // ─── Standard Values ────────────────────────────────
  static const double blurLight = 16;
  static const double blurMedium = 24;
  static const double blurHeavy = 32;
  static const double radiusSm = 16.0;
  static const double radiusMd = 24.0;
  static const double radiusLg = 32.0;
  static const double radiusXl = 40.0;

  // ─── Colors (Dark Mode) ─────────────────────────────
  static Color darkBg({double opacity = 0.14}) =>
      Colors.white.withValues(alpha: opacity);
  static const Color darkBorder = Color(0x1AFFFFFF); // 10%
  static const Color darkBorderHighlight = Color(0x33FFFFFF); // 20%
  static const Color darkGlow = Color(0x0DFFFFFF); // 5%

  // ─── Colors (Light Mode) ────────────────────────────
  static Color lightBg({double opacity = 0.12}) =>
      Colors.black.withValues(alpha: opacity);
  static const Color lightBorder = Color(0x0F000000); // 6%
  static const Color lightBorderHighlight = Color(0x1A000000); // 10%
  static const Color lightGlow = Color(0x08000000); // 3%

  // ─── Getters by theme ───────────────────────────────
  static Color bgColor(bool isDark, {double opacity = 0.14}) =>
      isDark ? darkBg(opacity: opacity) : lightBg(opacity: opacity + 0.02);
  static Color borderColor(bool isDark) =>
      isDark ? darkBorder : lightBorder;
  static Color borderHighlight(bool isDark) =>
      isDark ? darkBorderHighlight : lightBorderHighlight;
  static double blurForContext(bool isDark) => isDark ? blurMedium : blurLight;
}

/// ═══════════════════════════════════════════════════════
///  GlassCard — Carte principale avec effet frosted glass
/// ═══════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final double borderRadius;
  final double blur;
  final double? opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showGlow;
  final Color? accentColor;

  const GlassCard({
    super.key,
    required this.child,
    required this.isDark,
    this.borderRadius = NoahGlass.radiusMd,
    this.blur = NoahGlass.blurMedium,
    this.opacity,
    this.padding,
    this.margin,
    this.showGlow = true,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgOp = opacity ?? (isDark ? 0.14 : 0.12);
    final bg = isDark
        ? Color.fromRGBO(255, 255, 255, bgOp)
        : Color.fromRGBO(0, 0, 0, bgOp);
    final border = isDark ? NoahGlass.darkBorder : NoahGlass.lightBorder;
    final glow = isDark ? NoahGlass.darkGlow : NoahGlass.lightGlow;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 0.5),
              boxShadow: [
                if (showGlow)
                  BoxShadow(
                    color: glow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
              // Top-edge highlight gradient
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════
///  GlassModal — Modal/BottomSheet avec effet frosted
/// ═══════════════════════════════════════════════════════
class GlassModal extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final double borderRadius;
  final bool showHandle;

  const GlassModal({
    super.key,
    required this.child,
    required this.isDark,
    this.borderRadius = 32,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Color.fromRGBO(30, 30, 30, 0.92)
        : Color.fromRGBO(255, 255, 255, 0.92);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: NoahGlass.blurHeavy, sigmaY: NoahGlass.blurHeavy),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════
///  GlassButton — Bouton avec effet frosted glass
/// ═══════════════════════════════════════════════════════
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    required this.isDark,
    this.color,
    this.borderRadius = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? (isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06));
    final border = isDark ? NoahGlass.darkBorder : NoahGlass.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════
///  GlassSection — Section标题 + glass container
/// ═══════════════════════════════════════════════════════
class GlassSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  final String? subtitle;
  final Color? accentColor;

  const GlassSection({
    super.key,
    required this.title,
    required this.child,
    required this.isDark,
    this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? const Color(0xFFC2A878);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 3, height: 14,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 0.8,
              )),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(subtitle!, style: TextStyle(
                  fontSize: 10, color: isDark ? Colors.white38 : Colors.black38,
                )),
              ],
            ],
          ),
        ),
        GlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════
///  GlassToggle — Toggle switch glass morphism
/// ═══════════════════════════════════════════════════════
class GlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color activeColor;

  const GlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.activeColor = const Color(0xFFC2A878),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 24,
        decoration: BoxDecoration(
          color: value
              ? activeColor.withValues(alpha: 0.8)
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? activeColor.withValues(alpha: 0.3)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20, height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : (isDark ? Colors.white54 : Colors.black38),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════
///  GlassSlider — Slider glass morphism
/// ═══════════════════════════════════════════════════════
class GlassSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final bool isDark;
  final Color activeColor;

  const GlassSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.isDark,
    this.activeColor = const Color(0xFFC2A878),
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: activeColor,
        inactiveTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        thumbColor: activeColor,
        overlayColor: activeColor.withValues(alpha: 0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackHeight: 3,
      ),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged),
    );
  }
}

/// ═══════════════════════════════════════════════════════
///  GlassInput — Input field glass morphism
/// ═══════════════════════════════════════════════════════
class GlassInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool isDark;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;

  const GlassInput({
    super.key,
    this.controller,
    this.hintText,
    required this.isDark,
    this.prefixIcon,
    this.suffixIcon,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark ? NoahGlass.darkBorder : NoahGlass.lightBorder;
    final hintColor = isDark ? Colors.white30 : Colors.black26;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 0.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor, fontSize: 13),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════
///  GlassNav — Bottom navigation glass morphism
/// ═══════════════════════════════════════════════════════
class GlassNav extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const GlassNav({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: NoahGlass.blurHeavy, sigmaY: NoahGlass.blurHeavy),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: isDark
                ? Color.fromRGBO(18, 18, 18, 0.85)
                : Color.fromRGBO(247, 244, 238, 0.88),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
