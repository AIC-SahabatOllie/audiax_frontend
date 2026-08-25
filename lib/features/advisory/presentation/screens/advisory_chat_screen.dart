import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../shared/models/advisory_message.dart';
import '../../../../shared/models/inspection.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/advisory_repository.dart';
import '../widgets/advisory_bubble.dart';
import '../widgets/advisory_context_sheet.dart';

const List<String> _suggestedQuestions = [
  'Masih aman dipakai?',
  'Apa artinya indikator ini?',
  'Perlu panggil teknisi?',
];

/// Percakapan Teknisi Saku untuk SATU inspeksi.
///
/// Riwayat hidup di `_messages` dan dikirim ulang tiap giliran: backend tidak
/// menyimpan percakapan apa pun. Menutup layar ini berarti menghapus
/// percakapannya, dan itu memang yang dirancang.
class AdvisoryChatScreen extends StatefulWidget {
  const AdvisoryChatScreen({
    super.key,
    required this.repository,
    required this.machineId,
    required this.inspection,
  });

  final AdvisoryRepository repository;
  final String machineId;
  final Inspection inspection;

  @override
  State<AdvisoryChatScreen> createState() => _AdvisoryChatScreenState();
}

class _AdvisoryChatScreenState extends State<AdvisoryChatScreen> {
  final _messages = <AdvisoryMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();

  AdvisoryContext? _context;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Sheet dibuka setelah frame pertama supaya Navigator sudah siap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _collectContext());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _collectContext() async {
    final result = await showModalBottomSheet<AdvisoryContext>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdvisoryContextSheet(),
    );
    if (!mounted) return;
    // Operator boleh menutup sheet tanpa mengisi. Memakai default konservatif
    // lebih baik daripada memblokir fitur -- tabel keputusan akan memilih sel
    // yang lebih hati-hati, bukan yang lebih longgar.
    setState(() => _context = result ?? AdvisoryContext.conservativeDefault);
  }

  Future<void> _send([String? presetText]) async {
    final text = (presetText ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    // Snapshot SEBELUM pesan baru ditambahkan: `history` berarti giliran-giliran
    // sebelumnya, sementara pesan sekarang dikirim di `user_message`. Kalau
    // pesan sekarang ikut masuk history, model melihatnya dua kali.
    final history = List<AdvisoryMessage>.from(_messages);

    setState(() {
      _messages.add(AdvisoryMessage.user(text));
      _input.clear();
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await widget.repository.ask(
        machineId: widget.machineId,
        inspectionId: widget.inspection.id,
        history: history,
        userMessage: text,
        context: _context ?? AdvisoryContext.conservativeDefault,
      );
      if (!mounted) return;
      setState(() => _messages.add(reply));
    } on ApiException catch (e) {
      if (!mounted) return;
      // Pesan operator TIDAK dihapus dari daftar: ia sudah mengetiknya, dan
      // menghilangkannya membuat layar seperti kehilangan input.
      setState(() => _error = e.displayMessage);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Teknisi Saku'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _InspectionContextBar(inspection: widget.inspection),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(onTapSuggestion: _send)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => AdvisoryBubble(message: _messages[i]),
                    ),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                color: AppColors.criticalTint,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.criticalDeep),
                ),
              ),
            _Composer(controller: _input, sending: _sending, onSend: () => _send()),
          ],
        ),
      ),
    );
  }
}

/// Menampilkan status dan skor-z inspeksi yang sedang dibicarakan. Bukan
/// hiasan: operator harus tahu percakapan ini tentang pemeriksaan yang mana,
/// terutama kalau ia membukanya dari riwayat.
class _InspectionContextBar extends StatelessWidget {
  const _InspectionContextBar({required this.inspection});

  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final mapped = inspection.status.asMachineStatus;
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          mapped != null ? StatusBadge(status: mapped) : const StatusBadge.unknown(),
          const SizedBox(width: 10),
          Text(
            inspection.zScore != null
                ? 'SKOR-Z ${inspection.zScore!.toStringAsFixed(1).replaceAll('.', ',')}'
                : 'SKOR-Z –',
            style: AppTextStyles.mono(size: 10, color: AppColors.textMuted, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTapSuggestion});

  final ValueChanged<String> onTapSuggestion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 14),
            const Text(
              'Tanya apa saja tentang hasil pemeriksaan ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final question in _suggestedQuestions)
                  ActionChip(
                    label: Text(question, style: const TextStyle(fontSize: 12.5)),
                    backgroundColor: AppColors.surfaceMuted,
                    onPressed: () => onTapSuggestion(question),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Tulis pertanyaan…',
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.brand,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : onSend,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
