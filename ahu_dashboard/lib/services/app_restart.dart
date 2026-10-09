import 'dart:io';

import 'app_version.dart';

/// Relaunches the kiosk so a freshly built bundle starts.
class AppRestart {
  /// Starts `launch_kiosk.sh`, which waits for this process to exit, then
  /// exits. Returns false (and keeps running) when the launcher is missing.
  static Future<bool> restart() async {
    final dir = AppVersion.projectDir();
    if (dir == null) return false;
    final launcher = '$dir/rpi_kiosk_setup/launch_kiosk.sh';
    if (!File(launcher).existsSync()) return false;
    try {
      await Process.start(
        'bash',
        [launcher],
        mode: ProcessStartMode.detached,
        environment: {
          'ALMED_KIOSK_BOOT_DELAY': '0',
          'ALMED_KIOSK_WAIT_PID': '$pid',
        },
      );
    } catch (_) {
      return false;
    }
    exit(0);
  }
}
