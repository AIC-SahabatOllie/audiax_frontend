import '../../core/network/api_client.dart';
import '../models/machine.dart';

/// Raw CRUD calls to `/api/machines` (`docs/api_contract.md` §4). Lives in
/// `shared/services` rather than a feature's `data/` folder because it's
/// consumed by `machine_management`, `calibration`, `daily_check`, and
/// `result_card` alike.
class MachinesApi {
  MachinesApi(this._client);

  final ApiClient _client;

  Future<List<Machine>> list() async {
    final data = await _client.get('/machines') as List<dynamic>;
    return data.map((e) => Machine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Machine> get(String machineId) async {
    final data = await _client.get('/machines/$machineId') as Map<String, dynamic>;
    return Machine.fromJson(data);
  }

  Future<Machine> create({required String label, String? location, String? description}) async {
    final body = <String, dynamic>{'label': label};
    if (location != null) body['location'] = location;
    if (description != null) body['description'] = description;
    final data = await _client.post('/machines', body: body) as Map<String, dynamic>;
    return Machine.fromJson(data);
  }

  Future<Machine> update(String machineId, {String? label, String? location, String? description}) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (location != null) body['location'] = location;
    if (description != null) body['description'] = description;
    final data = await _client.patch('/machines/$machineId', body: body) as Map<String, dynamic>;
    return Machine.fromJson(data);
  }

  Future<void> delete(String machineId) => _client.delete('/machines/$machineId');
}
