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

  test('jadwal dapat difilter berdasarkan tanggal dan hari', () async {
    final first = Jadwal(
      mataKuliah: 'Basis Data',
      jamMulai: '08.00',
      jamSelesai: '09.40',
      ruangan: 'A101',
      dosen: 'Dosen 1',
      hari: 'Senin',
      tanggal: '2099-01-05',
    );
    final second = Jadwal(
      mataKuliah: 'Pemrograman',
      jamMulai: '10.00',
      jamSelesai: '11.40',
      ruangan: 'A102',
      dosen: 'Dosen 2',
      hari: 'Senin',
      tanggal: '2099-01-12',
    );
    final third = Jadwal(
      mataKuliah: 'Jaringan',
      jamMulai: '12.00',
      jamSelesai: '13.40',
      ruangan: 'A103',
      dosen: 'Dosen 3',
      hari: 'Selasa',
      tanggal: '2099-01-06',
    );
    await database.insertJadwal(first);
    await database.insertJadwal(second);
    await database.insertJadwal(third);

    expect(await database.getJadwalByTanggal('2099-01-05'), hasLength(1));
    expect(await database.getJadwalByHari('Senin'), hasLength(2));
    expect(
      (await database.getJadwalForDate(
        tanggal: '2099-01-05',
        hari: 'Senin',
      )).single.mataKuliah,
      'Basis Data',
    );
    expect(
      (await database.getJadwalForDate(
        tanggal: '2099-01-19',
        hari: 'Senin',
      )).map((item) => item.mataKuliah),
      ['Basis Data', 'Pemrograman'],
    );
    expect(
      await database.getDatesWithJadwal(),
      containsAll(['2099-01-05', '2099-01-12', '2099-01-06']),
    );
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

  test(
    'catatan dapat difilter berdasarkan mata kuliah dan urutan minggu',
    () async {
      await database.insertCatatan(
        Catatan(
          mataKuliah: 'Basis Data',
          mingguKe: 3,
          judul: 'Normalisasi',
          isi: 'Detail',
          tanggal: '2099-01-03',
          waktu: '10.00',
          createdAt: '2099-01-03T10:00:00',
        ),
      );
      await database.insertCatatan(
        Catatan(
          mataKuliah: 'Basis Data',
          mingguKe: 1,
          judul: 'ERD',
          isi: 'Detail',
          tanggal: '2099-01-01',
          waktu: '10.00',
          createdAt: '2099-01-01T10:00:00',
        ),
      );
      await database.insertCatatan(
        Catatan(
          mataKuliah: 'Pemrograman',
          mingguKe: 1,
          judul: 'Flutter',
          isi: 'Detail',
          tanggal: '2099-01-02',
          waktu: '10.00',
          createdAt: '2099-01-02T10:00:00',
        ),
      );

      expect(
        (await database.getCatatanByMataKuliah('Basis Data'))
            .map((item) => item.judul),
        ['ERD', 'Normalisasi'],
      );
      expect(await database.getAllCatatan(), hasLength(3));
      expect(await database.getCatatanByMataKuliah('Tidak ada'), isEmpty);
    },
  );
}
