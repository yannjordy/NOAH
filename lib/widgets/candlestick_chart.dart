import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/noah_theme.dart';
import '../utils.dart';

enum AnnotationType { trendLine, horizontal, ray, text }

class ChartAnnotation {
  final String id;
  final AnnotationType type;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final Color color;
  final String? label;

  const ChartAnnotation({
    required this.id,
    required this.type,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.color,
    this.label,
  });
}

class CandlestickChart extends StatelessWidget {
  final List<Kline> data;
  final bool isDark;
  final List<ChartAnnotation> annotations;
  final ValueChanged<List<ChartAnnotation>>? onAnnotationsChanged;
  final void Function(String text, String? imageBase64)? onShareToChat;
  final VoidCallback? navigateToChat;

  const CandlestickChart({
    super.key,
    required this.data,
    required this.isDark,
    this.annotations = const [],
    this.onAnnotationsChanged,
    this.onShareToChat,
    this.navigateToChat,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartBody(
      data: data,
      isDark: isDark,
      annotations: annotations,
      onAnnotationsChanged: onAnnotationsChanged,
      onShareToChat: onShareToChat,
      navigateToChat: navigateToChat,
    );
  }
}

class _ChartBody extends StatefulWidget {
  final List<Kline> data;
  final bool isDark;
  final List<ChartAnnotation> annotations;
  final ValueChanged<List<ChartAnnotation>>? onAnnotationsChanged;
  final void Function(String text, String? imageBase64)? onShareToChat;
  final VoidCallback? navigateToChat;

  const _ChartBody({
    required this.data,
    required this.isDark,
    required this.annotations,
    this.onAnnotationsChanged,
    this.onShareToChat,
    this.navigateToChat,
  });

  @override
  State<_ChartBody> createState() => _ChartBodyState();
}

class _ChartBodyState extends State<_ChartBody> {
  double _miniScale = 1.0;
  double _miniOffsetX = 0.0;
  double _baseScale = 1.0;
  bool _wasDrag = false;

