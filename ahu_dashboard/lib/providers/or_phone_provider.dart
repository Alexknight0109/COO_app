import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/or_phone_service.dart';
import '../services/rock4_gpio_service.dart';

enum OrCallState { idle, dialing, inCall, ringing, failed }

class OrSpeedDial {
  String name;
  String number;

  OrSpeedDial({required this.name, required this.number});
}

/// Local analog hospital phone: Ag2130 GPIO + CM108 ALSA. No cloud, no Ethernet.
class OrPhoneProvider extends ChangeNotifier {
  static const _prefixKey = 'or_phone_sip_prefix';
  static const _alsaKey = 'or_phone_alsa_dev';
  static const _hookHighKey = 'or_phone_hook_high';
  static const _presetNamePrefix = 'or_phone_preset_name_';
  static const _presetNumPrefix = 'or_phone_preset_num_';

  static const _defaultNames = ['OT desk', 'ICU', 'Engineer'];

  final OrPhoneService _line = OrPhoneService();
  final List<OrSpeedDial> _presets = [
    OrSpeedDial(name: _defaultNames[0], number: ''),
    OrSpeedDial(name: _defaultNames[1], number: ''),
    OrSpeedDial(name: _defaultNames[2], number: ''),
  ];

  String _sipPrefix = '';
  String _alsaDevice = '';
  bool _hookActiveHigh = true;
  String _dialBuffer = '';
  OrCallState _callState = OrCallState.idle;
  String _status = '';
  Timer? _ringTimer;

  List<OrSpeedDial> get presets => List.unmodifiable(_presets);
  String get sipPrefix => _sipPrefix;
  String get alsaDevice => _alsaDevice;
  bool get hookActiveHigh => _hookActiveHigh;
  String get dialBuffer => _dialBuffer;
  OrCallState get callState => _callState;
  String get status => _status;
  bool get sipReady => _line.isAvailable;
  bool get canHangup =>
      _callState == OrCallState.dialing || _callState == OrCallState.inCall;
  String get hookPinLabel => kPhoneHookPin.label;
  String get ringPinLabel => kPhoneRingPin.label;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sipPrefix = prefs.getString(_prefixKey) ?? '';
      _alsaDevice = prefs.getString(_alsaKey) ?? '';
      _hookActiveHigh = prefs.getBool(_hookHighKey) ?? true;
      for (var i = 0; i < 3; i++) {
        _presets[i].name =
            prefs.getString('$_presetNamePrefix$i') ?? _defaultNames[i];
        _presets[i].number = prefs.getString('$_presetNumPrefix$i') ?? '';
      }
    } catch (e) {
      debugPrint('OrPhone: load failed: $e');
    }
    await _line.init(preferredAlsa: _alsaDevice);
    if (_alsaDevice.isEmpty && _line.alsaDevice != null) {
      _alsaDevice = _line.alsaDevice!;
    }
    _status = _line.isAvailable
        ? 'Ready (${_line.backend})'
        : 'GPIO ${kPhoneHookPin.label} + CM108 USB audio';
    _ringTimer?.cancel();
    _ringTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _pollRing();
    });
    notifyListeners();
  }

  Future<void> _pollRing() async {
    if (_callState == OrCallState.dialing || _callState == OrCallState.inCall) {
      return;
    }
    final ringing = await _line.isRinging();
    if (ringing && _callState != OrCallState.ringing) {
      _callState = OrCallState.ringing;
      _status = 'Incoming — tap Call to answer';
      notifyListeners();
    } else if (!ringing && _callState == OrCallState.ringing) {
      _callState = OrCallState.idle;
      _status = 'Ready (${_line.backend})';
      notifyListeners();
    }
  }

  void appendDigit(String d) {
    if (_dialBuffer.length >= 16) return;
    _dialBuffer += d;
    notifyListeners();
  }

  void backspace() {
    if (_dialBuffer.isEmpty) return;
    _dialBuffer = _dialBuffer.substring(0, _dialBuffer.length - 1);
    notifyListeners();
  }

  void clearBuffer() {
    _dialBuffer = '';
    notifyListeners();
  }

  Future<void> setLine({
    String prefix = '',
    String? alsaDevice,
    bool? hookActiveHigh,
  }) async {
    _sipPrefix = prefix.trim();
    if (alsaDevice != null) _alsaDevice = alsaDevice.trim();
    if (hookActiveHigh != null) _hookActiveHigh = hookActiveHigh;
    await _line.init(preferredAlsa: _alsaDevice);
    notifyListeners();
    await _save();
  }

  /// Kept so older settings dialogs compile if any remain.
  Future<void> setSip({
    required String host,
    required String user,
    String? password,
    String prefix = '',
  }) =>
      setLine(prefix: prefix);

  Future<void> setPreset(int index, {required String name, required String number}) async {
    if (index < 0 || index > 2) return;
    final trimmed = name.trim();
    _presets[index].name = trimmed.isEmpty ? _defaultNames[index] : trimmed;
    _presets[index].number = number.replaceAll(RegExp(r'[^0-9*#+]'), '');
    notifyListeners();
    await _save();
  }

  Future<void> callTypedNumber() => dial(_dialBuffer);

  Future<void> dialPreset(int index) async {
    if (index < 0 || index > 2) return;
    await dial(_presets[index].number);
  }

  Future<void> dial(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9*#+]'), '');
    if (digits.isEmpty && _callState == OrCallState.ringing) {
      _callState = OrCallState.dialing;
      _status = 'Answering…';
      notifyListeners();
      final ok = await _line.answer(
        alsaDevice: _alsaDevice,
        hookActiveHigh: _hookActiveHigh,
      );
      _callState = ok ? OrCallState.inCall : OrCallState.failed;
      _status = ok ? 'In call' : 'Answer failed — check hook GPIO / CM108';
      notifyListeners();
      return;
    }
    if (digits.isEmpty) {
      _status = 'Enter a number';
      notifyListeners();
      return;
    }
    _dialBuffer = digits;
    _callState = OrCallState.dialing;
    _status = 'Calling $digits…';
    notifyListeners();

    final ok = await _line.dial(
      number: digits,
      prefix: _sipPrefix,
      alsaDevice: _alsaDevice,
      hookActiveHigh: _hookActiveHigh,
    );
    if (ok) {
      _callState = OrCallState.inCall;
      _status = 'In call · $digits';
    } else {
      _callState = OrCallState.failed;
      _status = 'Call failed — hook ${kPhoneHookPin.label}, CM108 USB';
    }
    notifyListeners();
  }

  Future<void> hangup() async {
    await _line.hangup(hookActiveHigh: _hookActiveHigh);
    _callState = OrCallState.idle;
    _status = 'Ended';
    notifyListeners();
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefixKey, _sipPrefix);
      await prefs.setString(_alsaKey, _alsaDevice);
      await prefs.setBool(_hookHighKey, _hookActiveHigh);
      for (var i = 0; i < 3; i++) {
        await prefs.setString('$_presetNamePrefix$i', _presets[i].name);
        await prefs.setString('$_presetNumPrefix$i', _presets[i].number);
      }
    } catch (e) {
      debugPrint('OrPhone: save failed: $e');
    }
  }
}
