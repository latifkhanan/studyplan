import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studyplan/models/catatan.dart';
import 'package:studyplan/models/jadwal.dart';
import 'package:studyplan/services/database_service.dart';

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
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService database;
  late String databaseName;

  setUp(() {
    databaseName = 'studyplan_test_${DateTime.now().microsecondsSinceEpoch}.db';
    database = DatabaseService.forTesting(databaseName);
  });

  tearDown(() async {
    await database.closeForTesting();
    await databaseFactory.deleteDatabase(
      path.join(await getDatabasesPath(), databaseName),
    );
  });

  test('CRUD jadwal berjalan pada database lokal', () async {
    final jadwal = Jadwal(
      mataKuliah: 'Pemrograman Mobile',
      jamMulai: '08.00',
      jamSelesai: '09.40',
      ruangan: 'A101',
      dosen: 'Dosen Mobile',
      hari: 'Senin',
      tanggal: '2099-01-01',
    );

    final insertedId = await database.insertJadwal(jadwal);
    final inserted = await database.getAllJadwal();
    expect(insertedId, greaterThan(0));
    expect(inserted, hasLength(1));
    expect(inserted.single.mataKuliah, 'Pemrograman Mobile');

    final updatedJadwal = inserted.single.copyWith(
      mataKuliah: 'Pemrograman Mobile Lanjutan',
    );
    expect(await database.updateJadwal(updatedJadwal), 1);
    expect(
      (await database.getAllJadwal()).single.mataKuliah,
      'Pemrograman Mobile Lanjutan',
    );

    expect(await database.deleteJadwal(insertedId), 1);
    expect(await database.getAllJadwal(), isEmpty);
  });

  test('CRUD catatan berjalan pada database lokal', () async {
    final catatan = Catatan(
      mataKuliah: 'Basis Data',
      judul: 'Normalisasi',
      isi: 'Pelajari bentuk normal pertama sampai ketiga.',
      tanggal: '2099-01-01',
      waktu: '10.00',
      createdAt: '2099-01-01T10:00:00.000',
    );

    final insertedId = await database.insertCatatan(catatan);
    final inserted = await database.getAllCatatan();
    expect(insertedId, greaterThan(0));
    expect(inserted, hasLength(1));
    expect(inserted.single.judul, 'Normalisasi');

    final updatedCatatan = inserted.single.copyWith(
      judul: 'Normalisasi Database',
    );
    expect(await database.updateCatatan(updatedCatatan), 1);
    expect(
      (await database.getAllCatatan()).single.judul,
      'Normalisasi Database',
    );

    expect(await database.deleteCatatan(insertedId), 1);
    expect(await database.getAllCatatan(), isEmpty);
  });
}