  void _openFullscreen() {
    Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => _FullscreenChart(
        data: widget.data,
        isDark: widget.isDark,
        annotations: List.from(widget.annotations),
        onAnnotationsChanged: widget.onAnnotationsChanged,
        onShareToChat: widget.onShareToChat,
        navigateToChat: widget.navigateToChat,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (_) => _openFullscreen(),
      onScaleStart: (d) {
        _baseScale = _miniScale;
        _wasDrag = false;
      },
      onScaleUpdate: (d) {
        if (d.pointerCount >= 2) {
          setState(() {
            _miniScale = (_baseScale * d.scale).clamp(1.0, 5.0);
            _miniOffsetX += d.focalPointDelta.dx;
            _wasDrag = true;
          });
        } else if (d.pointerCount == 1) {
          final dx = d.focalPointDelta.dx;
          if (dx.abs() > 1) {
            setState(() {
              _miniOffsetX += dx;
              _wasDrag = true;
            });
          }
        }
      },
      onScaleEnd: (_) {
        if (!_wasDrag) _openFullscreen();
      },
      child: ClipRect(
        child: SizedBox(
          height: 200,
          child: CustomPaint(
            size: Size.infinite,
            painter: _CandlestickPainter(
              data: widget.data,
              isDark: widget.isDark,
              scale: _miniScale,
              offsetX: _miniOffsetX,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Fullscreen chart page with drawing tools
// ────────────────────────────────────────────────────────────
class _FullscreenChart extends StatefulWidget {
  final List<Kline> data;
  final bool isDark;
  final List<ChartAnnotation> annotations;
  final ValueChanged<List<ChartAnnotation>>? onAnnotationsChanged;
  final void Function(String text, String? imageBase64)? onShareToChat;
  final VoidCallback? navigateToChat;

  const _FullscreenChart({
    required this.data,
    required this.isDark,
    required this.annotations,
    this.onAnnotationsChanged,
    this.onShareToChat,
    this.navigateToChat,
  });

  @override
  State<_FullscreenChart> createState() => _FullscreenChartState();
}

class _FullscreenChartState extends State<_FullscreenChart> {
  late List<ChartAnnotation> _annotations;
  AnnotationType _drawMode = AnnotationType.trendLine;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _drawing = false;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _baseScale = 1.0;
  final _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _annotations = widget.annotations;
  }

  void _addAnnotation(double x1, double y1, double x2, double y2) {
    final a = ChartAnnotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _drawMode,
      x1: x1, y1: y1, x2: x2, y2: y2,
      color: NoahTheme.s.accent,
    );
    setState(() => _annotations.add(a));
    widget.onAnnotationsChanged?.call(_annotations);
  }

  Offset _screenToData(Offset screen, Size size, List<Kline> data) {
    if (data.isEmpty) return Offset.zero;
    final sorted = List<Kline>.from(data)..sort((a, b) => a.openTime.compareTo(b.openTime));
    final mn = sorted.map((k) => k.low).reduce(math.min);
    final mx = sorted.map((k) => k.high).reduce(math.max);
    final rng = (mx - mn).clamp(0.0001, double.infinity);
    final n = sorted.length;
    const padL = 50.0, padR = 14.0, padT = 14.0, padB = 24.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;
    final zoomedW = chartW * _scale;
    final zoomedH = chartH * _scale;
    final dx = padL + _offset.dx + chartW / 2 - zoomedW / 2;
    final dy = padT + _offset.dy + chartH / 2 - zoomedH / 2;
    final nx = (screen.dx - dx) / zoomedW;
    final ny = (screen.dy - dy) / zoomedH;
    return Offset(nx * (n - 1), mx - ny * rng);
  }

  void _undo() {
    if (_annotations.isEmpty) return;
    setState(() => _annotations.removeLast());
    widget.onAnnotationsChanged?.call(_annotations);
  }

  void _clearAll() {
    setState(() => _annotations.clear());
    widget.onAnnotationsChanged?.call(_annotations);
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Future<void> _shareToChat() async {
    // Capture chart screenshot
    String? imageBase64;
    try {
      final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final uint8List = byteData.buffer.asUint8List();
          imageBase64 = base64Encode(uint8List);
        }
      }
    } catch (_) {}

    final text = StringBuffer('📊 **Analyse du graphique**');
    if (_annotations.isNotEmpty) {
      text.writeln('\n\n**Annotations:**');
      for (final a in _annotations) {
        final type = a.type == AnnotationType.trendLine ? 'Trend line' : a.type == AnnotationType.horizontal ? 'Horizontal' : a.type == AnnotationType.ray ? 'Ray' : 'Text';
        text.writeln('- $type');
      }
    }

    widget.onShareToChat?.call(text.toString(), imageBase64);
    widget.navigateToChat?.call();
    Navigator.of(context).pop();
  }

  void _shareExternal() {
    final txt = StringBuffer('📊 Crypto Chart Analysis\n');
    txt.writeln('Data points: ${widget.data.length}');
    txt.writeln('Annotations: ${_annotations.length}');
    for (final a in _annotations) {
      final type = a.type == AnnotationType.trendLine ? 'Trend' : a.type == AnnotationType.horizontal ? 'Horizontal' : a.type == AnnotationType.ray ? 'Ray' : 'Note';
      txt.writeln('$type: (${a.x1.toStringAsFixed(1)}, ${a.y1.toStringAsFixed(1)}) → (${a.x2.toStringAsFixed(1)}, ${a.y2.toStringAsFixed(1)})');
    }
    try {
      Clipboard.setData(ClipboardData(text: txt.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyse copiée dans le presse-papier'), duration: Duration(seconds: 2)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    final toolModes = [
      (AnnotationType.trendLine, 'Ligne', Icons.show_chart),
      (AnnotationType.horizontal, 'Horizontal', Icons.horizontal_rule),
      (AnnotationType.ray, 'Tir', Icons.trending_up),
      (AnnotationType.text, 'Texte', Icons.text_fields),
    ];

    return Scaffold(
      backgroundColor: bg0,
      appBar: AppBar(
        backgroundColor: bg0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: t1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Graphique', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t1)),
        actions: [
          IconButton(icon: Icon(Icons.undo, color: accent, size: 20), onPressed: _undo, tooltip: 'Annuler'),
          IconButton(icon: Icon(Icons.clear_all, color: accent, size: 20), onPressed: _clearAll, tooltip: 'Tout effacer'),
          IconButton(icon: Icon(Icons.share, color: accent, size: 20), onPressed: _shareExternal, tooltip: 'Copier analyse'),
        ],
      ),
      body: Column(
        children: [
          // Drawing tool selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                ...toolModes.map((m) {
                  final active = _drawMode == m.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _drawMode = m.$1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? accent.withOpacity( 0.15) : bg2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: active ? accent.withOpacity( 0.4) : borderMd),
                      ),
                      child: Row(
                        children: [
                          Icon(m.$3, size: 14, color: active ? accent : t2),
                          const SizedBox(width: 4),
                          Text(m.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? accent : t2)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Chart area
          Expanded(
            child: GestureDetector(
              onScaleStart: (d) {
                _baseScale = _scale;
                if (d.pointerCount == 1) {
                  setState(() {
                    _dragStart = d.localFocalPoint;
                    _dragCurrent = d.localFocalPoint;
                    _drawing = true;
                  });
                }
              },
              onScaleUpdate: (d) {
                if (d.pointerCount >= 2) {
                  setState(() {
                    _scale = (_baseScale * d.scale).clamp(1.0, 10.0);
                    _offset += d.focalPointDelta;
                  });
                } else if (_drawing) {
                  setState(() => _dragCurrent = d.localFocalPoint);
                }
              },
              onScaleEnd: (_) {
                if (_drawing && _dragStart != null && _dragCurrent != null) {
                  final ctx = context;
                  final size = (ctx.findRenderObject() as RenderBox?)?.size ?? Size.zero;
                  final start = _screenToData(_dragStart!, size, widget.data);
                  final current = _screenToData(_dragCurrent!, size, widget.data);
                  _addAnnotation(start.dx, start.dy, current.dx, current.dy);
                }
                setState(() {
                  _dragStart = null;
                  _dragCurrent = null;
                  _drawing = false;
                });
              },
              child: RepaintBoundary(
                key: _chartKey,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FullscreenPainter(
                    data: widget.data,
                    isDark: isDark,
                    annotations: _annotations,
                    dragStart: _dragStart,
                    dragCurrent: _dragCurrent,
                    scale: _scale,
                    offset: _offset,
                  ),
                ),
              ),
            ),
          ),
          // Bottom bar: zoom + share
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: bg2.withOpacity( 0.9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Zoom -
                GestureDetector(
                  onTap: () => setState(() => _scale = (_scale / 1.3).clamp(1.0, 10.0)),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bg2,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderMd),
                    ),
                    child: Icon(Icons.remove, size: 20, color: t1),
                  ),
                ),
                if (_scale > 1.01 || _offset != Offset.zero) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _resetZoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text('${(_scale * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Zoom +
                GestureDetector(
                  onTap: () => setState(() => _scale = (_scale * 1.3).clamp(1.0, 10.0)),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bg2,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderMd),
                    ),
                    child: Icon(Icons.add, size: 20, color: t1),
                  ),
                ),
                const SizedBox(width: 14),
                // Share to chat button
                GestureDetector(
                  onTap: _shareToChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text('Chat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Painters
// ────────────────────────────────────────────────────────────
class _CandlestickPainter extends CustomPainter {
  final List<Kline> data;
  final bool isDark;
  final double scale;
  final double offsetX;

  _CandlestickPainter({required this.data, required this.isDark, this.scale = 1.0, this.offsetX = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    _paintCandles(canvas, size, data, isDark, null, null, null, scale, Offset(offsetX, 0));
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter old) =>
      old.data != data || old.scale != scale || old.offsetX != offsetX;
}

class _FullscreenPainter extends CustomPainter {
  final List<Kline> data;
  final bool isDark;
  final List<ChartAnnotation> annotations;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final double scale;
  final Offset offset;

  _FullscreenPainter({
    required this.data,
    required this.isDark,
    required this.annotations,
    this.dragStart,
    this.dragCurrent,
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintCandles(canvas, size, data, isDark, annotations, dragStart, dragCurrent, scale, offset);
  }

  @override
  bool shouldRepaint(covariant _FullscreenPainter old) =>
      old.data != data || old.annotations != annotations || old.dragStart != dragStart || old.dragCurrent != dragCurrent || old.scale != scale || old.offset != offset;
}

void _paintCandles(Canvas canvas, Size size, List<Kline> data, bool isDark,
    List<ChartAnnotation>? annotations, Offset? dragStart, Offset? dragCurrent,
    [double scale = 1.0, Offset offset = Offset.zero]) {
  if (data.isEmpty) return;

  final sorted = List<Kline>.from(data)..sort((a, b) => a.openTime.compareTo(b.openTime));
  final mn = sorted.map((k) => k.low).reduce(math.min);
  final mx = sorted.map((k) => k.high).reduce(math.max);
  final rng = (mx - mn).clamp(0.0001, double.infinity);

  final n = sorted.length;
  const padL = 50.0;
  const padR = 14.0;
  const padT = 14.0;
  const padB = 24.0;
  final chartW = size.width - padL - padR;
  final chartH = size.height - padT - padB;
  // Zoom applies to the chart area only
  final zoomedW = chartW * scale;
  final zoomedH = chartH * scale;
  final dx = padL + offset.dx + chartW / 2 - zoomedW / 2;
  final dy = padT + offset.dy + chartH / 2 - zoomedH / 2;

  final candleW = (zoomedW / n) * 0.6;
  final halfGap = (zoomedW / n) * 0.2;

  final upColor = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
  final downColor = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);
  final gridColor = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
  final textColor = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
  final accentColor = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
  final dragColor = isDark ? const Color(0x60FFFFFF) : const Color(0x60000000);


  // Grid
  final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
  for (int i = 0; i <= 4; i++) {
    final y = dy + zoomedH * i / 4;
    canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);
  }

  // Price labels
  for (int i = 0; i <= 4; i++) {
    final val = mx - rng * i / 4;
    final tb = TextPainter(
      text: TextSpan(text: _fmt(val), style: TextStyle(fontSize: 9, color: textColor)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: padL - 4);
    tb.paint(canvas, Offset(2, dy + zoomedH * i / 4 - tb.height / 2));
  }

  // Time labels
  final timeStep = math.max(1, n ~/ 5);
  final timeLabels = <int>{};
  for (int i = 0; i < n; i += timeStep) {
    timeLabels.add(i);
  }
  timeLabels.add(0);
  timeLabels.add(n - 1);

  for (final i in timeLabels) {
    final k = sorted[i];
    final x = dx + i * zoomedW / n + halfGap;
    final dt = DateTime.fromMillisecondsSinceEpoch(k.openTime);
    final tb = TextPainter(
      text: TextSpan(
        text: '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        style: TextStyle(fontSize: 9, color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tb.paint(canvas, Offset(x - tb.width / 2, size.height - padB + 4));
  }

  // Candles
  for (int i = 0; i < n; i++) {
    final k = sorted[i];
    final x = dx + i * zoomedW / n + halfGap;
    final openY = dy + zoomedH * (1 - (k.open - mn) / rng);
    final closeY = dy + zoomedH * (1 - (k.close - mn) / rng);
    final highY = dy + zoomedH * (1 - (k.high - mn) / rng);
    final lowY = dy + zoomedH * (1 - (k.low - mn) / rng);
    final isUp = k.isUp;
    final color = isUp ? upColor : downColor;

    final wickPaint = Paint()..color = color..strokeWidth = 1;
    canvas.drawLine(Offset(x + candleW / 2, highY), Offset(x + candleW / 2, lowY), wickPaint);

    final bodyTop = math.min(openY, closeY);
    final bodyBot = math.max(openY, closeY);
    final bodyH = math.max(bodyBot - bodyTop, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, bodyTop, candleW, bodyH), const Radius.circular(1)),
      Paint()..color = color,
    );
  }

  // Annotations use data coordinates (candle index + price)
  if (annotations != null) {
    for (final a in annotations) {
      final c = Paint()..color = a.color..strokeWidth = 1.5..style = PaintingStyle.stroke;
      final nx1 = n > 1 ? a.x1 / (n - 1) : 0.0;
      final nx2 = n > 1 ? a.x2 / (n - 1) : 0.0;
      final ny1 = (mx - a.y1) / rng;
      final ny2 = (mx - a.y2) / rng;
      final x1 = dx + nx1 * zoomedW;
      final y1 = dy + ny1 * zoomedH;
      final x2 = dx + nx2 * zoomedW;
      final y2 = dy + ny2 * zoomedH;

      switch (a.type) {
        case AnnotationType.trendLine:
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), c);
          break;
        case AnnotationType.horizontal:
          canvas.drawLine(Offset(dx, y1), Offset(dx + zoomedW, y1), c);
          break;
        case AnnotationType.ray:
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), c);
          final angle = math.atan2(y2 - y1, x2 - x1);
          final arrowSize = 8.0;
          canvas.drawLine(Offset(x2, y2), Offset(x2 - arrowSize * math.cos(angle - 0.5), y2 - arrowSize * math.sin(angle - 0.5)), c);
          canvas.drawLine(Offset(x2, y2), Offset(x2 - arrowSize * math.cos(angle + 0.5), y2 - arrowSize * math.sin(angle + 0.5)), c);
          break;
        case AnnotationType.text:
          if (a.label != null) {
            final tb = TextPainter(
              text: TextSpan(text: a.label, style: TextStyle(fontSize: 11, color: a.color, fontWeight: FontWeight.w600)),
              textDirection: TextDirection.ltr,
            )..layout();
            tb.paint(canvas, Offset(x1, y1));
          }
          break;
      }
    }
  }

  // Drag preview
  if (dragStart != null && dragCurrent != null) {
    final dp = Paint()..color = dragColor..strokeWidth = 1.5;
    canvas.drawLine(dragStart, dragCurrent, dp);
    canvas.drawCircle(dragStart, 3, Paint()..color = accentColor);
    canvas.drawCircle(dragCurrent, 3, Paint()..color = accentColor);
  }
}

String _fmt(double v) {
  if (v >= 1000) return v.toStringAsFixed(0);
  if (v >= 1) return v.toStringAsFixed(2);
  return v.toStringAsFixed(4);
}
