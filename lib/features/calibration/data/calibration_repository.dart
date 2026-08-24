import 'dart:io';

import '../../../shared/models/baseline.dart';
import '../../../shared/services/baselines_api.dart';

/// `POST/GET /api/machines/:machineId/baselines` (`docs/api_contract.md` §5).
class CalibrationRepository {
  CalibrationRepository(this._baselinesApi);

  final BaselinesApi _baselinesApi;

  Future<Baseline> calibrate(String machineId, File audio) => _baselinesApi.create(machineId, audio);

  Future<List<Baseline>> history(String machineId) => _baselinesApi.list(machineId);
}
