import 'package:flutter/material.dart';
import 'package:Bornive/services/medicamento_service.dart';
import '../api/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? get userId => _userId;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sede;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();
  Timer? _tokenValidationTimer;
  String? _lastUsername; // Para re-login automático

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get sede => _sede;
  bool get isAuthenticated => _token != null;
  
  // ✅ CONSTRUCTOR: Registrar callback de expiración de token
  AuthProvider() {
    ApiService.onTokenExpired = _handleTokenExpired;
    _startTokenValidation();
  }
  
  // ✅ MANEJO DE TOKEN EXPIRADO
  void _handleTokenExpired() {
    logout();
  }
  
  // ✅ VALIDACIÓN PERIÓDICA DEL TOKEN (cada 10 minutos)
  void _startTokenValidation() {
    _tokenValidationTimer?.cancel();
    _tokenValidationTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      if (_token != null) {
        final isValid = await ApiService.validateToken(_token!);
        if (!isValid) {
          _handleTokenExpired();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _tokenValidationTimer?.cancel();
    super.dispose();
  }
  
  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  Future<bool> login(String usuario, String contrasena) async {
    bool needsInitialSync = false;

    try {
      // ✅ SOLO resetear al INICIO del login, no después
      _resetAuthState();
      
      final connectivity = await _connectivity.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline) {
        final hasLocalData = await _dbHelper.hasPacientes();
        await _onlineLogin(usuario, contrasena);
        if (!hasLocalData) {
          needsInitialSync = true;
        }
      } else {
        await _offlineLogin(usuario, contrasena);
      }

      // ✅ VERIFICAR QUE EL LOGIN FUE EXITOSO ANTES DE NOTIFICAR
      if (_token != null && _user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        throw Exception('Login falló: datos de autenticación incompletos');
      }

      return needsInitialSync;

    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        await _tryOfflineFallback(usuario, contrasena);
        return false;
      } else {
        // ✅ SOLO resetear si hay error real
        _resetAuthState();
        rethrow;
      }
    }
  }

  // Agregar este método a tu AuthProvider
  Future<void> limpiarTokensExpirados() async {
    try {
      await _dbHelper.limpiarTokensExpirados();
      await _dbHelper.clearOldSessions();
      _resetAuthState();
    } catch (e) {
      rethrow;
    }
  }

  // 👇 CAMBIO 3: Renombramos y hacemos público el método de cargar medicamentos
  Future<void> loadInitialMedicamentos() async {
    try {
      if (_token != null) {
        final dbHelper = DatabaseHelper.instance;
        final hasMedicamentos = await dbHelper.hasMedicamentos();
        
        if (!hasMedicamentos) {
          await MedicamentoService.loadMedicamentosFromServer(_token!);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _tryOfflineFallback(String usuario, String contrasena) async {
    try {
      await _offlineLogin(usuario, contrasena);
      
      if (_token != null && _user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
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
    
    try {
      final sedes = await ApiService.getSedes(_token!);
      await DatabaseHelper.instance.saveSedes(sedes);
    } catch (e) {
      // Silencioso
    }
  }

  Future<Map<String, dynamic>?> getCurrentSede() async {
    if (_sede != null) return _sede;
    
    final db = DatabaseHelper.instance;
    final user = await db.getLoggedInUser();
    if (user == null || user['sede_id'] == null) return null;
    
    final sedes = await db.getSedes();
    _sede = sedes.firstWhere(
      (s) => s['id'] == user['sede_id'],
      orElse: () => {},
    );
    
    return _sede;
  }

  Future<void> _offlineLogin(String usuario, String contrasena) async {
    try {
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
    } catch (e) {
      if (e.toString().contains('REQUIRES_ONLINE_LOGIN')) {
        throw Exception('Por seguridad, su sesión ha expirado tras varios días. Conéctese a internet e inicie sesión nuevamente para renovarla.');
      }
      rethrow;
    }
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

  // ✅ MÉTODO _resetAuthState CORREGIDO - SIEMPRE NOTIFICA
  void _resetAuthState() {
    _token = null;
    _user = null;
    _sede = null;
    _userId = null;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> autoLogin() async {
    try {
      final localUser = await _dbHelper.getLoggedInUser();
      if (localUser == null) {
        _resetAuthState();
        return;
      }

      if (localUser['token'] == null || 
          localUser['id'] == null || 
          localUser['token'].toString().isEmpty) {
        await _dbHelper.updateUserLoginStatus(localUser['id'].toString(), false);
        _resetAuthState();
        return;
      }

      final isExpired = await _dbHelper.isTokenExpired(localUser['usuario']);
      if (isExpired) {
        await _dbHelper.limpiarDatosUsuarioObsoletos(localUser['usuario']);
        _resetAuthState();
        return;
      }
      
      final connectivity = await _connectivity.checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.none)) {
        try {
          final isValid = await ApiService.validateToken(localUser['token']);
          if (!isValid) {
            await _dbHelper.limpiarDatosUsuarioObsoletos(localUser['usuario']);
            _resetAuthState();
            return;
          }
        } catch (e) {
          // Continuar con autologin si hay error de red
        }
      }

      _token = localUser['token'];
      _user = {
        'id': localUser['id'],
        'nombre': localUser['nombre'],
        'correo': localUser['correo'],
        'usuario': localUser['usuario'],
      };
      _sede = {'id': localUser['sede_id']};
      _lastUsername = localUser['usuario'];
      notifyListeners();
      
    } catch (e) {
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
        // Silencioso
      }
    }
  }

  Future<void> updateProfile({
    String? nombre,
    String? correo,
    String? contrasenaActual,
    String? contrasenaNueva,
    String? sedeId,
  }) async {
    if (_token != null) {
      try {
        final response = await ApiService.updateProfile(
          _token!,
          nombre: nombre,
          correo: correo,
          contrasenaActual: contrasenaActual,
          contrasenaNueva: contrasenaNueva,
          sedeId: sedeId,
        );
        
        _user = response['usuario'];
        _sede = response['sede'];
        
        // Actualizar en SQLite
        final db = DatabaseHelper.instance;
        await db.createUser({
          'id': _user!['id'].toString(),
          'usuario': _user!['usuario'],
          'contrasena': contrasenaNueva ?? await _getCurrentPassword(),
          'nombre': _user!['nombre'],
          'correo': _user!['correo'],
          'token': _token,
          'sede_id': _sede?['id']?.toString() ?? '',
          'is_logged_in': 1,
          'last_login': DateTime.now().toIso8601String(),
        });
        
        notifyListeners();
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<String> _getCurrentPassword() async {
    final db = DatabaseHelper.instance;
    final currentUser = await db.getLoggedInUser();
    return currentUser?['contrasena'] ?? '';
  }

  Future<void> syncUserData() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

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
      // Silencioso
    }
  }

  Future<void> logout() async {
    try {
      final userId = _user?['id']?.toString();
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Intentar logout en servidor si hay conexión
      if (!connectivityResult.contains(ConnectivityResult.none) && _token != null) {
        try {
          await ApiService.logout(_token!);
        } catch (e) {
          // No crítico
        }
      }
      
      if (userId != null) {
        try {
          await _dbHelper.updateUserLoginStatus(userId, false);
        } catch (e) {
          // No crítico
        }
      }
      
      try {
        await _dbHelper.limpiarTokensExpirados();
      } catch (e) {
        // No crítico
      }
      
    } catch (e) {
      // Silencioso
    } finally {
      // ✅ RESETEAR ESTADO INMEDIATAMENTE
      _token = null;
      _user = null;
      _sede = null;
      _userId = null;
      
      notifyListeners();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  bool get isReallyAuthenticated {
    final hasToken = _token != null && _token!.isNotEmpty;
    final hasUser = _user != null && _user!['id'] != null;
    return hasToken && hasUser;
  }

  get usuario => null;

  Future<void> forceLogout() async {
    _resetAuthState();
  }

  Future<void> debugListUsers() async {
    await _dbHelper.debugListUsers();
  }

  Future<void> clearOldSessions() async {
    try {
      final users = await _dbHelper.getAllUsers();
      final now = DateTime.now();
      
      for (var user in users) {
        final lastLogin = DateTime.tryParse(user['last_login'] ?? '');
        if (lastLogin != null && now.difference(lastLogin).inDays > 30) {
          await _dbHelper.updateUserLoginStatus(user['id'].toString(), false);
        }
      }
    } catch (e) {
      // Silencioso
    }
  }

  // Agrega estos métodos en tu AuthProvider
  Future<String?> getCurrentUserId() async {
    if (_user != null && _user!['id'] != null) {
      return _user!['id'].toString();
    }
    
    // Fallback a SQLite si no está en memoria
    final localUser = await _dbHelper.getLoggedInUser();
    return localUser?['id']?.toString();
  }

  Future<bool> canCreateVisitas() async {
    if (!isAuthenticated) return false;
    
    // Verificar permisos del usuario si es necesario
    final user = await getCurrentUserData();
    return user != null; // O alguna lógica específica de permisos
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_user != null) return _user;
    
    final localUser = await _dbHelper.getLoggedInUser();
    return localUser;
  }
}
