import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengambil data user saat ini dari state
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Info User
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            accountName: Text(user?.nama ?? "Pengguna EcoPatrol"),
            accountEmail: Text(user?.email ?? "email@contoh.com"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.green, size: 40),
            ),
          ),

          // Tombol Logout
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              // Tampilkan dialog konfirmasi
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Konfirmasi"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Ya, Keluar")),
                  ],
                ),
              );

              if (confirm == true) {
                // EKSEKUSI LOGOUT via Provider
                // Ini akan menghapus Shared Preferences & Reset State
                await ref.read(authProvider.notifier).logout();

                // Navigator akan di-handle otomatis oleh main.dart karena state berubah jadi null
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}