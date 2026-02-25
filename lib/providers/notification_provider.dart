import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo simple para una notificación en la app
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    receivedAt: DateTime.tryParse(json['receivedAt'] ?? '') ?? DateTime.now(),
    isRead: json['isRead'] ?? false,
  );
}

/// Provider que gestiona las notificaciones en la app.
/// Almacena notificaciones localmente con SharedPreferences.
class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'app_notifications';
  static const int _maxNotifications = 50; // Máximo de notificaciones almacenadas

  List<AppNotification> _notifications = [];
  bool _isLoaded = false;

  List<AppNotification> get notifications => _notifications;
  
  /// Cantidad de notificaciones no leídas
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Si hay notificaciones sin leer
  bool get hasUnread => unreadCount > 0;

  /// Cargar notificaciones desde almacenamiento local
  Future<void> loadNotifications() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _notifications = jsonList
            .map((json) => AppNotification.fromJson(json))
            .toList();
        // Ordenar: más recientes primero
        _notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error cargando notificaciones: $e');
    }
  }

  /// Agregar una nueva notificación (llamado desde NotificationService)
  Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      receivedAt: DateTime.now(),
    );

    _notifications.insert(0, notification);

    // Limitar cantidad máxima
    if (_notifications.length > _maxNotifications) {
      _notifications = _notifications.sublist(0, _maxNotifications);
    }

    await _saveToStorage();
    notifyListeners();
  }

  /// Marcar una notificación como leída
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveToStorage();
      notifyListeners();
    }
  }

  /// Marcar todas como leídas
  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    await _saveToStorage();
    notifyListeners();
  }

  /// Eliminar una notificación
  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  /// Limpiar todas las notificaciones
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToStorage();
    notifyListeners();
  }

  /// Guardar en SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('⚠️ Error guardando notificaciones: $e');
    }
  }
}
