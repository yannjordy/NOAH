import 'package:flutter/material.dart';
import '../services/ai_router_service.dart';
import '../services/storage_service.dart';

class AIRouterConfigScreen extends StatefulWidget {
  final StorageService storage;

  const AIRouterConfigScreen({super.key, required this.storage});

  @override
  State<AIRouterConfigScreen> createState() => _AIRouterConfigScreenState();
}

class _AIRouterConfigScreenState extends State<AIRouterConfigScreen> {
  final _groqCtrl = TextEditingController();
  final _geminiCtrl = TextEditingController();
  final _openrouterCtrl = TextEditingController();
  final _router = AIRouterService();
  bool _showGroqKey = false;
  bool _showGeminiKey = false;
  bool _showOpenRouterKey = false;

  @override
  void initState() {
    super.initState();
    _groqCtrl.text = widget.storage.getGroqKey();
    _geminiCtrl.text = widget.storage.getGeminiKey();
    _openrouterCtrl.text = widget.storage.getOpenRouterKey();

    if (_groqCtrl.text.isNotEmpty) _router.setGroqKey(_groqCtrl.text);
    if (_geminiCtrl.text.isNotEmpty) _router.setGeminiKey(_geminiCtrl.text);
    if (_openrouterCtrl.text.isNotEmpty) _router.setOpenRouterKey(_openrouterCtrl.text);
  }

  @override
  void dispose() {
    _groqCtrl.dispose();
    _geminiCtrl.dispose();
    _openrouterCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.storage.setGroqKey(_groqCtrl.text);
    widget.storage.setGeminiKey(_geminiCtrl.text);
    widget.storage.setOpenRouterKey(_openrouterCtrl.text);

    if (_groqCtrl.text.isNotEmpty) _router.setGroqKey(_groqCtrl.text);
    if (_geminiCtrl.text.isNotEmpty) _router.setGeminiKey(_geminiCtrl.text);
    if (_openrouterCtrl.text.isNotEmpty) _router.setOpenRouterKey(_openrouterCtrl.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration IA sauvegardée'),
        backgroundColor: Color(0xFF4CAF8E),
      ),
    );
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
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t0, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Configuration IA', style: TextStyle(color: t0, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Sauver', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text('Routeur IA Intelligent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t0)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '3 providers gratuit avec des rôles spécifiques:',
                  style: TextStyle(fontSize: 11, color: t1),
                ),
                const SizedBox(height: 8),
                _roleBadge('GROQ', 'Décisions rapides', const Color(0xFF4CAF8E), '500+ tok/sec'),
                const SizedBox(height: 4),
                _roleBadge('GEMINI', 'Analyse profonde', const Color(0xFF4A90D9), '1M contexte'),
                const SizedBox(height: 4),
                _roleBadge('OPENROUTER', 'Fallback + spécialiste', const Color(0xFF9B59B6), '25+ modèles'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // GROQ
          _providerSection(
            title: 'GROQ',
            subtitle: 'Décisions trading rapides (<200ms)',
            icon: Icons.flash_on,
            color: const Color(0xFF4CAF8E),
            controller: _groqCtrl,
            showKey: _showGroqKey,
            onToggle: () => setState(() => _showGroqKey = !_showGroqKey),
            model: 'llama-3.3-70b-versatile',
            limit: '1,000 req/jour',
            isDark: isDark,
            bg2: bg2,
            t0: t0,
            t1: t1,
            border: border,
            accent: accent,
          ),

          const SizedBox(height: 16),

          // GEMINI
          _providerSection(
            title: 'GEMINI',
            subtitle: 'Analyse approfondie (contexte long)',
            icon: Icons.auto_awesome,
            color: const Color(0xFF4A90D9),
            controller: _geminiCtrl,
            showKey: _showGeminiKey,
            onToggle: () => setState(() => _showGeminiKey = !_showGeminiKey),
            model: 'gemini-3.7-flash',
            limit: '1,500 req/jour',
            isDark: isDark,
            bg2: bg2,
            t0: t0,
            t1: t1,
            border: border,
            accent: accent,
          ),

          const SizedBox(height: 16),

          // OPENROUTER
          _providerSection(
            title: 'OPENROUTER',
            subtitle: 'Fallback + modèles free',
            icon: Icons.swap_horiz,
            color: const Color(0xFF9B59B6),
            controller: _openrouterCtrl,
            showKey: _showOpenRouterKey,
            onToggle: () => setState(() => _showOpenRouterKey = !_showOpenRouterKey),
            model: 'gemma-4-31b-it:free',
            limit: '50-1,000 req/jour',
            isDark: isDark,
            bg2: bg2,
            t0: t0,
            t1: t1,
            border: border,
            accent: accent,
          ),

          const SizedBox(height: 24),

          // Status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut des providers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t0)),
                const SizedBox(height: 8),
                _statusRow('Groq', _router.getStatus()['groq']['available'], _router.getStatus()['groq']['remaining'], t1),
                _statusRow('Gemini', _router.getStatus()['gemini']['available'], _router.getStatus()['gemini']['remaining'], t1),
                _statusRow('OpenRouter', _router.getStatus()['openrouter']['available'], _router.getStatus()['openrouter']['remaining'], t1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String name, String role, Color color, String spec) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 6),
        Text('$role • $spec', style: const TextStyle(fontSize: 10, color: Color(0xFF8C8C8C))),
      ],
    );
  }

  Widget _providerSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required bool showKey,
    required VoidCallback onToggle,
    required String model,
    required String limit,
    required bool isDark,
    required Color bg2,
    required Color t0,
    required Color t1,
    required Color border,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t0)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(limit, style: TextStyle(fontSize: 9, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: t1)),
          const SizedBox(height: 6),
          Text('Modèle: $model', style: TextStyle(fontSize: 9, color: t1)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            obscureText: !showKey,
            style: TextStyle(fontSize: 12, color: t0),
            decoration: InputDecoration(
              hintText: 'Clé API ${title.toLowerCase()}...',
              hintStyle: TextStyle(color: t1, fontSize: 11),
              prefixIcon: Icon(Icons.key, size: 14, color: t1),
              suffixIcon: IconButton(
                icon: Icon(showKey ? Icons.visibility_off : Icons.visibility, size: 14, color: t1),
                onPressed: onToggle,
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String name, bool available, int remaining, Color t1) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available ? const Color(0xFF4CAF8E) : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(fontSize: 11, color: t1)),
          const Spacer(),
          Text(
            available ? '$remaining restantes' : 'Indisponible',
            style: TextStyle(fontSize: 10, color: available ? const Color(0xFF4CAF8E) : Colors.red),
          ),
        ],
      ),
    );
  }
}
