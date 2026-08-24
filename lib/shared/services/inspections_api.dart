import 'dart:io';

import '../../core/network/api_client.dart';
import '../models/inspection.dart';

/// Raw calls to `/api/machines/:machineId/inspections`
/// (`docs/api_contract.md` §6). Shared across `daily_check` (create) and
/// `machine_management`/`result_card` (read history/trend).
class InspectionsApi {
  InspectionsApi(this._client);

  final ApiClient _client;

  /// Newest first, capped at `constants.InspectionHistoryLimit` (100) by the
  /// backend.
  Future<List<Inspection>> list(String machineId) async {
    final data = await _client.get('/machines/$machineId/inspections') as List<dynamic>;
    return data.map((e) => Inspection.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Always `201` — `KALIBRASI_KURANG` is a valid outcome, not an error
  /// (§6). Only genuine failures (422/413/503/etc.) throw.
  Future<Inspection> create(String machineId, File audio) async {
    final data =
        await _client.postMultipart(
              '/machines/$machineId/inspections',
              fieldName: 'audio',
              file: audio,
            )
            as Map<String, dynamic>;
    return Inspection.fromJson(data);
  }
}
