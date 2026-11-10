import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/pages/home_page.dart';

class _TestFirebaseAuthPlatform extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser => null;
}

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    FirebaseAuthPlatform.instance = _TestFirebaseAuthPlatform();
    await Firebase.initializeApp();
  });

  testWidgets('dashboard menampilkan seluruh jadwal terdaftar', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    final schedules = [
      Jadwal(
        mataKuliah: 'Pemrograman Mobile',
        jamMulai: '08.00',
        jamSelesai: '09.40',
        ruangan: 'A101',
        dosen: 'Dosen Mobile',
        hari: 'Senin',
        tanggal: _today(),
      ),
      Jadwal(
        mataKuliah: 'Basis Data',
        jamMulai: '10.00',
        jamSelesai: '11.40',
        ruangan: 'B202',
        dosen: 'Dosen Database',
        hari: 'Selasa',
        tanggal: '2099-01-01',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            loadTodaySchedules: ({required tanggal, required hari}) async => [
              schedules.first,
            ],
            loadAllSchedules: () async => schedules,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Hari Ini'), findsOneWidget);
    expect(find.text('Seluruh Jadwal'), findsOneWidget);
    expect(find.text('2 jadwal terdaftar'), findsOneWidget);
    expect(find.text('Pemrograman Mobile'), findsNWidgets(2));
    expect(find.text('Basis Data'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('dashboard menampilkan kondisi tanpa jadwal', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            loadTodaySchedules: ({required tanggal, required hari}) async => [],
            loadAllSchedules: () async => [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada jadwal yang didaftarkan.'), findsOneWidget);
    expect(find.text('0 jadwal terdaftar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
