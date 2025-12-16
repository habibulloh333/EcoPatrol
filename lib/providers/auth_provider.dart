import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// 1. Membuat Provider Global agar bisa diakses dari mana saja
final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

// 2. Class Logika Utama
class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FUNGSI 1: REGISTER (Daftar & Simpan Data)
  Future<void> register({
    required String email,
    required String password,
    required String nama,
    required String nim,
    required String prodi,
    required String kelas,
  }) async {
    try {
      // Buat akun di Firebase Auth (Cuma email & pass)
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Siapkan data profil lengkap
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid, // Ambil UID dari langkah a
        nama: nama,
        email: email,
        nim: nim,
        prodi: prodi,
        kelas: kelas,
        role: 'mahasiswa', // Default role
      );

      // Simpan data profil ke Firestore (Database)
      await _firestore
          .collection('users')
          .doc(newUser.uid) // Nama dokumen = UID User
          .set(newUser.toMap()..['created_at'] = FieldValue.serverTimestamp());

      // Update State aplikasi (Otomatis login)
      state = newUser;

      // Simpan sesi ke HP (biar gak login ulang kalau apps ditutup)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(newUser.toMap()));

    } catch (e) {
      rethrow; // Lempar error ke UI biar muncul pesan error
    }
  }

  // LOGIN
  Future<void> login(String email, String password) async {
    try {
      // Login ke Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil data profil lengkap dari Firestore berdasarkan UID
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        // Ubah data jadi UserModel dan update state
        UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        state = user;

        // Simpan sesi ke HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_session', jsonEncode(user.toMap()));
      } else {
        throw Exception("Data user tidak ditemukan di database!");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Potongan kode di dalam class AuthNotifier
  Future<void> Register(String nama, String email, String password) async {
    try {
      // Buat akun di Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Siapkan data user untuk Firestore
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        nama: nama,
        email: email,
        // Field lain bisa diisi default atau kosong dulu
        nim: '',
        prodi: '',
        kelas: '',
        role: 'warga', // Role default untuk EcoPatrol
        fcmToken: '',
      );

      // 3. Simpan data detail ke Firestore
      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());

      // Update state agar otomatis login
      state = newUser;

      // 5. Simpan sesi
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(newUser.toMap()));

    } catch (e) {
      rethrow;
    }
  }

  // FUNGSI 3: LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session'); // Hapus sesi dari HP
    state = null; // Set state jadi kosong
  }

  // CEK SESI (Dipanggil saat aplikasi baru dibuka)
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('user_session');

    if (userJson != null) {
      // Kalau ada sisa login, kembalikan datanya
      state = UserModel.fromMap(jsonDecode(userJson));
    }
  }
}