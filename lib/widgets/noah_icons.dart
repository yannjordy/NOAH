import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class NoahIcons {
  static Widget clock(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="7"/><path d="M12 9v3l2 2"/></svg>',
        size, color);
  static Widget chat(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>',
        size, color);
  static Widget chart(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M7 16V8m5 8V4m5 12v-4"/><rect x="2" y="2" width="20" height="20" rx="3"/></svg>',
        size, color);
  static Widget portfolio(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M12 8v4l3 3"/></svg>',
        size, color);
  static Widget connections(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="3"/><path d="M12 9V3M12 21v-6M15 12h6M3 12h6"/></svg>',
        size, color);
  static Widget risk(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 2l9 7-9 13-9-13 9-7z"/><path d="M12 10v2M12 15v1"/></svg>',
        size, color);
  static Widget settings(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/></svg>',
        size, color);
  static Widget info(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8v1"/></svg>',
        size, color);
  static Widget core(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 4a8 8 0 100 16 8 8 0 000-16z"/><path d="M12 9v3l2 2"/><circle cx="12" cy="12" r="7"/></svg>',
        size, color);
  static Widget send(double size) => _svg(
        '<svg viewBox="0 0 24 24"><path d="M22 2L11 13M22 2L15 22l-4-9-9-4 20-7z"/></svg>',
        size, const Color(0xFFFFFFFF));
  static Widget plus(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>',
        size, color);
  static Widget arrowRight(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14M12 5l7 7-7 7"/></svg>',
        size, color);
  static Widget close(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>',
        size, color);
  static Widget user(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>',
        size, color);
  static Widget mail(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M22 7l-10 6L2 7"/></svg>',
        size, color);
  static Widget upload(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M12 12V3M7 8l5-5 5 5"/></svg>',
        size, color);
  static Widget camera(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"/><circle cx="12" cy="13" r="4"/></svg>',
        size, color);
  static Widget file(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M13 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V9l-7-7z"/><path d="M13 2v7h7"/></svg>',
        size, color);
  static Widget moon(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"/></svg>',
        size, color);
  static Widget sun(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></svg>',
        size, color);
  static Widget logout(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/></svg>',
        size, color);
  static Widget login(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 3h4a2 2 0 012 2v14a2 2 0 01-2 2h-4M10 17l5-5-5-5M15 12H3"/></svg>',
        size, color);
  static Widget star(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3 6 6 .5-4.5 4.5L18 20l-6-3.5L6 20l1.5-7.5L3 8.5 9 8l3-6z"/></svg>',
        size, color);
  static Widget check(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4"/><circle cx="12" cy="12" r="9"/></svg>',
        size, color);
  static Widget lock(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>',
        size, color);
  static Widget buy(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 19V5M5 12l7-7 7 7"/></svg>',
        size, color);
  static Widget sell(double size, Color color) => _svg(
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 5v14M5 12l7 7 7-7"/></svg>',
        size, color);
  static Widget google(double size) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GooglePainter()),
      );

  static Widget _svg(String raw, double size, Color color) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SvgPainter(raw, color),
      ),
    );
  }
}

class _SvgPainter extends CustomPainter {
  final String raw;
  final Color color;
  _SvgPainter(this.raw, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = _parseSvgPath(raw, size);
    if (path != null) canvas.drawPath(path, paint);
  }

  Path? _parseSvgPath(String svg, Size size) {
    final match = RegExp(r'<path\s+d="([^"]+)"').firstMatch(svg);
    if (match == null) return null;
    return _pathFromD(match.group(1)!, size);
  }

  Path _pathFromD(String d, Size size) {
    final path = Path();
    final tokens = d.split(RegExp(r'(?=[MLCZVHmlczvh])'));
    double cx = 0, cy = 0;

    for (final t in tokens) {
      if (t.isEmpty) continue;
      final cmd = t[0];
      final nums = RegExp(r'-?\d+(?:\.\d+)?').allMatches(t.substring(1))
          .map((m) => double.parse(m.group(0)!)).toList();

      switch (cmd.toUpperCase()) {
        case 'M':
          if (nums.length >= 2) { cx = nums[0]; cy = nums[1]; path.moveTo(cx, cy); }
          break;
        case 'L':
          if (nums.length >= 2) { cx = nums[0]; cy = nums[1]; path.lineTo(cx, cy); }
          break;
        case 'H':
          cx = nums[0]; path.lineTo(cx, cy);
          break;
        case 'V':
          cy = nums[0]; path.lineTo(cx, cy);
          break;
        case 'C':
          if (nums.length >= 6) {
            path.cubicTo(nums[0], nums[1], nums[2], nums[3], nums[4], nums[5]);
            cx = nums[4]; cy = nums[5];
          }
          break;
        case 'Z':
          path.close();
          break;
      }
    }

    // Scale to fit size
    final bounds = path.getBounds();
    if (bounds.isEmpty || bounds.width <= 0 || bounds.height <= 0) return path;
    final s = (size.width / 24).clamp(0.1, 10.0);
    final matrix = Matrix4.identity()
      ..translateByVector3(Vector3(-bounds.left * s, -bounds.top * s, 0))
      ..scaleByVector3(Vector3(s, s, 1));
    return path.transform(matrix.storage);
  }

  @override
  bool shouldRepaint(covariant _SvgPainter old) => old.color != color || old.raw != raw;
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final s = size.width / 24;

    // Blue circle background
    paint.color = const Color(0xFF4285F4);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2.3, paint);

    // White "G"
    paint.color = Colors.white;
    final gPath = Path()
      ..moveTo(12.5 * s, 8.5 * s)
      ..lineTo(12.5 * s, 12 * s)
      ..lineTo(15.8 * s, 12 * s)
      ..quadraticBezierTo(15.3 * s, 14.2 * s, 13.5 * s, 15.2 * s)
      ..quadraticBezierTo(12.1 * s, 15.9 * s, 10.5 * s, 15.5 * s)
      ..quadraticBezierTo(8.8 * s, 15 * s, 7.8 * s, 13.5 * s)
      ..quadraticBezierTo(7 * s, 12.3 * s, 7 * s, 11 * s)
      ..quadraticBezierTo(7 * s, 9.7 * s, 7.8 * s, 8.5 * s)
      ..quadraticBezierTo(8.8 * s, 7 * s, 10.5 * s, 6.5 * s)
      ..quadraticBezierTo(12 * s, 6.1 * s, 13.5 * s, 6.8 * s)
      ..lineTo(15 * s, 5.3 * s)
      ..quadraticBezierTo(12.7 * s, 4 * s, 10 * s, 4.2 * s)
      ..quadraticBezierTo(7 * s, 4.5 * s, 5 * s, 7 * s)
      ..quadraticBezierTo(3.5 * s, 9 * s, 3.5 * s, 11.5 * s)
      ..quadraticBezierTo(3.5 * s, 14 * s, 5 * s, 16 * s)
      ..quadraticBezierTo(7 * s, 18.5 * s, 10 * s, 18.8 * s)
      ..quadraticBezierTo(12.5 * s, 19 * s, 14.5 * s, 17.5 * s)
      ..quadraticBezierTo(16.5 * s, 16 * s, 17 * s, 13.5 * s)
      ..lineTo(12.5 * s, 8.5 * s)
      ..close();
    canvas.drawPath(gPath, paint);
  }

  @override
  bool shouldRepaint(covariant _GooglePainter old) => false;
}
