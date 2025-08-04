import 'package:hive/hive.dart';
import 'signal_quality.dart';

part 'bp_record.g.dart'; // This line is correct

@HiveType(typeId: 1) // Changed typeId to 1 to avoid conflicts
class BPRecord extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final int systolic;

  @HiveField(2)
  final int diastolic;

  @HiveField(3)
  final int pulse;

  @HiveField(4)
  final String condition;

  @HiveField(5)
  final SignalQuality signalQuality;

  BPRecord({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.condition,
    required this.signalQuality,
  });
}