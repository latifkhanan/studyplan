class Jadwal {
  final int? id;
  final String? docId;
  final String? userId;
  final String mataKuliah;
  final String jamMulai;
  final String jamSelesai;
  final String ruangan;
  final String dosen;
  final String hari;
  final String tanggal; // Format YYYY-MM-DD, e.g. '2026-10-20'

  Jadwal({
    this.id,
    this.docId,
    this.userId,
    required this.mataKuliah,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruangan,
    required this.dosen,
    this.hari = 'Selasa',
    this.tanggal = '2026-10-20',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (docId != null) 'docId': docId,
      if (userId != null) 'userId': userId,
      'mataKuliah': mataKuliah,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'ruangan': ruangan,
      'dosen': dosen,
      'hari': hari,
      'tanggal': tanggal,
    };
  }

  factory Jadwal.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Jadwal(
      id: map['id'] as int?,
      docId: documentId ?? (map['docId'] as String?),
      userId: map['userId'] as String?,
      mataKuliah: map['mataKuliah'] as String? ?? '',
      jamMulai: map['jamMulai'] as String? ?? '08.00',
      jamSelesai: map['jamSelesai'] as String? ?? '09.40',
      ruangan: map['ruangan'] as String? ?? '',
      dosen: map['dosen'] as String? ?? '',
      hari: map['hari'] as String? ?? 'Selasa',
      tanggal: map['tanggal'] as String? ?? '2026-10-20',
    );
  }

  Jadwal copyWith({
    int? id,
    String? docId,
    String? userId,
    String? mataKuliah,
    String? jamMulai,
    String? jamSelesai,
    String? ruangan,
    String? dosen,
    String? hari,
    String? tanggal,
  }) {
    return Jadwal(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      userId: userId ?? this.userId,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      ruangan: ruangan ?? this.ruangan,
      dosen: dosen ?? this.dosen,
      hari: hari ?? this.hari,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}
