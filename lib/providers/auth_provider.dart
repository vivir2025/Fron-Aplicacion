import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sede;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get sede => _sede;
  bool get isAuthenticated => _token != null;

  Future<void> login(String usuario, String contrasena) async {
    try {
      _resetAuthState();
      final connectivity = await _connectivity.checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline) {
        await _onlineLogin(usuario, contrasena);
      } else {
        await _offlineLogin(usuario, contrasena);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error en login: $e');
      // Intenta fallback a offline si el error es de conexión
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        await _tryOfflineFallback(usuario, contrasena);
      } else {
        _resetAuthState();
        rethrow;
      }
    }
  }

  Future<void> _tryOfflineFallback(String usuario, String contrasena) async {
    try {
      await _offlineLogin(usuario, contrasena);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _resetAuthState();
      rethrow;
    }
  }

  Future<void> _onlineLogin(String usuario, String contrasena) async {
    final response = await ApiService.login(usuario, contrasena);
    
    if (response['token'] == null || response['usuario'] == null) {
      throw Exception('Datos de usuario inválidos');
    }

    _token = response['token'];
    _user = response['usuario'];
    _sede = response['sede'] ?? {};

    await _saveCredentialsLocally(usuario, contrasena);
  }

  // MÉTODO CORREGIDO: No requiere is_logged_in = 1 inicialmente
  Future<void> _offlineLogin(String usuario, String contrasena) async {
    final localUser = await _dbHelper.getUserByCredentials(usuario, contrasena);
    
    if (localUser == null) {
      throw Exception('No hay credenciales válidas almacenadas para inicio offline');
    }
    
    if (localUser['token'] == null) {
      throw Exception('Token no disponible para inicio offline');
    }
    
    _token = localUser['token'];
    _user = {
      'id': localUser['id'],
      'nombre': localUser['nombre'],
      'correo': localUser['correo'],
      'usuario': localUser['usuario'],
    };
    _sede = {'id': localUser['sede_id']};
    
    // Actualizar el estado de login después de verificar credenciales
    await _dbHelper.updateUserLoginStatus(localUser['id'].toString(), true);
  }

  Future<void> _saveCredentialsLocally(String usuario, String contrasena) async {
    await _dbHelper.createUser({
      'id': _user!['id'].toString(),
      'usuario': usuario,
      'contrasena': contrasena,
      'nombre': _user!['nombre'],
      'correo': _user!['correo'],
      'token': _token,
      'sede_id': _sede?['id']?.toString() ?? '',
      'is_logged_in': 1,
      'last_login': DateTime.now().toIso8601String(),
    });
  }

  void _resetAuthState() {
    _token = null;
    _user = null;
    _sede = null;
    notifyListeners();
  }

  // MÉTODO CORREGIDO: Asegura que el usuario tenga credenciales válidas
  Future<void> autoLogin() async {
    try {
      final localUser = await _dbHelper.getLoggedInUser();
      if (localUser == null) {
        _resetAuthState();
        return;
      }

      if (localUser['token'] == null || localUser['id'] == null) {
        await _dbHelper.updateUserLoginStatus(localUser['id'].toString(), false);
        _resetAuthState();
        return;
      }

      _token = localUser['token'];
      _user = {
        'id': localUser['id'],
        'nombre': localUser['nombre'],
        'correo': localUser['correo'],
        'usuario': localUser['usuario'],
      };
      _sede = {'id': localUser['sede_id']};
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error en autoLogin: $e');
      _resetAuthState();
    }
  }

  Future<void> loadProfile() async {
    if (_token != null) {
      try {
        final response = await ApiService.getProfile(_token!);
        _user = response['usuario'];
        _sede = response['sede'];
        notifyListeners();
      } catch (e) {
        debugPrint('Error al cargar perfil: $e');
      }
    }
  }

  Future<void> updateProfile({
    String? nombre,
    String? correo,
    String? contrasenaActual,
    String? contrasenaNueva,
  }) async {
    if (_token != null) {
      try {
        final response = await ApiService.updateProfile(
          _token!,
          nombre: nombre,
          correo: correo,
          contrasenaActual: contrasenaActual,
          contrasenaNueva: contrasenaNueva,
        );
        _user = response['usuario'];
        notifyListeners();
      } catch (e) {
        debugPrint('Error al actualizar perfil: $e');
        rethrow;
      }
    }
  }

  Future<void> syncUserData() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    try {
      final localUser = await _dbHelper.getLoggedInUser();
      if (localUser == null) return;

      final profile = await ApiService.getProfile(localUser['token']);
      
      await _dbHelper.createUser({
        'id': profile['usuario']['id'].toString(),
        'usuario': profile['usuario']['usuario'],
        'contrasena': localUser['contrasena'], // Mantener contraseña local
        'nombre': profile['usuario']['nombre'],
        'correo': profile['usuario']['correo'],
        'token': localUser['token'],
        'sede_id': profile['sede']['id'].toString(),
        'is_logged_in': 1,
        'last_sync': DateTime.now().toIso8601String(),
      });

      if (_token != null) {
        _user = profile['usuario'];
        _sede = profile['sede'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error en syncUserData: $e');
    }
  }

  Future<void> logout() async {
    try {
      final userId = _user?['id']?.toString();
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult != ConnectivityResult.none && _token != null) {
        try {
          await ApiService.logout(_token!);
        } catch (e) {
          debugPrint('Error al hacer logout en servidor: $e');
        }
      }
      
      if (userId != null) {
        await _dbHelper.updateUserLoginStatus(userId, false);
      }
    } catch (e) {
      debugPrint('Error en logout: $e');
    }
    
    _resetAuthState();
  }
  Future<void> debugListUsers() async {
  await _dbHelper.debugListUsers();
}
}