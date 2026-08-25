import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';

enum _AuthMode { login, register, forgot, admin, adminSetup }

class LoginModal extends StatefulWidget {
  final AuthProvider auth;
  final SupabaseService supabase;
  final VoidCallback onClose;

  const LoginModal({super.key, required this.auth, required this.supabase, required this.onClose});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  var _codeDigits = <String>['', '', '', '', '', ''];
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _showPassword = false;
  String? _toast;
  _AuthMode _mode = _AuthMode.login;
  String? _resetEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    for (final f in _codeFocusNodes) f.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _loading = false;
      _toast = null;
      _codeDigits = <String>['', '', '', '', '', ''];
    });
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || !email.contains('@') || password.isEmpty) {
      _showToast('Veuillez remplir tous les champs');
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.auth.loginWithEmail(widget.supabase, email, password);
    if (ok && mounted) widget.onClose();
    else {
      _showToast('Email ou mot de passe incorrect — vérifie que ton compte est confirmé');
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();
    if (email.isEmpty || !email.contains('@') || password.isEmpty || name.isEmpty) {
      _showToast('Veuillez remplir tous les champs');
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.auth.registerWithEmail(widget.supabase, email, password, name);
    if (ok && mounted) {
      widget.onClose();
    } else if (mounted) {
      _showToast('Inscription OK — vérifie tes emails pour confirmer ton compte');
      setState(() => _loading = false);
    }
  }

  Future<void> _sendResetCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showToast('Veuillez entrer un email valide');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.supabase.sendOtp(email);
      setState(() {
        _resetEmail = email;
        _loading = false;
      });
      _codeFocusNodes[0].requestFocus();
      _showToast('Code envoyé à $email');
    } catch (e) {
      _showToast('Erreur : ${e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '')}');
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyResetCode() async {
    final code = _codeDigits.join();
    if (code.length < 6 || _resetEmail == null) return;
    setState(() => _loading = true);
    final ok = await widget.auth.verifyForgotPasswordOtp(widget.supabase, _resetEmail!, code);
    if (ok && mounted) widget.onClose();
    else {
      _showToast('Code incorrect ou expiré');
      setState(() => _codeDigits = <String>['', '', '', '', '', '']);
      _loading = false;
      _codeFocusNodes[0].requestFocus();
    }
  }

  Future<void> _loginAdmin() async {
    if (!widget.auth.hasAdminPassword()) {
      setState(() => _mode = _AuthMode.adminSetup);
      return;
    }
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      _showToast('Veuillez entrer le mot de passe admin');
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.auth.loginWithAdminPassword(password);
    if (ok && mounted) {
      widget.onClose();
    } else {
      _showToast('Mot de passe admin incorrect');
      setState(() => _loading = false);
    }
  }

  Future<void> _setupAdminPassword() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty || password.length < 4) {
      _showToast('Le mot de passe doit faire au moins 4 caractères');
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.auth.setupAdminPassword(password);
    if (ok && mounted) {
      _showToast('Mot de passe défini ! Connexion...');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) widget.onClose();
    } else {
      _showToast('Erreur lors de la configuration');
      setState(() => _loading = false);
    }
  }

  Future<void> _loginWithBiometrics() async {
    setState(() => _loading = true);
    final ok = await widget.auth.loginWithBiometrics();
    if (ok && mounted) {
      widget.onClose();
    } else {
      _showToast('Authentification biométrique échouée');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final border = isDark ? const Color(0x0DFFFFFF) : const Color(0x0F000000);
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);

    final showCodeStep = _mode == _AuthMode.forgot && _resetEmail != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Color.fromRGBO(30, 30, 30, 0.88)
                : Color.fromRGBO(255, 255, 255, 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              width: 0.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('N', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                  ),
                  const SizedBox(width: 10),
                  Text('NOAH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent, letterSpacing: 2)),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(Icons.close, size: 16, color: t2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_mode == _AuthMode.login) ..._buildLogin(accent, bg2, t0, t2),
              if (_mode == _AuthMode.register) ..._buildRegister(accent, bg2, t0, t2),
              if (_mode == _AuthMode.forgot && !showCodeStep) ..._buildForgotEmail(accent, bg2, t0, t2),
              if (_mode == _AuthMode.forgot && showCodeStep) ..._buildCodeStep(accent, bg2, t0, t2, border),
              if (_mode == _AuthMode.admin) ..._buildAdmin(accent, bg2, t0, t2),
              if (_mode == _AuthMode.adminSetup) ..._buildAdminSetup(accent, bg2, t0, t2),
            ],
          ),
        ),
      ),
    );
  }

  // ── Login ──
  List<Widget> _buildLogin(Color accent, Color bg2, Color t0, Color t2) {
    return [
      Text('Connexion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t0)),
      const SizedBox(height: 20),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Email',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          hintText: 'Mot de passe',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: t2,
            ),
          ),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => _switchMode(_AuthMode.forgot),
          child: Text('Mot de passe oublié ?', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Se connecter', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
      if (_toast != null) ...[
        const SizedBox(height: 12),
        Text(_toast!, style: TextStyle(fontSize: 11, color: t2), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: Divider(color: t2.withValues(alpha: 0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('ou', style: TextStyle(fontSize: 11, color: t2)),
          ),
          Expanded(child: Divider(color: t2.withValues(alpha: 0.3))),
        ],
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => _switchMode(_AuthMode.admin),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 18, color: accent),
              const SizedBox(width: 8),
              Text('Accès Admin', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : _loginWithBiometrics,
          icon: const Icon(Icons.fingerprint, size: 22),
          label: Text('Connexion par empreinte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => _switchMode(_AuthMode.register),
        child: Text("Pas de compte ? Inscris-toi", style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
      ),
    ];
  }

  // ── Register ──
  List<Widget> _buildRegister(Color accent, Color bg2, Color t0, Color t2) {
    return [
      Text('Créer un compte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t0)),
      const SizedBox(height: 20),
      TextField(
        controller: _nameCtrl,
        decoration: InputDecoration(
          hintText: 'Nom',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Email',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          hintText: 'Mot de passe',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: t2,
            ),
          ),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text("S'inscrire", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
      if (_toast != null) ...[
        const SizedBox(height: 12),
        Text(_toast!, style: TextStyle(fontSize: 11, color: t2), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => _switchMode(_AuthMode.login),
        child: Text("Déjà un compte ? Connecte-toi", style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
      ),
    ];
  }

  // ── Forgot Password: Email step ──
  List<Widget> _buildForgotEmail(Color accent, Color bg2, Color t0, Color t2) {
    return [
      Text('Mot de passe oublié', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t0)),
      const SizedBox(height: 4),
      Text("Un code à 6 chiffres sera envoyé par email", style: TextStyle(fontSize: 12, color: t2)),
      const SizedBox(height: 24),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Email',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _sendResetCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Envoyer le code', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
      if (_toast != null) ...[
        const SizedBox(height: 12),
        Text(_toast!, style: TextStyle(fontSize: 11, color: t2), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => _switchMode(_AuthMode.login),
        child: Text("Retour à la connexion", style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
      ),
    ];
  }

  // ── Code step ──
  List<Widget> _buildCodeStep(Color accent, Color bg2, Color t0, Color t2, Color border) {
    return [
      Text('Code de vérification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t0)),
      const SizedBox(height: 4),
      Text('Entrez le code reçu par email', style: TextStyle(fontSize: 12, color: t2)),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          final isFilled = _codeDigits[i].isNotEmpty;
          return Container(
            width: 44, height: 52,
            margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
            decoration: BoxDecoration(
              color: bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isFilled ? accent : border, width: isFilled ? 1.5 : 1),
            ),
            child: TextField(
              controller: TextEditingController(text: _codeDigits[i]),
              focusNode: _codeFocusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t0),
              decoration: const InputDecoration(border: InputBorder.none, counterText: '', contentPadding: EdgeInsets.only(bottom: 8)),
              onChanged: (v) {
                setState(() => _codeDigits[i] = v);
                if (v.isNotEmpty && i < 5) _codeFocusNodes[i + 1].requestFocus();
                else if (v.isEmpty && i > 0) _codeFocusNodes[i - 1].requestFocus();
                if (_codeDigits.every((d) => d.isNotEmpty)) _verifyResetCode();
              },
            ),
          );
        }),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading || _codeDigits.any((d) => d.isEmpty) ? null : _verifyResetCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Vérifier', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
      if (_toast != null) ...[
        const SizedBox(height: 12),
        Text(_toast!, style: TextStyle(fontSize: 11, color: t2), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () {
          setState(() {
            _resetEmail = null;
            _codeDigits = <String>['', '', '', '', '', ''];
          });
        },
        child: Text("Modifier l'email", style: TextStyle(fontSize: 12, color: t2, decoration: TextDecoration.underline)),
      ),
    ];
  }

  // ── Admin Access ──
  List<Widget> _buildAdmin(Color accent, Color bg2, Color t0, Color t2) {
    return [
      Text('Accès Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t0)),
      const SizedBox(height: 8),
      Text('Connectez-vous avec votre mot de passe admin ou l\'empreinte digitale', style: TextStyle(fontSize: 12, color: t2), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          hintText: 'Mot de passe admin',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: t2,
            ),
          ),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _loginAdmin,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Se connecter', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: Divider(color: t2.withValues(alpha: 0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('ou', style: TextStyle(fontSize: 11, color: t2)),
          ),
          Expanded(child: Divider(color: t2.withValues(alpha: 0.3))),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : _loginWithBiometrics,
          icon: const Icon(Icons.fingerprint, size: 20),
          label: Text('Empreinte digitale', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      if (_toast != null) ...[
        const SizedBox(height: 12),
        Text(_toast!, style: TextStyle(fontSize: 11, color: t2), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => _switchMode(_AuthMode.login),
        child: Text("Retour à la connexion", style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
      ),
    ];
  }

  // ── Admin Setup ──
  List<Widget> _buildAdminSetup(Color accent, Color bg2, Color t0, Color t2) {
    return [
      Text('Configurer l\'accès Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t0)),
      const SizedBox(height: 8),
      Text('Aucun mot de passe admin défini. Créez-le maintenant pour pouvoir vous connecter via l\'empreinte digitale ou ce mot de passe.', style: TextStyle(fontSize: 12, color: t2), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          hintText: 'Nouveau mot de passe admin',
          filled: true, fillColor: bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: t2,
            ),
          ),
        ),
        style: TextStyle(fontSize: 14, color: t0),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _setupAdminPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Créer et se connecter', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
      if (_toast != null) ...[
        const SizedBox(height: 12),
        Text(_toast!, style: TextStyle(fontSize: 11, color: t2), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => _switchMode(_AuthMode.login),
        child: Text("Retour à la connexion", style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
      ),
    ];
  }
}
