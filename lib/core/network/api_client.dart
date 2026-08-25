import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../errors/api_exception.dart';
import 'session_store.dart';

/// Single HTTP entry point to `audiax_backend`, per
/// `docs/project_structure.md` "Satu pintu masuk HTTP". Unwraps the
/// `{"data": ...}` / `{"error","fields"}` envelope (`docs/api_contract.md`
/// §1) and throws [ApiException] for every non-2xx response or connectivity
/// failure — callers never see raw `http` types.
class ApiClient {
  ApiClient({required this.sessionStore, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SessionStore sessionStore;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({bool withContentType = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (withContentType) headers['Content-Type'] = 'application/json';
    final token = sessionStore.token;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<dynamic> get(String path) =>
      _send(() => _http.get(_uri(path), headers: _headers(withContentType: false)));

  Future<dynamic> post(String path, {Object? body}) => _send(
    () => _http.post(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body)),
  );

  Future<dynamic> patch(String path, {Object? body}) => _send(
    () => _http.patch(_uri(path), headers: _headers(), body: body == null ? null : jsonEncode(body)),
  );

  Future<void> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _headers(withContentType: false)));

  /// Uploads the single `audio` multipart field expected by the
  /// baselines/inspections endpoints (`docs/api_contract.md` §1 "Upload
  /// audio").
  Future<dynamic> postMultipart(
    String path, {
    required String fieldName,
    required File file,
  }) async {
    if (!file.existsSync() || await file.length() == 0) {
      throw const ApiException(statusCode: 400, error: 'Berkas audio tidak ditemukan atau kosong.');
    }
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path));
      final token = sessionStore.token;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      final streamed = await _http.send(request);
      return http.Response.fromStream(streamed);
    }, timeout: const Duration(seconds: 240));
  }

  Future<dynamic> _send(
    Future<http.Response> Function() call, {
    Duration timeout = const Duration(seconds: 30),
    int retries = 1,
  }) async {
    http.Response? response;
    Object? lastError;

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        response = await call().timeout(timeout);
        break;
      } on TimeoutException {
        throw ApiException.network('timeout');
      } on SocketException catch (e) {
        lastError = e;
        if (attempt < retries) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
      } on http.ClientException catch (e) {
        lastError = e;
        if (attempt < retries) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
      }
    }

    if (response == null) {
      final message = lastError is SocketException
          ? lastError.message
          : (lastError is http.ClientException ? lastError.message : 'network error');
      throw ApiException.network(message);
    }

    if (response.statusCode == 204) {
      return null;
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(statusCode: response.statusCode, error: 'malformed response body');
      }
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok) {
      if (decoded is Map<String, dynamic>) return decoded['data'];
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      throw ApiException.fromResponse(response.statusCode, decoded);
    }
    throw ApiException(statusCode: response.statusCode, error: 'unknown error');
  }
}
