import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Hospital account returned by the same login the phone app uses.
class AccountSession {
  final String email;
  final String accessLevel;
  final List<String> assignedAhuIds;

  const AccountSession({
    required this.email,
    required this.accessLevel,
    required this.assignedAhuIds,
  });

  bool get canOperate => accessLevel == 'operator';
}

class AccountAuthResult {
  final AccountSession? session;
  final String? error;

  const AccountAuthResult.success(this.session) : error = null;
  const AccountAuthResult.failure(this.error) : session = null;
}

/// Posts to the web dashboard user login and keeps the session for AWS
/// fallback (device status and commands) until the user logs out.
class AccountAuthService {
  static const String baseUrl = 'https://app.almedequipments.in/api';
  static const String loginEndpoint = '$baseUrl/user/login';

  // Stored in SharedPreferences: the kiosk has no keyring for secure storage.
  static const String _idKey = 'account_login_id';
  static const String _passwordKey = 'account_login_password';
  static const String _cookieKey = 'account_session_cookie';
  static const String _emailKey = 'account_email';
  static const String _accessKey = 'account_access_level';
  static const String _assignedKey = 'account_assigned_ahu_ids';

  String? _id;
  String? _password;
  String? _sessionCookie;

  bool get hasCredentials =>
      (_id ?? '').isNotEmpty && (_password ?? '').isNotEmpty;

  Future<AccountAuthResult> login(String id, String password) async {
    final email = id.trim().toLowerCase();
    if (email.isEmpty || password.isEmpty) {
      return const AccountAuthResult.failure('ID and password are required');
    }

    try {
      final response = await http
          .post(
            Uri.parse(loginEndpoint),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}

      if (response.statusCode != 200 || data['success'] != true) {
        final message = data['message']?.toString();
        return AccountAuthResult.failure(
          message == null || message.isEmpty
              ? 'Invalid ID or password'
              : message,
        );
      }

      final user = data['user'];
      if (user is! Map) {
        return const AccountAuthResult.failure('Login response was incomplete');
      }

      final status = (user['status'] ?? '').toString().toLowerCase();
      if (status != 'active') {
        return AccountAuthResult.failure(
          status.isEmpty
              ? 'This account is not active'
              : 'This account is $status. An administrator must assign an AHU first.',
        );
      }

      final rawIds = user['assigned_ahu_ids'] ?? user['assignedAhuIds'];
      final assigned = <String>[];
      if (rawIds is List) {
        for (final id in rawIds) {
          final value = id.toString().trim();
          if (value.isNotEmpty) assigned.add(value);
        }
      }
      if (assigned.isEmpty) {
        return const AccountAuthResult.failure(
          'No AHU is assigned to this account',
        );
      }

      final access = (user['access_level'] ?? user['accessLevel'] ?? 'viewer')
          .toString()
          .toLowerCase();

      final cookie = response.headers['set-cookie'];
      if (cookie != null && cookie.isNotEmpty) {
        _sessionCookie = cookie.split(';').first;
      }
      _id = email;
      _password = password;

      final session = AccountSession(
        email: (user['email'] ?? email).toString(),
        accessLevel: access == 'operator' ? 'operator' : 'viewer',
        assignedAhuIds: assigned,
      );
      await _save(session);
      return AccountAuthResult.success(session);
    } catch (e) {
      return const AccountAuthResult.failure(
        'Cannot reach the login server. Check the Radxa internet connection.',
      );
    }
  }

  Future<void> _save(AccountSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_idKey, _id ?? '');
      await prefs.setString(_passwordKey, _password ?? '');
      if (_sessionCookie != null) {
        await prefs.setString(_cookieKey, _sessionCookie!);
      }
      await prefs.setString(_emailKey, session.email);
      await prefs.setString(_accessKey, session.accessLevel);
      await prefs.setStringList(_assignedKey, session.assignedAhuIds);
    } catch (_) {}
  }

  /// Restores the last login without contacting the server.
  Future<AccountSession?> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _id = prefs.getString(_idKey);
      _password = prefs.getString(_passwordKey);
      _sessionCookie = prefs.getString(_cookieKey);
      final assigned = prefs.getStringList(_assignedKey) ?? const [];
      if (!hasCredentials || assigned.isEmpty) return null;
      return AccountSession(
        email: prefs.getString(_emailKey) ?? _id!,
        accessLevel: prefs.getString(_accessKey) ?? 'viewer',
        assignedAhuIds: assigned,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _id = null;
    _password = null;
    _sessionCookie = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        _idKey,
        _passwordKey,
        _cookieKey,
        _emailKey,
        _accessKey,
        _assignedKey,
        'account_restricted',
      ]) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  Future<http.Response> _send(
    String method,
    Uri url, {
    String? body,
    bool retried = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (_sessionCookie != null) 'Cookie': _sessionCookie!,
    };
    final response = method == 'POST'
        ? await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 15))
        : await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 15));

    if ((response.statusCode == 401 || response.statusCode == 302) &&
        !retried &&
        hasCredentials) {
      final result = await login(_id!, _password!);
      if (result.session != null) {
        return _send(method, url, body: body, retried: true);
      }
    }
    return response;
  }

  /// `data` from `/api/device/<id>/status`, or null when unavailable.
  Future<Map<String, dynamic>?> fetchDeviceStatus(String deviceId) async {
    if (!hasCredentials) return null;
    try {
      final response = await _send(
        'GET',
        Uri.parse('$baseUrl/device/${Uri.encodeComponent(deviceId)}/status'),
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['success'] == true && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
    } catch (_) {}
    return null;
  }

  /// Publishes [command] to `esp32/<thing>/sub` through the web dashboard.
  Future<bool> sendCommand(String deviceId, Map<String, dynamic> command) async {
    if (!hasCredentials) return false;
    try {
      final response = await _send(
        'POST',
        Uri.parse('$baseUrl/device/${Uri.encodeComponent(deviceId)}/command'),
        body: jsonEncode({'command': command}),
      );
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
