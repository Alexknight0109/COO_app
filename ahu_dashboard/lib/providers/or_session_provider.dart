import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One elapsed-time stamp from the operation clock.
class OrTimeStamp {
  final Duration elapsed;
  final DateTime at;

  const OrTimeStamp({required this.elapsed, required this.at});

  Map<String, dynamic> toJson() => {
        'elapsedMs': elapsed.inMilliseconds,
        'at': at.toIso8601String(),
      };

  factory OrTimeStamp.fromJson(Map<String, dynamic> json) {
    return OrTimeStamp(
      elapsed: Duration(milliseconds: (json['elapsedMs'] as num?)?.toInt() ?? 0),
      at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Local-only operation timer. Newest 5 stamps stay; a sixth tap drops the oldest.
class OrSessionProvider extends ChangeNotifier {
  static const int maxStamps = 5;
  static const String _prefsKey = 'or_session_state';

  DateTime? _startedAt;
  DateTime? _stoppedAt;
  final List<OrTimeStamp> _stamps = [];
  Timer? _ticker;

  DateTime? get startedAt => _startedAt;
  DateTime? get stoppedAt => _stoppedAt;
  List<OrTimeStamp> get stamps => List.unmodifiable(_stamps);
  bool get isRunning => _startedAt != null && _stoppedAt == null;
  bool get isStopped => _startedAt != null && _stoppedAt != null;
  bool get hasSession => _startedAt != null;

  Duration get elapsed {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    final end = _stoppedAt ?? DateTime.now();
    return end.difference(start);
  }

  static String formatElapsed(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw);
      if (data is! Map) return;
      _startedAt = DateTime.tryParse(data['startedAt']?.toString() ?? '');
      _stoppedAt = DateTime.tryParse(data['stoppedAt']?.toString() ?? '');
      _stamps
        ..clear()
        ..addAll(
          ((data['stamps'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => OrTimeStamp.fromJson(Map<String, dynamic>.from(e))),
        );
      if (isRunning) _ensureTicker();
      notifyListeners();
    } catch (e) {
      debugPrint('OrSession: load failed: $e');
    }
  }

  Future<void> start() async {
    if (isRunning) return;
    if (_startedAt == null) {
      _startedAt = DateTime.now();
      _stoppedAt = null;
      _stamps.clear();
    } else if (isStopped) {
      _stoppedAt = null;
    }
    _ensureTicker();
    notifyListeners();
    await _save();
  }

  Future<void> logTime() async {
    if (!hasSession) return;
    _stamps.insert(0, OrTimeStamp(elapsed: elapsed, at: DateTime.now()));
    while (_stamps.length > maxStamps) {
      _stamps.removeLast();
    }
    notifyListeners();
    await _save();
  }

  Future<void> stop() async {
    if (!isRunning) return;
    _stoppedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _startedAt = null;
    _stoppedAt = null;
    _stamps.clear();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
    await _save();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (isRunning) notifyListeners();
    });
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'startedAt': _startedAt?.toIso8601String(),
          'stoppedAt': _stoppedAt?.toIso8601String(),
          'stamps': _stamps.map((s) => s.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('OrSession: save failed: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
