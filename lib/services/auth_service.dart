import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream status autentikasi real-time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Pengguna aktif saat ini
  User? get currentUser => _auth.currentUser;

  // 1. Registrasi Pengguna Baru & Simpan Detail Profil ke Firestore (Cepat & Non-blocking)
  Future<UserCredential?> register({
    required String email,
    required String password,
    required String nama,
    required String nim,
    required String prodi,
  }) async {
    try {
      // 1. Buat akun di FirebaseAuth dengan batas waktu 15 detik
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw 'Koneksi lambat. Periksa jaringan internet Anda.',
      );

      final user = userCredential.user;
      if (user != null) {
        // 2. Update Display Name di FirebaseAuth
        user.updateDisplayName(nama).catchError((_) {});

        // 3. Simpan data tambahan ke Firestore secara non-blocking dengan timeout 5 detik
        _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'nama': nama,
          'email': email,
          'nim': nim,
          'prodi': prodi,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Jika Firestore lambat/offline, registrasi akun tetap berhasil di FirebaseAuth
          },
        ).catchError((_) {});
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email sudah terdaftar. Silakan gunakan email lain atau masuk.';
      } else if (e.code == 'weak-password') {
        throw 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
      } else if (e.code == 'invalid-email') {
        throw 'Format email tidak valid.';
      }
      throw e.message ?? 'Terjadi kesalahan saat registrasi.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Terjadi kesalahan tidak terduga.';
    }
  }

  // 2. Login Pengguna dengan Email & Password
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw 'Koneksi lambat. Periksa koneksi internet Anda.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Email atau kata sandi yang Anda masukkan salah.';
      }
      throw e.message ?? 'Gagal masuk. Periksa kembali email dan kata sandi Anda.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Terjadi kesalahan saat mencoba masuk.';
    }
  }

  // 3. Ambil Data Profil Pengguna dari Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data();
        }
      } catch (_) {}
    }
    return null;
  }

  // 4. Update Data Profil Pengguna di Firestore
  Future<void> updateUserProfile({
    required String nama,
    required String nim,
    required String prodi,
  }) async {
    final user = currentUser;
    if (user != null) {
      await user.updateDisplayName(nama).catchError((_) {});
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'nama': nama,
        'email': user.email ?? '',
        'nim': nim,
        'prodi': prodi,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // 5. Keluar dari Akun (Logout)
  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // 6. Kirim Email Reset Kata Sandi
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'Koneksi lambat. Periksa koneksi internet Anda.',
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Gagal mengirim email reset kata sandi.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Terjadi kesalahan saat mengirim permintaan reset kata sandi.';
    }
  }

  // 7. Login dengan Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // Pengguna membatalkan login

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        final displayName = (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : (googleUser.displayName ?? 'Pengguna Google');
        final email = user.email ?? googleUser.email;

        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          await docRef.set({
            'uid': user.uid,
            'nama': displayName,
            'email': email,
            'nim': '-',
            'prodi': '-',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final data = docSnap.data() ?? {};
          await docRef.set({
            'uid': user.uid,
            'nama': data['nama'] ?? displayName,
            'email': data['email'] ?? email,
            'nim': data['nim'] ?? '-',
            'prodi': data['prodi'] ?? '-',
          }, SetOptions(merge: true));
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Gagal masuk dengan Google.';
    } catch (e) {
      final str = e.toString();
      if (str.contains('12500') || str.contains('10') || str.contains('sign_in_failed')) {
        throw 'Google Sign-In gagal. Pastikan SHA-1 Fingerprint telah didaftarkan di Firebase Console.';
      }
      if (e is String) rethrow;
      throw 'Terjadi kesalahan saat masuk dengan Google: $str';
    }
  }
}
