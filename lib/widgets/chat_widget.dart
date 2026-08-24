import 'package:flutter/material.dart';
import '../providers/providers.dart';
import 'widget_card.dart';

class ChatWidget extends StatelessWidget {
  final ChatProvider chat;

  const ChatWidget({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);

    final recent = chat.messages.reversed.take(3).toList();

    return WidgetCard(
      title: 'Chat',
      subtitle: 'Derniers messages',
      icon: Icons.chat_bubble_outline,
      iconColor: green,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chat.tradingEnabled ? green : t2,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            chat.tradingEnabled ? 'Actif' : 'Veille',
            style: TextStyle(fontSize: 8, color: chat.tradingEnabled ? green : t2, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      child: recent.isEmpty
          ? Center(
              child: Text(
                'Aucun message',
                style: TextStyle(fontSize: 11, color: t2),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final msg = recent[i];
                final isUser = msg.role == 'user';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFC2A878).withValues(alpha: 0.08) : bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: !isUser ? Border.all(color: border) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUser ? Icons.person_outline : Icons.auto_awesome,
                        size: 12,
                        color: isUser ? const Color(0xFFC2A878) : t2,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          msg.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? t0 : t2,
                            fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (msg.signal != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: msg.signal!.type == 'BUY'
                                ? green.withValues(alpha: 0.15)
                                : msg.signal!.type == 'SELL'
                                    ? const Color(0xFFE07060).withValues(alpha: 0.15)
                                    : t2.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            msg.signal!.type,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              color: msg.signal!.type == 'BUY'
                                  ? green
                                  : msg.signal!.type == 'SELL'
                                      ? const Color(0xFFE07060)
                                      : t2,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
