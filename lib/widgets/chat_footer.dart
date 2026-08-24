import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/providers.dart';
import '../services/native_file_picker.dart';

class _FrostedButton extends StatelessWidget {
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  final Color accent;
  final bool isDark;

  const _FrostedButton({required this.size, required this.child, this.onTap, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Color.fromRGBO(255, 255, 255, 0.08)
                  : Color.fromRGBO(0, 0, 0, 0.06),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                width: 0.5,
              ),
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ChatFooter extends StatefulWidget {
  final ChatProvider chat;

  const ChatFooter({super.key, required this.chat});

  @override
  State<ChatFooter> createState() => _ChatFooterState();
}

class _ChatFooterState extends State<ChatFooter> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  bool _hasText = false;
  String? _pendingImage;
  bool _isListening = false;
  bool _voiceAvailable = false;
  String _voiceError = '';
  final _speech = SpeechToText();
  double _swipeCancelProgress = 0.0;

  late AnimationController _waveCtrl;
  late Animation<double> _waveAnim;
  late AnimationController _cancelCtrl;
  late Animation<double> _cancelSlide;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut);
    _cancelCtrl = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _cancelSlide = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _cancelCtrl, curve: Curves.easeOutCubic));
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _voiceAvailable = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() => _voiceError = e.errorMsg);
      },
      onStatus: (s) {
        if (s == 'notListening' && _isListening && mounted) {
          setState(() => _isListening = false);
          _waveCtrl.reverse();
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _speech.stop();
    _waveCtrl.dispose();
    _cancelCtrl.dispose();
    super.dispose();
  }

  void _startListening() {
    if (!_voiceAvailable) {
      setState(() => _voiceError = 'Reconnaissance vocale non disponible');
      return;
    }
    _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          _ctrl.text = _ctrl.text.isNotEmpty ? '${_ctrl.text} ${result.recognizedWords}' : result.recognizedWords;
          _hasText = true;
          _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
          if (mounted) setState(() {});
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'FR_fr',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
    setState(() {
      _isListening = true;
      _voiceError = '';
    });
    _waveCtrl.repeat();
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _waveCtrl.reverse();
  }

  void _toggleVoice() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _onSwipeUpdate(double dy) {
    if (!_isListening) return;
    setState(() {
      _swipeCancelProgress = (_swipeCancelProgress + dy.abs() / 200).clamp(0.0, 1.0);
    });
  }

  void _onSwipeEnd(double velocity) {
    if (!_isListening) return;
    if (_swipeCancelProgress > 0.5 || velocity < -200) {
      _stopListening();
    }
    setState(() => _swipeCancelProgress = 0.0);
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    if (widget.chat.isTyping) {
      widget.chat.cancelResponse();
    }
    if (_pendingImage != null) {
      widget.chat.sendMessageWithImage(text, _pendingImage!);
      _pendingImage = null;
    } else {
      widget.chat.sendMessage(text);
    }
    _ctrl.clear();
    setState(() {
      _hasText = false;
      _pendingImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bg.withValues(alpha: 0),
            bg.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 26,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    _chip(' BTC', Icons.bar_chart, accent, () => _sendQuick('Analyse BTC maintenant')),
                    _chip(' ETH', Icons.currency_bitcoin, accent, () => _sendQuick('Signal sur ETH')),
                    _chip(' Marché', Icons.language, accent, () => _sendQuick('Tendance du marché')),
                    _chip(' Risques', Icons.shield, accent, () => _sendQuick('Évaluation des risques')),
                    _chip(
                      widget.chat.tradingEnabled ? ' ON' : ' OFF',
                      widget.chat.tradingEnabled ? Icons.toggle_on : Icons.toggle_off_outlined,
                      widget.chat.tradingEnabled ? const Color(0xFF4CAF8E) : const Color(0xFF6C6C6C),
                      () => widget.chat.setTradingEnabled(!widget.chat.tradingEnabled),
                    ),
                  ],
                ),
              ),
              if (_pendingImage != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(_pendingImage!, width: 32, height: 32, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 6),
                      Text('Image prête', style: TextStyle(fontSize: 11, color: t2)),
                      const Spacer(),
                      GestureDetector(onTap: () => setState(() => _pendingImage = null), child: Icon(Icons.close, size: 14, color: t2)),
                    ],
                  ),
                ),
              if (_voiceError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_voiceError, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A))),
                ),
              if (widget.chat.tradingEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(Icons.memory, size: 10, color: const Color(0xFF4CAF8E)),
                      const SizedBox(width: 4),
                      Text('Trading IA actif', style: TextStyle(fontSize: 9, color: const Color(0xFF4CAF8E))),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _FrostedButton(
                    size: 38,
                    accent: accent,
                    isDark: isDark,
                    onTap: () => _showImportMenu(context),
                    child: Icon(Icons.upload_file, size: 16, color: _pendingImage != null ? accent : isDark ? t2.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onVerticalDragUpdate: (d) => _onSwipeUpdate(d.delta.dy),
                      onVerticalDragEnd: (d) => _onSwipeEnd(d.primaryVelocity ?? 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.only(left: 4, right: 4, top: 6, bottom: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Color.fromRGBO(30, 30, 30, 0.85)
                              : Color.fromRGBO(255, 255, 255, 0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _cancelCtrl,
                          builder: (_, __) {
                            final cancelOffset = _cancelSlide.value * -80;
                            return Transform.translate(
                              offset: Offset(0, cancelOffset),
                              child: Opacity(
                                opacity: 1.0 - _cancelSlide.value,
                                child: _buildInputRow(accent, isDark),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(Color accent, bool isDark) {
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t3 = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8);
    final showCancelHint = _swipeCancelProgress > 0.3 && _isListening;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCancelHint)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: ((_swipeCancelProgress - 0.3) / 0.7).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_upward, size: 12, color: isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A)),
                  const SizedBox(width: 4),
                  Text('Glisser vers le haut pour annuler', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A))),
                ],
              ),
            ),
          ),
        Row(
          children: [
            _FrostedButton(
              size: 30,
              accent: accent,
              isDark: isDark,
              onTap: _voiceAvailable ? _toggleVoice : null,
              child: AnimatedBuilder(
                animation: _waveAnim,
                builder: (_, __) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isListening)
                        CustomPaint(
                          size: const Size(30, 30),
                          painter: _WaveformPainter(progress: _waveAnim.value, color: accent),
                        ),
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 14,
                        color: _isListening ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _isListening
                  ? AnimatedBuilder(
                      animation: _waveAnim,
                      builder: (_, __) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final h = 6 + sin(_waveAnim.value * 2 * pi + i * 1.5) * 8 + 4;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Container(
                                width: 3,
                                height: h.clamp(4.0, 20.0),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.6 + 0.4 * sin(_waveAnim.value * 3 + i * 1.2).abs()),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    )
                  : TextField(
                      controller: _ctrl,
                      onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                      onSubmitted: (_) => _send(),
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(fontSize: 13, color: t0, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'Posez une question à NOAH...',
                        hintStyle: TextStyle(color: t3.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            ListenableBuilder(
              listenable: widget.chat,
              builder: (_, __) {
                if (widget.chat.isTyping) {
                  return _FrostedButton(
                    size: 34,
                    accent: accent,
                    isDark: isDark,
                    onTap: () => widget.chat.cancelResponse(),
                    child: Icon(
                      Icons.stop_rounded,
                      size: 16,
                      color: const Color(0xFFE07060),
                    ),
                  );
                }
                return _FrostedButton(
                  size: 34,
                  accent: accent,
                  isDark: isDark,
                  onTap: (_hasText || _pendingImage != null) ? _send : null,
                  child: Icon(
                    Icons.send,
                    size: 14,
                    color: (_hasText || _pendingImage != null) ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _sendQuick(String text) {
    if (widget.chat.isTyping) {
      widget.chat.cancelResponse();
    }
    widget.chat.sendMessage(text);
  }

  Widget _chip(String label, IconData icon, Color accent, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? Color.fromRGBO(255, 255, 255, 0.06) : Color.fromRGBO(0, 0, 0, 0.05);
    final chipBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final chipText = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.7);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(right: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: chipBorder, width: 0.5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: accent.withValues(alpha: 0.8)),
                const SizedBox(width: 3),
                Text(label, style: TextStyle(fontSize: 10, color: chipText, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Color.fromRGBO(30, 30, 30, 0.90)
                  : Color.fromRGBO(255, 255, 255, 0.90),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuItem(Icons.image, 'Photo', () { _pickImage(ctx, ImageSource.gallery); }, isDark, context),
                  _menuItem(Icons.camera_alt, 'Caméra', () { _pickImage(ctx, ImageSource.camera); }, isDark, context),
                  _menuItem(Icons.insert_drive_file, 'Fichier', () { _pickFile(ctx); }, isDark, context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C)),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext ctx, ImageSource source) async {
    Navigator.pop(ctx);
    try {
      final xfile = await ImagePicker().pickImage(source: source, maxWidth: 1024);
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        final b64 = base64Encode(bytes);
        setState(() => _pendingImage = 'data:image/jpeg;base64,$b64');
      }
    } catch (_) {}
  }

  Future<void> _pickFile(BuildContext ctx) async {
    Navigator.pop(ctx);
    try {
      final result = await pickNativeFile();
      if (result == null) return;

      // Image — send as vision
      if (result.mime.startsWith('image/')) {
        final b64 = base64Encode(result.bytes);
        widget.chat.sendImageMessage(b64);
        return;
      }

      // Text-based files — read content and send to AI
      final textMimes = ['text/', 'application/json', 'application/csv', 'application/xml'];
      final isText = textMimes.any((m) => result.mime.startsWith(m)) ||
          result.name.endsWith('.txt') || result.name.endsWith('.json') ||
          result.name.endsWith('.csv') || result.name.endsWith('.xml') ||
          result.name.endsWith('.md') || result.name.endsWith('.log') ||
          result.name.endsWith('.dart') || result.name.endsWith('.py') ||
          result.name.endsWith('.js') || result.name.endsWith('.ts');

      if (isText) {
        try {
          final text = utf8.decode(result.bytes);
          final preview = text.length > 3000 ? '${text.substring(0, 3000)}\n\n... (tronqué, ${text.length} caractères)' : text;
          widget.chat.sendMessage('📄 Contenu de ${result.name}:\n\n$preview');
        } catch (_) {
          widget.chat.sendMessage('📎 ${result.name} (${result.bytes.length} bytes) — impossible de lire le contenu');
        }
        return;
      }

      // Other files — send info
      final sizeKb = (result.bytes.length / 1024).toStringAsFixed(1);
      widget.chat.sendMessage('📎 ${result.name} ($sizeKb KB, ${result.mime})');
    } catch (_) {}
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final center = size.height / 2;
    final amp = size.height * 0.35 * (0.3 + 0.7 * progress);
    for (var i = 0; i < 3; i++) {
      final x = size.width / 2 + (i - 1) * 6;
      final h = amp * (0.5 + 0.5 * sin(progress * 2 * pi + i * 1.2));
      canvas.drawLine(Offset(x, center - h), Offset(x, center + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => old.progress != progress;
}
