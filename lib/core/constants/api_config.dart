/// Backend base URL, overridable at build/run time:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api   # emulator Android
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000/api  # device fisik (IP LAN)
/// ```
///
/// Default mengasumsikan `audiax_backend` jalan lewat Docker di mesin yang
/// sama menjalankan Flutter (mis. desktop/web/simulator iOS).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
