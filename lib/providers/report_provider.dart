import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '/db_helper.dart';
import 'package:flutter_riverpod/legacy.dart';

final reportProvider =
StateNotifierProvider<ReportNotifier, AsyncValue<List<ReportModel>>>(
        (ref) {
      return ReportNotifier();
    });

class ReportNotifier extends StateNotifier<AsyncValue<List<ReportModel>>> {
  ReportNotifier() : super(const AsyncValue.loading()) {
    _listenReports();
  }

  final DbHelper _db = DbHelper();

  // Stream listener (realtime)
  void _listenReports() {
    _db.getReports().listen((reports) {
      state = AsyncValue.data(reports);
    });
  }

  // Create
  Future<void> addReport(ReportModel report) async {
    await _db.addReport(report);
  }
}
