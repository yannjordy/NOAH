import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';

enum _AuthMode { login, register, forgot, admin, adminSetup }

class LoginModal extends StatefulWidget {
  final AuthProvider auth;
  final SupabaseService supabase;
  final VoidCallback onClose;

  const LoginModal({
    super.key,
    required this.auth,
    required this.supabase,
    required this.onClose,
  });

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
    final ok = await widget.auth.loginWithEmail(
      widget.supabase,
      email,
      password,
    );
    if (ok && mounted)
      widget.onClose();
    else {
      _showToast(
        'Email ou mot de passe incorrect — vérifie que ton compte est confirmé',
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();
    if (email.isEmpty ||
        !email.contains('@') ||
        password.isEmpty ||
        name.isEmpty) {
      _showToast('Veuillez remplir tous les champs');
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.auth.registerWithEmail(
      widget.supabase,
      email,
      password,
      name,
    );
    if (ok && mounted) {
      widget.onClose();
    } else if (mounted) {
      _showToast(
        'Inscription OK — vérifie tes emails pour confirmer ton compte',
      );
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
      _showToast(
        'Erreur : ${e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '')}',
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyResetCode() async {
    final code = _codeDigits.join();
    if (code.length < 6 || _resetEmail == null) return;
    setState(() => _loading = true);
    final ok = await widget.auth.verifyForgotPasswordOtp(
      widget.supabase,
      _resetEmail!,
      code,
    );
    if (ok && mounted)
      widget.onClose();
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
    if (ok && mounted)
      widget.onClose();
    else {
      _showToast('Mot de passe admin incorrect');
      setState(() => _loading = false);
    }
  }

  Future<void> _setupAdmin() async {
    final password = _passwordCtrl.text;
    if (password.length < 4) {
      _showToast('Le mot de passe doit faire au moins 4 caractères');
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.auth.setupAdminPassword(password);
    if (ok && mounted)
      widget.onClose();
    else {
      _showToast('Erreur lors de la configuration');
      setState(() => _loading = false);
    }
  }

  Future<void> _loginBiometric() async {
    setState(() => _loading = true);
    final ok = await widget.auth.loginWithBiometrics();
    if (ok && mounted)
      widget.onClose();
    else {
      _showToast('Authentification biométrique échouée');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC2A878) : const Color(0xFFB08D57);
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final bg2 = isDark ? const Color(0xFF282828) : const Color(0xFFF0ECE4);
    final t0 = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1C1C1C);
    final t1 = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5C5C5C);
    final t2 = isDark ? const Color(0xFF6C6C6C) : const Color(0xFF9C9C9C);
    final border = isDark ? const Color(0x17FFFFFF) : const Color(0x1A000000);

    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo-remove.png',
                  height: 52,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
                const SizedBox(height: 16),
                Text(
                  _mode == _AuthMode.admin || _mode == _AuthMode.adminSetup
                      ? 'Connexion Admin'
                      : _mode == _AuthMode.forgot
                      ? 'Réinitialiser le mot de passe'
                      : _mode == _AuthMode.register
                      ? 'Créer un compte'
                      : 'Bienvenue',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: t0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _mode == _AuthMode.forgot
                      ? 'Entrez votre email pour recevoir un code'
                      : _mode == _AuthMode.admin ||
                            _mode == _AuthMode.adminSetup
                      ? 'Accès réservé à l\'administrateur'
                      : 'Connectez-vous à votre compte NOAH',
                  style: TextStyle(fontSize: 12, color: t2),
                ),
                const SizedBox(height: 24),
                if (_mode == _AuthMode.forgot && _resetEmail == null) ...[
                  _input(
                    _emailCtrl,
                    'Email',
                    Icons.email_outlined,
                    isDark,
                    accent,
                    bg2,
                    t0,
                    t1,
                    border,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _btn(
                    'Envoyer le code',
                    accent,
                    () => _sendResetCode(),
                    loading: _loading,
                  ),
                ] else if (_mode == _AuthMode.forgot &&
                    _resetEmail != null) ...[
                  Text(
                    'Code envoyé à $_resetEmail',
                    style: TextStyle(fontSize: 12, color: t1),
                  ),
                  const SizedBox(height: 16),
                  _codeInput(isDark, accent, bg2, border),
                  const SizedBox(height: 14),
                  _btn(
                    'Vérifier',
                    accent,
                    () => _verifyResetCode(),
                    loading: _loading,
                  ),
                ] else if (_mode == _AuthMode.adminSetup) ...[
                  _input(
                    _passwordCtrl,
                    'Nouveau mot de passe admin',
                    Icons.lock_outline,
                    isDark,
                    accent,
                    bg2,
                    t0,
                    t1,
                    border,
                    obscure: true,
                  ),
                  const SizedBox(height: 14),
                  _btn(
                    'Configurer',
                    accent,
                    () => _setupAdmin(),
                    loading: _loading,
                  ),
                ] else ...[
                  if (_mode == _AuthMode.register)
                    _input(
                      _nameCtrl,
                      'Nom',
                      Icons.person_outline,
                      isDark,
                      accent,
                      bg2,
                      t0,
                      t1,
                      border,
                    ),
                  if (_mode == _AuthMode.register) const SizedBox(height: 14),
                  _input(
                    _emailCtrl,
                    'Email',
                    Icons.email_outlined,
                    isDark,
                    accent,
                    bg2,
                    t0,
                    t1,
                    border,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _input(
                    _passwordCtrl,
                    _mode == _AuthMode.admin
                        ? 'Mot de passe admin'
                        : 'Mot de passe',
                    Icons.lock_outline,
                    isDark,
                    accent,
                    bg2,
                    t0,
                    t1,
                    border,
                    obscure: !_showPassword,
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _showPassword = !_showPassword),
                      child: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: t2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_mode == _AuthMode.login || _mode == _AuthMode.admin)
                    _btn(
                      _mode == _AuthMode.admin
                          ? 'Connexion Admin'
                          : 'Se connecter',
                      accent,
                      _mode == _AuthMode.admin
                          ? () => _loginAdmin()
                          : () => _login(),
                      loading: _loading,
                    )
                  else
                    _btn(
                      'S\'inscrire',
                      accent,
                      () => _register(),
                      loading: _loading,
                    ),
                ],
                const SizedBox(height: 12),
                if (_mode != _AuthMode.forgot && _mode != _AuthMode.adminSetup)
                  GestureDetector(
                    onTap: () => _switchMode(
                      _mode == _AuthMode.login
                          ? _AuthMode.register
                          : _AuthMode.login,
                    ),
                    child: Text(
                      _mode == _AuthMode.login
                          ? 'Pas de compte ? S\'inscrire'
                          : 'Déjà un compte ? Se connecter',
                      style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_mode == _AuthMode.login) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _switchMode(_AuthMode.forgot),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(fontSize: 11, color: t2),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(height: 1, color: border),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _switchMode(
                        _mode == _AuthMode.admin
                            ? _AuthMode.login
                            : _AuthMode.admin,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: bg2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 14,
                              color: t2,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: t1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FutureBuilder<bool>(
                      future: widget.auth.isBiometricAvailable(),
                      builder: (_, snap) {
                        if (snap.data != true) return const SizedBox();
                        return GestureDetector(
                          onTap: () => _loginBiometric(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bg2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fingerprint,
                                  size: 14,
                                  color: accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Biométrie',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: t1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => widget.onClose(),
                  child: Text(
                    'Continuer en tant qu\'invité',
                    style: TextStyle(fontSize: 11, color: t2),
                  ),
                ),
                if (_toast != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07060).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE07060).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _toast!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE07060),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark,
    Color accent,
    Color bg2,
    Color t0,
    Color t1,
    Color border, {
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: t0),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: t1, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: t1),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _codeInput(bool isDark, Color accent, Color bg2, Color border) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          width: 40,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: TextEditingController(text: _codeDigits[i]),
            focusNode: _codeFocusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFamily: 'JetBrainsMono',
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (v) {
              if (v.length == 1) {
                _codeDigits[i] = v;
                if (i < 5) _codeFocusNodes[i + 1].requestFocus();
              } else {
                _codeDigits[i] = '';
                if (i > 0) _codeFocusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _btn(
    String label,
    Color accent,
    VoidCallback onTap, {
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
