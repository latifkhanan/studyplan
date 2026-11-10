import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:studyplan/services/auth_service.dart';

class _FakeFirebaseAuthPlatform extends FirebaseAuthPlatform {
  Object? createUserError;
  bool createUserSucceeds = false;
  UserPlatform? credentialUser;
  UserPlatform? signedInUser;
  Object? loginError;
  bool loginSucceeds = false;
  Object? resetPasswordError;

  @override
  Stream<UserPlatform?> authStateChanges() => Stream.value(null);

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser => signedInUser;

  @override
  set currentUser(UserPlatform? user) => signedInUser = user;

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (createUserSucceeds) {
      return _FakeUserCredential(auth: this, user: credentialUser);
    }
    throw createUserError ??
        FirebaseAuthException(code: 'weak-password', message: 'weak');
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (loginSucceeds) return _FakeUserCredential(auth: this);
    throw loginError ??
        FirebaseAuthException(code: 'user-not-found', message: 'missing');
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
    AuthCredential credential,
  ) async => _FakeUserCredential(auth: this, user: credentialUser);

  @override
  Future<void> sendPasswordResetEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    throw resetPasswordError ??
        FirebaseAuthException(code: 'invalid-email', message: 'invalid');
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUserCredential extends UserCredentialPlatform {
  _FakeUserCredential({required super.auth, super.user});
}

class _FakeFirestorePlatform extends FirebaseFirestorePlatform {
  _FakeFirestorePlatform(FirebaseApp app) : super(appInstance: app);

  bool throwOnCollection = false;
  String? duplicateNimOwner;
  Map<String, dynamic>? profileData;
  final Map<String, Map<String, dynamic>> savedDocuments = {};

  @override
  FirebaseFirestorePlatform delegateFor({
    required FirebaseApp app,
    required String databaseId,
  }) => this;

  @override
  CollectionReferencePlatform collection(String collectionPath) {
    if (throwOnCollection) {
      throw FirebaseException(plugin: 'cloud_firestore', message: 'offline');
    }
    return _FakeCollectionReferencePlatform(this, collectionPath);
  }

  @override
  DocumentReferencePlatform doc(String documentPath) {
    return _FakeDocumentReferencePlatform(this, documentPath);
  }
}

class _FakeCollectionReferencePlatform extends CollectionReferencePlatform {
  _FakeCollectionReferencePlatform(super.firestore, super.path);

  @override
  Map<String, dynamic> get parameters => {
    'where': <List<dynamic>>[],
    'orderBy': <List<dynamic>>[],
    'startAt': null,
    'startAfter': null,
    'endAt': null,
    'endBefore': null,
    'limit': null,
    'limitToLast': null,
  };

  @override
  DocumentReferencePlatform doc([String? path]) {
    return _FakeDocumentReferencePlatform(
      firestore,
      '${this.path}/${path ?? 'generated'}',
    );
  }

  @override
  QueryPlatform where(List<List<dynamic>> conditions) => this;

  @override
  QueryPlatform limit(int limit) => this;

  @override
  Future<QuerySnapshotPlatform> get([
    GetOptions options = const GetOptions(),
  ]) async {
    final firestore = this.firestore as _FakeFirestorePlatform;
    final docs = <DocumentSnapshotPlatform>[];
    final duplicateOwner = firestore.duplicateNimOwner;
    if (duplicateOwner != null) {
      docs.add(
        DocumentSnapshotPlatform(firestore, '$path/$duplicateOwner', {
          'nim': '123',
        }, PigeonSnapshotMetadata(hasPendingWrites: false, isFromCache: false)),
      );
    }
    return QuerySnapshotPlatform(
      docs,
      [],
      SnapshotMetadataPlatform(false, false),
    );
  }
}

class _FakeDocumentReferencePlatform extends DocumentReferencePlatform {
  _FakeDocumentReferencePlatform(super.firestore, super.path);

  @override
  Future<DocumentSnapshotPlatform> get([
    GetOptions options = const GetOptions(),
  ]) async {
    final firestore = this.firestore as _FakeFirestorePlatform;
    return DocumentSnapshotPlatform(
      firestore,
      path,
      firestore.profileData,
      PigeonSnapshotMetadata(hasPendingWrites: false, isFromCache: false),
    );
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final firestore = this.firestore as _FakeFirestorePlatform;
    firestore.savedDocuments[path] = Map<String, dynamic>.from(data);
  }
}

