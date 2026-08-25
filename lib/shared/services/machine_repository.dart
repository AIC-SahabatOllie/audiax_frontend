import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../models/baseline.dart';
import '../models/inspection.dart';
import '../models/machine.dart';
import 'advisory_api.dart';
import 'baselines_api.dart';
import 'inspections_api.dart';
import 'machines_api.dart';

/// Fleet state for the whole app — composes the three raw API wrappers
/// (`machines_api.dart`, `baselines_api.dart`, `inspections_api.dart`) into
/// the enriched [Machine] list every screen renders
/// (`docs/project_structure.md` §"Kapan Pakai shared/", since this is used
/// by `machine_management`, `calibration`, `daily_check`, and
/// `result_card` alike). Every mutation round-trips through
/// `audiax_backend` — there is no local fabrication left.
class MachineRepository extends ChangeNotifier {
  MachineRepository({
    required MachinesApi machinesApi,
    required BaselinesApi baselinesApi,
    required InspectionsApi inspectionsApi,
    required AdvisoryApi advisoryApi,
  }) : _machinesApi = machinesApi,
       _baselinesApi = baselinesApi,
       _inspectionsApi = inspectionsApi,
       _advisoryApi = advisoryApi;

  final MachinesApi _machinesApi;
  final BaselinesApi _baselinesApi;
  final InspectionsApi _inspectionsApi;
  final AdvisoryApi _advisoryApi;

  /// Exposed so `RecordingScreen`/`ResultScreen` can build the thin
  /// `CalibrationRepository`/`InspectionRepository`/`AdvisoryRepository`
  /// wrappers without every screen in the calibration/daily-check/result
  /// flow needing its own API-client wiring threaded through
  /// `Navigator.push`.
  BaselinesApi get baselinesApi => _baselinesApi;
  InspectionsApi get inspectionsApi => _inspectionsApi;
  AdvisoryApi get advisoryApi => _advisoryApi;

  List<Machine> _machines = [];
  final Map<String, List<Baseline>> _baselineHistory = {};
  final Map<String, List<Inspection>> _inspectionHistory = {};

  bool isLoading = false;
  String? error;

  List<Machine> get machines => List.unmodifiable(_machines);

  Machine? byId(String id) {
    for (final machine in _machines) {
      if (machine.id == id) return machine;
    }
    return null;
  }

  List<Baseline> baselinesFor(String machineId) =>
      List.unmodifiable(_baselineHistory[machineId] ?? const []);

  List<Inspection> inspectionsFor(String machineId) =>
      List.unmodifiable(_inspectionHistory[machineId] ?? const []);

  /// Fetches the whole fleet plus each machine's latest baseline/inspection
  /// (§4/§5/§6) — called once after login and whenever the machine list
  /// screen needs a full reload.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final machines = await _machinesApi.list();
      _machines = await Future.wait(machines.map(_attachLatest));
    } on ApiException catch (e) {
      error = e.displayMessage;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes one machine plus its full baseline/inspection history —
  /// used by `MachineDetailScreen` (trend chart) and after a
  /// calibration/inspection completes.
  Future<void> refreshDetail(String machineId) async {
    try {
      final machine = await _machinesApi.get(machineId);
      _replaceMachine(await _attachLatest(machine));
    } on ApiException catch (e) {
      error = e.displayMessage;
    }
    notifyListeners();
  }

  Future<Machine> _attachLatest(Machine machine) async {
    Baseline? latestBaseline;
    Inspection? latestInspection;
    try {
      final baselines = await _baselinesApi.list(machine.id);
      _baselineHistory[machine.id] = baselines;
      for (final baseline in baselines) {
        if (baseline.isActive) {
          latestBaseline = baseline;
          break;
        }
      }
      latestBaseline ??= baselines.isNotEmpty ? baselines.first : null;
    } on ApiException {
      // Keep the machine visible even if history fetch fails; the detail
      // screen's own refresh gives the user another chance.
    }
    try {
      final inspections = await _inspectionsApi.list(machine.id);
      _inspectionHistory[machine.id] = inspections;
      latestInspection = inspections.isNotEmpty ? inspections.first : null;
    } on ApiException {
      // Same as above.
    }
    return machine.copyWith(latestBaseline: latestBaseline, latestInspection: latestInspection);
  }

  void _replaceMachine(Machine machine) {
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index == -1) {
      _machines.insert(0, machine);
    } else {
      _machines[index] = machine;
    }
  }

  Future<Machine> create({required String label, String? location, String? description}) async {
    final machine = await _machinesApi.create(label: label, location: location, description: description);
    _machines.insert(0, machine);
    notifyListeners();
    return machine;
  }

  Future<void> rename(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final updated = await _machinesApi.update(id, label: trimmed);
    final existing = byId(id);
    _replaceMachine(existing?.copyWith(label: updated.label) ?? updated);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _machinesApi.delete(id);
    _machines.removeWhere((m) => m.id == id);
    _baselineHistory.remove(id);
    _inspectionHistory.remove(id);
    notifyListeners();
  }
}
