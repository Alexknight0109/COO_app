import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'rock4_gpio_service.dart';

/// Analog hospital line via Ag2130-S FXO + CM108 USB audio.
/// Hook / ring are GPIO (not the OT-light pins). Call audio is ALSA on the
/// CM108 — Ethernet and SIP are not used. UI still works if tools are missing.
class OrPhoneService {
  Process? _audio;
  bool _gpioOk = false;
  bool _alsaOk = false;
  String? _alsaDev;
  bool _offHook = false;

  bool get isAvailable => _gpioOk || _alsaOk;
  bool get gpioAvailable => _gpioOk;
  bool get alsaAvailable => _alsaOk;
  String? get alsaDevice => _alsaDev;
  bool get inCall => _offHook;
  String get backend {
    if (_gpioOk && _alsaOk) return 'Ag2130+CM108';
    if (_gpioOk) return 'GPIO hook (no ALSA)';
    if (_alsaOk) return 'ALSA (no GPIO)';
    return 'unavailable';
  }

  Future<void> init({String? preferredAlsa}) async {
    if (kIsWeb || !Platform.isLinux) {
      _gpioOk = false;
      _alsaOk = false;
      return;
    }
    _gpioOk = await _hasBin('gpioset');
    if (_gpioOk) {
      await _setHook(false);
    }
    _alsaDev = preferredAlsa?.trim().isNotEmpty == true
        ? preferredAlsa!.trim()
        : await _detectCm108();
    _alsaOk = _alsaDev != null && await _hasBin('aplay');
  }

