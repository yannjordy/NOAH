import 'package:flutter/material.dart';
import '../providers/providers.dart';
import '../widgets/portfolio_widget.dart';
import '../widgets/chart_widget.dart';
import '../widgets/chat_widget.dart';
import '../widgets/pnl_widget.dart';
import '../theme/noah_theme.dart';

class WidgetsScreen extends StatelessWidget {
  final PortfolioProvider portfolio;
  final ChatProvider chat;

  const WidgetsScreen({
    super.key,
    required this.portfolio,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? NoahColors.dkBg0 : NoahColors.bg0;
    final t1 = isDark ? NoahColors.dkT1 : NoahColors.t1;

    return ListenableBuilder(
      listenable: Listenable.merge([portfolio, chat]),
      builder: (_, __) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Widgets',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: bg0.computeLuminance() > 0.5
                            ? const Color(0xFF1C1C1C)
                            : const Color(0xFFF0F0F0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tableau de bord',
                      style: TextStyle(fontSize: 10, color: t1),
                    ),
                  ],
                ),
              ),
              // Grid of widget cards
              LayoutBuilder(
                builder: (_, constraints) {
                  final isWide = constraints.maxWidth > 380;
                  if (isWide) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _WidgetWrapper(child: PortfolioWidget(data: portfolio.data))),
                            const SizedBox(width: 12),
                            Expanded(child: _WidgetWrapper(child: PnLWidget(data: portfolio.data))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _WidgetWrapper(
                                child: ChartWidget(data: portfolio.data),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _WidgetWrapper(
                                height: 220,
                                child: ChatWidget(chat: chat),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  // Narrow layout
                  return Column(
                    children: [
                      _WidgetWrapper(child: PortfolioWidget(data: portfolio.data)),
                      const SizedBox(height: 12),
                      _WidgetWrapper(child: PnLWidget(data: portfolio.data)),
                      const SizedBox(height: 12),
                      _WidgetWrapper(height: 220, child: ChartWidget(data: portfolio.data)),
                      const SizedBox(height: 12),
                      _WidgetWrapper(height: 220, child: ChatWidget(chat: chat)),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WidgetWrapper extends StatelessWidget {
  final Widget child;
  final double? height;

  const _WidgetWrapper({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, child: child);
  }
}
