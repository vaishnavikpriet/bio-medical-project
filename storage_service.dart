import 'package:hive/hive.dart';
import '../models/bp_record.dart';
import '../models/user_profile.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Box names
  static const String _bpRecordsBoxName = 'bpRecords';
  static const String _userProfileBoxName = 'userProfile';

  // Box instances
  late Box<BPRecord> _bpRecordsBox;
  late Box<UserProfile> _userProfileBox;

  // Initialize all boxes
  Future<void> init() async {
    try {
      _bpRecordsBox = await Hive.openBox<BPRecord>(_bpRecordsBoxName);
      _userProfileBox = await Hive.openBox<UserProfile>(_userProfileBoxName);
    } catch (e) {
      throw Exception('Failed to initialize storage: $e');
    }
  }

  // --- BP Record Methods ---
  Future<void> saveBPRecord(BPRecord record) async {
    try {
      await _bpRecordsBox.add(record);
      // Force immediate write to disk
      await _bpRecordsBox.flush();
    } catch (e) {
      throw Exception('Failed to save BP record: $e');
    }
  }

  Future<void> saveBPRecords(List<BPRecord> records) async {
    try {
      await _bpRecordsBox.addAll(records);
    } catch (e) {
      throw Exception('Failed to save multiple BP records: $e');
    }
  }

  List<BPRecord> getAllBPRecords() {
    try {
      final records = _bpRecordsBox.values.toList();
      // Sort by timestamp in descending order (newest first)
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (e) {
      throw Exception('Failed to get BP records: $e');
    }
  }

  Future<void> deleteBPRecord(int key) async {
    try {
      await _bpRecordsBox.delete(key);
    } catch (e) {
      throw Exception('Failed to delete BP record: $e');
    }
  }

  Future<void> clearBPRecords() async {
    try {
      await _bpRecordsBox.clear();
    } catch (e) {
      throw Exception('Failed to clear BP records: $e');
    }
  }

  // --- User Profile Methods ---
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _userProfileBox.put('profile', profile);
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  UserProfile? getUserProfile() {
    try {
      return _userProfileBox.get('profile');
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  bool hasUserProfile() {
    try {
      return _userProfileBox.containsKey('profile');
    } catch (e) {
      throw Exception('Failed to check user profile existence: $e');
    }
  }

  Future<void> deleteUserProfile() async {
    try {
      await _userProfileBox.delete('profile');
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // --- General Methods ---
  Future<void> close() async {
    try {
      await _bpRecordsBox.close();
      await _userProfileBox.close();
    } catch (e) {
      throw Exception('Failed to close storage: $e');
    }
  }
}