  Future<bool> _hasBin(String name) async {
    try {
      final result = await Process.run('which', [name]);
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _detectCm108() async {
    try {
      final result = await Process.run('arecord', ['-l']);
      if (result.exitCode != 0) return null;
      final lines = result.stdout.toString().split('\n');
      final match = RegExp(r'card (\d+):.*', caseSensitive: false);
      for (final line in lines) {
        final lower = line.toLowerCase();
        final isUsb = lower.contains('cm108') ||
            lower.contains('c-media') ||
            lower.contains('usb audio') ||
            lower.contains('usb-audio') ||
            lower.contains('pnp sound') ||
            lower.contains('usb');
        if (!isUsb) continue;
        final m = match.firstMatch(line);
        if (m != null) return 'plughw:${m.group(1)},0';
      }
    } catch (e) {
      debugPrint('OrPhone ALSA detect: $e');
    }
    return null;
  }

  /// Seize the analog line, play DTMF, then bridge CM108 capture↔playback.
  Future<bool> dial({
    required String number,
    String prefix = '',
    String? alsaDevice,
    bool hookActiveHigh = true,
  }) async {
    await hangup();
    await init(preferredAlsa: alsaDevice);
    final digits = '$prefix${_digits(number)}';
    if (digits.isEmpty) return false;

    final hooked = await _setHook(true, activeHigh: hookActiveHigh);
    if (!hooked && _gpioOk) return false;
    _offHook = true;
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (digits.isNotEmpty) {
      await _playDtmf(digits);
    }
    await _startAudioBridge();
    return true;
  }

  /// Answer an incoming ring: off-hook, no DTMF.
  Future<bool> answer({
    String? alsaDevice,
    bool hookActiveHigh = true,
  }) async {
    await hangup();
    await init(preferredAlsa: alsaDevice);
    final hooked = await _setHook(true, activeHigh: hookActiveHigh);
    if (!hooked && _gpioOk) return false;
    _offHook = true;
    await _startAudioBridge();
    return true;
  }

  Future<bool> isRinging() async {
    if (!_gpioOk) return false;
    try {
      final result = await Process.run(
        'gpioget',
        [kPhoneRingPin.chip, '${kPhoneRingPin.line}'],
      );
      if (result.exitCode != 0) return false;
      return result.stdout.toString().trim().contains('1');
    } catch (_) {
      return false;
    }
  }

  Future<void> hangup({bool hookActiveHigh = true}) async {
    await _stopAudio();
    await _setHook(false, activeHigh: hookActiveHigh);
    _offHook = false;
  }

  Future<bool> _setHook(bool offHook, {bool activeHigh = true}) async {
    if (!_gpioOk) {
      debugPrint('OrPhone: gpioset missing — hook pin ${kPhoneHookPin.label} not driven');
      return false;
    }
    final level = (offHook == activeHigh) ? 1 : 0;
    try {
      final result = await Process.run(
        'gpioset',
        [kPhoneHookPin.chip, '${kPhoneHookPin.line}=$level'],
      );
      if (result.exitCode != 0) {
        debugPrint('OrPhone hook failed: ${result.stderr}'.trim());
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('OrPhone hook: $e');
      return false;
    }
  }

  Future<void> _playDtmf(String digits) async {
    if (!_alsaOk || _alsaDev == null) {
      debugPrint('OrPhone: aplay/CM108 missing — DTMF skipped for $digits');
      return;
    }
    final wav = _dtmfWav(digits);
    final file = File('/tmp/or_phone_dtmf.wav');
    try {
      await file.writeAsBytes(wav, flush: true);
      await Process.run('aplay', ['-q', '-D', _alsaDev!, file.path]);
    } catch (e) {
      debugPrint('OrPhone DTMF: $e');
    }
  }

  Future<void> _startAudioBridge() async {
    await _stopAudio();
    if (!_alsaOk || _alsaDev == null) return;
    if (await _hasBin('alsaloop')) {
      try {
        _audio = await Process.start('alsaloop', [
          '-C', _alsaDev!,
          '-P', _alsaDev!,
          '-t', '20000',
          '-S', '1',
        ]);
        final spawned = _audio;
        spawned!.exitCode.then((_) {
          if (identical(_audio, spawned)) _audio = null;
        });
        return;
      } catch (e) {
        debugPrint('OrPhone alsaloop: $e');
      }
    }
    // Fallback: capture → playback (latency is higher, still hands-free).
    try {
      _audio = await Process.start('sh', [
        '-c',
        'arecord -q -D $_alsaDev -f S16_LE -c1 -r 8000 | aplay -q -D $_alsaDev -f S16_LE -c1 -r 8000',
      ]);
    } catch (e) {
      debugPrint('OrPhone audio bridge: $e');
    }
  }

  Future<void> _stopAudio() async {
    final p = _audio;
    _audio = null;
    if (p == null) return;
    try {
      p.kill();
    } catch (_) {}
  }

  static String _digits(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9*#+]'), '');
  }

  static const _dtmfLow = {
    '1': 697, '2': 697, '3': 697, 'A': 697,
    '4': 770, '5': 770, '6': 770, 'B': 770,
    '7': 852, '8': 852, '9': 852, 'C': 852,
    '*': 941, '0': 941, '#': 941, 'D': 941,
  };
  static const _dtmfHigh = {
    '1': 1209, '2': 1336, '3': 1477, 'A': 1633,
    '4': 1209, '5': 1336, '6': 1477, 'B': 1633,
    '7': 1209, '8': 1336, '9': 1477, 'C': 1633,
    '*': 1209, '0': 1336, '#': 1477, 'D': 1633,
  };

  /// 8 kHz 16-bit mono WAV: 80 ms tone + 80 ms gap per digit.
  static Uint8List _dtmfWav(String digits) {
    const rate = 8000;
    const toneMs = 80;
    const gapMs = 80;
    final toneN = rate * toneMs ~/ 1000;
    final gapN = rate * gapMs ~/ 1000;
    final samples = <int>[];
    for (var i = 0; i < digits.length; i++) {
      final ch = digits[i].toUpperCase();
      final lo = _dtmfLow[ch];
      final hi = _dtmfHigh[ch];
      if (lo == null || hi == null) continue;
      for (var n = 0; n < toneN; n++) {
        final t = n / rate;
        final v = 0.35 * sin(2 * pi * lo * t) + 0.35 * sin(2 * pi * hi * t);
        samples.add((v * 32767).round().clamp(-32767, 32767));
      }
      for (var n = 0; n < gapN; n++) {
        samples.add(0);
      }
    }
    final dataBytes = samples.length * 2;
    final out = BytesBuilder();
    void ascii(String s) => out.add(s.codeUnits);
    void u16(int v) {
      out.addByte(v & 0xff);
      out.addByte((v >> 8) & 0xff);
    }

    void u32(int v) {
      out.addByte(v & 0xff);
      out.addByte((v >> 8) & 0xff);
      out.addByte((v >> 16) & 0xff);
      out.addByte((v >> 24) & 0xff);
    }

    ascii('RIFF');
    u32(36 + dataBytes);
    ascii('WAVE');
    ascii('fmt ');
    u32(16);
    u16(1);
    u16(1);
    u32(rate);
    u32(rate * 2);
    u16(2);
    u16(16);
    ascii('data');
    u32(dataBytes);
    for (final s in samples) {
      u16(s & 0xffff);
    }
    return out.toBytes();
  }
}
