import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import file kamu
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
// Import dummy dashboard (karena dashboard tugas mhs lain)
// Nanti diganti dengan file dashboard asli
import 'package:flutter/cupertino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Nyalakan Firebase

  // Bungkus root dengan ProviderScope untuk Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // Status untuk menampilkan loading saat aplikasi pertama kali cek sesi
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // LOGIKA UTAMA BYPASS LOGIN
  Future<void> _checkSession() async {
    // Panggil fungsi loadSession dari auth_provider
    // Fungsi ini membaca Shared Preferences dan update state 'user'
    await ref.read(authProvider.notifier).loadSession();

    if (mounted) {
      setState(() {
        _isCheckingSession = false; // Selesai cek, matikan loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantau terus state user (Login atau Logout)
    final user = ref.watch(authProvider);

    if (_isCheckingSession) {
      // Tampilkan layar loading putih saat cek sesi berlangsung
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.green)),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoPatrol',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // ROUTING OTOMATIS BERDASARKAN STATE
      // Jika user tidak null (Login) -> Ke Dashboard
      // Jika user null (Belum Login/Logout) -> Ke LoginScreen
      home: user != null ? const DashboardPlaceholder() : const LoginScreen(),
    );
  }
}

// --- DUMMY DASHBOARD (Hanya Pemanis sementara) ---
// Ini nanti diganti dengan Dashboard buatan temanmu
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard EcoPatrol"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigasi ke Settings buatanmu
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 100, color: Colors.green),
            Text("Peta & Kamera akan ada di sini"),
            Text("(Tugas Mahasiswa Lain)"),
          ],
        ),
      ),
    );
  }
}