import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/models/catatan.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/pages/catatan_page.dart';

Catatan _note({
  required String title,
  required String type,
  required String course,
  int week = 1,
}) => Catatan(
  mataKuliah: course,
  mingguKe: week,
  judul: title,
  isi: 'Detail $title',
  tanggal: '2026-10-20',
  waktu: '10.00',
  tipe: type,
  createdAt: '2026-10-20T10:00:00',
);

Jadwal _schedule(String course) => Jadwal(
  mataKuliah: course,
  jamMulai: '08.00',
  jamSelesai: '09.40',
  ruangan: 'A101',
  dosen: 'Dosen',
);

void main() {
  testWidgets('empty notes page shows its state and validates new notes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CatatanPage(
            loadNotes: _emptyNotes,
            loadSchedules: _emptySchedules,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catatan & Tugas'), findsOneWidget);
    expect(find.text('Belum ada catatan atau tugas.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Tambah catatan atau tugas'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Catatan / Tugas'), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(find.text('Isi wajib diisi'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
    expect(find.text('Tambah Catatan / Tugas'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('notes can be searched and filtered by type', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    final notes = [
      _note(
        title: 'Ringkasan Normalisasi',
        type: 'catatan',
        course: 'Basis Data',
        week: 2,
      ),
      _note(title: 'Tugas ERD', type: 'tugas', course: 'Basis Data', week: 3),
      _note(
        title: 'Catatan Flutter',
        type: 'catatan',
        course: 'Pemrograman',
        week: 1,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatatanPage(
            loadNotes: () async => notes,
            loadSchedules: () async => [
              _schedule('Basis Data'),
              _schedule('Pemrograman'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Normalisasi'), findsOneWidget);
    expect(find.text('Tugas ERD'), findsOneWidget);
    expect(find.text('Minggu Ke-2 / Pertemuan 2'), findsOneWidget);
    expect(find.text('Minggu Ke-3 / Pertemuan 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan Normalisasi'), findsOneWidget);
    expect(find.text('Tugas ERD'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tugas'));
    await tester.pumpAndSettle();
    expect(find.text('Tugas ERD'), findsOneWidget);
    expect(find.text('Catatan Flutter'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'detail tugas');
    await tester.pumpAndSettle();
    expect(find.text('Tugas ERD'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'not found');
    await tester.pumpAndSettle();
    expect(find.text('Tugas ERD'), findsNothing);
    expect(find.text('Belum ada catatan atau tugas.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Tugas ERD'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('edit and delete controls open their confirmation forms', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    final note = _note(
      title: 'Tugas ERD',
      type: 'tugas',
      course: 'Basis Data',
      week: 4,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatatanPage(
            loadNotes: () async => [note],
            loadSchedules: () async => [_schedule('Basis Data')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Edit catatan Tugas ERD'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Item'), findsOneWidget);
    expect(find.text('Tugas ERD'), findsNWidgets(2));
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Hapus catatan Tugas ERD'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Tugas?'), findsOneWidget);
    expect(
      find.text('Item "Tugas ERD" akan dihapus permanen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Tugas ERD'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('reloads notes when the page becomes active', (tester) async {
    var loadCount = 0;
    Future<List<Catatan>> loadNotes() async {
      loadCount++;
      return [_note(title: 'Catatan Aktif', type: 'catatan', course: 'Umum')];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatatanPage(
            isActive: false,
            loadNotes: loadNotes,
            loadSchedules: _emptySchedules,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loadCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatatanPage(
            isActive: true,
            loadNotes: loadNotes,
            loadSchedules: _emptySchedules,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loadCount, 2);
    expect(find.text('Catatan Aktif'), findsOneWidget);
  });
}

Future<List<Catatan>> _emptyNotes() async => [];
Future<List<Jadwal>> _emptySchedules() async => [];
