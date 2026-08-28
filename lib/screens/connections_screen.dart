import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/providers.dart';
import '../theme/noah_theme.dart';

const _incompatibleApis = {'Binance API'};

class ConnectionsScreen extends StatefulWidget {
  final AuthProvider auth;
  final ChatProvider chat;
  final void Function(int) openLogin;

  const ConnectionsScreen({super.key, required this.auth, required this.chat, required this.openLogin});

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

  TextEditingController _ctrl(Map<int, TextEditingController> map, int i, String v) {
    return map.putIfAbsent(i, () => TextEditingController(text: v));
  }

  void _saveProvider(int i, _ProviderData p) async {
    if (!widget.auth.isLoggedIn) {
      widget.openLogin(0);
      return;
    }
    final apiKey = _apiCtrls[i]?.text.trim() ?? '';
    if (apiKey.isEmpty && p.placeholder.isNotEmpty && p.name != 'Binance API' && p.name != 'OpenCode Local') {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Entrez une clé API pour ${p.name}'), duration: const Duration(seconds: 2)),
      );
      return;
    }
    final secretKey = _secretCtrls[i]?.text.trim() ?? '';
    if (p.name == 'OpenCode Local') {
      final url = _urlCtrls[i]?.text.trim() ?? 'http://localhost:4096';
      widget.chat.updateOpenCodeUrl(url);
      // Auto-test and fetch models when connecting OpenCode
      widget.chat.connectModel(p.name, p.model, apiKey: apiKey, secretKey: secretKey);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('🔍 Test de connexion OpenCode...'), duration: Duration(seconds: 2)),
      );
      final ok = await widget.chat.testOpenCodeConnection();
      if (!mounted) return;
      if (ok) {
        final models = await widget.chat.fetchOpenCodeModels();
        if (!mounted) return;
        setState(() {
          _opencodeOk[i] = true;
          _opencodeModels[i] = models;
        });
        // Update the default model to first available model
        if (models.isNotEmpty && !models.contains(p.model)) {
          p.model = models.first;
          widget.chat.connectModel(p.name, models.first, apiKey: apiKey, secretKey: secretKey);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ OpenCode connecté — ${models.length} modèles disponibles'), duration: const Duration(seconds: 3)),
        );
      } else {
        setState(() {
          _opencodeOk[i] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ OpenCode configuré — vérifiez l\'URL dans les paramètres'), duration: Duration(seconds: 3)),
        );
      }
    } else {
      widget.chat.connectModel(p.name, p.model, apiKey: apiKey, secretKey: secretKey);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('${p.name} connecté'), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _testOpenCode(int i, _ProviderData p) async {
    final url = _urlCtrls[i]?.text.trim() ?? 'http://localhost:4096';
    setState(() {
      _opencodeTesting[i] = true;
      _opencodeOk.remove(i);
    });
    widget.chat.updateOpenCodeUrl(url);
    final ok = await widget.chat.testOpenCodeConnection();
    if (!mounted) return;
    setState(() {
      _opencodeTesting[i] = false;
      _opencodeOk[i] = ok;
    });
    if (ok) {
      final models = await widget.chat.fetchOpenCodeModels();
      if (!mounted) return;
      setState(() => _opencodeModels[i] = models);
      // Auto-connect with first available model
      final model = models.isNotEmpty ? models.first : p.model;
      widget.chat.connectModel(p.name, model);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ OpenCode connecté — ${models.length} modèles — Chat et Agents actifs'), duration: const Duration(seconds: 3)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Impossible de joindre OpenCode — vérifiez l\'URL'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _testBinance() async {
    final ok = await widget.chat.testBinanceConnection();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ Connexion Binance réussie' : '❌ Échec de connexion Binance'),
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final savedOpenCodeUrl = widget.chat.getSavedOpenCodeUrl();
    final providers = [
      // ── GROQ ── Ultra-rapide, décisions trading
      _ProviderData('Groq', 'llama-3.3-70b-versatile', [
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'meta-llama/llama-4-scout-17b-16e-instruct',
        'qwen/qwen3-32b',
        'gemma-2-9b-it',
      ], true, const Color(0xFFFF5722), 'Gq', '', free: true, apiUrl: 'https://console.groq.com/keys',
      description: 'Ultra-rapide (500+ tok/sec) — Décisions trading',
      role: 'SPEED'),

      // ── GEMINI ── Analyse profonde, long contexte
      _ProviderData('Google Gemini', 'gemini-3.6-flash', [
        'gemini-3.6-flash',
        'gemini-3.5-flash-lite',
      ], false, const Color(0xFF4285F4), 'Gm', 'AIza...', free: true, apiUrl: 'https://aistudio.google.com/apikey',
      description: '1M contexte — Analyse profonde',
      role: 'ANALYST'),

      // ── OPENROUTER ── Fallback, modèles variés
      _ProviderData('OpenRouter', 'openrouter/auto', [
        'openrouter/auto',
      ], false, const Color(0xFF6461FF), 'OR', 'sk-or-...', free: true, apiUrl: 'https://openrouter.ai/keys',
      description: 'Fallback intelligent — Crédits requis',
      role: 'FALLBACK'),

      // ── OPENCODE LOCAL ── Modèles locaux via OpenCode
      _ProviderData('OpenCode Local', widget.chat.currentModel.startsWith('opencode/') ? widget.chat.currentModel : 'google/gemma-4-31b-it:free', _opencodeModels[18] ?? const [
        'google/gemma-4-31b-it:free',
        'nvidia/nemotron-3-ultra-550b-a55b:free',
        'nvidia/nemotron-nano-9b-v2:free',
        'google/gemma-4-26b-a4b-it:free',
        'nvidia/nemotron-3-nano-30b-a3b:free',
        'poolside/laguna-s-2.1:free',
        'cohere/north-mini-code:free',
        'nvidia/nemotron-3.5-lightning:free',
      ], false, const Color(0xFF00D4AA), 'OC', '', free: true, apiUrl: 'https://opencode.ai',
      description: 'Modèles locaux — Illimité, offline',
      role: 'LOCAL'),

      // ── HUGGING FACE ── Modèles open-source
      _ProviderData('Hugging Face', 'HuggingFaceH4/zephyr-7b-beta', [
        'HuggingFaceH4/zephyr-7b-beta',
        'mistralai/Mistral-7B-Instruct-v0.3',
        'meta-llama/Llama-3.2-3B-Instruct',
        'google/gemma-2-9b-it',
      ], true, const Color(0xFFFFBF00), 'HF', '', free: true, apiUrl: 'https://huggingface.co/settings/tokens',
      description: 'Open-source — Modèles communautaires',
      role: 'COMMUNITY'),

      // ── BINANCE ── Exchange (pas un LLM)
      _ProviderData('Binance API', '', [], false, const Color(0xFFF0B90B), 'BN', 'Clé API', hasSecret: true, apiUrl: 'https://www.binance.com/en/support/faq/how-to-create-api-keys-on-binance-360002502072'),
    ];

    return ListenableBuilder(
        listenable: widget.chat,
        builder: (context, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg1 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
          final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
          final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
          final borderMd = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);
          final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
          final accentBorder = isDark ? const Color(0x2EC2A878) : const Color(0x33B08D57);
          final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
          final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
          final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
          final t3 = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8);
          final green = isDark ? const Color(0xFF4CAF8E) : const Color(0xFF2E7D5E);
          final greenBg = isDark ? const Color(0x144CAF8E) : const Color(0x142E7D5E);
        return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: providers.length + 1,
        itemBuilder: (context, idx) {
          if (idx == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Fournisseurs IA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t2, letterSpacing: 1.2)),
                ],
              ),
            );
          }
          final i = idx - 1;
          final p = providers[i];
          final open = _expanded.contains(i);
          final savedKey = widget.chat.getSavedApiKey(p.name);
          final apiCtrl = _ctrl(_apiCtrls, i, savedKey.isNotEmpty ? savedKey : p.placeholder);
          final secretCtrl = p.hasSecret ? _ctrl(_secretCtrls, i, '') : null;

          if (p.baseUrl != null && !_urlCtrls.containsKey(i)) {
            _urlCtrls[i] = TextEditingController(text: p.baseUrl);
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                if (open) _expanded.remove(i); else _expanded.add(i);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: bg1,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: open ? accentBorder : border),
                boxShadow: open ? NoahTheme.shadowMd(isDark) : NoahTheme.shadow(isDark),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(p.initials,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.color)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t0)),
                                  if (p.free) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: greenBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text('GRATUIT', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: green, letterSpacing: 0.5)),
                                    ),
                                  ],
                                  if (_incompatibleApis.contains(p.name)) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: Color(0x2EEF5350), borderRadius: BorderRadius.circular(4)),
                                      child: Text('⚠️', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFFEF5350))),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(p.model, style: TextStyle(fontSize: 11, color: t2)),
                            ],
                          ),
                        ),
                        if (p.name == 'OpenCode Local') ...[
                          if (_opencodeOk[i] == true)
                            Icon(Icons.check_circle, size: 16, color: green)
                          else if (_opencodeOk[i] == false)
                            Icon(Icons.error_outline, size: 16, color: const Color(0xFFEF5350))
                          else
                            Icon(Icons.help_outline, size: 16, color: t3),
                          const SizedBox(width: 6),
                        ],
                        Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: t2),
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Container(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          if (p.baseUrl != null) ...[
                            Text('URL du serveur', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.4)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                              decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderMd)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _urlCtrls[i],
                                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: t0),
                                      decoration: InputDecoration.collapsed(hintText: 'http://localhost:4096', hintStyle: TextStyle(color: t3)),
                                      onChanged: (v) {
                                        if (p.name == 'OpenCode Local') {
                                          widget.chat.updateOpenCodeUrl(v.trim());
                                        }
                                      },
                                    ),
                                  ),
                                  if (p.name == 'OpenCode Local') ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _opencodeTesting[i] == true ? null : () => _testOpenCode(i, p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _opencodeOk[i] == true ? greenBg : bg1,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: _opencodeOk[i] == true ? green : borderMd),
                                        ),
                                        child: _opencodeTesting[i] == true
                                            ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: t2))
                                            : Icon(
                                                _opencodeOk[i] == true ? Icons.check : Icons.wifi_tethering,
                                                size: 14,
                                                color: _opencodeOk[i] == true ? green : t2,
                                              ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (p.name != 'OpenCode Local') ...[
                            Text('API Key', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.4)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                              decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderMd)),
                              child: TextField(
                                controller: apiCtrl,
                                obscureText: true,
                                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: t0),
                                decoration: InputDecoration.collapsed(hintText: p.placeholder, hintStyle: TextStyle(color: t3)),
                              ),
                            ),
                          ],
                          if (p.models.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Modèle', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.4)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                              decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderMd)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: p.models.contains(p.model) ? p.model : p.models.first,
                                  isExpanded: true,
                                  style: TextStyle(fontSize: 12, color: t0),
                                  dropdownColor: isDark ? const Color(0xFF282828) : const Color(0xFFFFFFFF),
                                  items: p.models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(fontSize: 11, color: t0)))).toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => p.model = v);
                                    final savedKey = widget.chat.getSavedApiKey(p.name);
                                    widget.chat.connectModel(p.name, v, apiKey: savedKey);
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (p.hasSecret) ...[
                            const SizedBox(height: 8),
                            Text('Secret Key', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t2, letterSpacing: 0.4)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                              decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderMd)),
                              child: TextField(
                                controller: secretCtrl,
                                obscureText: true,
                                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: t0),
                                decoration: InputDecoration.collapsed(hintText: 'Secret Key', hintStyle: TextStyle(color: t3)),
                              ),
                            ),
                          ],
                          if (p.name == 'Binance API') ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _testBinance,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: widget.chat.binanceWorking ? greenBg : bg2,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: widget.chat.binanceWorking ? green : borderMd,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      widget.chat.binanceWorking
                                          ? Icons.check_circle
                                          : Icons.wifi_tethering,
                                      size: 14,
                                      color: widget.chat.binanceWorking ? green : t2,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.chat.binanceWorking
                                          ? '✅ Connecté à Binance'
                                          : widget.chat.binanceConnected
                                              ? 'Tester la connexion'
                                              : 'Tester après connexion',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: widget.chat.binanceWorking ? green : t1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (p.apiUrl != null)
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse(p.apiUrl!), mode: LaunchMode.externalApplication),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: bg2,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderMd),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.open_in_new, size: 12, color: accent),
                                    const SizedBox(width: 5),
                                    Text('Obtenir une clé API', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                                  ],
                                ),
                              ),
                            ),
                          if (p.apiUrl != null) const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              if (widget.chat.connectedModels.containsKey(p.name)) {
                                widget.chat.disconnectModel(p.name);
                              } else {
                                _saveProvider(i, p);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: widget.chat.connectedModels.containsKey(p.name) ? green.withValues(alpha: 0.15) : accent,
                                borderRadius: BorderRadius.circular(16),
                                border: widget.chat.connectedModels.containsKey(p.name) ? Border.all(color: green.withValues(alpha: 0.3)) : null,
                              ),
                              child: Text(
                                widget.chat.connectedModels.containsKey(p.name) ? '✅ Connecté' : 'Connecter',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: widget.chat.connectedModels.containsKey(p.name) ? green : Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
    );
  }
}

class _ProviderData {
  final String name;
  String model;
  List<String> models;
  final bool connected;
  final Color color;
  final String initials;
  final String placeholder;
  final bool free;
  final bool hasSecret;
  final String? apiUrl;
  String? baseUrl;
  final String? description;
  final String? role;

  _ProviderData(this.name, this.model, this.models, this.connected, this.color,
      this.initials, this.placeholder,
      {this.free = false, this.hasSecret = false, this.apiUrl, this.baseUrl, this.description, this.role});
}
