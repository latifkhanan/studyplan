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
  final String tanggal; // Format YYYY-MM-DD
  final bool isAlarmActive;
  final List<int> alarmMinutesList; // Contoh: [30, 15] atau [15, 5]

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
    this.isAlarmActive = true,
    List<int>? alarmMinutesList,
    int? alarmMinutesBefore,
  }) : alarmMinutesList =
           (alarmMinutesList != null && alarmMinutesList.isNotEmpty)
           ? alarmMinutesList
           : [(alarmMinutesBefore ?? 10)];

  int get alarmMinutesBefore =>
      alarmMinutesList.isNotEmpty ? alarmMinutesList.first : 10;

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
      'isAlarmActive': isAlarmActive ? 1 : 0,
      'alarmMinutesBefore': alarmMinutesBefore,
      'alarmMinutesList': alarmMinutesList.join(','),
    };
  }

  factory Jadwal.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawAlarm = map['isAlarmActive'];
    final bool alarmBool =
        (rawAlarm == true || rawAlarm == 1 || rawAlarm == null);

    List<int> parsedList = [];
    if (map['alarmMinutesList'] != null) {
      final raw = map['alarmMinutesList'];
      final values = raw is List ? raw : raw.toString().split(',');
      parsedList = values
          .map(
            (value) => int.tryParse(
              value.toString().replaceAll(RegExp(r'[\[\]]'), '').trim(),
            ),
          )
          .whereType<int>()
          .toSet()
          .toList();
    } else if (map['alarmMinutesBefore'] != null) {
      final single = int.tryParse(map['alarmMinutesBefore'].toString());
      if (single != null) parsedList = [single];
    }

    if (parsedList.isEmpty) {
      parsedList = [10];
    }
    parsedList.sort(
      (a, b) => b.compareTo(a),
    ); // Sort descending (e.g. [30, 15, 5])

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
      isAlarmActive: alarmBool,
      alarmMinutesList: parsedList,
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
    bool? isAlarmActive,
    List<int>? alarmMinutesList,
    int? alarmMinutesBefore,
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
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      alarmMinutesList: alarmMinutesList ?? this.alarmMinutesList,
      alarmMinutesBefore: alarmMinutesBefore ?? this.alarmMinutesBefore,
    );
  }
}
