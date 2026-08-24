import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/models.dart';

class SupabaseService {
  static const _url = 'https://dimnepbasmswqmexlhvs.supabase.co';
  static const _anonKey = 'sb_publishable_LzS7Y7L3vjno6yS54w1LkA_KAAxdeBO';

  sb.SupabaseClient get client => sb.Supabase.instance.client;

  Future<void> init() async {
    await sb.Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  bool get isLoggedIn => client.auth.currentUser != null;
  String? get userEmail => client.auth.currentUser?.email;

  Future<bool> signUp(String email, String password, String name) async {
    try {
      final res = await client.auth.signUp(email: email, password: password, data: {'name': name});
      if (res.session != null) return true;
      // Email confirmation required — try to sign in anyway (some Supabase configs auto-confirm)
      try {
        await client.auth.signInWithPassword(email: email, password: password);
        return client.auth.currentUser != null;
      } catch (_) {
        // Email not confirmed yet — return true so app can create local account
        return true;
      }
    } catch (e) {
      // If signup fails (e.g. user already exists), try sign in
      try {
        await client.auth.signInWithPassword(email: email, password: password);
        return client.auth.currentUser != null;
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendOtp(String email) async {
    await client.auth.signInWithOtp(email: email);
  }

  Stream<sb.AuthState> get onAuthChange => client.auth.onAuthStateChange;

  Future<void> verifyOtp(String email, String token) async {
    await client.auth.verifyOTP(email: email, token: token, type: sb.OtpType.email);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> upsertProfile(String email, String name, String passwordHash,
      {bool? termsAccepted, bool? isDemo}) async {
    final data = <String, dynamic>{
      'email': email,
      'name': name,
      'password_hash': passwordHash,
    };
    if (termsAccepted != null) data['terms_accepted'] = termsAccepted;
    if (isDemo != null) data['is_demo'] = isDemo;
    await client.from('profiles').upsert(data, onConflict: 'email');
  }

  Future<Map<String, dynamic>?> getProfile(String email) async {
    final res = await client.from('profiles').select().eq('email', email).maybeSingle();
    return res;
  }

  Future<void> saveWallet(String email, double usdt, double initialUsdt, double totalDeposits) async {
    await client.from('wallet').upsert({
      'user_email': email,
      'usdt': usdt,
      'initial_usdt': initialUsdt,
      'total_deposits': totalDeposits,
    }, onConflict: 'user_email');
  }

  Future<Map<String, dynamic>?> getWallet(String email) async {
    return client.from('wallet').select().eq('user_email', email).maybeSingle();
  }

  Future<void> savePositions(String email, List<Position> positions) async {
    await client.from('positions').delete().eq('user_email', email);
    if (positions.isEmpty) return;
    final rows = positions.map((p) => {
      'user_email': email,
      'symbol': p.sym,
      'qty': p.qty,
      'entry_price': p.entry,
      'stop_loss': p.stopLoss,
      'take_profit': p.takeProfit,
    }).toList();
    await client.from('positions').insert(rows);
  }

  Future<List<Map<String, dynamic>>> getPositions(String email) async {
    final res = await client.from('positions').select().eq('user_email', email);
    return res;
  }

  Future<void> addTrade(String email, TradeOrder trade) async {
    await client.from('trade_history').insert({
      'user_email': email,
      'side': trade.side,
      'symbol': trade.sym,
      'qty': trade.qty,
      'price': trade.price,
      'pnl': trade.pnl,
    });
  }

  Future<List<Map<String, dynamic>>> getTradeHistory(String email, {int limit = 100}) async {
    final res = await client.from('trade_history')
        .select()
        .eq('user_email', email)
        .order('time', ascending: false)
        .limit(limit);
    return res;
  }

  Future<void> addWalletTransaction(String email, WalletTransaction tx) async {
    await client.from('wallet_transactions').insert({
      'user_email': email,
      'type': tx.type,
      'amount': tx.amount,
      'label': tx.label,
    });
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions(String email) async {
    final res = await client.from('wallet_transactions')
        .select()
        .eq('user_email', email)
        .order('created_at', ascending: false);
    return res;
  }

  Future<void> saveApiConnection(String email, String model, String apiKey, String apiUrl) async {
    await client.from('api_connections').upsert({
      'user_email': email,
      'model_name': model,
      'api_key_encrypted': apiKey,
      'api_url': apiUrl,
      'is_active': true,
    }, onConflict: 'user_email,model_name');
  }

  Future<List<Map<String, dynamic>>> getApiConnections(String email) async {
    final res = await client.from('api_connections')
        .select()
        .eq('user_email', email)
        .eq('is_active', true);
    return res;
  }

  Future<void> deleteApiConnection(String email, String model) async {
    await client.from('api_connections')
        .delete()
        .eq('user_email', email)
        .eq('model_name', model);
  }

  Future<bool> isBanned(String email) async {
    try {
      final res = await client.from('profiles').select('banned').eq('email', email).maybeSingle();
      return res?['banned'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getMinVersion() async {
    try {
      final res = await client.from('app_config').select('value').eq('key', 'min_version').maybeSingle();
      return res?['value'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveChatSessions(String email, List<ChatSession> sessions) async {
    await client.from('chat_sessions').delete().eq('user_email', email);
    if (sessions.isEmpty) return;
    final rows = sessions.map((s) => {
      'id': s.id,
      'user_email': email,
      'title': s.title,
      'date': s.date,
      'msgs_json': s.toJson()['msgs'],
    }).toList();
    await client.from('chat_sessions').insert(rows);
  }

  Future<List<Map<String, dynamic>>> getChatSessions(String email) async {
    final res = await client.from('chat_sessions')
        .select()
        .eq('user_email', email)
        .order('date', ascending: false);
    return res;
  }
}
