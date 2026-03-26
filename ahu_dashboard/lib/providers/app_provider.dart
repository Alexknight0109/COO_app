import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ahu_unit.dart';
import '../models/ahu_telemetry.dart';
import '../models/ahu_state.dart';
import '../models/ahu_log.dart';
import '../models/user_role.dart';
import '../services/mqtt_service.dart';

/// Main application state provider with optimized updates for RPi
class AppProvider extends ChangeNotifier {
  Timer? _debounceTimer;
  Timer? _stateDebounceTimer;
  MqttService? _mqttService;
  UserRole? _currentRole;
  final Map<String, AhuUnit> _ahuUnits = {};
  final Map<String, AhuTelemetry> _telemetryData = {};
  final Map<String, AhuState> _stateData = {};
  final Map<String, List<AhuLog>> _logData = {};
  final Map<String, String> _statusData = {};
  final Map<String, bool> _awsStatusData = {};  // AWS cloud connection status per AHU
  final Set<String> _hospitalVisibleAhuKeys = {};
  bool _isConnected = false;
  
  // Cache for frequently accessed data
  List<AhuUnit>? _cachedAhuUnits;
  bool _ahuUnitsChanged = true;
  
  // RPi Performance: Track if updates are pending to batch notifications
  bool _hasPendingUpdates = false;
  DateTime _lastNotify = DateTime.now();
  
  // Screen Lock feature - blocks temp/humidity changes when locked
  // Lock state persists across restarts - can only unlock with passcode
  bool _isScreenLocked = true;  // Default to locked on startup
  String _screenLockPasscode = '123123';  // Default passcode
  static const String _passcodeKey = 'screen_lock_passcode';
  static const String _lockStateKey = 'screen_lock_state';
  static const String _hospitalVisibleAhuKeysKey = 'hospital_visible_ahu_keys';

  // Getters
  UserRole? get currentRole => _currentRole;
  bool get isConnected => _isConnected;
  MqttService? get mqttService => _mqttService;
  bool get isScreenLocked => _isScreenLocked;
  
