import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // For Windows Desktop app, use localhost or 127.0.0.1
  // Flutter desktop apps use http://127.0.0.1 for local connections
  static const String baseUrl = 'http://127.0.0.1:3001/api';
  
  // Alternative: Use localhost if 127.0.0.1 doesn't work
  // static const String baseUrl = 'http://localhost:3001/api';
  
  late final Dio _dio;
  late final SharedPreferences _prefs;

  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle unauthorized - clear token and redirect to login
          _prefs.remove('auth_token');
        }
        return handler.next(error);
      },
    ));
  }

  // Auth endpoints
  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/auth/register', data: data);
  }

  Future<Response> getProfile() async {
    return await _dio.get('/auth/profile');
  }

  // Tasks endpoints
  Future<Response> getTasks({String? userId}) async {
    return await _dio.get('/tasks', queryParameters: userId != null ? {'userId': userId} : null);
  }

  Future<Response> getTask(String id) async {
    return await _dio.get('/tasks/$id');
  }

  Future<Response> createTask(Map<String, dynamic> data) async {
    return await _dio.post('/tasks', data: data);
  }

  Future<Response> updateTask(String id, Map<String, dynamic> data) async {
    return await _dio.patch('/tasks/$id', data: data);
  }

  Future<Response> deleteTask(String id) async {
    return await _dio.delete('/tasks/$id');
  }

  Future<Response> updateTaskStatus(String id, String status) async {
    return await _dio.patch('/tasks/$id/status', data: {'status': status});
  }

  // Messages endpoints
  Future<Response> getMessages() async {
    return await _dio.get('/messages');
  }

  Future<Response> getConversation(String userId) async {
    return await _dio.get('/messages/conversation/$userId');
  }

  Future<Response> sendMessage(Map<String, dynamic> data) async {
    return await _dio.post('/messages', data: data);
  }

  Future<Response> markMessageAsRead(String messageId) async {
    return await _dio.post('/messages/$messageId/read');
  }

  // Projects endpoints
  Future<Response> getProjects() async {
    return await _dio.get('/projects');
  }

  Future<Response> getProject(String id) async {
    return await _dio.get('/projects/$id');
  }

  Future<Response> createProject(Map<String, dynamic> data) async {
    return await _dio.post('/projects', data: data);
  }

  // Sites endpoints
  Future<Response> getSites() async {
    return await _dio.get('/sites');
  }

  Future<Response> getSite(String id) async {
    return await _dio.get('/sites/$id');
  }

  // Complaints endpoints
  Future<Response> getComplaints() async {
    return await _dio.get('/complaints');
  }

  Future<Response> getComplaint(String id) async {
    return await _dio.get('/complaints/$id');
  }

  // Factory endpoints
  Future<Response> getFactoryProductions() async {
    return await _dio.get('/factory');
  }

  // Inventory endpoints
  Future<Response> getInventoryItems() async {
    return await _dio.get('/inventory');
  }

  // Accounts endpoints
  Future<Response> getAccounts() async {
    return await _dio.get('/accounts');
  }

  // Calendar endpoints
  Future<Response> getCalendarEvents() async {
    return await _dio.get('/calendar');
  }

  Future<Response> createCalendarEvent(Map<String, dynamic> data) async {
    return await _dio.post('/calendar', data: data);
  }

  // Notifications endpoints
  Future<Response> getNotifications() async {
    return await _dio.get('/notifications');
  }

  Future<Response> markNotificationAsRead(String id) async {
    return await _dio.patch('/notifications/$id/read');
  }

  // Users endpoints
  Future<Response> getUsers() async {
    return await _dio.get('/users');
  }

  Future<Response> getUser(String id) async {
    return await _dio.get('/users/$id');
  }

  // HR endpoints
  Future<Response> getEmployees() async {
    return await _dio.get('/hr/employees');
  }

  Future<Response> getDepartments() async {
    return await _dio.get('/hr/departments');
  }

  // Reports endpoints
  Future<Response> getReports() async {
    return await _dio.get('/reports');
  }
}
