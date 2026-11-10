import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/models/catatan.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/widgets/catatan_dialog.dart';

void main() {
  testWidgets('catatan dialog validates and creates a note or task', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    final notes = <Catatan>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatatanDialog(
            jadwal: _schedule,
            loadNotes: (_) async => notes,
            insertNote: (note) async {
              notes.add(note.copyWith(id: 1));
              return 1;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada catatan atau tugas.'), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
    expect(find.text('Isi tidak boleh kosong'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Tugas ERD');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Buat diagram entitas.',
    );
    await tester.tap(find.text('Tugas'));
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(notes, hasLength(1));
    expect(notes.single.mataKuliah, 'Basis Data');
    expect(notes.single.tipe, 'tugas');
    expect(find.text('Tugas ERD'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('catatan dialog edits and deletes existing notes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    final notes = [
      Catatan(
        id: 8,
        mataKuliah: 'Basis Data',
        mingguKe: 3,
        judul: 'Ringkasan Lama',
        isi: 'Detail lama',
        tanggal: '2026-10-20',
        waktu: '10.00',
        tipe: 'catatan',
        createdAt: '2026-10-20T10:00:00',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatatanDialog(
            jadwal: _schedule,
            loadNotes: (_) async => notes,
            updateNote: (note) async {
              notes[0] = note;
              return 1;
            },
            deleteNote: (id, {docId}) async {
              notes.removeWhere((note) => note.id == id);
              return 1;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Edit Item'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Ringkasan Baru');
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(notes.single.judul, 'Ringkasan Baru');
    expect(find.text('Ringkasan Baru'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(notes, isEmpty);
    expect(find.text('Belum ada catatan atau tugas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}

final _schedule = Jadwal(
  mataKuliah: 'Basis Data',
  jamMulai: '08.00',
  jamSelesai: '09.40',
  ruangan: 'A101',
  dosen: 'Dosen Basis Data',
  id: 12,
  docId: 'schedule-doc',
);
