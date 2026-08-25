import '../../../shared/models/advisory_message.dart';
import '../../../shared/services/advisory_api.dart';

/// Lapisan tipis di atas [AdvisoryApi], mengikuti pola
/// `InspectionRepository`/`CalibrationRepository`: layar tidak pernah
/// menyentuh `ApiClient` langsung.
class AdvisoryRepository {
  AdvisoryRepository(this._api);

  final AdvisoryApi _api;

  Future<AdvisoryMessage> ask({
    required String machineId,
    required String inspectionId,
    required List<AdvisoryMessage> history,
    required String userMessage,
    required AdvisoryContext context,
  }) {
    return _api.send(
      machineId: machineId,
      inspectionId: inspectionId,
      history: history,
      userMessage: userMessage,
      context: context,
    );
  }
}
