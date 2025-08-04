import 'package:csv/csv.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/bp_record.dart';

class DataExporter {
  static Future<void> exportToCSV(List<BPRecord> records) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bp_data_${DateTime.now().millisecondsSinceEpoch}.csv');

    final csvData = ListToCsvConverter().convert([
      ['Timestamp', 'Systolic', 'Diastolic', 'Pulse', 'Condition'],
      ...records.map((r) => [
        r.timestamp.toIso8601String(),
        r.systolic,
        r.diastolic,
        r.pulse,
        r.condition
      ])
    ]);

    await file.writeAsString(csvData);
  }

  static Future<void> exportPPGSignal(List<double> ppgSignal) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ppg_signal_${DateTime.now().millisecondsSinceEpoch}.csv');

    await file.writeAsString(
        ppgSignal.map((v) => v.toString()).join('\n')
    );
  }
}