import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/or_phone_service.dart';

enum OrCallState { idle, dialing, inCall, failed }

class OrSpeedDial {
  String name;
  String number;

  OrSpeedDial({required this.name, required this.number});
}

/// Local hospital phone: 3 presets + SIP to the FXO gateway. No cloud.
class OrPhoneProvider extends ChangeNotifier {
  static const _hostKey = 'or_phone_sip_host';
  static const _userKey = 'or_phone_sip_user';
  static const _passKey = 'or_phone_sip_pass';
  static const _prefixKey = 'or_phone_sip_prefix';
  static const _presetNamePrefix = 'or_phone_preset_name_';
  static const _presetNumPrefix = 'or_phone_preset_num_';

  static const _defaultNames = ['OT desk', 'ICU', 'Engineer'];

  final OrPhoneService _sip = OrPhoneService();
  final List<OrSpeedDial> _presets = [
    OrSpeedDial(name: _defaultNames[0], number: ''),
    OrSpeedDial(name: _defaultNames[1], number: ''),
    OrSpeedDial(name: _defaultNames[2], number: ''),
  ];

  String _sipHost = '';
  String _sipUser = '';
  String _sipPass = '';
  String _sipPrefix = '';
  String _dialBuffer = '';
  OrCallState _callState = OrCallState.idle;
  String _status = '';

  List<OrSpeedDial> get presets => List.unmodifiable(_presets);
  String get sipHost => _sipHost;
  String get sipUser => _sipUser;
  String get sipPrefix => _sipPrefix;
  String get dialBuffer => _dialBuffer;
  OrCallState get callState => _callState;
  String get status => _status;
  bool get sipReady => _sip.isAvailable;
  bool get canHangup =>
      _callState == OrCallState.dialing || _callState == OrCallState.inCall;

  Future<void> load() async {
    await _sip.init();
    try {
      final prefs = await SharedPreferences.getInstance();
      _sipHost = prefs.getString(_hostKey) ?? '';
      _sipUser = prefs.getString(_userKey) ?? '';
      _sipPass = prefs.getString(_passKey) ?? '';
      _sipPrefix = prefs.getString(_prefixKey) ?? '';
      for (var i = 0; i < 3; i++) {
        _presets[i].name =
            prefs.getString('$_presetNamePrefix$i') ?? _defaultNames[i];
        _presets[i].number = prefs.getString('$_presetNumPrefix$i') ?? '';
      }
    } catch (e) {
      debugPrint('OrPhone: load failed: $e');
    }
    _status = _sip.isAvailable
        ? 'Ready (${_sip.backend})'
        : 'Install pjsua on this Radxa to place calls';
    notifyListeners();
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

  Future<void> setSip({
    required String host,
    required String user,
    String? password,
    String prefix = '',
  }) async {
    _sipHost = host.trim();
    _sipUser = user.trim();
    if (password != null && password.isNotEmpty) _sipPass = password;
    _sipPrefix = prefix.trim();
    notifyListeners();
    await _save();
  }

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
    if (digits.isEmpty) {
      _status = 'Enter a number';
      notifyListeners();
      return;
    }
    if (_sipHost.isEmpty) {
      _status = 'Set the HT813 IP in phone settings first';
      _callState = OrCallState.failed;
      notifyListeners();
      return;
    }
    _dialBuffer = digits;
    _callState = OrCallState.dialing;
    _status = 'Calling $digits…';
    notifyListeners();

    final ok = await _sip.dial(
      number: digits,
      host: _sipHost,
      user: _sipUser.isEmpty ? '100' : _sipUser,
      password: _sipPass,
      prefix: _sipPrefix,
    );
    if (ok) {
      _callState = OrCallState.inCall;
      _status = 'In call · $digits';
    } else {
      _callState = OrCallState.failed;
      _status = _sip.isAvailable
          ? 'Call failed'
          : 'No SIP client — install pjsua, then retry';
    }
    notifyListeners();
  }

  Future<void> hangup() async {
    await _sip.hangup();
    _callState = OrCallState.idle;
    _status = _sip.isAvailable ? 'Ended' : _status;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_hostKey, _sipHost);
      await prefs.setString(_userKey, _sipUser);
      await prefs.setString(_passKey, _sipPass);
      await prefs.setString(_prefixKey, _sipPrefix);
      for (var i = 0; i < 3; i++) {
        await prefs.setString('$_presetNamePrefix$i', _presets[i].name);
        await prefs.setString('$_presetNumPrefix$i', _presets[i].number);
      }
    } catch (e) {
      debugPrint('OrPhone: save failed: $e');
    }
  }
}
