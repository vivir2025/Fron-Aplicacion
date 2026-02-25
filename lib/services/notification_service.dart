import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../providers/notification_provider.dart';

/// Handler de mensajes en background (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handler silencioso para mensajes en background
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Referencia al provider de notificaciones (se asigna desde main.dart)
  NotificationProvider? _notificationProvider;

  /// Asignar el provider de notificaciones para almacenar mensajes recibidos
  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  // Keys para SharedPreferences (almacenamiento offline)
  static const String _keyPendingToken = 'pending_fcm_token';
  static const String _keyPendingUserId = 'pending_fcm_user_id';
  static const String _keyLastRegisteredToken = 'last_registered_fcm_token';
  static const String _keyTokenRegistered = 'fcm_token_registered';

  // Topic para notificaciones broadcast (send-to-all)
  static const String topicTodosLosUsuarios = 'all_users';

  // Canal de notificaciones Android
  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'bornive_notificaciones',
    'Notificaciones Bornive',
    description: 'Notificaciones de la aplicación Bornive',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Inicializar Firebase Messaging + Notificaciones Locales
  Future<void> initialize() async {
    try {
      // 1. Solicitar permisos de notificación
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      // 2. Inicializar flutter_local_notifications
      await _inicializarNotificacionesLocales();

      // 3. Configurar handlers de mensajes FCM
      _configurarHandlers();

      // 4. Escuchar cambios de token
      _fcm.onTokenRefresh.listen((newToken) {
        _guardarTokenPendiente(newToken);
      });

    } catch (e) {
      // Error inicializando - silencioso
    }
  }

  /// Inicializar notificaciones locales (para mostrar en foreground)
  Future<void> _inicializarNotificacionesLocales() async {
    // Configuración Android - usa icono monocromo para notificaciones
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    
    // Configuración iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Ya lo pide FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Crear canal de notificaciones en Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_canal);
    }
  }

  /// Configurar handlers para mensajes FCM
  void _configurarHandlers() {
    // ✅ Mensaje en FOREGROUND → mostrar como notificación del sistema + guardar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _mostrarNotificacionSistema(message);
      _guardarNotificacionEnProvider(message);
    });

    // Cuando tocan la notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _guardarNotificacionEnProvider(message);
    });

    // App abierta desde notificación (app terminada)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _guardarNotificacionEnProvider(message);
      }
    });
  }

  /// Mostrar notificación del sistema cuando la app está en foreground
  Future<void> _mostrarNotificacionSistema(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetalles = AndroidNotificationDetails(
      _canal.id,
      _canal.name,
      channelDescription: _canal.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF2E7D32),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
      ),
    );

    final detalles = NotificationDetails(
      android: androidDetalles,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único
      notification.title ?? 'Bornive',
      notification.body ?? '',
      detalles,
    );
  }

  /// Guardar la notificación recibida en el provider para mostrar en la campanita
  void _guardarNotificacionEnProvider(RemoteMessage message) {
    try {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title'] ?? 'Bornive';
      final body = notification?.body ?? message.data['body'] ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        _notificationProvider?.addNotification(
          title: title,
          body: body,
        );
      }
    } catch (e) {
      // Silencioso
    }
  }

  // ========================================================================
  // REGISTRO DE TOKEN - OFFLINE SAFE
  // ========================================================================

  /// Registrar token FCM cuando el usuario inicia sesión
  /// Si no hay internet, guarda el token localmente para enviarlo después
  Future<void> registrarTokenConUsuario(String userId, String authToken) async {
    try {
      // 1. Obtener token FCM del dispositivo
      String? fcmToken = await _fcm.getToken();

      if (fcmToken == null) {
        return;
      }

      // 2. Verificar si el token ya fue registrado previamente
      final prefs = await SharedPreferences.getInstance();
      final lastRegistered = prefs.getString(_keyLastRegisteredToken);
      
      if (lastRegistered == fcmToken && prefs.getBool(_keyTokenRegistered) == true) {
        return;
      }

      // 3. Verificar conectividad
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline) {
        // ✅ Hay internet: enviar directamente al backend
        await _enviarTokenAlBackend(userId, fcmToken, authToken);
      } else {
        await _guardarTokenPendiente(fcmToken, userId: userId);
      }

      // ✅ Suscribir al topic de broadcast (funciona offline, se sincroniza después)
      await suscribirATema(topicTodosLosUsuarios);
      
    } catch (e) {
      // No bloquear el login por error de token
    }
  }

  /// Enviar token al backend
  Future<bool> _enviarTokenAlBackend(String userId, String fcmToken, String authToken) async {
    try {
      String platform = Platform.isAndroid ? 'android' : 'ios';

      final url = '${ApiService.baseUrl}/notifications/register-device';
      final body = {
        'user_id': userId,
        'fcm_token': fcmToken,
        'platform': platform,
        'device_name': _getDeviceName(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        
        // Guardar que el token fue registrado exitosamente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastRegisteredToken, fcmToken);
        await prefs.setBool(_keyTokenRegistered, true);
        // Limpiar pendientes
        await prefs.remove(_keyPendingToken);
        await prefs.remove(_keyPendingUserId);
        
        return true;
      } else {
        await _guardarTokenPendiente(fcmToken, userId: userId);
        return false;
      }
    } catch (e) {
      await _guardarTokenPendiente(fcmToken, userId: userId);
      return false;
    }
  }

  /// Guardar token pendiente en SharedPreferences
  Future<void> _guardarTokenPendiente(String token, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPendingToken, token);
      if (userId != null) {
        await prefs.setString(_keyPendingUserId, userId);
      }
      await prefs.setBool(_keyTokenRegistered, false);
    } catch (e) {
      // Silencioso
    }
  }

  /// Reintentar envío de token pendiente (llamar cuando vuelva la conexión)
  Future<void> reintentarRegistroPendiente(String authToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString(_keyPendingToken);
      final pendingUserId = prefs.getString(_keyPendingUserId);

      if (pendingToken == null || pendingUserId == null) {
        return; // No hay token pendiente
      }

      // Verificar conectividad
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return;
      }

      await _enviarTokenAlBackend(pendingUserId, pendingToken, authToken);
    } catch (e) {
      // Silencioso
    }
  }

  // ========================================================================
  // DESREGISTRO DE TOKEN - OFFLINE SAFE
  // ========================================================================

  /// Desregistrar token cuando el usuario cierra sesión
  Future<void> desregistrarToken(String? authToken) async {
    try {
      // ✅ Desuscribir del topic de broadcast
      await desuscribirDeTema(topicTodosLosUsuarios);
      
      String? fcmToken = await _fcm.getToken();

      // Verificar conectividad antes de intentar enviar al servidor
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline && fcmToken != null && authToken != null) {
        try {
          await http.post(
            Uri.parse('${ApiService.baseUrl}/notifications/unregister-device'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'fcm_token': fcmToken}),
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          // No es crítico
        }
      }

      // Eliminar token del dispositivo
      try {
        await _fcm.deleteToken();
      } catch (e) {
        // Silencioso
      }

      // Limpiar datos locales de token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingToken);
      await prefs.remove(_keyPendingUserId);
      await prefs.remove(_keyLastRegisteredToken);
      await prefs.setBool(_keyTokenRegistered, false);

    } catch (e) {
      // No bloquear logout
    }
  }

  // ========================================================================
  // UTILIDADES
  // ========================================================================

  /// Obtener nombre del dispositivo
  String _getDeviceName() {
    if (Platform.isAndroid) {
      return 'Dispositivo Android';
    } else if (Platform.isIOS) {
      return 'Dispositivo iOS';
    }
    return 'Dispositivo desconocido';
  }

  /// Obtener el token FCM actual (útil para debug)
  Future<String?> obtenerToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Verificar si hay un token pendiente de registro
  Future<bool> hayTokenPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingToken) != null &&
           prefs.getBool(_keyTokenRegistered) != true;
  }

  /// Suscribir a un tema (topic) para notificaciones broadcast
  Future<void> suscribirATema(String tema) async {
    try {
      await _fcm.subscribeToTopic(tema);
    } catch (e) {
      // Silencioso
    }
  }

  /// Desuscribir de un tema
  Future<void> desuscribirDeTema(String tema) async {
    try {
      await _fcm.unsubscribeFromTopic(tema);
    } catch (e) {
      // Silencioso
    }
  }
}
