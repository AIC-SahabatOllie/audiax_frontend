import '../../../core/network/api_client.dart';
import '../../../core/network/session_store.dart';
import '../../../shared/models/user.dart';

/// Calls `/api/users*` (`docs/api_contract.md` §3) and keeps [SessionStore]
/// in sync with the returned Bearer token.
class AuthRepository {
  AuthRepository({required ApiClient client, required SessionStore sessionStore})
    : _client = client,
      _sessionStore = sessionStore;

  final ApiClient _client;
  final SessionStore _sessionStore;

  Future<User> register({required String email, required String name, required String password}) async {
    final data =
        await _client.post('/users', body: {'email': email, 'name': name, 'password': password})
            as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<void> login({required String email, required String password}) async {
    final data =
        await _client.post('/users/_login', body: {'email': email, 'password': password})
            as Map<String, dynamic>;
    final token = data['token'] as String;
    final expiresAt = DateTime.parse(data['expires_at'] as String);
    await _sessionStore.save(token, expiresAt);
  }

  Future<User> currentUser() async {
    final data = await _client.get('/users/_current') as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _client.delete('/users/_current');
    } finally {
      await _sessionStore.clear();
    }
  }
}
