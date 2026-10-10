import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/rock4_gpio_service.dart';

class OrLight {
  final String id;
  String name;
  final int headerPin;
  bool on;

  OrLight({
    required this.id,
    required this.name,
    required this.headerPin,
    this.on = false,
  });

  Rock4GpioPin? get pin {
    for (final p in kSafeLightPins) {
      if (p.headerPin == headerPin) return p;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'headerPin': headerPin,
        'on': on,
      };

  factory OrLight.fromJson(Map<String, dynamic> json) {
    return OrLight(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Light',
      headerPin: (json['headerPin'] as num?)?.toInt() ?? 11,
      on: json['on'] == true,
    );
  }
}

/// Renameable OT lights, max one per safe ROCK 4B pin. Local only.
class OrLightsProvider extends ChangeNotifier {
  static const String _prefsKey = 'or_lights_state';
  static const String _sceneNameKey = 'or_lights_scene_name';
  static const String _sceneIdsKey = 'or_lights_scene_ids';
  static const List<String> _defaultNames = ['OT Light', 'Peripheral', 'UV'];

  final Rock4GpioService _gpio = Rock4GpioService();
  final List<OrLight> _lights = [];
  String _sceneName = 'Custom';
  final Set<String> _sceneIds = {};

  List<OrLight> get lights => List.unmodifiable(_lights);
  bool get canAdd => _unusedPins.isNotEmpty;
  bool get gpioAvailable => _gpio.isAvailable;
  int get maxLights => kSafeLightPins.length;
  bool get allOn => _lights.isNotEmpty && _lights.every((l) => l.on);
  String get sceneName => _sceneName;
  Set<String> get sceneIds => Set.unmodifiable(_sceneIds);
  bool get sceneActive =>
      _sceneIds.isNotEmpty &&
      _lights.every((l) => _sceneIds.contains(l.id) ? l.on : !l.on);

  List<Rock4GpioPin> get _unusedPins {
    final used = _lights.map((l) => l.headerPin).toSet();
    return kSafeLightPins.where((p) => !used.contains(p.headerPin)).toList();
  }

  Future<void> load() async {
    await _gpio.init();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _lights
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((e) => OrLight.fromJson(Map<String, dynamic>.from(e))),
            );
        }
      }
      _sceneName = prefs.getString(_sceneNameKey) ?? 'Custom';
      _sceneIds
        ..clear()
        ..addAll(prefs.getStringList(_sceneIdsKey) ?? const []);
    } catch (e) {
      debugPrint('OrLights: load failed: $e');
    }
    if (_lights.isEmpty) {
      for (var i = 0; i < _defaultNames.length; i++) {
        _lights.add(OrLight(
          id: 'light_$i',
          name: _defaultNames[i],
          headerPin: kSafeLightPins[i].headerPin,
        ));
      }
    }
    for (final light in _lights) {
      final pin = light.pin;
      if (pin != null && light.on) await _gpio.setPin(pin, true);
    }
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    final index = _lights.indexWhere((l) => l.id == id);
    if (index < 0) return;
    final light = _lights[index];
    light.on = !light.on;
    final pin = light.pin;
    if (pin != null) await _gpio.setPin(pin, light.on);
    notifyListeners();
    await _save();
  }

  Future<void> setAll(bool on) async {
    for (final light in _lights) {
      light.on = on;
      final pin = light.pin;
      if (pin != null) await _gpio.setPin(pin, on);
    }
    notifyListeners();
    await _save();
  }

  Future<void> applyCustomScene() async {
    if (_sceneIds.isEmpty) return;
    for (final light in _lights) {
      final on = _sceneIds.contains(light.id);
      light.on = on;
      final pin = light.pin;
      if (pin != null) await _gpio.setPin(pin, on);
    }
    notifyListeners();
    await _save();
  }

  Future<void> setCustomScene({
    required String name,
    required Iterable<String> lightIds,
  }) async {
    final trimmed = name.trim();
    _sceneName = trimmed.isEmpty ? 'Custom' : trimmed;
    _sceneIds
      ..clear()
      ..addAll(lightIds.where((id) => _lights.any((l) => l.id == id)));
    notifyListeners();
    await _save();
  }

  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    for (final light in _lights) {
      if (light.id == id) {
        light.name = trimmed;
        break;
      }
    }
    notifyListeners();
    await _save();
  }

  Future<bool> addLight(String name) async {
    final unused = _unusedPins;
    if (unused.isEmpty) return false;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    _lights.add(OrLight(
      id: 'light_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      headerPin: unused.first.headerPin,
    ));
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> removeLight(String id) async {
    OrLight? removed;
    _lights.removeWhere((l) {
      if (l.id == id) {
        removed = l;
        return true;
      }
      return false;
    });
    final pin = removed?.pin;
    if (pin != null) await _gpio.setPin(pin, false);
    if (removed != null) _sceneIds.remove(removed!.id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_lights.map((l) => l.toJson()).toList()),
      );
      await prefs.setString(_sceneNameKey, _sceneName);
      await prefs.setStringList(_sceneIdsKey, _sceneIds.toList());
    } catch (e) {
      debugPrint('OrLights: save failed: $e');
    }
  }
}
