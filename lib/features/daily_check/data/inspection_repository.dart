import 'dart:io';

import '../../../shared/models/inspection.dart';
import '../../../shared/services/inspections_api.dart';

/// `POST/GET /api/machines/:machineId/inspections` (`docs/api_contract.md` §6).
class InspectionRepository {
  InspectionRepository(this._inspectionsApi);

  final InspectionsApi _inspectionsApi;

  Future<Inspection> inspect(String machineId, File audio) => _inspectionsApi.create(machineId, audio);

  Future<List<Inspection>> history(String machineId) => _inspectionsApi.list(machineId);
}
