import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyplan/pages/pengaturan_page.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    FirebaseAuthPlatform.instance = _TestFirebaseAuthPlatform();
    await Firebase.initializeApp();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('settings page displays defaults and reports theme changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1500));
    final selectedThemes = <AppThemeMode>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PengaturanPage(
            currentTheme: AppThemeMode.sistem,
            onThemeChanged: selectedThemes.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Profil Pengguna'), findsOneWidget);
    expect(find.text('Nada Dering / Suara Alarm'), findsOneWidget);
    expect(find.text('Tema aplikasi'), findsOneWidget);
    expect(find.text('Pengguna StudyPlan'), findsOneWidget);

    await tester.ensureVisible(find.text('Gelap'));
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(selectedThemes, [AppThemeMode.gelap]);

    await tester.ensureVisible(find.text('Terang'));
    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();
    expect(selectedThemes, [AppThemeMode.gelap, AppThemeMode.terang]);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('logout action supports cancellation and confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1500));
    var logoutCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PengaturanPage(
            currentTheme: AppThemeMode.terang,
            onThemeChanged: (_) {},
            onLogout: () => logoutCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Keluar dari Akun'));
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(logoutCount, 0);

    await tester.ensureVisible(find.text('Keluar dari Akun'));
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar Akun'));
    await tester.pumpAndSettle();
    expect(logoutCount, 1);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('profile form validates and updates the displayed profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1500));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PengaturanPage(
            currentTheme: AppThemeMode.terang,
            onThemeChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Edit Profil'));
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profil Pengguna'), findsOneWidget);

    for (var index = 0; index < 4; index++) {
      await tester.enterText(find.byType(TextFormField).at(index), '');
    }
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    expect(find.text('NIM tidak boleh kosong'), findsOneWidget);
    expect(find.text('Program Studi tidak boleh kosong'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Latif Khan');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'latif@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '12345678');
    await tester.enterText(find.byType(TextFormField).at(3), 'Informatika');
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Latif Khan'), findsOneWidget);
    expect(find.text('NIM: 12345678 • Informatika'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('ringtone picker displays built-in and custom choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_ringtone_sound': 'custom_file',
      'custom_ringtone_file_name': 'alarm.mp3',
    });
    await tester.binding.setSurfaceSize(const Size(900, 1500));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PengaturanPage(
            currentTheme: AppThemeMode.terang,
            onThemeChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Nada Dering / Suara Alarm'));
    await tester.tap(find.text('Nada Dering / Suara Alarm'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Nada Dering Alarm'), findsOneWidget);
    expect(find.text('🔔 Nada Alarm Standar HP'), findsWidgets);
    expect(find.text('🎵 Nada Notifikasi Standar HP'), findsOneWidget);
    expect(find.text('⏰ Alarm Digital Melodi'), findsOneWidget);
    expect(find.text('🍃 Chime Lembut'), findsOneWidget);
    expect(find.text('🎶 File Kustom: alarm.mp3'), findsNWidgets(2));
    expect(find.text('Pilih File Musik/MP3 dari HP...'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(null);
  });
}
