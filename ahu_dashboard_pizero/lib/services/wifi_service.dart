import 'dart:io';
import 'package:flutter/foundation.dart';

/// WiFi network model
class WiFiNetwork {
  final String ssid;
  final String? security; // WPA2, WPA, Open, etc.
  final int signal; // Signal strength (0-100)
  final bool isConnected;
  final String? bssid;

  WiFiNetwork({
    required this.ssid,
    this.security,
    required this.signal,
    this.isConnected = false,
    this.bssid,
  });

  @override
  String toString() => 'WiFiNetwork(ssid: $ssid, signal: $signal%, security: $security, connected: $isConnected)';
}

/// WiFi service for Linux/Raspberry Pi
class WiFiService {
  static final WiFiService _instance = WiFiService._internal();
  factory WiFiService() => _instance;
  WiFiService._internal();

  /// Check if WiFi is available (Linux only)
  Future<bool> isAvailable() async {
    if (!Platform.isLinux) return false;
    
    try {
      final result = await Process.run('which', ['nmcli']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('WiFiService: nmcli not found: $e');
      return false;
    }
  }

  /// Get currently connected WiFi network
  Future<WiFiNetwork?> getCurrentConnection() async {
    if (!await isAvailable()) return null;

    try {
      final result = await Process.run('nmcli', [
        '-t',
        '-f',
        'ACTIVE,SSID,SIGNAL,SECURITY',
        'device',
        'wifi',
      ]);

      if (result.exitCode != 0) {
        debugPrint('WiFiService: Failed to get current connection: ${result.stderr}');
        return null;
      }

      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(':');
        if (parts.length >= 4 && parts[0] == '*') {
          return WiFiNetwork(
            ssid: parts[1],
            signal: int.tryParse(parts[2]) ?? 0,
            security: parts.length > 3 ? parts[3] : null,
            isConnected: true,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('WiFiService: Error getting current connection: $e');
      return null;
    }
  }

  /// Scan for available WiFi networks
  Future<List<WiFiNetwork>> scanNetworks() async {
    if (!await isAvailable()) return [];

    try {
      // Trigger a new scan
      await Process.run('nmcli', ['device', 'wifi', 'rescan']);

      // Wait a bit for scan to complete
      await Future.delayed(const Duration(seconds: 2));

      // Get list of networks
      final result = await Process.run('nmcli', [
        '-t',
        '-f',
        'SSID,SIGNAL,SECURITY,BSSID',
        'device',
        'wifi',
        'list',
      ]);

      if (result.exitCode != 0) {
        debugPrint('WiFiService: Failed to scan networks: ${result.stderr}');
        return [];
      }

      final currentConnection = await getCurrentConnection();
      final networks = <WiFiNetwork>[];
      final seenSSIDs = <String>{};

      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(':');
        if (parts.length >= 3) {
          final ssid = parts[0].trim();
          if (ssid.isEmpty || ssid == '--') continue; // Skip empty or hidden SSIDs
          
          // Avoid duplicates (nmcli sometimes shows same SSID multiple times with different BSSIDs)
          if (seenSSIDs.contains(ssid)) continue;
          seenSSIDs.add(ssid);

          final signal = int.tryParse(parts[1]) ?? 0;
          final security = parts.length > 2 ? parts[2] : null;
          final bssid = parts.length > 3 ? parts[3] : null;

          final isConnected = currentConnection?.ssid == ssid;

          networks.add(WiFiNetwork(
            ssid: ssid,
            signal: signal,
            security: security,
            isConnected: isConnected,
            bssid: bssid,
          ));
        }
      }

      // Sort by signal strength (strongest first), then by SSID
      networks.sort((a, b) {
        if (a.isConnected != b.isConnected) {
          return a.isConnected ? -1 : 1; // Connected first
        }
        if (a.signal != b.signal) {
          return b.signal.compareTo(a.signal); // Stronger signal first
        }
        return a.ssid.compareTo(b.ssid);
      });

      return networks;
    } catch (e) {
      debugPrint('WiFiService: Error scanning networks: $e');
      return [];
    }
  }

  /// Connect to a WiFi network
  Future<bool> connect(String ssid, String password) async {
    if (!await isAvailable()) return false;

    try {
      // Delete existing connection if it exists
      await Process.run('nmcli', ['connection', 'delete', ssid], runInShell: false);

      // Create new connection
      final result = await Process.run('nmcli', [
        'device',
        'wifi',
        'connect',
        ssid,
        'password',
        password,
      ]);

      if (result.exitCode == 0) {
        debugPrint('WiFiService: Successfully connected to $ssid');
        return true;
      } else {
        debugPrint('WiFiService: Failed to connect: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('WiFiService: Error connecting: $e');
      return false;
    }
  }

  /// Connect to an open (no password) WiFi network
  Future<bool> connectOpen(String ssid) async {
    if (!await isAvailable()) return false;

    try {
      final result = await Process.run('nmcli', [
        'device',
        'wifi',
        'connect',
        ssid,
      ]);

      if (result.exitCode == 0) {
        debugPrint('WiFiService: Successfully connected to open network $ssid');
        return true;
      } else {
        debugPrint('WiFiService: Failed to connect: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('WiFiService: Error connecting: $e');
      return false;
    }
  }

  /// Disconnect from current WiFi network
  Future<bool> disconnect() async {
    if (!await isAvailable()) return false;

    try {
      final result = await Process.run('nmcli', ['device', 'disconnect', 'wlan0']);
      
      if (result.exitCode == 0) {
        debugPrint('WiFiService: Successfully disconnected');
        return true;
      } else {
        debugPrint('WiFiService: Failed to disconnect: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('WiFiService: Error disconnecting: $e');
      return false;
    }
  }

  /// Check if WiFi is enabled
  Future<bool> isEnabled() async {
    if (!await isAvailable()) return false;

    try {
      final result = await Process.run('nmcli', ['radio', 'wifi']);
      return result.stdout.toString().trim().contains('enabled');
    } catch (e) {
      debugPrint('WiFiService: Error checking WiFi status: $e');
      return false;
    }
  }

  /// Enable/disable WiFi radio
  Future<bool> setEnabled(bool enabled) async {
    if (!await isAvailable()) return false;

    try {
      final result = await Process.run('nmcli', ['radio', 'wifi', enabled ? 'on' : 'off']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('WiFiService: Error setting WiFi status: $e');
      return false;
    }
  }
}

