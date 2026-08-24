import 'dart:io';

import '../../core/network/api_client.dart';
import '../models/baseline.dart';

/// Raw calls to `/api/machines/:machineId/baselines`
/// (`docs/api_contract.md` §5). Shared across `calibration` (create) and
/// `machine_management`/`result_card` (read history).
class BaselinesApi {
  BaselinesApi(this._client);

  final ApiClient _client;

  Future<List<Baseline>> list(String machineId) async {
    final data = await _client.get('/machines/$machineId/baselines') as List<dynamic>;
    return data.map((e) => Baseline.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Baseline> create(String machineId, File audio) async {
    final data =
        await _client.postMultipart(
              '/machines/$machineId/baselines',
              fieldName: 'audio',
              file: audio,
            )
            as Map<String, dynamic>;
    return Baseline.fromJson(data);
  }
}
