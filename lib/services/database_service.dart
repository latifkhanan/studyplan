import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/jadwal.dart';
import '../models/catatan.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('studyplan_v6.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE jadwal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        docId TEXT,
        userId TEXT,
        mataKuliah TEXT NOT NULL,
        jamMulai TEXT NOT NULL,
        jamSelesai TEXT NOT NULL,
        ruangan TEXT NOT NULL,
        dosen TEXT NOT NULL,
        hari TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        isAlarmActive INTEGER DEFAULT 1,
        alarmMinutesBefore INTEGER DEFAULT 10,
        alarmMinutesList TEXT DEFAULT '10'
      )
    ''');

    await db.execute('''
      CREATE TABLE catatan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        docId TEXT,
        userId TEXT,
        jadwalId TEXT,
        mataKuliah TEXT NOT NULL,
        mingguKe INTEGER DEFAULT 1,
        judul TEXT NOT NULL,
        isi TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        waktu TEXT NOT NULL,
        tipe TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE jadwal ADD COLUMN isAlarmActive INTEGER DEFAULT 1',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE jadwal ADD COLUMN alarmMinutesBefore INTEGER DEFAULT 10',
        );
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS catatan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          docId TEXT,
          userId TEXT,
          jadwalId TEXT,
          mataKuliah TEXT NOT NULL,
          mingguKe INTEGER DEFAULT 1,
          judul TEXT NOT NULL,
          isi TEXT NOT NULL,
          tanggal TEXT NOT NULL,
          waktu TEXT NOT NULL,
          tipe TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE catatan ADD COLUMN mingguKe INTEGER DEFAULT 1',
        );
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE jadwal ADD COLUMN alarmMinutesList TEXT DEFAULT '10'",
        );
      } catch (_) {}
    }
  }

  // ID pengguna aktif saat ini
  String get _currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  // Helper referensi koleksi Firestore user
  CollectionReference<Map<String, dynamic>>? _getUserJadwalCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('jadwal');
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>>? _getUserCatatanCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('catatan');
    }
    return null;
  }

  // ===================== JADWAL CRUD =====================

  // 1. Ambil Semua Jadwal milik Akun yang Sedang Login
  Future<List<Jadwal>> getAllJadwal() async {
    final uid = _currentUserId;
    final collection = _getUserJadwalCollection();

    if (collection != null) {
      try {
        final snapshot = await collection.get();
        final firestoreList = snapshot.docs.map((doc) {
          return Jadwal.fromMap(
            doc.data(),
            documentId: doc.id,
          ).copyWith(userId: uid);
        }).toList();

        final db = await instance.database;
        for (var item in firestoreList) {
          final existing = await db.query(
            'jadwal',
            where: 'userId = ? AND (docId = ? OR (mataKuliah = ? AND tanggal = ? AND jamMulai = ?))',
            whereArgs: [
              uid,
              item.docId,
              item.mataKuliah,
              item.tanggal,
              item.jamMulai,
            ],
          );
          if (existing.isEmpty) {
            await db.insert('jadwal', item.toMap());
          }
        }
      } catch (_) {}
    }

    final db = await instance.database;
    final result = await db.query(
      'jadwal',
      where: 'userId = ?',
      whereArgs: [uid],
      orderBy: 'jamMulai ASC',
    );
    return result.map((json) => Jadwal.fromMap(json)).toList();
  }

  // 2. Ambil Jadwal berdasarkan Tanggal
  Future<List<Jadwal>> getJadwalByTanggal(String tanggal) async {
    final uid = _currentUserId;
    final collection = _getUserJadwalCollection();

    if (collection != null) {
      try {
        final snapshot = await collection
            .where('tanggal', isEqualTo: tanggal)
            .get();

        final firestoreList = snapshot.docs.map((doc) {
          return Jadwal.fromMap(
            doc.data(),
            documentId: doc.id,
          ).copyWith(userId: uid);
        }).toList();

        final db = await instance.database;
        for (var item in firestoreList) {
          final existing = await db.query(
            'jadwal',
            where: 'userId = ? AND (docId = ? OR (mataKuliah = ? AND tanggal = ? AND jamMulai = ?))',
            whereArgs: [
              uid,
              item.docId,
              item.mataKuliah,
              item.tanggal,
              item.jamMulai,
            ],
          );
          if (existing.isEmpty) {
            await db.insert('jadwal', item.toMap());
          }
        }
      } catch (_) {}
    }

    final db = await instance.database;
    final result = await db.query(
      'jadwal',
      where: 'userId = ? AND tanggal = ?',
      whereArgs: [uid, tanggal],
      orderBy: 'jamMulai ASC',
    );
    return result.map((json) => Jadwal.fromMap(json)).toList();
  }

  // 3. Ambil Jadwal berdasarkan Hari
  Future<List<Jadwal>> getJadwalByHari(String hari) async {
    final uid = _currentUserId;
    final collection = _getUserJadwalCollection();

    if (collection != null) {
      try {
        final snapshot = await collection.where('hari', isEqualTo: hari).get();

        final firestoreList = snapshot.docs.map((doc) {
          return Jadwal.fromMap(
            doc.data(),
            documentId: doc.id,
          ).copyWith(userId: uid);
        }).toList();

        final db = await instance.database;
        for (var item in firestoreList) {
          final existing = await db.query(
            'jadwal',
            where: 'userId = ? AND (docId = ? OR (mataKuliah = ? AND tanggal = ? AND jamMulai = ?))',
            whereArgs: [
              uid,
              item.docId,
              item.mataKuliah,
              item.tanggal,
              item.jamMulai,
            ],
          );
          if (existing.isEmpty) {
            await db.insert('jadwal', item.toMap());
          }
        }
      } catch (_) {}
    }

    final db = await instance.database;
    final result = await db.query(
      'jadwal',
      where: 'userId = ? AND hari = ?',
      whereArgs: [uid, hari],
      orderBy: 'jamMulai ASC',
    );
    return result.map((json) => Jadwal.fromMap(json)).toList();
  }

  // 4. Ambil Daftar Tanggal yang Ada Jadwalnya
  Future<List<String>> getDatesWithJadwal() async {
    final uid = _currentUserId;
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT tanggal FROM jadwal WHERE userId = ?',
      [uid],
    );
    return result.map((row) => row['tanggal'] as String).toList();
  }

  // 5. Tambah Jadwal Baru
  Future<int> insertJadwal(Jadwal jadwal) async {
    final uid = _currentUserId;
    final jadwalWithUser = jadwal.copyWith(userId: uid);
    String? createdDocId = jadwalWithUser.docId;

    final collection = _getUserJadwalCollection();
    if (collection != null) {
      try {
        final docRef = collection.doc();
        createdDocId = docRef.id;
        final finalWithDoc = jadwalWithUser.copyWith(docId: createdDocId);
        docRef.set(finalWithDoc.toMap());
      } catch (_) {}
    }

    final db = await instance.database;
    final finalJadwal = jadwalWithUser.copyWith(docId: createdDocId);
    return await db.insert('jadwal', finalJadwal.toMap());
  }

  // 6. Update Jadwal
  Future<int> updateJadwal(Jadwal jadwal) async {
    final uid = _currentUserId;
    final jadwalWithUser = jadwal.copyWith(userId: uid);

    final collection = _getUserJadwalCollection();
    if (collection != null) {
      try {
        if (jadwalWithUser.docId != null) {
          collection.doc(jadwalWithUser.docId).update(jadwalWithUser.toMap());
        } else {
          final docRef = collection.doc();
          final updated = jadwalWithUser.copyWith(docId: docRef.id);
          docRef.set(updated.toMap());
        }
      } catch (_) {}
    }

    final db = await instance.database;
    return await db.update(
      'jadwal',
      jadwalWithUser.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [jadwalWithUser.id, uid],
    );
  }

  // 7. Hapus Jadwal
  Future<int> deleteJadwal(int id, {String? docId}) async {
    final uid = _currentUserId;
    final collection = _getUserJadwalCollection();

    if (collection != null && docId != null) {
      try {
        collection.doc(docId).delete();
      } catch (_) {}
    }

    final db = await instance.database;
    return await db.delete(
      'jadwal',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, uid],
    );
  }

  // ===================== CATATAN CRUD =====================

  // 1. Ambil Semua Catatan MILIK User Saat Ini
  Future<List<Catatan>> getAllCatatan() async {
    final uid = _currentUserId;
    final collection = _getUserCatatanCollection();

    if (collection != null) {
      try {
        final snapshot = await collection.get();
        final firestoreList = snapshot.docs.map((doc) {
          return Catatan.fromMap(
            doc.data(),
            documentId: doc.id,
          ).copyWith(userId: uid);
        }).toList();

        final db = await instance.database;
        for (var item in firestoreList) {
          final existing = await db.query(
            'catatan',
            where: 'userId = ? AND (docId = ? OR (mataKuliah = ? AND judul = ? AND createdAt = ?))',
            whereArgs: [
              uid,
              item.docId,
              item.mataKuliah,
              item.judul,
              item.createdAt,
            ],
          );
          if (existing.isEmpty) {
            await db.insert('catatan', item.toMap());
          }
        }
      } catch (_) {}
    }

    final db = await instance.database;
    final result = await db.query(
      'catatan',
      where: 'userId = ?',
      whereArgs: [uid],
      orderBy: 'mingguKe ASC, createdAt DESC',
    );
    return result.map((json) => Catatan.fromMap(json)).toList();
  }

  // 2. Ambil Catatan Berdasarkan Mata Kuliah
  Future<List<Catatan>> getCatatanByMataKuliah(String mataKuliah) async {
    final uid = _currentUserId;
    final db = await instance.database;
    final result = await db.query(
      'catatan',
      where: 'userId = ? AND mataKuliah = ?',
      whereArgs: [uid, mataKuliah],
      orderBy: 'mingguKe ASC, createdAt DESC',
    );
    return result.map((json) => Catatan.fromMap(json)).toList();
  }

  // 3. Tambah Catatan Baru
  Future<int> insertCatatan(Catatan catatan) async {
    final uid = _currentUserId;
    final catatanWithUser = catatan.copyWith(userId: uid);
    String? createdDocId = catatanWithUser.docId;

    final collection = _getUserCatatanCollection();
    if (collection != null) {
      try {
        final docRef = collection.doc();
        createdDocId = docRef.id;
        final finalWithDoc = catatanWithUser.copyWith(docId: createdDocId);
        docRef.set(finalWithDoc.toMap());
      } catch (_) {}
    }

    final db = await instance.database;
    final finalCatatan = catatanWithUser.copyWith(docId: createdDocId);
    return await db.insert('catatan', finalCatatan.toMap());
  }

  // 4. Update Catatan
  Future<int> updateCatatan(Catatan catatan) async {
    final uid = _currentUserId;
    final catatanWithUser = catatan.copyWith(userId: uid);

    final collection = _getUserCatatanCollection();
    if (collection != null) {
      try {
        if (catatanWithUser.docId != null) {
          collection.doc(catatanWithUser.docId).update(catatanWithUser.toMap());
        } else {
          final docRef = collection.doc();
          final updated = catatanWithUser.copyWith(docId: docRef.id);
          docRef.set(updated.toMap());
        }
      } catch (_) {}
    }

    final db = await instance.database;
    return await db.update(
      'catatan',
      catatanWithUser.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [catatanWithUser.id, uid],
    );
  }

  // 5. Hapus Catatan
  Future<int> deleteCatatan(int id, {String? docId}) async {
    final uid = _currentUserId;
    final collection = _getUserCatatanCollection();

    if (collection != null && docId != null) {
      try {
        collection.doc(docId).delete();
      } catch (_) {}
    }

    final db = await instance.database;
    return await db.delete(
      'catatan',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, uid],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
