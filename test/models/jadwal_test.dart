import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/models/jadwal.dart';

void main() {
  group('Jadwal alarm minutes', () {
    test('round-trips multiple reminder times through the stored map', () {
      final jadwal = Jadwal(
        mataKuliah: 'Matematika',
        jamMulai: '08.00',
        jamSelesai: '09.40',
        ruangan: 'A101',
        dosen: 'Dosen',
        alarmMinutesList: [30, 15],
      );

      final restored = Jadwal.fromMap(jadwal.toMap());

      expect(restored.alarmMinutesList, [30, 15]);
      expect(restored.alarmMinutesBefore, 30);
    });

    test('reads reminder times stored as a Firestore list', () {
      final jadwal = Jadwal.fromMap({
        'mataKuliah': 'Matematika',
        'alarmMinutesList': [15, 30],
      });

      expect(jadwal.alarmMinutesList, [30, 15]);
    });

    test('keeps compatibility with the legacy single reminder field', () {
      final jadwal = Jadwal.fromMap({
        'mataKuliah': 'Matematika',
        'alarmMinutesBefore': 15,
      });

      expect(jadwal.alarmMinutesList, [15]);
    });
  });
}
