import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _apiService.initialize();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['access_token'];
        final user = response.data['user'];
        
        await _prefs?.setString('auth_token', token);
        await _prefs?.setString('user_id', user['id']);
        await _prefs?.setString('user_email', user['email']);
        await _prefs?.setString('user_name', '${user['firstName']} ${user['lastName']}');
        await _prefs?.setString('user_role', user['role']);
        
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final response = await _apiService.register({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      });
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  String? getToken() {
    return _prefs?.getString('auth_token');
  }

  String? getUserId() {
    return _prefs?.getString('user_id');
  }

  String? getUserEmail() {
    return _prefs?.getString('user_email');
  }

  String? getUserName() {
    return _prefs?.getString('user_name');
  }

  String? getUserRole() {
    return _prefs?.getString('user_role');
  }

  bool isAuthenticated() {
    return getToken() != null;
  }

  Future<void> logout() async {
    await _prefs?.remove('auth_token');
    await _prefs?.remove('user_id');
    await _prefs?.remove('user_email');
    await _prefs?.remove('user_name');
    await _prefs?.remove('user_role');
  }
}
