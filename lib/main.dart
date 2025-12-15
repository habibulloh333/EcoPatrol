import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Provider & Screen
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart'; // Import Dashboard barumu
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // KEMBALIKAN PROVIDER SCOPE (Wajib untuk Riverpod)
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Cek apakah ada user yang nyangkut (login) di HP
    await ref.read(authProvider.notifier).loadSession();
    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    if (_isCheckingSession) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoPatrol',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      // LOGIKA KUNCI:
      // Sudah Login? -> Ke DashboardScreen (Buatanmu)
      // Belum Login? -> Ke LoginScreen (Buatan M1)
      home: user != null ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
