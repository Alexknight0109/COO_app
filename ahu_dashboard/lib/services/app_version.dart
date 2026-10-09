import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dashboard version shown at the bottom of the role screen.
///
/// `v1.0.<git commit count> · <short hash>`. The updater and
/// `rpi_kiosk_setup/build_dashboard.sh` pass these as `--dart-define`s; a plain
/// `flutter build` falls back to reading git next to the bundle.
class AppVersion {
  static const String _base = '1.0';
  static const String _definedVersion = String.fromEnvironment('APP_VERSION');
  static const String _definedCommit = String.fromEnvironment('APP_COMMIT');
  static const String _lastSeenKey = 'last_seen_app_version';

  static String _label = 'v$_base.0';
  static String get label => _label;

  /// Set when this launch is the first one after an update.
  static String? updatedFrom;

  static Future<void> load() async {
    if (_definedVersion.isNotEmpty) {
      _label = _format(_definedVersion, _definedCommit);
    } else if (!kIsWeb) {
      await _loadFromGit();
    }
    await _checkUpdated();
  }

  static String _format(String version, String commit) =>
      commit.isEmpty ? 'v$version' : 'v$version · $commit';

  static Future<void> _loadFromGit() async {
    final dir = projectDir();
    if (dir == null) return;
    try {
      final count = await Process.run(
        'git',
        ['rev-list', '--count', 'HEAD'],
        workingDirectory: dir,
      );
      if (count.exitCode != 0) return;
      final hash = await Process.run(
        'git',
        ['rev-parse', '--short', 'HEAD'],
        workingDirectory: dir,
      );
      _label = _format(
        '$_base.${count.stdout.toString().trim()}',
        hash.exitCode == 0 ? hash.stdout.toString().trim() : '',
      );
    } catch (_) {}
  }

  static Future<void> _checkUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_lastSeenKey);
      if (last != null && last != _label) updatedFrom = last;
      await prefs.setString(_lastSeenKey, _label);
    } catch (_) {}
  }

  /// The Flutter project folder (`.../ahu_dashboard`) of the running bundle,
  /// i.e. five levels above `build/linux/<arch>/release/bundle/ahu_dashboard`.
  static String? projectDir() {
    if (kIsWeb || !Platform.isLinux) return null;
    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 5; i++) {
      dir = dir.parent;
    }
    return File('${dir.path}/pubspec.yaml').existsSync() ? dir.path : null;
  }
}