class _FakeMultiFactorPlatform extends MultiFactorPlatform {
  _FakeMultiFactorPlatform(super.auth);
}

class _FakeUserPlatform extends UserPlatform {
  _FakeUserPlatform(super.auth, super.multiFactor, super.user);

  String? _displayName;

  @override
  String? get displayName => _displayName ?? super.displayName;

  @override
  Future<void> updateProfile(Map<String, String?> profile) async {
    _displayName = profile['displayName'];
  }
}

_FakeUserPlatform _makeUser(_FakeFirebaseAuthPlatform auth) {
  final userInfo = PigeonUserInfo(
    uid: 'user-id',
    email: 'user@test.com',
    displayName: 'Tester',
    isAnonymous: false,
    isEmailVerified: true,
  );
  return _FakeUserPlatform(
    auth,
    _FakeMultiFactorPlatform(auth),
    PigeonUserDetails(userInfo: userInfo, providerData: []),
  );
}

class _FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  Object? signInError;
  GoogleSignInUserData? signedInUser;

  @override
  Future<void> init({
    List<String> scopes = const [],
    SignInOption signInOption = SignInOption.standard,
    String? hostedDomain,
    String? clientId,
  }) async {}

  @override
  Future<GoogleSignInUserData?> signIn() async {
    if (signInError != null) throw signInError!;
    return signedInUser;
  }

  @override
  Future<GoogleSignInTokenData> getTokens({
    required String email,
    bool? shouldRecoverAuth,
  }) async =>
      GoogleSignInTokenData(idToken: 'id-token', accessToken: 'access-token');

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeFirebaseAuthPlatform platform;
  late _FakeFirestorePlatform firestore;
  late _FakeGoogleSignInPlatform googlePlatform;

  setUpAll(() async {
    setupFirebaseCoreMocks();
    platform = _FakeFirebaseAuthPlatform();
    FirebaseAuthPlatform.instance = platform;
    await Firebase.initializeApp();
    firestore = _FakeFirestorePlatform(Firebase.app());
    FirebaseFirestorePlatform.instance = firestore;
    googlePlatform = _FakeGoogleSignInPlatform();
    GoogleSignInPlatform.instance = googlePlatform;
  });

  setUp(() {
    platform.createUserError = null;
    platform.createUserSucceeds = false;
    platform.loginError = null;
    platform.loginSucceeds = false;
    platform.resetPasswordError = null;
    platform.credentialUser = null;
    platform.signedInUser = null;
    firestore.throwOnCollection = false;
    firestore.duplicateNimOwner = null;
    firestore.profileData = null;
    firestore.savedDocuments.clear();
    googlePlatform.signInError = null;
    googlePlatform.signedInUser = null;
  });

  test('authStateChanges meneruskan stream status autentikasi', () async {
    expect(await AuthService().authStateChanges.first, isNull);
  });

  test('getUserProfile mengembalikan null jika belum login', () async {
    expect(await AuthService().getUserProfile(), isNull);
  });

  test('getUserProfile mengembalikan profil dari Firestore', () async {
    platform.signedInUser = _makeUser(platform);
    firestore.profileData = {'nama': 'Tester', 'nim': '123'};

    expect(await AuthService().getUserProfile(), firestore.profileData);
  });

  test('updateUserProfile tidak melakukan operasi jika belum login', () async {
    await AuthService().updateUserProfile(
      nama: 'Tester',
      nim: '123',
      prodi: 'Sistem Informasi',
    );
  });

  test('updateUserProfile menyimpan perubahan jika NIM tersedia', () async {
    platform.signedInUser = _makeUser(platform);

    await AuthService().updateUserProfile(
      nama: 'Nama Baru',
      nim: ' 456 ',
      prodi: 'Informatika',
    );

    expect(
      firestore.savedDocuments['users/user-id'],
      containsPair('nim', '456'),
    );
    expect(
      firestore.savedDocuments['users/user-id'],
      containsPair('nama', 'Nama Baru'),
    );
  });

  test('updateUserProfile menolak NIM milik pengguna lain', () async {
    platform.signedInUser = _makeUser(platform);
    firestore.duplicateNimOwner = 'another-user';

    await expectLater(
      AuthService().updateUserProfile(
        nama: 'Tester',
        nim: '123',
        prodi: 'Sistem Informasi',
      ),
      throwsA('NIM sudah terdaftar. Silakan gunakan NIM lain.'),
    );
  });

  test('login memetakan kredensial tidak valid ke pesan pengguna', () async {
    await expectLater(
      AuthService().login(email: 'x@y.com', password: 'secret'),
      throwsA('Email atau kata sandi yang Anda masukkan salah.'),
    );
  });

  test('login meneruskan pesan error Firebase lainnya', () async {
    platform.loginError = FirebaseAuthException(
      code: 'invalid-email',
      message: 'Format email salah',
    );

    await expectLater(
      AuthService().login(email: 'bad', password: 'secret'),
      throwsA('Format email salah'),
    );
  });

  test(
    'login memakai pesan bawaan saat Firebase tidak memberi pesan',
    () async {
      platform.loginError = FirebaseAuthException(code: 'unknown');

      await expectLater(
        AuthService().login(email: 'bad', password: 'secret'),
        throwsA('Gagal masuk. Periksa kembali email dan kata sandi Anda.'),
      );
    },
  );

  test('login menangani error tak terduga', () async {
    platform.loginError = Exception('offline');

    await expectLater(
      AuthService().login(email: 'user@test.com', password: 'password'),
      throwsA('Terjadi kesalahan saat mencoba masuk.'),
    );
  });

  test('login berhasil mengembalikan credential', () async {
    platform.loginSucceeds = true;

    expect(
      await AuthService().login(email: 'user@test.com', password: 'password'),
      isNotNull,
    );
  });

  test('register memetakan password lemah', () async {
    await expectLater(
      AuthService().register(
        email: 'user@test.com',
        password: '123',
        nama: 'Tester',
        nim: '',
        prodi: 'Sistem Informasi',
      ),
      throwsA('Kata sandi terlalu lemah. Gunakan minimal 6 karakter.'),
    );
  });

  test('register berhasil ketika Firebase mengembalikan credential', () async {
    platform.createUserSucceeds = true;

    expect(
      await AuthService().register(
        email: ' USER@TEST.COM ',
        password: 'password',
        nama: 'Tester',
        nim: '',
        prodi: 'Sistem Informasi',
      ),
      isNotNull,
    );
  });

  test('register menyimpan profil setelah NIM lolos verifikasi', () async {
    platform.createUserSucceeds = true;
    platform.credentialUser = _makeUser(platform);

    await AuthService().register(
      email: ' USER@TEST.COM ',
      password: 'password',
      nama: 'Tester',
      nim: '123',
      prodi: 'Sistem Informasi',
    );

    expect(
      firestore.savedDocuments['users/user-id'],
      containsPair('email', 'user@test.com'),
    );
    expect(
      firestore.savedDocuments['users/user-id'],
      containsPair('nim', '123'),
    );
  });

  test('register menolak NIM yang sudah dipakai', () async {
    firestore.duplicateNimOwner = 'another-user';

    await expectLater(
      AuthService().register(
        email: 'user@test.com',
        password: 'password',
        nama: 'Tester',
        nim: '123',
        prodi: 'Sistem Informasi',
      ),
      throwsA('NIM sudah terdaftar. Silakan gunakan NIM lain.'),
    );
  });

  test('register memetakan email yang sudah terdaftar', () async {
    platform.createUserError = FirebaseAuthException(
      code: 'email-already-in-use',
    );

    await expectLater(
      AuthService().register(
        email: 'user@test.com',
        password: 'password',
        nama: 'Tester',
        nim: '',
        prodi: 'Sistem Informasi',
      ),
      throwsA('Email sudah terdaftar. Silakan gunakan email lain atau masuk.'),
    );
  });

  test('register memetakan email tidak valid', () async {
    platform.createUserError = FirebaseAuthException(code: 'invalid-email');

    await expectLater(
      AuthService().register(
        email: 'bad',
        password: 'password',
        nama: 'Tester',
        nim: '',
        prodi: 'Sistem Informasi',
      ),
      throwsA('Format email tidak valid.'),
    );
  });

  test('register memetakan error Firebase tanpa pesan', () async {
    platform.createUserError = FirebaseAuthException(code: 'unknown');

    await expectLater(
      AuthService().register(
        email: 'user@test.com',
        password: 'password',
        nama: 'Tester',
        nim: '',
        prodi: 'Sistem Informasi',
      ),
      throwsA('Terjadi kesalahan saat registrasi.'),
    );
  });

  test(
    'register gagal dengan pesan jelas jika NIM tidak dapat diverifikasi',
    () async {
      firestore.throwOnCollection = true;

      await expectLater(
        AuthService().register(
          email: 'user@test.com',
          password: 'password',
          nama: 'Tester',
          nim: '123',
          prodi: 'Sistem Informasi',
        ),
        throwsA('NIM tidak dapat diverifikasi. Periksa koneksi internet Anda.'),
      );
    },
  );

  test('register menangani error tak terduga', () async {
    platform.createUserError = Exception('offline');

    await expectLater(
      AuthService().register(
        email: 'user@test.com',
        password: 'password',
        nama: 'Tester',
        nim: '',
        prodi: 'Sistem Informasi',
      ),
      throwsA('Terjadi kesalahan tidak terduga.'),
    );
  });

  test('reset password meneruskan pesan Firebase', () async {
    await expectLater(
      AuthService().sendPasswordResetEmail('bad'),
      throwsA('invalid'),
    );
  });

  test('reset password menangani error tak terduga', () async {
    platform.resetPasswordError = Exception('offline');

    await expectLater(
      AuthService().sendPasswordResetEmail('user@test.com'),
      throwsA('Terjadi kesalahan saat mengirim permintaan reset kata sandi.'),
    );
  });

  test(
    'reset password memakai pesan bawaan jika Firebase tidak memberi pesan',
    () async {
      platform.resetPasswordError = FirebaseAuthException(code: 'unknown');

      await expectLater(
        AuthService().sendPasswordResetEmail('user@test.com'),
        throwsA('Gagal mengirim email reset kata sandi.'),
      );
    },
  );

  test('reset password meneruskan error string', () async {
    platform.resetPasswordError = 'Koneksi lambat.';

    await expectLater(
      AuthService().sendPasswordResetEmail('user@test.com'),
      throwsA('Koneksi lambat.'),
    );
  });

  test('logout menyelesaikan sesi Firebase', () async {
    await AuthService().logout();
  });

  test('Google login mengembalikan null saat pengguna membatalkan', () async {
    expect(await AuthService().signInWithGoogle(), isNull);
  });

  test('Google login berhasil mendapatkan credential', () async {
    googlePlatform.signedInUser = GoogleSignInUserData(
      email: 'user@test.com',
      id: 'google-user',
      displayName: 'Tester',
    );
    platform.credentialUser = _makeUser(platform);
    firestore.profileData = null;

    expect(await AuthService().signInWithGoogle(), isNotNull);
    expect(
      firestore.savedDocuments['users/user-id'],
      containsPair('nama', 'Tester'),
    );
  });

  test('Google login mempertahankan data profil yang sudah ada', () async {
    googlePlatform.signedInUser = GoogleSignInUserData(
      email: 'google@test.com',
      id: 'google-user',
      displayName: 'Google Name',
    );
    platform.credentialUser = _makeUser(platform);
    firestore.profileData = {'nama': 'Nama Tersimpan', 'nim': '321'};

    await AuthService().signInWithGoogle();

    expect(
      firestore.savedDocuments['users/user-id'],
      containsPair('nama', 'Nama Tersimpan'),
    );
    expect(
      firestore.savedDocuments['users/user-id'],
      containsPair('nim', '321'),
    );
  });

  test('Google login memetakan kegagalan platform', () async {
    googlePlatform.signInError = PlatformException(code: 'sign_in_failed');

    await expectLater(
      AuthService().signInWithGoogle(),
      throwsA(
        'Google Sign-In gagal. Pastikan SHA-1 Fingerprint telah didaftarkan di Firebase Console.',
      ),
    );
  });
}
