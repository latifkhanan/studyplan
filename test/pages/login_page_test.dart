import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyplan/pages/login_page.dart';
import 'package:studyplan/services/auth_service.dart';

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

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.loginSucceeds = false, this.googleCancelled = false});

  final bool loginSucceeds;
  final bool googleCancelled;

  @override
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    if (loginSucceeds) return null;
    throw 'Email atau kata sandi yang Anda masukkan salah.';
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    if (googleCancelled) return null;
    throw 'Google Sign-In gagal.';
  }
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    FirebaseAuthPlatform.instance = _TestFirebaseAuthPlatform();
    await Firebase.initializeApp();
  });

  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(authService: _FakeAuthService(), onLoginSuccess: () {}),
      ),
    );
    await tester.pump();
  }

  testWidgets('menampilkan validasi saat login tanpa input', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Masukkan email Anda'), findsOneWidget);
    expect(find.text('Masukkan kata sandi Anda'), findsOneWidget);
  });

  testWidgets('toggle kata sandi mengubah mode tersembunyi', (tester) async {
    await pumpLoginPage(tester);

    final passwordField = find.byType(EditableText).at(1);
    expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('membuka halaman lupa kata sandi', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();

    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
  });

  testWidgets('membuka halaman registrasi', (tester) async {
    await pumpLoginPage(tester);

    await tester.ensureVisible(find.text('Daftar Sekarang'));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Akun Baru'), findsOneWidget);
  });

  testWidgets('menampilkan error saat login gagal', (tester) async {
    await pumpLoginPage(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(
      find.text('Email atau kata sandi yang Anda masukkan salah.'),
      findsOneWidget,
    );
  });

  testWidgets('menampilkan error saat login Google gagal', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pump();

    expect(find.text('Google Sign-In gagal.'), findsOneWidget);
  });

  testWidgets('memanggil callback setelah login berhasil', (tester) async {
    var loginSucceeded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authService: _FakeAuthService(loginSucceeds: true),
          onLoginSuccess: () => loginSucceeded = true,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(loginSucceeded, isTrue);
    expect(
      find.text('Login berhasil! Selamat datang di StudyPlan.'),
      findsOneWidget,
    );
  });

  testWidgets('tidak memanggil callback saat login Google dibatalkan', (
    tester,
  ) async {
    var loginSucceeded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authService: _FakeAuthService(googleCancelled: true),
          onLoginSuccess: () => loginSucceeded = true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pump();

    expect(loginSucceeded, isFalse);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
  });
}
