import 'package:hive/hive.dart';

part 'signal_quality.g.dart'; // Add this line for the generated file

@HiveType(typeId: 2) // Give it a unique typeId
enum SignalQuality {
  @HiveField(0)
  poor,

  @HiveField(1)
  fair,

  @HiveField(2)
  good,

  @HiveField(3)
  excellent,
}