import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/providers.dart';
import '../theme/noah_theme.dart';

const _incompatibleApis = {'Anthropic Claude', 'Google Gemini', 'Meta LLaMA', 'Replicate'};

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
    return map.pu