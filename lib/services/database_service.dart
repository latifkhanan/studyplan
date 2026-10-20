import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/jadwal.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('studyplan_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel dibuat bersih TANPA data dummy bawaan
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
        tanggal TEXT NOT NULL
      )
    ''');
  }

  // ID pengguna aktif saat ini
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

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

  // 1. Ambil Semua Jadwal milik Akun yang Sedang Login
  Future<List<Jadwal>> getAllJadwal() async {
    final uid = _currentUserId;
    final collection = _getUserJadwalCollection();

    if (collection != null) {
      try {
        final snapshot = await collection.get();
        final firestoreList = snapshot.docs.map((doc) {
          return Jadwal.fromMap(doc.data(), documentId: doc.id).copyWith(userId: uid);
        }).toList();

        final db = await instance.database;
        for (var item in firestoreList) {
          final existing = await db.query(
            'jadwal',
            where: 'userId = ? AND (docId = ? OR (mataKuliah = ? AND tanggal = ? AND jamMulai = ?))',
            whereArgs: [uid, item.docId, item.mataKuliah, item.tanggal, item.jamMulai],
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

  // 2. Ambil Jadwal berdasarkan Tanggal milik Akun yang Sedang Login
  Future<List<Jadwal>> getJadwalByTanggal(String tanggal) async {
    final uid = _currentUserId;
    final collection = _getUserJadwalCollection();

    if (collection != null) {
      try {
        final snapshot = await collection
            .where('tanggal', isEqualTo: tanggal)
            .get();

        final firestoreList = snapshot.docs.map((doc) {
          return Jadwal.fromMap(doc.data(), documentId: doc.id).copyWith(userId: uid);
        }).toList();

        final db = await instance.database;
        for (var item in firestoreList) {
          final existing = await db.query(
            'jadwal',
            where: 'userId = ? AND (docId = ? OR (mataKuliah = ? AND tanggal = ? AND jamMulai = ?))',
            whereArgs: [uid, item.docId, item.mataKuliah, item.tanggal, item.jamMulai],
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

  // 3. Ambil Jadwal berdasarkan Hari milik Akun yang Sedang Login
  Future<List<Jadwal>> getJadwalByHari(String hari) async {
    final uid = _currentUserId;
    final collection = _getUserJadwalCollection();

    if (collection != null) {
      try {
        final snapshot = await collection
            .where('hari', isEqualTo: hari)
            .get();

        final firestoreList = snapshot.docs.map((doc) {
          return Jadwal.fromMap(doc.data(), documentId: doc.id).copyWith(userId: uid);
        }).toList();

        final db = await instance.database;
        for (var item in firestoreList) {
          final existing = await db.query(
            'jadwal',
            where: 'userId = ? AND (docId = ? OR (mataKuliah = ? AND tanggal = ? AND jamMulai = ?))',
            whereArgs: [uid, item.docId, item.mataKuliah, item.tanggal, item.jamMulai],
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

  // 4. Ambil Daftar Tanggal yang Ada Jadwalnya milik Akun yang Sedang Login
  Future<List<String>> getDatesWithJadwal() async {
    final uid = _currentUserId;
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT tanggal FROM jadwal WHERE userId = ?',
      [uid],
    );
    return result.map((row) => row['tanggal'] as String).toList();
  }

  // 5. Tambah Jadwal Baru (Ditautkan ke User ID)
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

  // 6. Update Jadwal MILIK User Saat Ini
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
          jadwalWithUser.copyWith(docId: docRef.id);
          docRef.set(jadwalWithUser.toMap());
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

  // 7. Hapus Jadwal MILIK User Saat Ini
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

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
