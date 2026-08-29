import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/chat_footer.dart';

class ChatScreen extends StatefulWidget {
  final ChatProvider chat;
  final VoidCallback? navigateToConnections;

  const ChatScreen({super.key, required this.chat, this.navigateToConnections});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.chat.addListener(_onChatChanged);
  }

  @override
  void dispose() {
    widget.chat.removeListener(_onChatChanged);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onModelTap(BuildContext context, bool isDark, Color bg1, Color bg2, Color borderMd, Color accent, Color t0, Color t1, Color t2, bool hasModels) {
    if (hasModels) {
      _showModelPicker(context, isDark, bg1, bg2, borderMd, accent, t0, t1, t2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucun modèle connecté. Allez dans Connexions pour ajouter un modèle.'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Connexions',
            textColor: accent,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              widget.navigateToConnections?.call();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final bg3 = isDark ? const Color(0xFF323232) : const Color(0xFFE8E3D8);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final accentBg = isDark ? const Color(0x1AC2A878) : const Color(0x1AB08D57);
    final accentBorder = isDark ? const Color(0x2EC2A878) : const Color(0x33B08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final t3 = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);

    return Container(
      color: bg0,
      child: Stack(
        children: [
          // Messages list fills entire area
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ListenableBuilder(
                        listenable: widget.chat,
                        builder: (context, _) {
                          final msgs = widget.chat.messages;
                          final showWelcome = widget.chat.welcomeVisible && msgs.isEmpty;

                          return Stack(
                            children: [
                              if (msgs.isNotEmpty)
                                ListView.builder(
                                  controller: _scrollCtrl,
                                  key: const ValueKey('msgList'),
                                  padding: EdgeInsets.fromLTRB(14, 14, 14, widget.chat.pendingTradingRequest || widget.chat.tradingEnabled ? 180 : 100),
                                  itemCount: msgs.length,
                                  itemBuilder: (context, i) {
                                    final m = msgs[i];
                                    return _buildMessage(context, m, isDark, bg1, bg3, border, accent, accentBg, accentBorder, t0, t2, t3);
                                  },
                                ),
                              AnimatedOpacity(
                                opacity: showWelcome ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: showWelcome || !widget.chat.welcomeVisible
                                    ? _buildWelcome(isDark, accent, t0, t2, showWelcome)
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
                      // Model selector bar at top
                      Positioned(
                        top: 4,
                        right: 14,
                        child: ListenableBuilder(
                          listenable: widget.chat,
                          builder: (_, __) {
                            final models = widget.chat.connectedModels.entries.toList();
                            final hasModels = models.isNotEmpty;
                            return GestureDetector(
                              onTap: () => _onModelTap(context, isDark, bg1, bg2, borderMd, accent, t0, t1, t2, hasModels),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: bg1.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: hasModels ? accent.withValues(alpha: 0.2) : borderMd),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      hasModels ? widget.chat.currentModel : 'Aucun modèle',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: hasModels ? accent.withValues(alpha: 0.7) : t2),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(Icons.arrow_drop_down, size: 14, color: hasModels ? accent.withValues(alpha: 0.5) : t2),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer overlays at bottom with blur
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ChatFooter(chat: widget.chat),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(bool isDark, Color accent, Color t0, Color t2, bool visible) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.06,
                  child: Icon(Icons.chat_bubble_outline, size: 200, color: accent),
                ),
                Column(
                  children: [
                    Image.asset('assets/logo-remove.png', height: 72, errorBuilder: (_, __, ___) => const SizedBox()),
                    const SizedBox(height: 16),
                    Text("Prêt à trader, Jordy ?",
                        style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 22, color: t0, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 260,
                      child: Text(
                        'NOAH analyse les marchés 24/7 pour vous',
                        style: TextStyle(fontSize: 13, color: t2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Uint8List _decodeBase64(String data) {
    final raw = data.contains(',') ? data.split(',').last : data;
    return base64Decode(raw);
  }

  Widget _buildMessage(BuildContext context,
      ChatMessage m, bool isDark, Color bg1, Color bg3, Color border, Color accent, Color accentBg, Color accentBorder, Color t0, Color t2, Color t3) {
    final isUser = m.role == 'user';
    final isNoah = m.role == 'noah';

    if (m.isTyping) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            _avatar(isNoah, false, accent, accentBg, accentBorder, bg3, t0),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bg1,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(4), bottomRight: Radius.circular(30),
                ),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => _dot(i, accent.withValues(alpha: 0.6))),
              ),
            ),
          ],
        ),
      );
    }

    final text = m.text;
    String bodyText = text;
    Widget? fileWidget;
    final signal = m.signal;
    final hasSignal = signal != null && signal.sym.isNotEmpty;

    // Parse file card if present
    final fileMatch = RegExp(r'\[FILE:([^\]]+)\]').firstMatch(text);
    if (fileMatch != null) {
      final fileName = fileMatch.group(1)!;
      final codeMatch = RegExp(r'```.*?\n([\s\S]*?)```', multiLine: true).firstMatch(text);
      bodyText = text.replaceAll(RegExp(r'\[FILE:[^\]]+\]'), '').trim();
      if (codeMatch != null) {
        fileWidget = _fileCard(fileName, codeMatch.group(1)!, isDark, bg3, border, accent, t0, t2);
        bodyText = '';
      }
    }

    final parsed = _parseText(bodyText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _avatar(true, false, accent, accentBg, accentBorder, bg3, t0),
                const SizedBox(width: 8),
              ],
              if (isUser)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parsed.isNotEmpty)
                          Text(
                            parsed,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.55,
                              color: Colors.white,
                            ),
                          ),
                        if (m.imageBase64 != null) ...[
                          if (parsed.isNotEmpty) const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _showImagePreview(context, m.imageBase64!, isDark),
                            behavior: HitTestBehavior.opaque,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_decodeBase64(m.imageBase64!), width: 200, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (!isUser)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.blocks.isNotEmpty)
                          ...m.blocks.map((block) => renderBlock(block, isDark, onTap: () {
                            if (widget.chat.tradingEnabled) {
                              widget.chat.setTradingEnabled(false);
                            } else {
                              widget.chat.setTradingEnabled(true);
                            }
                          })),
                        if (parsed.isNotEmpty) ...[
                          if (m.blocks.isNotEmpty) const SizedBox(height: 10),
                          SelectableText.rich(
                            TextSpan(children: _buildMarkdownSpans(parsed, t0, t2, accent)),
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.55,
                              color: t0,
                            ),
                          ),
                        ],
                        if (fileWidget != null) ...[
                          if (parsed.isNotEmpty) const SizedBox(height: 6),
                          fileWidget,
                        ],
                        if (m.imageBase64 != null) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _showImagePreview(context, m.imageBase64!, isDark),
                            behavior: HitTestBehavior.opaque,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_decodeBase64(m.imageBase64!), width: 200, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                        if (hasSignal) _signalCard(m.signal!, isDark),
                      ],
                    ),
                  ),
                ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _avatar(false, true, accent, accentBg, accentBorder, bg3, t0),
              ],
            ],

          ),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 36, right: isUser ? 36 : 0, top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.formattedTime, style: TextStyle(fontSize: 10, color: t2)),
                if (isNoah && !m.isTyping) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyMessage(context, m),
                    child: Icon(Icons.copy_rounded, size: 12, color: t3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context, ChatMessage m) async {
    String content;
    if (m.blocks.isNotEmpty) {
      content = m.blocks
          .where((b) => b.type == BlockType.text)
          .map((b) => (b.data['text'] as String?) ?? '')
          .join('\n');
    } else {
      content = m.text;
    }
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copié'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
      );
    }
  }

  String _parseText(String text) {
    return text
        .replaceAll(RegExp(r'SIGNAL\s*:\s*(BUY|SELL|HOLD)\|[\w]+\|[\d.]+'), '');
  }

  List<TextSpan> _buildMarkdownSpans(String text, Color t0, Color t2, Color accent) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) spans.add(const TextSpan(text: '\n'));

      // Code block
      if (line.startsWith('```')) {
        continue; // skip fence lines
      }
      // Inline code
      if (line.contains('`') && !line.startsWith('```')) {
        final parts = line.split('`');
        for (var j = 0; j < parts.length; j++) {
          if (j % 2 == 0) {
            spans.addAll(_parseInlineMarkdown(parts[j], t0, t2, accent));
          } else {
            spans.add(TextSpan(text: parts[j], style: TextStyle(
              fontFamily: 'JetBrainsMono', fontSize: 12, color: accent,
              backgroundColor: t2.withValues(alpha: 0.15),
            )));
          }
        }
        continue;
      }
      // List items
      if (line.startsWith(RegExp(r'^[\s]*[-*•]\s'))) {
        final content = line.replaceFirst(RegExp(r'^[\s]*[-*•]\s'), '');
        spans.add(TextSpan(text: '• ', style: TextStyle(color: accent, fontWeight: FontWeight.w700)));
        spans.addAll(_parseInlineMarkdown(content, t0, t2, accent));
        continue;
      }
      // Numbered list
      final numMatch = RegExp(r'^(\d+[\.\)]\s)').firstMatch(line);
      if (numMatch != null) {
        final content = line.substring(numMatch.end);
        spans.add(TextSpan(text: '${numMatch.group(1)}', style: TextStyle(color: accent, fontWeight: FontWeight.w700)));
        spans.addAll(_parseInlineMarkdown(content, t0, t2, accent));
        continue;
      }
      // Headers
      if (line.startsWith('### ')) {
        spans.add(TextSpan(text: line.substring(4), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t0)));
        continue;
      }
      if (line.startsWith('## ')) {
        spans.add(TextSpan(text: line.substring(3), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t0)));
        continue;
      }
      if (line.startsWith('# ')) {
        spans.add(TextSpan(text: line.substring(2), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: t0)));
        continue;
      }
      // Default line
      spans.addAll(_parseInlineMarkdown(line, t0, t2, accent));
    }
    return spans;
  }

  List<TextSpan> _parseInlineMarkdown(String text, Color t0, Color t2, Color accent) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*(.+?)\*\*)|(_(.+?)_)|(\*(.+?)\*)');
    var lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      if (match.group(2) != null) {
        // **bold**
        spans.add(TextSpan(text: match.group(2), style: TextStyle(fontWeight: FontWeight.w700, color: t0)));
      } else if (match.group(4) != null) {
        // _italic_
        spans.add(TextSpan(text: match.group(4), style: TextStyle(fontStyle: FontStyle.italic, color: t0)));
      } else if (match.group(6) != null) {
        // *italic*
        spans.add(TextSpan(text: match.group(6), style: TextStyle(fontStyle: FontStyle.italic, color: t0)));
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  Widget _avatar(bool isNoah, bool isUser, Color accent, Color accentBg, Color accentBorder, Color bg3, Color t0) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNoah ? accentBg : bg3,
        border: isNoah ? Border.all(color: accentBorder) : null,
      ),
      child: Center(
        child: isNoah
            ? Image.asset('assets/logo-remove.png', width: 20, height: 20, errorBuilder: (_, __, ___) => const SizedBox())
            : Icon(Icons.person, size: 14, color: t0),
      ),
    );
  }

  Widget _dot(int i, Color t3) {
    return Container(
      width: 5, height: 5, margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
      decoration: BoxDecoration(color: t3, shape: BoxShape.circle),
    );
  }

  Widget _signalCard(Signal signal, bool isDark) {
    final sc = signal.type == 'BUY'
        ? (isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E))
        : signal.type == 'SELL'
            ? (isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A))
            : (isDark ? const Color(0xFFD4A84B) : const Color(0xFFA67C2E));
    final sBg = signal.type == 'BUY'
        ? (isDark ? const Color(0x144CAF8E) : const Color(0x142E7D5E))
        : signal.type == 'SELL'
            ? (isDark ? const Color(0x14E07060) : const Color(0x14B8453A))
            : (isDark ? const Color(0x14D4A84B) : const Color(0x14A67C2E));
    final sBorder = signal.type == 'BUY'
        ? (isDark ? const Color(0x2E4CAF8E) : const Color(0x2E2E7D5E))
        : signal.type == 'SELL'
            ? (isDark ? const Color(0x2EE07060) : const Color(0x2EB8453A))
            : (isDark ? const Color(0x2ED4A84B) : const Color(0x2EA67C2E));

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                signal.type == 'BUY' ? Icons.arrow_upward : signal.type == 'SELL' ? Icons.arrow_downward : Icons.remove,
                size: 14,
                color: sc,
              ),
              const SizedBox(width: 4),
              Text(signal.type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: sc, letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${signal.sym}/USDT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C))),
          const SizedBox(height: 4),
          Text('${(signal.conf * 100).toInt()}% confiance',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
          const SizedBox(height: 4),
          Container(
            height: 3,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF323232) : const Color(0xFFE8E3D8), borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: signal.conf,
              child: Container(decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(2))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileCard(String fileName, String? content, bool isDark, Color bg3, Color border, Color accent, Color t0, Color t2, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x14FFFFFF) : const Color(0x14000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(content == null ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(fileName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 10, color: t2)),
          ],
          if (content != null) ...[
            const SizedBox(height: 6),
            Text(
              (() {
                final lines = content.split('\n');
                return lines.length > 15 ? [...lines.sublist(0, 15), '...'].join('\n') : content;
              })(),
              style: TextStyle(fontSize: 11, height: 1.4, color: t2, fontFamily: 'JetBrains Mono'),
            ),
          ],
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageBase64, bool isDark) {
    showDialog(
      context: context,
      barrierColor: (isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE)).withValues(alpha: 0.95),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_decodeBase64(imageBase64), fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 18, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context, bool isDark, Color bg1, Color bg2, Color borderMd, Color accent, Color t0, Color t1, Color t2) {
    final models = widget.chat.connectedModels.entries.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Changer de modèle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t0)),
              const SizedBox(height: 4),
              Text('Sélectionnez un modèle connecté', style: TextStyle(fontSize: 11, color: t2)),
              const SizedBox(height: 10),
              ...models.map((entry) {
                final isActive = entry.value == widget.chat.currentModel;
                return GestureDetector(
                  onTap: () {
                    widget.chat.setCurrentModel(entry.value);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? accent.withValues(alpha: 0.12) : bg2,
                      borderRadius: BorderRadius.circular(16),
                      border: isActive ? Border.all(color: accent.withValues(alpha: 0.3)) : Border.all(color: borderMd),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(entry.value, style: TextStyle(fontSize: 12, color: t0, fontWeight: FontWeight.w500)),
                        ),
                        if (isActive)
                          Icon(Icons.check_circle, size: 16, color: accent),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
