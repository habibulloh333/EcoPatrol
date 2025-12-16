import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/report_provider.dart';
import '../widgets/report_item.dart';
import 'detail_report_screen.dart';
// Import komponen
import '../widgets/summary_card.dart';
import 'add_report_screen.dart';
// Import halaman navigasi
import 'settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. DENGARKAN DATA (WATCH)
    final asyncReports = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("EcoPatrol Monitor"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddReportScreen()),
        ),
      ),

      // 2. KITA BUNGKUS BODY DENGAN .when AGAR LOADING MERATA
      body: asyncReports.when(
        // A. KONDISI LOADING (Full Screen Loading)
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.green)),

        // B. KONDISI ERROR
        error: (err, stack) => Center(child: Text("Error: $err")),

        // C. KONDISI DATA ADA (Main Logic Kita)
        data: (reports) {
          // --- LOGIKA HITUNG RINGKASAN (PAKET 4) ---
          final int totalLaporan = reports.length;

          // Filter laporan yang statusnya 'selesai' (case insensitive)
          final int laporanSelesai = reports
              .where((r) => r.status.toLowerCase() == 'selesai')
              .length;

          return Column(
            children: [
              // 3. TAMPILKAN HEADER DENGAN ANGKA ASLI
              SummaryCard(total: totalLaporan, selesai: laporanSelesai),

              // 4. TAMPILKAN LIST
              Expanded(
                child: reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Belum ada laporan",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return ReportItem(
                            report: report,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DetailReportScreen(report: report)),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
