import '../../core/network/api_client.dart';
import '../models/advisory_message.dart';

/// Panggilan mentah ke
/// `POST /machines/:machineId/inspections/:inspectionId/advisory/messages`.
///
/// `inspectionId` bukan formalitas: backend membaca fakta klinis (status,
/// z-score, indikator dominan) dari baris inspeksi itu, bukan dari yang
/// dikirim klien. Karena itu tidak ada varian "tanya umum" tanpa inspeksi —
/// endpoint-nya memang tidak menyediakannya.
class AdvisoryApi {
  AdvisoryApi(this._client);

  final ApiClient _client;

  /// Batas riwayat yang ikut dikirim. Backend memotong di angka yang sama
  /// (`constants.AdvisoryMaxHistoryTurns`); memotong di sini menghemat kuota
  /// operator, bukan mengubah hasilnya.
  static const int maxHistoryTurns = 8;

  Future<AdvisoryMessage> send({
    required String machineId,
    required String inspectionId,
    required List<AdvisoryMessage> history,
    required String userMessage,
    required AdvisoryContext context,
  }) async {
    final trimmed = history.length > maxHistoryTurns
        ? history.sublist(history.length - maxHistoryTurns)
        : history;

    final data =
        await _client.post(
              '/machines/$machineId/inspections/$inspectionId/advisory/messages',
              body: {
                'history': trimmed.map((m) => m.toHistoryJson()).toList(),
                'user_message': userMessage,
                'context': context.toJson(),
              },
            )
            as Map<String, dynamic>;

    return AdvisoryMessage.fromResponse(data);
  }
}
