import 'package:hive/hive.dart';

part 'user_profile.g.dart'; // This file will be generated

@HiveType(typeId: 2) // Must be a unique ID (0 is BPRecord, 1 is SignalQuality)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  String gender;

  @HiveField(3)
  double height;

  @HiveField(4)
  double weight;

  @HiveField(5)
  bool hasHypertension;

  @HiveField(6)
  bool hasDiabetes;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.hasHypertension,
    required this.hasDiabetes,
  });
}