  /// Initialize and load saved passcode and lock state
  Future<void> loadScreenLockPasscode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _screenLockPasscode = prefs.getString(_passcodeKey) ?? '123123';
      // Load lock state - defaults to true (locked) if not saved
      _isScreenLocked = prefs.getBool(_lockStateKey) ?? true;
      final savedVisibleKeys = prefs.getStringList(_hospitalVisibleAhuKeysKey) ?? const [];
      _hospitalVisibleAhuKeys
        ..clear()
        ..addAll(savedVisibleKeys);
      debugPrint('AppProvider: Loaded screen lock - locked: $_isScreenLocked');
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error loading passcode: $e');
      _isScreenLocked = true; // Default to locked on error
    }
  }
  
  /// Toggle screen lock state
  void toggleScreenLock() {
    _isScreenLocked = !_isScreenLocked;
    _saveLockState();
    debugPrint('AppProvider: Screen ${_isScreenLocked ? "LOCKED" : "UNLOCKED"}');
    notifyListeners();
  }
  
  /// Lock the screen
  void lockScreen() {
    _isScreenLocked = true;
    _saveLockState();
    debugPrint('AppProvider: Screen LOCKED');
    notifyListeners();
  }
  
  /// Unlock screen with passcode verification
  bool unlockScreen(String passcode) {
    if (passcode == _screenLockPasscode) {
      _isScreenLocked = false;
      _saveLockState();
      debugPrint('AppProvider: Screen UNLOCKED');
      notifyListeners();
      return true;
    }
    debugPrint('AppProvider: Unlock failed - wrong passcode');
    return false;
  }
  
  /// Save lock state to SharedPreferences
  Future<void> _saveLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockStateKey, _isScreenLocked);
      debugPrint('AppProvider: Lock state saved: $_isScreenLocked');
    } catch (e) {
      debugPrint('AppProvider: Error saving lock state: $e');
    }
  }
  
  /// Change the screen lock passcode
  Future<bool> changeScreenLockPasscode(String currentPasscode, String newPasscode) async {
    if (currentPasscode != _screenLockPasscode) {
      debugPrint('AppProvider: Passcode change failed - wrong current passcode');
      return false;
    }
    
    if (newPasscode.length != 6) {
      debugPrint('AppProvider: Passcode change failed - must be 6 digits');
      return false;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_passcodeKey, newPasscode);
      _screenLockPasscode = newPasscode;
      debugPrint('AppProvider: Screen lock passcode changed successfully');
      return true;
    } catch (e) {
      debugPrint('AppProvider: Error saving passcode: $e');
      return false;
    }
  }
  
  /// Get current passcode (for admin settings display)
  String get currentPasscode => _screenLockPasscode;
  
  /// Get AWS cloud connection status for specific AHU
  bool isAwsConnected(String ahuId) => _awsStatusData[ahuId] ?? false;
  
  /// Get AHU units list with caching
  List<AhuUnit> get ahuUnits {
    if (_ahuUnitsChanged || _cachedAhuUnits == null) {
      _cachedAhuUnits = List.unmodifiable(_ahuUnits.values.toList());
      _ahuUnitsChanged = false;
    }
    return _cachedAhuUnits!;
  }

  /// AHUs visible on hospital dashboard.
  /// Admin sees all AHUs regardless of visibility toggles.
  List<AhuUnit> get visibleAhuUnits {
    final units = ahuUnits;
    if (_currentRole == UserRole.admin) return units;
    return units.where((ahu) => isAhuVisibleToHospital(ahu)).toList();
  }

  Set<String> get hospitalVisibleAhuKeys => Set.unmodifiable(_hospitalVisibleAhuKeys);

  /// Get telemetry for specific AHU
  AhuTelemetry? getTelemetry(String ahuId) => _telemetryData[ahuId];

  /// Get state for specific AHU
  AhuState? getState(String ahuId) => _stateData[ahuId];

  /// Get logs for specific AHU
  List<AhuLog> getLogs(String ahuId) => _logData[ahuId] ?? const [];

  /// Get status for specific AHU
  String? getStatus(String ahuId) => _statusData[ahuId];

  String _ahuVisibilityKey(AhuUnit ahu) => '${ahu.id}@${ahu.site}/${ahu.room}';
  bool isAhuVisibleToHospital(AhuUnit ahu) {
    // Default to visible unless explicitly disabled by admin.
    return _hospitalVisibleAhuKeys.contains(_ahuVisibilityKey(ahu));
  }

  Future<void> setAhuVisibilityForHospital(AhuUnit ahu, bool isVisible) async {
    final key = _ahuVisibilityKey(ahu);
    if (isVisible) {
      _hospitalVisibleAhuKeys.add(key);
    } else {
      _hospitalVisibleAhuKeys.remove(key);
    }
    await _saveHospitalVisibility();
    notifyListeners();
  }

  Future<void> _saveHospitalVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _hospitalVisibleAhuKeysKey,
        _hospitalVisibleAhuKeys.toList(),
      );
    } catch (e) {
      debugPrint('AppProvider: Error saving AHU visibility: $e');
    }
  }

  /// Set user role
  void setUserRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  /// Initialize MQTT connection
  /// Dashboard runs ON the Raspberry Pi, so connect to localhost
  /// ESP32 connects to this same broker at 192.168.1.100 (RPi static IP on AlMed network)
  Future<bool> initializeMqtt({
    String? broker,
    int? port,
    String? username,
    String? password,
  }) async {
    // Dashboard runs on RPi - connect to local MQTT broker
    // Single WiFi mode: Both ESP32 and RPi connect to "AlMed" network
    final defaultBroker = broker ?? 'localhost';
    
    _mqttService = MqttService(
      broker: defaultBroker,
      port: port ?? 1883,
      username: username ?? 'almed',
      password: password ?? 'Almed1234\$',
      useTLS: false,
    );
    
    debugPrint('AppProvider: Initializing MQTT - Connecting to local broker at $defaultBroker:${port ?? 1883}');

    // Listen to connection status
    _mqttService!.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    // Listen to telemetry updates - auto-register devices for multi-AHU discovery.
    _mqttService!.telemetryStream.listen((entry) {
      if (!_isMatchingAhu(entry.key)) {
        _ensureAhuRegistered(entry.key);
        _statusData[_extractAhuId(entry.key)] = 'online';
      }
      final ahuId = _extractAhuId(entry.key);
      _telemetryData[ahuId] = entry.value;
      _debouncedNotify();  // 250ms debounce for RPi
    });

    // Listen to state updates - auto-register devices that send state (dynamic discovery)
    _mqttService!.stateStream.listen((entry) {
      // Auto-register AHU if we receive state data (fallback for status topic issues)
      if (!_isMatchingAhu(entry.key)) {
        debugPrint('AppProvider: Auto-registering AHU from state message');
        _ensureAhuRegistered(entry.key);
        _statusData[_extractAhuId(entry.key)] = 'online';  // Mark as online since we got data
      }
      final ahuId = _extractAhuId(entry.key);
      _stateData[ahuId] = entry.value;
      _debouncedStateNotify();  // Debounced for RPi performance
    });

    // Listen to log updates - only process if device is registered
    _mqttService!.logStream.listen((entry) {
      if (!_isMatchingAhu(entry.key)) return; // Ignore unregistered devices
      final ahuId = _extractAhuId(entry.key);
      
      final logs = _logData.putIfAbsent(ahuId, () => []);
      logs.add(entry.value);
      
      // Keep only last 70 logs - FIFO (oldest gets deleted as new ones arrive)
      while (logs.length > 70) {
        logs.removeAt(0);
      }
      _debouncedNotify();  // Debounced for RPi
    });

    // Listen to status updates - only register ONLINE devices (dynamic discovery)
    _mqttService!.statusStream.listen((entry) {
      final ahuId = _extractAhuId(entry.key);
      final status = entry.value.trim().toLowerCase();
      
      if (status == 'online') {
        // Device is online - register if new.
      _ensureAhuRegistered(entry.key);
      _statusData[ahuId] = entry.value;
        _debouncedStateNotify();
      } else if (status == 'offline') {
        // Device went offline - just update status if registered, don't register new
        if (_isMatchingAhu(entry.key)) {
          _statusData[ahuId] = entry.value;
          _debouncedStateNotify();
        }
      }
    });

    // Listen to AWS connection status updates
    _mqttService!.awsStatusStream.listen((entry) {
      if (!_isMatchingAhu(entry.key)) return;  // Only process registered devices
      final ahuId = _extractAhuId(entry.key);
      _awsStatusData[ahuId] = entry.value;
      debugPrint('AppProvider: AWS status for $ahuId: ${entry.value ? "CONNECTED" : "DISCONNECTED"}');
      _debouncedStateNotify();  // Debounced for RPi
    });

    final connected = await _mqttService!.connect();
    return connected;
  }
  
  /// Extract AHU ID from topic data
  String _extractAhuId(String topicData) {
    final parts = topicData.split('|');
    return parts.isNotEmpty ? parts[0] : topicData;
  }

  /// Debounced notify to reduce UI rebuilds (optimized for RPi)
  void _debouncedNotify() {
    _hasPendingUpdates = true;
    _debounceTimer?.cancel();
    // RPi Performance: Increased debounce from 100ms to 250ms
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (_hasPendingUpdates) {
        _hasPendingUpdates = false;
        _lastNotify = DateTime.now();
        notifyListeners();
      }
    });
  }
  
  /// Debounced state notify (for critical state changes)
  void _debouncedStateNotify() {
    _stateDebounceTimer?.cancel();
    // State updates need faster response but still debounced
    _stateDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      _lastNotify = DateTime.now();
      notifyListeners();
    });
  }
  
  /// Throttled notify - ensures minimum time between notifications
  void _throttledNotify() {
    final now = DateTime.now();
    if (now.difference(_lastNotify).inMilliseconds > 300) {
      _lastNotify = now;
      notifyListeners();
    } else {
      _debouncedNotify();
    }
  }

  /// Add AHU unit to monitor
  void addAhuUnit(AhuUnit ahu) {
    _ahuUnits[ahu.id] = ahu;
    _ahuUnitsChanged = true;
    _mqttService?.subscribeToAhu(ahu);
    notifyListeners();
  }

  /// Remove AHU unit
  void removeAhuUnit(String ahuId) {
    _ahuUnits.remove(ahuId);
    _telemetryData.remove(ahuId);
    _stateData.remove(ahuId);
    _logData.remove(ahuId);
    _statusData.remove(ahuId);
    _ahuUnitsChanged = true;
    notifyListeners();
  }

  /// Clear all data - start fresh (forget previous devices and logs)
  void clearAllData() {
    debugPrint('AppProvider: Clearing all previous device data and logs');
    _ahuUnits.clear();
    _telemetryData.clear();
    _stateData.clear();
    _logData.clear();
    _statusData.clear();
    _awsStatusData.clear();  // Also clear AWS status
    _cachedAhuUnits = null;
    _ahuUnitsChanged = true;
    notifyListeners();
  }

  /// Load default AHU units - just clears data and waits for auto-discovery
  void loadDefaultAhus() {
    // Clear any previous data first to start fresh
    clearAllData();
    
    // Don't pre-register any AHU - let all AHUs be auto-discovered from MQTT.
    debugPrint('AppProvider: Ready for multi-AHU auto-discovery on almed/ahu/#');
  }

  /// Check if message is from currently registered AHU
  /// Returns true only if the message matches our active device
  bool _isMatchingAhu(String topicData) {
    if (_ahuUnits.isEmpty) return false; // No device registered yet
    
    final parts = topicData.split('|');
    final ahuId = parts.isNotEmpty ? parts[0] : topicData;
    final site = parts.length > 1 ? parts[1] : '';
    final room = parts.length > 2 ? parts[2] : '';
    
    // Check if this matches our currently registered AHU
    for (final ahu in _ahuUnits.values) {
      if (ahu.id == ahuId && ahu.site == site && ahu.room == room) {
        return true;
      }
    }
    return false;
  }
  
  /// Auto-discover and register AHU when data arrives.
  void _ensureAhuRegistered(String topicData, {String? site, String? room}) {
    final parts = topicData.split('|');
    final ahuId = parts.isNotEmpty ? parts[0] : topicData;
    final discoveredSite = parts.length > 1 ? parts[1] : (site ?? 'unknown');
    final discoveredRoom = parts.length > 2 ? parts[2] : (room ?? 'unknown');
    
    // Create unique key for this specific AHU (id + site + room combo)
    final uniqueKey = '$ahuId@$discoveredSite/$discoveredRoom';
    
    // Check if this exact AHU is already registered
    for (final ahu in _ahuUnits.values) {
      if (ahu.id == ahuId && ahu.site == discoveredSite && ahu.room == discoveredRoom) {
        return; // Already registered, nothing to do
      }
    }
    
    // Create friendly display name from site and room
    String friendlyName = discoveredRoom.replaceAll('_', ' ');
    if (discoveredSite.isNotEmpty && discoveredSite != 'unknown') {
      final siteName = discoveredSite.replaceAll('_', ' ');
      final roomName = discoveredRoom.replaceAll('_', ' ');
      friendlyName = '$siteName - $roomName';
    }
    
    final newAhu = AhuUnit(
      id: ahuId,
      name: friendlyName,
      site: discoveredSite,
      room: discoveredRoom,
      org: 'almed',
    );
    
    addAhuUnit(newAhu);
    // New devices are visible to hospital by default.
    _hospitalVisibleAhuKeys.add(uniqueKey);
    _saveHospitalVisibility();
    debugPrint('AppProvider: Auto-discovered AHU - $ahuId at $discoveredSite/$discoveredRoom');
  }

  /// Check if MQTT is ready for commands
  bool get canSendCommands => _mqttService != null && _isConnected;

  /// Start AHU
  bool startAhu(String ahuId) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send start command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.startAhu(ahu);
      debugPrint('AppProvider: Start command sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Stop AHU
  bool stopAhu(String ahuId) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send stop command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.stopAhu(ahu);
      debugPrint('AppProvider: Stop command sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Toggle AHU
  bool toggleAhu(String ahuId) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send toggle command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.toggleAhu(ahu);
      debugPrint('AppProvider: Toggle command sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Set temperature setpoint
  bool setTemperature(String ahuId, double temp) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send temperature command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.setTemperature(ahu, temp);
      debugPrint('AppProvider: Temperature command ($temp) sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Set humidity setpoint
  bool setHumidity(String ahuId, double humidity) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send humidity command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.setHumidity(ahu, humidity);
      debugPrint('AppProvider: Humidity command ($humidity) sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Set fan speed (0=OFF, 1=LOW, 2=MED, 3=HIGH)
  bool setFanSpeed(String ahuId, int speed) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send fan speed command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.setFanSpeed(ahu, speed);
      debugPrint('AppProvider: Fan speed command ($speed) sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Toggle fan speed
  bool toggleFanSpeed(String ahuId) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send fan toggle command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.toggleFanSpeed(ahu);
      debugPrint('AppProvider: Fan toggle command sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Set operation mode (Admin only)
  bool setMode(String ahuId, bool onlineMode) {
    if (_currentRole != UserRole.admin) return false;
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send mode command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.setMode(ahu, onlineMode);
      debugPrint('AppProvider: Mode command (${onlineMode ? 'online' : 'offline'}) sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Set CP mode (dual or single) - Available to all users
  bool setCpMode(String ahuId, String mode) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send CP mode command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.setCpMode(ahu, mode);
      debugPrint('AppProvider: CP mode command ($mode) sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Set active CP (1 or 2) - Available to all users
  bool setCpActive(String ahuId, int cpActive) {
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send CP active command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.setCpActive(ahu, cpActive);
      debugPrint('AppProvider: CP active command ($cpActive) sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Reset ESP32 (Admin only) - same as pressing physical reset button
  bool resetEsp32(String ahuId) {
    if (_currentRole != UserRole.admin) return false;
    if (!canSendCommands) {
      debugPrint('AppProvider: Cannot send reset command - MQTT not connected');
      return false;
    }
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService!.resetEsp32(ahu);
      debugPrint('AppProvider: Reset command sent to ${ahu.cmdTopic}');
      return true;
    }
    debugPrint('AppProvider: AHU $ahuId not found');
    return false;
  }

  /// Provision WiFi (admin only)
  void provisionWifi(
    String ahuId, {
    String? primarySsid,
    String? primaryPass,
    String? secondarySsid,
    String? secondaryPass,
  }) {
    if (_currentRole != UserRole.admin) return;
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService?.provisionWifi(
        ahu,
        primarySsid: primarySsid,
        primaryPass: primaryPass,
        secondarySsid: secondarySsid,
        secondaryPass: secondaryPass,
      );
    }
  }

  /// Provision broker (admin only)
  void provisionBroker(String ahuId, String host, int port) {
    if (_currentRole != UserRole.admin) return;
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      _mqttService?.provisionBroker(ahu, host, port);
    }
  }

  /// Provision motor timings (admin only)
  void provisionMotorTimings(String ahuId, {
    int? m1Start,
    int? m1Post,
    int? m2Interval,
    int? m2Run,
    int? m2Delay,
  }) {
    if (_currentRole != UserRole.admin) return;
    final ahu = _ahuUnits[ahuId];
    if (ahu != null) {
      final waitTime = m2Interval ?? 30;
      final m2RunTime = m2Run ?? 10;
      final actualInterval = waitTime + m2RunTime;
      
      debugPrint('AppProvider: M2 Interval calculation - Wait: ${waitTime}s + Run: ${m2RunTime}s = Actual: ${actualInterval}s');
      
      _mqttService?.provisionMotorTimings(
        ahu,
        m1Start: m1Start,
        m1Post: m1Post,
        m2Interval: actualInterval,
        m2Run: m2Run,
        m2Delay: m2Delay,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _stateDebounceTimer?.cancel();
    _mqttService?.dispose();
    super.dispose();
  }
}
