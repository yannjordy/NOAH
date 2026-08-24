import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static const _url = 'https://dimnepbasmswqmexlhvs.supabase.co';
  static const _anonKey = 'sb_publishable_LzS7Y7L3vjno6yS54w1LkA_KAAxdeBO';

  late final SupabaseClient _client;
  User? _user;
  StreamSubscription<AuthState>? _authSub;

  Future<void> init() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
    _client = Supabase.instance.client;
    _user = _client.auth.currentUser;
  }

  bool get isLoggedIn => _user != null;
  String? get userEmail => _user?.email;

  SupabaseClient get client => _client;

  User? get user => _user;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
  Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;

  void listenAuth(void Function(User?) onChange) {
    _authSub?.cancel();
    _authSub = _client.auth.onAuthStateChange.listen((state) {
      _user = state.session?.user;
      onChange(_user);
    });
  }

  void dispose() {
    _authSub?.cancel();
  }

  Future<bool> signUp(String email, String password, [String? name]) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );
      _user = res.user;
      return res.user != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signInWithPassword(String email, String password) async {
    return signIn(email, password);
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      _user = res.user;
      return res.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _user = null;
  }

  Future<void> sendOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<bool> verifyOtp(String email, String token) async {
    try {
      final res = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.magiclink,
      );
      _user = res.user;
      return res.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<bool> verifyForgotPasswordOtp(String email, String token) async {
    try {
      final res = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      _user = res.user;
      return res.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;
    await _client.from('profiles').upsert({
      'id': _user!.id,
      ...updates,
    });
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderColumn,
    bool ascending = false,
    int? limit,
  }) async {
    var query = _client.from(table).select(select ?? '*');
    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }
    if (orderColumn != null) {
      query = query.order(orderColumn, ascending: ascending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    return await query;
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    await _client.from(table).insert(data);
  }

  Future<void> update(String table, Map<String, dynamic> data, {
    required Map<String, dynamic> match,
  }) async {
    var query = _client.from(table).update(data);
    for (final entry in match.entries) {
      query = query.eq(entry.key, entry.value);
    }
    await query;
  }

  Future<void> delete(String table, {
    required Map<String, dynamic> match,
  }) async {
    var query = _client.from(table).delete();
    for (final entry in match.entries) {
      query = query.eq(entry.key, entry.value);
    }
    await query;
  }

  Stream<List<Map<String, dynamic>>> subscribe(String table, {
    String? filter,
  }) {
    return _client.from(table).stream(primaryKey: ['id']);
  }
}
