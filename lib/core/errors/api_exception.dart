/// Error thrown by [ApiClient][../network/api_client.dart] for every non-2xx
/// response, plus connectivity failures. Mirrors the error table in
/// `docs/api_contract.md` §1.
class ApiException implements Exception {
  final int statusCode;
  final String error;
  final Map<String, String>? fields;

  const ApiException({
    required this.statusCode,
    required this.error,
    this.fields,
  });

  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> body) {
    final rawFields = body['fields'];
    return ApiException(
      statusCode: statusCode,
      error: (body['error'] as String?) ?? 'unknown error',
      fields: rawFields is Map
          ? rawFields.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
    );
  }

  factory ApiException.network([String? detail]) => ApiException(
    statusCode: 0,
    error: detail ?? 'network error',
  );

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 400;

  /// User-facing message. `422` is shown verbatim (already actionable
  /// Bahasa Indonesia per kontrak §2.1); the rest get a friendly generic
  /// translation since the raw `error` string is a short English label.
  String get displayMessage {
    switch (statusCode) {
      case 0:
        return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
      case 400:
        return error;
      case 401:
        return 'Sesi berakhir, silakan login kembali.';
      case 403:
        return 'Aksi tidak diizinkan.';
      case 404:
        return 'Data tidak ditemukan.';
      case 409:
        return 'Data sudah ada / dipakai.';
      case 413:
        return 'Berkas audio terlalu besar (maks 16 MB).';
      case 422:
        return error;
      case 503:
        return 'Layanan sedang tidak tersedia. Coba lagi beberapa saat lagi.';
      default:
        return 'Terjadi kesalahan pada server. Coba lagi nanti.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $error)';
}
