import 'package:flutter/material.dart'; // Agrega este import
import '../api/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';


class AuthProvider extends ChangeNotifier {
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
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult != ConnectivityResult.none) {
      _resetAuthState();
      final response = await ApiService.login(usuario, contrasena);
      
      if (response['token'] == null || response['usuario'] == null) {
        throw Exception('Datos de usuario inválidos');
      }

      _token = response['token'];
      _user = response['usuario'];
      _sede = response['sede'] ?? {};  // Manejo seguro si sede es null

      await _dbHelper.createUser({
        'id': _user!['id'].toString(),
        'usuario': usuario,
        'contrasena': contrasena,
        'nombre': _user!['nombre'],
        'correo': _user!['correo'],
        'token': _token,
        'sede_id': _sede?['id']?.toString() ?? '',  // Manejo seguro
        'is_logged_in': 1,
        'last_login': DateTime.now().toIso8601String(),
      });
    } else {
      // Modo offline - verifica datos locales
      final localUser = await _dbHelper.getUserByCredentials(usuario, contrasena);
      if (localUser == null || localUser['token'] == null) {
        throw Exception('No hay credenciales válidas almacenadas');
      }
      
      // Carga desde SQLite
      _token = localUser['token'];
      _user = {
        'id': localUser['id'],
        'nombre': localUser['nombre'],
        'correo': localUser['correo'],
        'usuario': localUser['usuario'],
      };
      _sede = {'id': localUser['sede_id']};
      
      // Actualiza último acceso
      await _dbHelper.updateUserLoginStatus(localUser['id'].toString(), true);
    }
    
    notifyListeners();
  } catch (e) {
    _resetAuthState(); // Limpia estado al fallar
    debugPrint('Error en login: $e');
    rethrow;
  }
}

void _resetAuthState() {
  _token = null;
  _user = null;
  _sede = null;
  notifyListeners();
}



  Future<void> loadProfile() async {
    if (_token != null) {
      final response = await ApiService.getProfile(_token!);
      _user = response['usuario'];
      _sede = response['sede'];
      notifyListeners(); // Notifica cambios
    }
  }
 Future<void> autoLogin() async {
  try {
    final localUser = await _dbHelper.getLoggedInUser();
    if (localUser == null || localUser['is_logged_in'] != 1) {
      _resetAuthState();
      return;
    }

    // Verifica integridad de datos mínimos
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
  Future<void> updateProfile({
    String? nombre,
    String? correo,
    String? contrasenaActual,
    String? contrasenaNueva,
  }) async {
    if (_token != null) {
      final response = await ApiService.updateProfile(
        _token!,
        nombre: nombre,
        correo: correo,
        contrasenaActual: contrasenaActual,
        contrasenaNueva: contrasenaNueva,
      );
      _user = response['usuario'];
      notifyListeners(); // Notifica cambios
    }
  }
  Future<void> syncUserData() async {
  final connectivityResult = await _connectivity.checkConnectivity();
  if (connectivityResult != ConnectivityResult.none && _token != null) {
    try {
      final profile = await ApiService.getProfile(_token!);
      // Actualizar datos locales con la información más reciente
      await _dbHelper.createUser({
        'id': profile['usuario']['id'].toString(),
        'usuario': profile['usuario']['usuario'],
        'nombre': profile['usuario']['nombre'],
        'correo': profile['usuario']['correo'],
        'token': _token,
        'sede_id': profile['sede']['id'].toString(),
        'is_logged_in': 1,
        'last_sync': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Manejar error de sincronización
    }
  } }
  Future<void> logout() async {
  try {
    final userId = _user?['id']?.toString();  // Guarda ID antes de limpiar
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult != ConnectivityResult.none && _token != null) {
      await ApiService.logout(_token!);
    }
    
    if (userId != null) {
      await _dbHelper.updateUserLoginStatus(userId, false);
    }
  } catch (e) {
    debugPrint('Error en logout: $e');
  }
  
  _resetAuthState();  // Limpia todo al final
}
}