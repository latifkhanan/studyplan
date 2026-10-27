class Catatan {
  final int? id;
  final String? docId;
  final String? userId;
  final String? jadwalId;
  final String mataKuliah;
  final int mingguKe; // Minggu / Pertemuan ke-1, 2, 3...
  final String judul;
  final String isi;
  final String tanggal; // Format YYYY-MM-DD
  final String waktu; // Format HH.mm
  final String tipe; // 'catatan', 'tugas'
  final String createdAt;

  Catatan({
    this.id,
    this.docId,
    this.userId,
    this.jadwalId,
    required this.mataKuliah,
    this.mingguKe = 1,
    required this.judul,
    required this.isi,
    required this.tanggal,
    required this.waktu,
    this.tipe = 'catatan',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (docId != null) 'docId': docId,
      if (userId != null) 'userId': userId,
      if (jadwalId != null) 'jadwalId': jadwalId,
      'mataKuliah': mataKuliah,
      'mingguKe': mingguKe,
      'judul': judul,
      'isi': isi,
      'tanggal': tanggal,
      'waktu': waktu,
      'tipe': tipe,
      'createdAt': createdAt,
    };
  }

  factory Catatan.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Catatan(
      id: map['id'] as int?,
      docId: documentId ?? (map['docId'] as String?),
      userId: map['userId'] as String?,
      jadwalId: map['jadwalId'] as String?,
      mataKuliah: map['mataKuliah'] as String? ?? '',
      mingguKe: (map['mingguKe'] as int?) ?? 1,
      judul: map['judul'] as String? ?? '',
      isi: map['isi'] as String? ?? '',
      tanggal: map['tanggal'] as String? ?? '',
      waktu: map['waktu'] as String? ?? '',
      tipe: map['tipe'] as String? ?? 'catatan',
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Catatan copyWith({
    int? id,
    String? docId,
    String? userId,
    String? jadwalId,
    String? mataKuliah,
    int? mingguKe,
    String? judul,
    String? isi,
    String? tanggal,
    String? waktu,
    String? tipe,
    String? createdAt,
  }) {
    return Catatan(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      userId: userId ?? this.userId,
      jadwalId: jadwalId ?? this.jadwalId,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      mingguKe: mingguKe ?? this.mingguKe,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      tipe: tipe ?? this.tipe,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
