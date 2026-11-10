import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/pages/form_jadwal_page.dart';
import 'package:studyplan/pages/jadwal_page.dart';

void main() {
  testWidgets('calendar navigates months and loads the selected day', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    var selectedDayLoads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JadwalPage(
            loadSchedulesForDate: ({required tanggal, required hari}) async {
              selectedDayLoads++;
              if (selectedDayLoads == 1) return [];
              return [
                Jadwal(
                  mataKuliah: 'Basis Data',
                  jamMulai: '08.00',
                  jamSelesai: '09.40',
                  ruangan: 'A101',
                  dosen: 'Dosen Basis Data',
                  hari: hari,
                  tanggal: tanggal,
                ),
              ];
            },
            loadDatesWithSchedules: () async => [],
            loadAllSchedules: () async => [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Kuliah'), findsOneWidget);
    expect(find.text('Tidak ada kelas pada tanggal ini.'), findsOneWidget);
    final before = selectedDayLoads;

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(selectedDayLoads, before);

    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    expect(selectedDayLoads, before + 1);
    expect(find.text('Basis Data'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('calendar page reloads when activated', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    var loads = 0;
    Future<List<Jadwal>> loadDay({
      required String tanggal,
      required String hari,
    }) async {
      loads++;
      return [];
    }

    Widget page(bool isActive) => MaterialApp(
      home: Scaffold(
        body: JadwalPage(
          isActive: isActive,
          loadSchedulesForDate: loadDay,
          loadDatesWithSchedules: () async => [],
          loadAllSchedules: () async => [],
        ),
      ),
    );

    await tester.pumpWidget(page(false));
    await tester.pumpAndSettle();
    expect(loads, 1);

    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(loads, 2);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('schedule form validates inputs and alarm reminder selection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormJadwalPage(selectedDate: DateTime(2026, 10, 20)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah Jadwal'), findsOneWidget);
    expect(find.text('Selasa, 20 Oktober 2026'), findsOneWidget);
    await tester.ensureVisible(find.text('Simpan Jadwal'));
    await tester.tap(find.text('Simpan Jadwal'));
    await tester.pumpAndSettle();
    expect(find.text('Mata kuliah tidak boleh kosong'), findsOneWidget);
    expect(find.text('Nama dosen tidak boleh kosong'), findsOneWidget);
    expect(find.text('Ruang kuliah tidak boleh kosong'), findsOneWidget);

    await tester.tap(find.text('10 Menit'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih minimal satu waktu pengingat.'), findsOneWidget);

    await tester.tap(find.text('15 Menit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 Menit'));
    await tester.pumpAndSettle();
    expect(find.text('15 Menit'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Bunyikan Alarm Sebelum Kelas:'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'editing form initializes existing values and date/time pickers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      final item = Jadwal(
        mataKuliah: 'Basis Data',
        jamMulai: '08.00',
        jamSelesai: '09.40',
        ruangan: 'A101',
        dosen: 'Dosen Lama',
        hari: 'Selasa',
        tanggal: '2026-10-20',
        isAlarmActive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormJadwalPage(jadwal: item)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Jadwal'), findsOneWidget);
      expect(find.text('Selasa, 20 Oktober 2026'), findsOneWidget);
      expect(find.text('08.00'), findsOneWidget);
      expect(find.text('09.40'), findsOneWidget);
      expect(find.text('Dosen Lama'), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.calendar_today_outlined));
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final timeButton = find.byIcon(Icons.access_time_rounded).first;
      await tester.ensureVisible(timeButton);
      await tester.tap(timeButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );
}
