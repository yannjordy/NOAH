import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/models.dart';

class SupabaseService {
  static const _url = 'https://dimnepbasmswqmexlhvs.supabase.co';
  static const _anonKey = 'sb_publishable_LzS7Y7L3vjno6yS54w1LkA_KAAxdeBO';

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  String? _userEmail;

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: _url,
      headers: {
        'apikey': _anonKey,
        'Content-Type': 'application/json',
      },
      validateStatus: (_) => true,
    ));
  }

  bool get isLoggedIn => _accessToken != null;
  String? get userEmail => _userEmail;

  Map<String, String> get _authHeaders => {
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<bool> signUp(String email, String password, String name) async {
    try {
      final res = await _dio.post('/auth/v1/signup', data: {
        'email': email,
        'password': password,
        'data': {'name': name},
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _extractSession(res.data);
        return true;
      }
      // Try sign in if user already exists
      return await signIn(email, password);
    } catch (_) {
      try {
        return await signIn(email, password);
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    await signIn(email, password);
  }

  Future<void> signIn(String email, String password) async {
    final res = await _dio.post('/auth/v1/token?grant_type=password', data: {
      'email': email,
      'password': password,
    });
    if (res.statusCode == 200) {
      _extractSession(res.data);
    } else {
      throw Exception(res.data['msg'] ?? 'Login failed');
    }
  }

  Future<void> sendOtp(String email) async {
    await _dio.post('/auth/v1/otp', data: {'email': email});
  }

  Stream<Map<String, dynamic>> get onAuthChange async* {
    // Simplified auth state stream
    if (_accessToken != null) {
      yield {'event': 'SIGNED_IN', 'session': {'access_token': _accessToken}};
    }
  }

  Future<void> verifyOtp(String email, String token) async {
    final res = await _dio.post('/auth/v1/verify', data: {
      'email': email,
      'token': token,
      'type': 'magiclink',
    });
    if (res.statusCode == 200) {
      _extractSession(res.data);
    }
  }

  Future<void> signOut() async {
    if (_accessToken != null) {
      await _dio.post('/auth/v1/logout', options: Options(headers: _authHeaders));
    }
    _accessToken = null;
    _refreshToken = null;
    _userEmail = null;
  }

  void _extractSession(Map<String, dynamic> data) {
    _accessToken = data['access_token'];
    _refreshToken = data['refresh_token'];
    _userEmail = data['user']?['email'];
  }

  // --- Database operations via REST API ---

  Future<void> upsertProfile(String email, String name, String passwordHash,
      {bool? termsAccepted, bool? isDemo}) async {
    final data = <String, dynamic>{
      'email': email,
      'name': name,
      'password_hash': passwordHash,
    };
    if (termsAccepted != null) data['terms_accepted'] = termsAccepted;
    if (isDemo != null) data['is_demo'] = isDemo;
    await _restUpsert('profiles', data, 'email');
  }

  Future<Map<String, dynamic>?> getProfile(String email) async {
    return await _restSelect('profiles', 'email=eq.$email');
  }

  Future<void> saveWallet(String email, double usdt, double initialUsdt, double totalDeposits) async {
    await _restUpsert('wallet', {
      'user_email': email,
      'usdt': usdt,
      'initial_usdt': initialUsdt,
      'total_deposits': totalDeposits,
    }, 'user_email');
  }

  Future<Map<String, dynamic>?> getWallet(String email) async {
    return await _restSelect('wallet', 'user_email=eq.$email');
  }

  Future<void> savePositions(String email, List<Position> positions) async {
    await _restDelete('positions', 'user_email=eq.$email');
    if (positions.isEmpty) return;
    final rows = positions.map((p) => {
      'user_email': email,
      'symbol': p.sym,
      'qty': p.qty,
      'entry_price': p.entry,
      'stop_loss': p.stopLoss,
      'take_profit': p.takeProfit,
    }).toList();
    await _restInsert('positions', rows);
  }

  Future<List<Map<String, dynamic>>> getPositions(String email) async {
    return await _restSelectList('positions', 'user_email=eq.$email');
  }

  Future<void> addTrade(String email, TradeOrder trade) async {
    await _restInsert('trade_history', [{
      'user_email': email,
      'side': trade.side,
      'symbol': trade.sym,
      'qty': trade.qty,
      'price': trade.price,
      'pnl': trade.pnl,
    }]);
  }

  Future<List<Map<String, dynamic>>> getTradeHistory(String email, {int limit = 100}) async {
    return await _restSelectList('trade_history',
        'user_email=eq.$email&order=time.desc&limit=$limit');
  }

  Future<void> addWalletTransaction(String email, WalletTransaction tx) async {
    await _restInsert('wallet_transactions', [{
      'user_email': email,
      'type': tx.type,
      'amount': tx.amount,
      'label': tx.label,
    }]);
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions(String email) async {
    return await _restSelectList('wallet_transactions',
        'user_email=eq.$email&order=created_at.desc');
  }

  Future<void> saveApiConnection(String email, String model, String apiKey, String apiUrl) async {
    await _restUpsert('api_connections', {
      'user_email': email,
      'model_name': model,
      'api_key_encrypted': apiKey,
      'api_url': apiUrl,
      'is_active': true,
    }, 'user_email,model_name');
  }

  Future<List<Map<String, dynamic>>> getApiConnections(String email) async {
    return await _restSelectList('api_connections',
        'user_email=eq.$email&is_active=eq.true');
  }

  Future<void> deleteApiConnection(String email, String model) async {
    await _restDelete('api_connections', 'user_email=eq.$email&model_name=eq.$model');
  }

  Future<bool> isBanned(String email) async {
    try {
      final res = await _restSelect('profiles', 'email=eq.$email&select=banned');
      return res?['banned'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getMinVersion() async {
    try {
      final res = await _restSelect('app_config', 'key=eq.min_version&select=value');
      return res?['value'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveChatSessions(String email, List<ChatSession> sessions) async {
    await _restDelete('chat_sessions', 'user_email=eq.$email');
    if (sessions.isEmpty) return;
    final rows = sessions.map((s) => {
      'user_email': email,
      'id': s.id,
      'title': s.title,
      'date': s.date,
      'msgs_json': s.toJson()['msgs'],
    }).toList();
    await _restInsert('chat_sessions', rows);
  }

  Future<List<Map<String, dynamic>>> getChatSessions(String email) async {
    return await _restSelectList('chat_sessions',
        'user_email=eq.$email&order=date.desc');
  }

  // --- REST helpers ---

  Future<Map<String, dynamic>?> _restSelect(String table, String query) async {
    final res = await _dio.get('/rest/v1/$table?$query',
        options: Options(headers: {..._authHeaders, 'Prefer': 'return=representation'}));
    if (res.statusCode == 200 && res.data is List && res.data.isNotEmpty) {
      return res.data[0];
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _restSelectList(String table, String query) async {
    final res = await _dio.get('/rest/v1/$table?$query',
        options: Options(headers: {..._authHeaders, 'Prefer': 'return=representation'}));
    if (res.statusCode == 200 && res.data is List) {
      return List<Map<String, dynamic>>.from(res.data);
    }
    return [];
  }

  Future<void> _restInsert(String table, List<Map<String, dynamic>> data) async {
    await _dio.post('/rest/v1/$table',
        data: data.length == 1 ? data[0] : data,
        options: Options(headers: {..._authHeaders, 'Prefer': 'return=minimal'}));
  }

  Future<void> _restUpsert(String table, Map<String, dynamic> data, String onConflict) async {
    await _dio.post('/rest/v1/$table',
        data: data,
        options: Options(headers: {
          ..._authHeaders,
          'Prefer': 'return=minimal,resolution=merge-duplicates',
        }));
  }

  Future<void> _restDelete(String table, String query) async {
    await _dio.delete('/rest/v1/$table?$query',
        options: Options(headers: _authHeaders));
  }
}
