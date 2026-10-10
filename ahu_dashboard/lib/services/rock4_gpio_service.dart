import 'dart:io';

import 'package:flutter/foundation.dart';

/// One safe ROCK 4B header pin reserved for a surgeon-panel light.
class Rock4GpioPin {
  final int headerPin;
  final String gpioName;
  final String chip;
  final int line;

  const Rock4GpioPin({
    required this.headerPin,
    required this.gpioName,
    required this.chip,
    required this.line,
  });

  String get label => 'Pin $headerPin · $gpioName';
}

/// Safe GPIO (not I2C, UART2 console, SPI flash, CSI, or ADC).
const kSafeLightPins = <Rock4GpioPin>[
  Rock4GpioPin(headerPin: 11, gpioName: 'GPIO4_C2', chip: 'gpiochip4', line: 18),
  Rock4GpioPin(headerPin: 13, gpioName: 'GPIO4_C6', chip: 'gpiochip4', line: 22),
  Rock4GpioPin(headerPin: 15, gpioName: 'GPIO4_C5', chip: 'gpiochip4', line: 21),
  Rock4GpioPin(headerPin: 16, gpioName: 'GPIO4_D2', chip: 'gpiochip4', line: 26),
  Rock4GpioPin(headerPin: 18, gpioName: 'GPIO4_D4', chip: 'gpiochip4', line: 28),
  Rock4GpioPin(headerPin: 22, gpioName: 'GPIO4_D5', chip: 'gpiochip4', line: 29),
];

/// Writes light state with libgpiod `gpioset`. UI still works if the binary
/// is missing. Lines stay low (off) unless a light is on.
class Rock4GpioService {
  bool _available = false;
  bool get isAvailable => _available;

  Future<void> init() async {
    if (kIsWeb || !Platform.isLinux) {
      _available = false;
      return;
    }
    try {
      final result = await Process.run('which', ['gpioset']);
      _available = result.exitCode == 0 &&
          result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      _available = false;
    }
    if (_available) {
      await allOff();
    }
  }

  Future<void> allOff() async {
    for (final pin in kSafeLightPins) {
      await setPin(pin, false);
    }
  }

  Future<bool> setPin(Rock4GpioPin pin, bool on) async {
    if (!_available) return false;
    try {
      final result = await Process.run(
        'gpioset',
        [pin.chip, '${pin.line}=${on ? 1 : 0}'],
      );
      if (result.exitCode != 0) {
        debugPrint(
          'GPIO ${pin.label} failed: ${result.stderr}'.trim(),
        );
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('GPIO ${pin.label}: $e');
      return false;
    }
  }
}
