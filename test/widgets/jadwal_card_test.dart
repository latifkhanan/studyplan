import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/widgets/jadwal_card.dart';

void main() {
  testWidgets('JadwalCard tidak overflow pada layar sempit', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));

    final jadwal = Jadwal(
      mataKuliah: 'Pemrograman Mobile',
      jamMulai: '08.00',
      jamSelesai: '09.40',
      ruangan: 'Ruang Laboratorium Komputer A101',
      dosen: 'Dosen Pengampu Mata Kuliah Pemrograman Mobile',
      tanggal: '2026-11-10',
      alarmMinutesList: [30, 15],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: JadwalCard(jadwal: jadwal),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(
      find.textContaining('Ruang Laboratorium Komputer A101'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
