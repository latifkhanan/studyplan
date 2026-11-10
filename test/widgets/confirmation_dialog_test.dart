import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/widgets/delete_confirmation_dialog.dart';
import 'package:studyplan/widgets/logout_confirmation_dialog.dart';

void main() {
  testWidgets('delete schedule dialog displays details and returns choice', (
    tester,
  ) async {
    bool? result;
    final jadwal = Jadwal(
      mataKuliah: 'Basis Data',
      jamMulai: '08.00',
      jamSelesai: '09.40',
      ruangan: 'A101',
      dosen: 'Dosen',
      hari: 'Senin',
      tanggal: '2026-10-20',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDeleteConfirmationDialog(context, jadwal);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus jadwal?'), findsOneWidget);
    expect(find.text('Basis Data'), findsOneWidget);
    expect(find.text('Senin, 20 Oktober 2026'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('delete schedule dialog confirms deletion', (tester) async {
    bool? result;
    final jadwal = Jadwal(
      mataKuliah: 'Pemrograman',
      jamMulai: '08.00',
      jamSelesai: '09.40',
      ruangan: 'A101',
      dosen: 'Dosen',
      hari: 'Senin',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDeleteConfirmationDialog(context, jadwal);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus Jadwal'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('logout confirmation shows optional account details', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showLogoutConfirmationDialog(
                context,
                userName: 'Latif',
                userEmail: 'latif@example.com',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    expect(find.text('Latif'), findsOneWidget);
    expect(find.text('latif@example.com'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);

    await tester.tap(find.text('Keluar Akun'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('logout confirmation works without account details', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showLogoutConfirmationDialog(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
