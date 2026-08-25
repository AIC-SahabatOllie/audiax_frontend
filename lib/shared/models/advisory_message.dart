/// Satu giliran percakapan Teknisi Saku.
///
/// Model ini merangkap dua peran: apa yang ditampilkan di layar, DAN apa yang
/// dikirim ulang sebagai `history` di giliran berikutnya. Backend tidak
/// menyimpan percakapan sama sekali — kalau layar chat di-dispose, riwayatnya
/// hilang, dan itu memang perilaku yang dirancang.
class AdvisoryMessage {
  const AdvisoryMessage({
    required this.role,
    required this.content,
    this.nextStep,
    this.needsTechnician = false,
    this.escalated = false,
    this.source,
    this.disclaimer,
  });

  /// `user` atau `assistant` — dua nilai yang divalidasi backend.
  final String role;
  final String content;

  /// Hanya terisi untuk balasan asisten.
  final String? nextStep;
  final bool needsTechnician;

  /// Kondisi bahaya terdeteksi dari kata-kata operator sendiri. Diputuskan
  /// deterministik di backend sebelum LLM dipanggil.
  final bool escalated;

  /// `llm` atau `fallback_static`. Wajib terlihat oleh pengguna: penurunan
  /// kualitas tidak boleh senyap.
  final String? source;
  final String? disclaimer;

  bool get isUser => role == 'user';
  bool get isFallback => source == 'fallback_static';

  factory AdvisoryMessage.user(String text) =>
      AdvisoryMessage(role: 'user', content: text);

  factory AdvisoryMessage.fromResponse(Map<String, dynamic> json) =>
      AdvisoryMessage(
        role: 'assistant',
        content: json['reply'] as String,
        nextStep: json['next_step'] as String?,
        needsTechnician: json['needs_technician'] as bool? ?? false,
        escalated: json['escalated'] as bool? ?? false,
        source: json['source'] as String?,
        disclaimer: json['disclaimer'] as String?,
      );

  /// Bentuk yang dikirim balik sebagai `history`. Sengaja hanya `role` dan
  /// `content`: backend memvalidasi `oneof=user assistant` dan menolak field
  /// tambahan yang tidak dikenalnya.
  Map<String, String> toHistoryJson() => {'role': role, 'content': content};
}

/// Atribut mesin yang wajib menyertai setiap giliran.
///
/// Sementara dikumpulkan dari operator lewat sheet, karena `entity.Machine` di
/// backend belum punya kolomnya (menunggu migrasi 0005). Begitu migrasi itu
/// mendarat, kelas ini bisa diisi dari `Machine` alih-alih dari form.
class AdvisoryContext {
  const AdvisoryContext({
    required this.driveType,
    required this.recency,
    required this.machineAge,
    required this.hoursPerDay,
    required this.hasBackup,
    required this.loadState,
  });

  final String driveType;
  final String recency;
  final String machineAge;
  final String hoursPerDay;
  final bool hasBackup;
  final String loadState;

  /// Nilai default yang paling tidak berbahaya kalau operator melewati form:
  /// mesin tua, lama tidak dirawat, tanpa cadangan, sedang bermuatan. Tabel
  /// keputusan akan memilih sel yang lebih konservatif — kalau menebak, lebih
  /// baik menebak ke arah hati-hati.
  static const AdvisoryContext conservativeDefault = AdvisoryContext(
    driveType: 'belt',
    recency: 'tidak-tahu',
    machineAge: '>5th',
    hoursPerDay: '>8',
    hasBackup: false,
    loadState: 'bermuatan',
  );

  Map<String, dynamic> toJson() => {
    'drive_type': driveType,
    'recency': recency,
    'machine_age': machineAge,
    'hours_per_day': hoursPerDay,
    'has_backup': hasBackup,
    'load_state': loadState,
  };
}

/// Nilai enum yang sah, divalidasi ketat oleh backend. Kunci = nilai API,
/// nilai = label Indonesia. JANGAN mengirim labelnya — backend memvalidasi
/// kuncinya, dan satu huruf salah menghasilkan 422.
class AdvisoryOptions {
  static const driveType = {
    'belt': 'Sabuk-puli',
    'direct-coupled': 'Kopling langsung',
    'direct-drive': 'Direct drive',
  };
  static const recency = {
    '<1bln': 'Kurang dari 1 bulan',
    '1-6bln': '1–6 bulan',
    '>6bln': 'Lebih dari 6 bulan',
    'tidak-tahu': 'Tidak tahu',
  };
  static const machineAge = {
    '<1th': 'Kurang dari 1 tahun',
    '1-3th': '1–3 tahun',
    '3-5th': '3–5 tahun',
    '>5th': 'Lebih dari 5 tahun',
  };
  static const hoursPerDay = {
    '<4': 'Kurang dari 4 jam',
    '4-8': '4–8 jam',
    '>8': 'Lebih dari 8 jam',
  };
  static const loadState = {
    'kosong': 'Kosong',
    'bermuatan': 'Bermuatan',
  };
}
