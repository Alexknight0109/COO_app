import 'dart:convert';

import 'package:http/http.dart' as http;

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

/// Posts to the web dashboard user login and keeps only an active assignment.
class AccountAuthService {
  static const String loginEndpoint =
      'https://app.almedequipments.in/api/user/login';

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

      return AccountAuthResult.success(
        AccountSession(
          email: (user['email'] ?? email).toString(),
          accessLevel: access == 'operator' ? 'operator' : 'viewer',
          assignedAhuIds: assigned,
        ),
      );
    } catch (e) {
      return const AccountAuthResult.failure(
        'Cannot reach the login server. Check the Radxa internet connection.',
      );
    }
  }
}
