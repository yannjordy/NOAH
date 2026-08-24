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

  void _onModelTap(
    BuildContext context,
    bool isDark,
    Color bg1,
    Color bg2,
    Color borderMd,
    Color accent,
    Color t0,
    Color t1,
    Color t2,
    bool hasModels,
  ) {
    if (hasModels) {
      _showModelPicker(context, isDark, bg1, bg2, borderMd, accent, t0, t1, t2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Aucun modèle connecté. Allez dans Connexions pour ajouter un modèle.',
          ),
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

  void _showModelPicker(
    BuildContext context,
    bool isDark,
    Color bg1,
    Color bg2,
    Color borderMd,
    Color accent,
    Color t0,
    Color t1,
    Color t2,
  ) {
    final models = widget.chat.connectedModels.entries.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Modèles connectés',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'PlayfairDisplay',
                color: t0,
              ),
            ),
            const SizedBox(height: 12),
            ...models.map(
              (e) => GestureDetector(
                onTap: () {
                  widget.chat.setCurrentModel(e.value);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.chat.currentModel == e.value
                        ? accent.withValues(alpha: 0.15)
                        : bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.chat.currentModel == e.value
                          ? accent.withValues(alpha: 0.3)
                          : borderMd,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: widget.chat.currentModel == e.value
                            ? accent
                            : t2,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.chat.currentModel == e.value
                                ? accent
                                : t1,
                          ),
                        ),
                      ),
                      Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'JetBrainsMono',
                          color: t2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    final accentBorder = isDark
        ? const Color(0x2EC2A878)
        : const Color(0x33B08D57);
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
                          final showWelcome =
                              widget.chat.welcomeVisible && msgs.isEmpty;

                          return Stack(
                            children: [
                              if (msgs.isNotEmpty)
                                ListView.builder(
                                  controller: _scrollCtrl,
                                  key: const ValueKey('msgList'),
                                  padding: EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    14,
                                    widget.chat.pendingTradingRequest ||
                                            widget.chat.tradingEnabled
                                        ? 180
                                        : 100,
                                  ),
                                  itemCount: msgs.length,
                                  itemBuilder: (context, i) {
                                    final m = msgs[i];
                                    return _buildMessage(
                                      context,
                                      m,
                                      isDark,
                                      bg1,
                                      bg3,
                                      border,
                                      accent,
                                      accentBg,
                                      accentBorder,
                                      t0,
                                      t2,
                                      t3,
                                    );
                                  },
                                ),
                              AnimatedOpacity(
                                opacity: showWelcome ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child:
                                    showWelcome || !widget.chat.welcomeVisible
                                    ? _buildWelcome(
                                        isDark,
                                        accent,
                                        t0,
                                        t2,
                                        showWelcome,
                                      )
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: ListenableBuilder(
                          listenable: widget.chat,
                          builder: (_, __) {
                            final models = widget.chat.connectedModels.entries
                                .toList();
                            final hasModels = models.isNotEmpty;
                            return GestureDetector(
                              onTap: () => _onModelTap(
                                context,
                                isDark,
                                bg1,
                                bg2,
                                borderMd,
                                accent,
                                t0,
                                t1,
                                t2,
                                hasModels,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: bg1.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: hasModels
                                        ? accent.withValues(alpha: 0.2)
                                        : borderMd,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      hasModels
                                          ? widget.chat.currentModel
                                          : 'Aucun modèle',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: hasModels
                                            ? accent.withValues(alpha: 0.7)
                                            : t2,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 14,
                                      color: hasModels
                                          ? accent.withValues(alpha: 0.5)
                                          : t2,
                                    ),
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
                ListenableBuilder(
                  listenable: widget.chat,
                  builder: (_, __) {
                    if (widget.chat.pendingTradingRequest) {
                      return _tradingConfirmCard(
                        isDark,
                        bg1,
                        border,
                        accent,
                        accentBg,
                        accentBorder,
                        t0,
                        t1,
                        t2,
                        green,
                        red,
                      );
                    }
                    if (widget.chat.tradingEnabled) {
                      return _tradingActiveCard(
                        isDark,
                        bg1,
                        border,
                        accent,
                        t0,
                        t1,
                        t2,
                        green,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
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

  Widget _buildWelcome(
    bool isDark,
    Color accent,
    Color t0,
    Color t2,
    bool visible,
  ) {
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
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 200,
                    color: accent,
                  ),
                ),
                Column(
                  children: [
                    Image.asset(
                      'assets/logo-remove.png',
                      height: 72,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Prêt à trader, Jordy ?",
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 22,
                        color: t0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

  Widget _tradingConfirmCard(
    bool isDark,
    Color bg1,
    Color border,
    Color accent,
    Color accentBg,
    Color accentBorder,
    Color t0,
    Color t1,
    Color t2,
    Color green,
    Color red,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.15),
              accent.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentBorder),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_graph, size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'Trading IA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'NOAH peut analyser les marchés et passer des trades en votre nom. Cette fonction est expérimentale.',
              style: TextStyle(fontSize: 11, height: 1.4, color: t1),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.chat.setTradingEnabled(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Activer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => widget.chat.cancelTradingRequest(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel, size: 16, color: t2),
                        const SizedBox(width: 6),
                        Text(
                          'Refuser',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tradingActiveCard(
    bool isDark,
    Color bg1,
    Color border,
    Color accent,
    Color t0,
    Color t1,
    Color t2,
    Color green,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              green.withValues(alpha: 0.12),
              green.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: green.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trading IA Actif',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.chat.lastTradingAction.isNotEmpty
                        ? widget.chat.lastTradingAction
                        : 'Les agents analysent les marchés en temps réel',
                    style: TextStyle(fontSize: 10, color: t2),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => widget.chat.setTradingEnabled(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFFFE0E0).withValues(alpha: 0.1)
                      : const Color(0xFFFFE0E0).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        (isDark
                                ? const Color(0xFFE07060)
                                : const Color(0xFFB8453A))
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 12,
                      color: isDark
                          ? const Color(0xFFE07060)
                          : const Color(0xFFB8453A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Désactiver',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFE07060)
                            : const Color(0xFFB8453A),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildMessage(
    BuildContext context,
    ChatMessage m,
    bool isDark,
    Color bg1,
    Color bg3,
    Color border,
    Color accent,
    Color accentBg,
    Color accentBorder,
    Color t0,
    Color t2,
    Color t3,
  ) {
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
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(30),
                ),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => _dot(i, accent.withValues(alpha: 0.6)),
                ),
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

    final fileMatch = RegExp(r'\[FILE:([^\]]+)\]').firstMatch(text);
    if (fileMatch != null) {
      final fileName = fileMatch.group(1)!;
      final codeMatch = RegExp(
        r'```.*?\n([\s\S]*?)```',
        multiLine: true,
      ).firstMatch(text);
      bodyText = text.replaceAll(RegExp(r'\[FILE:[^\]]+\]'), '').trim();
      if (codeMatch != null) {
        fileWidget = _fileCard(
          fileName,
          codeMatch.group(1)!,
          isDark,
          bg3,
          border,
          accent,
          t0,
          t2,
        );
        bodyText = '';
      }
    }

    final parsed = _parseText(bodyText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (m.imageBase64 != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              _decodeBase64(m.imageBase64!),
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (bodyText.isNotEmpty) parsed,
                      ],
                    ),
                  ),
                ),
              if (!isUser)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bg1,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.imageBase64 != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _decodeBase64(m.imageBase64!),
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Icon(
                                  Icons.broken_image,
                                  color: t3,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (fileWidget != null) fileWidget,
                        if (hasSignal) _signalBadge(signal!, accent, isDark),
                        if (bodyText.isNotEmpty) parsed,
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
            padding: EdgeInsets.only(
              top: 3,
              left: !isUser ? 44 : 0,
              right: isUser ? 44 : 0,
            ),
            child: Text(
              m.formattedTime,
              style: TextStyle(fontSize: 8, color: t3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(
    bool isNoah,
    bool isRight,
    Color accent,
    Color accentBg,
    Color accentBorder,
    Color bg3,
    Color t0,
  ) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isNoah
            ? LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)])
            : LinearGradient(colors: [bg3, bg3.withValues(alpha: 0.8)]),
        border: Border.all(
          color: isNoah ? accentBorder : bg3.withValues(alpha: 0.5),
        ),
      ),
      child: Center(
        child: isNoah
            ? Text(
                'N',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.person, size: 14, color: t0),
      ),
    );
  }

  Widget _dot(int i, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + i * 200),
        builder: (_, __, child) =>
            Opacity(opacity: 0.4 + (i == 1 ? 0.3 : 0), child: child),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _signalBadge(Signal signal, Color accent, bool isDark) {
    final isBuy = signal.type.toUpperCase().contains('BUY');
    final color = isBuy
        ? (isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E))
        : signal.type.toUpperCase().contains('SELL')
        ? (isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A))
        : accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBuy
                ? Icons.arrow_upward
                : signal.type.toUpperCase().contains('SELL')
                ? Icons.arrow_downward
                : Icons.remove,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${signal.type} ${signal.sym}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(signal.conf * 100).toInt()}%',
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'JetBrainsMono',
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileCard(
    String fileName,
    String code,
    bool isDark,
    Color bg3,
    Color border,
    Color accent,
    Color t0,
    Color t2,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F3ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFECE9E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              code.length > 500 ? '${code.substring(0, 500)}...' : code,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'JetBrainsMono',
                color: t2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseRichText(String text, Color t0, Color accent) {
    final spans = <InlineSpan>[];
    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(fontSize: 13.5, height: 1.55, color: t0),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontSize: 13.5,
            height: 1.55,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(fontSize: 13.5, height: 1.55, color: t0),
        ),
      );
    }

    return spans;
  }

  Widget _parseText(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    if (text.trim().isEmpty) return const SizedBox();

    final clean = text
        .replaceAll('**', '')
        .replaceAll('## ', '')
        .replaceAll('__', '')
        .trim();

    if (clean.isEmpty) return const SizedBox();

    return RichText(text: TextSpan(children: _parseRichText(text, t0, accent)));
  }

  Widget _parseBlocks(
    String text,
    bool isDark,
    Color bg1,
    Color bg3,
    Color border,
    Color accent,
    Color t0,
    Color t2,
    Color t3,
  ) {
    return _parseText(text);
  }
}
