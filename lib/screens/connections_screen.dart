import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/providers.dart';
import '../theme/noah_theme.dart';

const _incompatibleApis = {
  'Anthropic Claude',
  'Google Gemini',
  'Meta LLaMA',
  'Replicate',
};

class ConnectionsScreen extends StatefulWidget {
  final AuthProvider auth;
  final ChatProvider chat;
  final void Function(int) openLogin;

  const ConnectionsScreen({
    super.key,
    required this.auth,
    required this.chat,
    required this.openLogin,
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final Set<int> _expanded = {};
  final Map<int, TextEditingController> _apiCtrls = {};
  final Map<int, TextEditingController> _secretCtrls = {};
  final Map<int, TextEditingController> _urlCtrls = {};
  final Map<int, bool> _opencodeTesting = {};
  final Map<int, bool> _opencodeOk = {};
  final Map<int, List<String>> _opencodeModels = {};

  @override
  void dispose() {
    for (final c in _apiCtrls.values) c.dispose();
    for (final c in _secretCtrls.values) c.dispose();
    for (final c in _urlCtrls.values) c.dispose();
    super.dispose();
  }

  TextEditingController _ctrl(
    Map<int, TextEditingController> map,
    int i,
    String v,
  ) {
    return map.putIfAbsent(i, () => TextEditingController(text: v));
  }

  bool _isConnected(String provider) {
    return widget.chat.connectedModels.containsKey(provider);
  }

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  Future<void> _testOpenCode(int index) async {
    setState(() => _opencodeTesting[index] = true);
    final url = _urlCtrls[index]?.text.trim() ?? '';
    if (url.isNotEmpty) {
      widget.chat.updateOpenCodeUrl(url);
    }
    final ok = await widget.chat.testOpenCodeConnection();
    setState(() {
      _opencodeOk[index] = ok;
      _opencodeTesting[index] = false;
    });
    if (ok) {
      final models = await widget.chat.fetchOpenCodeModels();
      setState(() => _opencodeModels[index] = models);
    }
  }

  void _connectOpenCode(int index) {
    final url = _urlCtrls[index]?.text.trim() ?? '';
    final model = _opencodeModels[index]?.isNotEmpty == true
        ? _opencodeModels[index]!.first
        : 'default';
    final apiKey = _apiCtrls[index]?.text.trim() ?? '';
    if (url.isNotEmpty) widget.chat.updateOpenCodeUrl(url);
    widget.chat.connectModel('OpenCode Local', model, apiKey: apiKey);
    setState(() {});
  }

  void _disconnect(String provider) {
    widget.chat.disconnectModel(provider);
    setState(() {});
  }

  void _connectGeneric(String provider, String model) {
    final apiKey = _apiCtrls[provider.hashCode]?.text.trim() ?? '';
    widget.chat.connectModel(provider, model, apiKey: apiKey);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg0 = isDark ? const Color(0xFF121212) : const Color(0xFFF7F4EE);
    final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
    final red = isDark ? const Color(0xFFE07060) : const Color(0xFFB8453A);

    final cards = <Map<String, dynamic>>[
      {
        'name': 'OpenCode Local',
        'icon': Icons.code,
        'desc': 'Assistant IA local (OpenCode)',
        'needsApiKey': true,
        'needsUrl': true,
        'urlHint': 'http://localhost:3000',
        'apiKeyHint': 'Clé API (optionnel)',
        'model': widget.chat.connectedModels['OpenCode Local'] ?? '',
        'isOpencode': true,
      },
      {
        'name': 'OpenAI',
        'icon': Icons.auto_awesome,
        'desc': 'GPT-4o, GPT-4, GPT-3.5',
        'needsApiKey': true,
        'apiKeyHint': 'sk-...',
        'model': widget.chat.connectedModels['OpenAI'] ?? '',
        'models': ['gpt-4o', 'gpt-4', 'gpt-3.5-turbo'],
      },
      {
        'name': 'Anthropic Claude',
        'icon': Icons.psychology,
        'desc': 'Claude 3.5, Claude 3',
        'needsApiKey': true,
        'apiKeyHint': 'sk-ant-...',
        'model': widget.chat.connectedModels['Anthropic Claude'] ?? '',
        'models': ['claude-3.5-sonnet', 'claude-3-haiku'],
        'incompatible': true,
      },
      {
        'name': 'DeepSeek',
        'icon': Icons.water_drop,
        'desc': 'DeepSeek V3, DeepSeek R1',
        'needsApiKey': true,
        'apiKeyHint': 'sk-...',
        'model': widget.chat.connectedModels['DeepSeek'] ?? '',
        'models': ['deepseek-chat', 'deepseek-reasoner'],
      },
      {
        'name': 'Binance API',
        'icon': Icons.candlestick_chart,
        'desc': 'Trading réel sur Binance',
        'needsApiKey': true,
        'needsSecret': true,
        'apiKeyHint': 'Clé API Binance',
        'secretHint': 'Clé secrète',
        'model': widget.chat.connectedModels['Binance API'] ?? '',
        'isBinance': true,
      },
    ];

    return Container(
      color: bg0,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Connexions',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: t0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.chat.connectedModels.length} actives',
                    style: TextStyle(fontSize: 11, color: t2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                itemCount: cards.length,
                itemBuilder: (context, i) {
                  final card = cards[i];
                  final name = card['name'] as String;
                  final icon = card['icon'] as IconData;
                  final desc = card['desc'] as String;
                  final connected = _isConnected(name);
                  final expanded = _expanded.contains(i);

                  return GestureDetector(
                    onTap: () => _toggle(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bg1,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: connected
                              ? accent.withValues(alpha: 0.3)
                              : borderMd,
                          width: connected ? 1.5 : 1,
                        ),
                        boxShadow: connected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: connected
                                      ? accent.withValues(alpha: 0.15)
                                      : bg2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  size: 18,
                                  color: connected ? accent : t2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: t0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      connected
                                          ? 'Connecté: ${card['model']}'
                                          : desc,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: connected ? accent : t2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (connected) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: name == 'Binance API'
                                        ? (widget.chat.binanceWorking
                                              ? green
                                              : red)
                                        : green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (name == 'Binance API'
                                                    ? (widget
                                                              .chat
                                                              .binanceWorking
                                                          ? green
                                                          : red)
                                                    : green)
                                                .withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Icon(
                                expanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: t2,
                              ),
                            ],
                          ),
                          if (expanded) ...[
                            const SizedBox(height: 14),
                            if (card['isOpencode'] == true) ...[
                              _urlField(
                                i,
                                bg2,
                                border,
                                t0,
                                t1,
                                card['urlHint'] ?? '',
                                isDark,
                              ),
                              const SizedBox(height: 10),
                              _apiKeyField(
                                i,
                                bg2,
                                border,
                                t0,
                                t1,
                                card['apiKeyHint'] ?? '',
                                isDark,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _testBtn(
                                      'Tester',
                                      accent,
                                      _opencodeTesting[i] ?? false,
                                      () => _testOpenCode(i),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_opencodeOk[i] == true)
                                    Expanded(
                                      child: _connectBtn(
                                        'Connecter',
                                        accent,
                                        () => _connectOpenCode(i),
                                      ),
                                    ),
                                  if (connected)
                                    Expanded(
                                      child: _disconnectBtn(
                                        red,
                                        () => _disconnect(name),
                                      ),
                                    ),
                                ],
                              ),
                              if (_opencodeModels[i]?.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: _opencodeModels[i]!
                                      .take(5)
                                      .map(
                                        (m) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bg2,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(color: border),
                                          ),
                                          child: Text(
                                            m,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontFamily: 'JetBrainsMono',
                                              color: t1,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ] else if (card['isBinance'] == true) ...[
                              _apiKeyField(
                                i,
                                bg2,
                                border,
                                t0,
                                t1,
                                card['apiKeyHint'] ?? '',
                                isDark,
                              ),
                              const SizedBox(height: 10),
                              _secretField(
                                i,
                                bg2,
                                border,
                                t0,
                                t1,
                                card['secretHint'] ?? '',
                                isDark,
                              ),
                              const SizedBox(height: 10),
                              if (connected)
                                _disconnectBtn(red, () => _disconnect(name))
                              else
                                _connectBtn('Connecter Binance', accent, () {
                                  final apiKey =
                                      _apiCtrls[i]?.text.trim() ?? '';
                                  final secret =
                                      _secretCtrls[i]?.text.trim() ?? '';
                                  if (apiKey.isNotEmpty && secret.isNotEmpty) {
                                    widget.chat.connectModel(
                                      name,
                                      'binance',
                                      apiKey: apiKey,
                                      secretKey: secret,
                                    );
                                    setState(() {});
                                  }
                                }),
                              if (connected) ...[
                                const SizedBox(height: 8),
                                FutureBuilder<bool>(
                                  future: widget.chat.testBinanceConnection(),
                                  builder: (_, snap) {
                                    final ok = snap.data ?? false;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (ok ? green : red).withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            ok
                                                ? Icons.check_circle
                                                : Icons.error,
                                            size: 12,
                                            color: ok ? green : red,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ok
                                                ? 'Binance connecté'
                                                : 'Test en cours...',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: ok ? green : red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ] else ...[
                              if (card['needsApiKey'] == true)
                                _apiKeyField(
                                  i,
                                  bg2,
                                  border,
                                  t0,
                                  t1,
                                  card['apiKeyHint'] ?? '',
                                  isDark,
                                ),
                              const SizedBox(height: 10),
                              if (card['needsSecret'] == true) ...[
                                _secretField(
                                  i,
                                  bg2,
                                  border,
                                  t0,
                                  t1,
                                  card['secretHint'] ?? '',
                                  isDark,
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (card['incompatible'] == true)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: red.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    'API incompatible avec le format OpenAI. Connectez DeepSeek ou OpenAI à la place.',
                                    style: TextStyle(fontSize: 10, color: red),
                                  ),
                                ),
                              Row(
                                children: [
                                  if (connected)
                                    Expanded(
                                      child: _disconnectBtn(
                                        red,
                                        () => _disconnect(name),
                                      ),
                                    )
                                  else if (card['incompatible'] != true)
                                    Expanded(
                                      child: _connectBtn(
                                        'Connecter',
                                        accent,
                                        () {
                                          final models =
                                              card['models'] as List<String>?;
                                          final model =
                                              models?.first ?? 'default';
                                          _connectGeneric(name, model);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
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
    );
  }

  Widget _apiKeyField(
    int i,
    Color bg,
    Color border,
    Color t0,
    Color t1,
    String hint,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _ctrl(_apiCtrls, i, ''),
        obscureText: true,
        style: TextStyle(fontSize: 12, color: t0, fontFamily: 'JetBrainsMono'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t1, fontSize: 11),
          prefixIcon: Icon(Icons.key, size: 14, color: t1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _secretField(
    int i,
    Color bg,
    Color border,
    Color t0,
    Color t1,
    String hint,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _ctrl(_secretCtrls, i, ''),
        obscureText: true,
        style: TextStyle(fontSize: 12, color: t0, fontFamily: 'JetBrainsMono'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t1, fontSize: 11),
          prefixIcon: Icon(Icons.lock, size: 14, color: t1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _urlField(
    int i,
    Color bg,
    Color border,
    Color t0,
    Color t1,
    String hint,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _ctrl(_urlCtrls, i, widget.chat.getSavedOpenCodeUrl()),
        style: TextStyle(fontSize: 12, color: t0, fontFamily: 'JetBrainsMono'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t1, fontSize: 11),
          prefixIcon: Icon(Icons.link, size: 14, color: t1),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _testBtn(
    String label,
    Color accent,
    bool loading,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: accent,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _connectBtn(String label, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _disconnectBtn(Color red, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: red.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            'Déconnecter',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: red,
            ),
          ),
        ),
      ),
    );
  }
}
