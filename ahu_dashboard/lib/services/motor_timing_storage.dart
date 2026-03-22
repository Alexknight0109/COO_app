import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for motor timing configurations
/// Stores the last configured motor timings for each AHU on the Raspberry Pi
class MotorTimingStorage {
  static const String _keyPrefix = 'motor_timing_';
  
  /// Save motor timings for an AHU
  static Future<void> saveTimings(
    String ahuId, {
    required int m1Start,
    required int m1Post,
    required int m2WaitTime,  // Note: This is wait time, not actual interval
    required int m2Run,
    required int m2Delay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_keyPrefix}${ahuId}_m1_start', m1Start);
    await prefs.setInt('${_keyPrefix}${ahuId}_m1_post', m1Post);
    await prefs.setInt('${_keyPrefix}${ahuId}_m2_wait', m2WaitTime);
    await prefs.setInt('${_keyPrefix}${ahuId}_m2_run', m2Run);
    await prefs.setInt('${_keyPrefix}${ahuId}_m2_delay', m2Delay);
    print('MotorTimingStorage: Saved timings for $ahuId - M1Start:$m1Start, M2Wait:$m2WaitTime, M2Run:$m2Run');
  }
  
  /// Load motor timings for an AHU
  /// Returns null if no timings were previously saved
  static Future<Map<String, int>?> loadTimings(String ahuId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final m1Start = prefs.getInt('${_keyPrefix}${ahuId}_m1_start');
    final m1Post = prefs.getInt('${_keyPrefix}${ahuId}_m1_post');
    final m2Wait = prefs.getInt('${_keyPrefix}${ahuId}_m2_wait');
    final m2Run = prefs.getInt('${_keyPrefix}${ahuId}_m2_run');
    final m2Delay = prefs.getInt('${_keyPrefix}${ahuId}_m2_delay');
    
    // If any value is missing, return null (no saved config)
    if (m1Start == null || m1Post == null || m2Wait == null || m2Run == null || m2Delay == null) {
      print('MotorTimingStorage: No saved timings for $ahuId');
      return null;
    }
    
    print('MotorTimingStorage: Loaded timings for $ahuId - M1Start:$m1Start, M2Wait:$m2Wait, M2Run:$m2Run');
    
    return {
      'm1_start': m1Start,
      'm1_post': m1Post,
      'm2_wait': m2Wait,
      'm2_run': m2Run,
      'm2_delay': m2Delay,
    };
  }
  
  /// Clear saved timings for an AHU
  static Future<void> clearTimings(String ahuId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}${ahuId}_m1_start');
    await prefs.remove('${_keyPrefix}${ahuId}_m1_post');
    await prefs.remove('${_keyPrefix}${ahuId}_m2_wait');
    await prefs.remove('${_keyPrefix}${ahuId}_m2_run');
    await prefs.remove('${_keyPrefix}${ahuId}_m2_delay');
    print('MotorTimingStorage: Cleared timings for $ahuId');
  }
}

