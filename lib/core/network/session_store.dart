import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Bearer token returned by `POST /api/users/_login`
/// (`docs/api_contract.md` §1 "Autentikasi") across app restarts.
class SessionStore extends ChangeNotifier {
  static const _tokenKey = 'audiax.session.token';
  static const _expiresAtKey = 'audiax.session.expiresAt';

  String? _token;
  DateTime? _expiresAt;
  bool _loaded = false;

  String? get token => _token;
  bool get isLoaded => _loaded;

  bool get isAuthenticated {
    if (_token == null) return false;
    if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final expiresAtRaw = prefs.getString(_expiresAtKey);
    _expiresAt = expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(String token, DateTime expiresAt) async {
    _token = token;
    _expiresAt = expiresAt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_expiresAtKey, expiresAt.toIso8601String());
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _expiresAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresAtKey);
    notifyListeners();
  }
}
