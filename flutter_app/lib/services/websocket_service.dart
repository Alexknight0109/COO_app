import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketService {
  IO.Socket? _socket;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _taskUpdateController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  Stream<Map<String, dynamic>> get taskUpdateStream => _taskUpdateController.stream;

  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('No auth token found. Cannot connect to WebSocket.');
        return;
      }

      // For Windows Desktop app, use 127.0.0.1
      _socket = IO.io(
        'http://127.0.0.1:3001',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setQuery({'token': token})
            .enableAutoConnect()
            .build(),
      );

      _socket?.onConnect((_) {
        print('WebSocket connected');
      });

      _socket?.onDisconnect((_) {
        print('WebSocket disconnected');
      });

      _socket?.onError((error) {
        print('WebSocket error: $error');
      });

      // Listen for new messages
      _socket?.on('new_message', (data) {
        _messageController.add(Map<String, dynamic>.from(data));
      });

      // Listen for notifications
      _socket?.on('notification', (data) {
        _notificationController.add(Map<String, dynamic>.from(data));
      });

      // Listen for task updates
      _socket?.on('task_updated', (data) {
        _taskUpdateController.add(Map<String, dynamic>.from(data));
      });

      // Listen for broadcast messages
      _socket?.on('broadcast', (data) {
        _notificationController.add(Map<String, dynamic>.from(data));
      });

    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void sendMessage(String event, Map<String, dynamic> data) {
    _socket?.emit(event, data);
  }

  bool get isConnected => _socket?.connected ?? false;

  void dispose() {
    disconnect();
    _messageController.close();
    _notificationController.close();
    _taskUpdateController.close();
  }
}
