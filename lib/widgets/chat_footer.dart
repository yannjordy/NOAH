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
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF2A2A2A).withValues(alpha: 0.85),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF3A3A3A).withValues(alpha: 0.3)),
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
              