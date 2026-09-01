import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/multi_llm_coordinator.dart';
import '../services/autonomous_brain.dart';

class LLMChatScreen extends StatefulWidget {
  final MultiLLMCoordinator coordinator;

  const LLMChatScreen({super.key, required this.coordinator});

  @override
  State<LLMChatScreen> createState() => _LLMChatScreenState();
}

class _LLMChatScreenState extends State<LLMChatScreen> with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  late AutonomousBrain _brain;

  @override
  void initState() {
    super.initState();
    _brain = AutonomousBrain(widget.coordinator, onAction: _handleAction);
    _messages.add({
      'role': 'assistant',
      'content': 'Salut ! Je suis NOAH. Je peux:\n• Analyser le marché\n• Gérer ton portefeuille\n• Ajuster les risques\n• Modifier les settings\n\nQue veux-tu faire ?',
    });
  }

  void _handleAction(String action, Map<String, dynamic> params) {
    // Handle autonomous actions
    switch (action) {
      case 'adjust_risk':
        _messages.add({
          'role': 'assistant',
          'content': '✅ Risque ajusté: SL ${params['stopLoss']}% | TP ${params['takeProfit']}% | Max ${params['maxPosition']}%\nRaison: ${params['reason']}',
        });
        break;
      case 'execute_trade':
        _messages.add({
          'role': 'assistant',
          'content': '✅ Trade exécuté: ${params['side']} ${params['quantity']} ${params['symbol']}\nRaison: ${params['reason']}',
        });
        break;
      case 'modify_settings':
        _messages.add({
          'role': 'assistant',
          'content': '✅ Settings modifiés: ${jsonEncode(params)}\nRaison: ${params['reason']}',
        });
        break;
    }
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _msgCtrl.clear();

    try {
      // Determine task type from message
      String taskType = 'chat';
      if (text.toLowerCase().contains('acheter') || text.toLowerCase().contains('buy')) {
        taskType = 'trading_signal';
      } else if (text.toLowerCase().contains('analyse') || text.toLowerCase().contains('analyze')) {
        taskType = 'deep_analysis';
      } else if (text.toLowerCase().contains('risque') || text.toLowerCase().contains('risk')) {
        taskType = 'risk';
      } else if (text.toLowerCase().contains('portefeuille') || text.toLowerCase().contains('portfolio')) {
        taskType = 'portfolio';
      }

      final reply = await widget.coordinator.chat(
        prompt: text,
        taskType: taskType,
        systemContext: 'Tu es NOAH, un assistant de trading intelligent. Tu peux gérer le portefeuille, ajuster les risques, et modifier les paramètres. Réponds en français. Si tu décides d\'une action (trade, risque, settings), inclut un JSON: {"action":"...","params":{...}}',
      );

      // Check if LLM wants to take action
      if (reply.contains('"action"')) {
        try {
          final jsonStart = reply.indexOf('{');
          final jsonEnd = reply.lastIndexOf('}');
          if (jsonStart >= 0 && jsonEnd >= 0) {
            final actionData = jsonDecode(reply.substring(jsonStart, jsonEnd + 1));
            if (actionData['action'] != null) {
              _brain.chat(text); // Process autonomous action
            }
          }
        } catch (_) {}
      }

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '❌ Erreur: $e'});
      });
    } finally {
      setState(() => _isTyping = false);
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0E17) : Colors.white;
    final bg2 = isDark ? const Color(0xFF141820) : const Color(0xFFF5F5F5);
    final t0 = isDark ? Colors.white : Colors.black87;
    final t1 = isDark ? Colors.white70 : Colors.black54;
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t0, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat NOAH', style: TextStyle(color: t0, fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${widget.coordinator.connectedLLMs.where((l) => l.isConnected).length} LLMs connectés',
              style: TextStyle(color: t2, fontSize: 10),
            ),
          ],
        ),
        actions: [
          // LLM status indicator
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.coordinator.connectedLLMs.any((l) => l.available)
                  ? const Color(0xFF4CAF8E).withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.coordinator.connectedLLMs.any((l) => l.available)
                        ? const Color(0xFF4CAF8E)
                        : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.coordinator.connectedLLMs.any((l) => l.available) ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: widget.coordinator.connectedLLMs.any((l) => l.available)
                        ? const Color(0xFF4CAF8E)
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Typing indicator
                  return _typingIndicator(isDark);
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser
                                ? accent.withValues(alpha: 0.15)
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : bg2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            border: Border.all(
                              color: isUser
                                  ? accent.withValues(alpha: 0.3)
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                            ),
                          ),
                          child: Text(
                            msg['content']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUser ? accent : t0,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.person, size: 16, color: accent),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                        ),
                        child: TextField(
                          controller: _msgCtrl,
                          style: TextStyle(fontSize: 14, color: t0),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Parle à NOAH...',
                            hintStyle: TextStyle(color: t2),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isTyping ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isTyping
                              ? [Colors.grey, Colors.grey]
                              : [accent, accent.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: _isTyping
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFC2A878), const Color(0xFFC2A878).withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(1),
                const SizedBox(width: 4),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(period: const Duration(milliseconds: 600)),
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFC2A878).withValues(alpha: 0.5),
          ),
        );
      },
    );
  }
}
