import 'dart:io';

import 'package:flutter/foundation.dart';

/// Talks to a local SIP client (pjsua or linphonecsh) so the Radxa can
/// place a call through a Grandstream HT813 FXO gateway.
/// UI still works if neither binary is installed.
class OrPhoneService {
  Process? _call;
  String? _backend;

  bool get isAvailable => _backend != null;
  String? get backend => _backend;
  bool get inCall => _call != null;

  Future<void> init() async {
    if (kIsWeb || !Platform.isLinux) {
      _backend = null;
      return;
    }
    _backend = await _which('pjsua') ?? await _which('linphonecsh');
  }

  Future<String?> _which(String name) async {
    try {
      final result = await Process.run('which', [name]);
      final path = result.stdout.toString().trim();
      if (result.exitCode == 0 && path.isNotEmpty) return path;
    } catch (_) {}
    return null;
  }

  /// Dials [number] via SIP at [host]. Optional [prefix] is prepended
  /// (hospital PBX outbound, often 0 or 9).
  Future<bool> dial({
    required String number,
    required String host,
    required String user,
    required String password,
    String prefix = '',
  }) async {
    await hangup();
    await init();
    final digits = '$prefix${_digits(number)}';
    if (digits.isEmpty || host.trim().isEmpty) return false;
    final dest = 'sip:$digits@${host.trim()}';

    if (_backend != null && _backend!.endsWith('pjsua')) {
      return _dialPjsua(
        dest: dest,
        host: host.trim(),
        user: user.trim(),
        password: password,
      );
    }
    if (_backend != null && _backend!.endsWith('linphonecsh')) {
      return _dialLinphone(
        dest: dest,
        host: host.trim(),
        user: user.trim(),
        password: password,
      );
    }
    debugPrint('OrPhone: no SIP client (install pjsua). Would dial $dest');
    return false;
  }

  Future<bool> _dialPjsua({
    required String dest,
    required String host,
    required String user,
    required String password,
  }) async {
    try {
      final args = <String>[
        '--id', 'sip:$user@$host',
        '--registrar', 'sip:$host',
        '--realm', '*',
        '--username', user,
        '--password', password,
        dest,
      ];
      _call = await Process.start(_backend!, args);
      _call!.exitCode.then((_) {
        _call = null;
      });
      return true;
    } catch (e) {
      debugPrint('OrPhone pjsua: $e');
      _call = null;
      return false;
    }
  }

  Future<bool> _dialLinphone({
    required String dest,
    required String host,
    required String user,
    required String password,
  }) async {
    try {
      await Process.run(_backend!, ['init']);
      await Process.run(_backend!, [
        'register',
        '--host',
        host,
        '--username',
        user,
        '--password',
        password,
      ]);
      final result = await Process.run(_backend!, ['dial', dest]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('OrPhone linphone: $e');
      return false;
    }
  }

  Future<void> hangup() async {
    if (_call != null) {
      try {
        _call!.stdin.writeln('h');
        await _call!.stdin.flush();
      } catch (_) {}
      try {
        _call!.kill();
      } catch (_) {}
      _call = null;
    }
    if (_backend != null && _backend!.endsWith('linphonecsh')) {
      try {
        await Process.run(_backend!, ['generic', 'terminate']);
      } catch (_) {}
    }
  }

  static String _digits(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9*#+]'), '');
  }
}
