import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
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
      setState(() => _mo