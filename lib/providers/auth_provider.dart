import 'package:flutter/material.dart';
import 'package:fnpv_app/services/medicamento_service.dart';
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
    debugPrint('🔴 Token expirado detectado - Cerrando sesión...');
    logout();
  }
  
  // ✅ VALIDACIÓN PERIÓDICA DEL TOKEN (cada 10 minutos)
  void _startTokenValidation() {
    _tokenValidationTimer?.cancel();
    _tokenValidationTimer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      if (_token != null) {
        debugPrint('🔍 Validación periódica de token...');
        final isValid = await ApiService.validateToken(_token!);
        if (!isValid) {
          debugPrint('❌ Token inválido en validación periódica');
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
      final isOnline = connectivity != ConnectivityResult.none;

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
        debugPrint('✅ Login completado exitosamente - Token: ${_token != null ? "presente" : "null"}, User: ${_user?['nombre']}');
        
        // ✅ NOTIFICAR CAMBIOS SOLO SI EL LOGIN FUE EXITOSO
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
          debugPrint('✅ Listeners notificados después de login exitoso');
        });
      } else {
        debugPrint('❌ Login falló - Token o usuario nulos');
        throw Exception('Login falló: datos de autenticación incompletos');
      }

      return needsInitialSync;

    } catch (e) {
      debugPrint('❌ Error en login: $e');
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
      debugPrint('✅ Tokens expirados limpiados desde AuthProvider');
    } catch (e) {
      debugPrint('❌ Error limpiando tokens desde AuthProvider: $e');
      rethrow;
    }
  }

  // 👇 CAMBIO 3: Renombramos y hacemos público el método de cargar medicamentos
  Future<void> loadInitialMedicamentos() async {
    try {
      if (_token != null) {
        debugPrint('🔄 Cargando medicamentos iniciales...');
        
        final dbHelper = DatabaseHelper.instance;
        final hasMedicamentos = await dbHelper.hasMedicamentos();
        
        if (!hasMedicamentos) {
          final success = await MedicamentoService.loadMedicamentosFromServer(_token!);
          if (success) {
            debugPrint('✅ Medicamentos iniciales cargados exitosamente');
          } else {
            debugPrint('⚠️ No se pudieron cargar medicamentos iniciales');
          }
        } else {
          final count = await dbHelper.countMedicamentos();
          debugPrint('ℹ️ Ya hay $count medicamentos disponibles localmente');
        }
      }
    } catch (e) {
      debugPrint('❌ Error en carga inicial de medicamentos: $e');
      // Es importante relanzar el error para que la pantalla de sync lo capture
      rethrow;
    }
  }

  Future<void> _tryOfflineFallback(String usuario, String contrasena) async {
    try {
      debugPrint('🔄 Intentando login offline...');
      await _offlineLogin(usuario, contrasena);
      
      // ✅ SOLO notificar si el login offline fue exitoso
      if (_token != null && _user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
          debugPrint('✅ Login offline exitoso, listeners notificados');
        });
      }
    } catch (e) {
      debugPrint('❌ Error en login offline: $e');
      _resetAuthState(); // ✅ SOLO resetear si falla
      rethrow;
    }
  }

  Future<void> _onlineLogin(String usuario, String contrasena) async {
    debugPrint('🔄 Iniciando login online...');
    
    final response = await ApiService.login(usuario, contrasena);
    
    if (response['token'] == null || response['usuario'] == null) {
      throw Exception('Datos de usuario inválidos');
    }

    // ✅ ESTABLECER DATOS SIN RESETEAR
    _token = response['token'];
    _user = response['usuario'];
    _sede = response['sede'] ?? {};

    debugPrint('✅ Datos de autenticación establecidos:');
    debugPrint('   - Token: ${_token != null ? "presente" : "null"}');
    debugPrint('   - Usuario: ${_user?['nombre']}');
    debugPrint('   - Sede: ${_sede?['nombresede']}');

    // Guardar credenciales y sedes localmente
    await _saveCredentialsLocally(usuario, contrasena);
    
    // Obtener y guardar sedes
    try {
      final sedes = await ApiService.getSedes(_token!);
      await DatabaseHelper.instance.saveSedes(sedes);
    } catch (e) {
      debugPrint('Error al guardar sedes: $e');
    }
    
    debugPrint('✅ Login online completado exitosamente');
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

  // ✅ MÉTODO _resetAuthState CORREGIDO - SIEMPRE NOTIFICA
  void _resetAuthState() {
    debugPrint('🔄 AuthProvider: Reseteando estado de autenticación...');
    _token = null;
    _user = null;
    _sede = null;
    _userId = null;
    
    // ✅ FORZAR NOTIFICACIÓN INMEDIATA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      debugPrint('✅ Estado reseteado y listeners notificados');
    });
  }

  Future<void> autoLogin() async {
    try {
      debugPrint('🔄 Iniciando autoLogin...');
      
      final localUser = await _dbHelper.getLoggedInUser();
      if (localUser == null) {
        debugPrint('❌ No hay usuario logueado localmente');
        _resetAuthState();
        return;
      }

      // ✅ VERIFICACIÓN MÁS ESTRICTA
      if (localUser['token'] == null || 
          localUser['id'] == null || 
          localUser['token'].toString().isEmpty) {
        debugPrint('❌ Token o ID de usuario inválido');
        await _dbHelper.updateUserLoginStatus(localUser['id'].toString(), false);
        _resetAuthState();
        return;
      }

      // ✅ VERIFICAR SI EL TOKEN ESTÁ EXPIRADO
      final isExpired = await _dbHelper.isTokenExpired(localUser['usuario']);
      if (isExpired) {
        debugPrint('❌ Token expirado para usuario: ${localUser['usuario']}');
        await _dbHelper.limpiarDatosUsuarioObsoletos(localUser['usuario']);
        _resetAuthState();
        return;
      }
      
      // ✅ VALIDAR TOKEN CON EL SERVIDOR (si hay conexión)
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        debugPrint('🌐 Validando token con servidor...');
        try {
          final isValid = await ApiService.validateToken(localUser['token']);
          if (!isValid) {
            debugPrint('❌ Token rechazado por servidor');
            await _dbHelper.limpiarDatosUsuarioObsoletos(localUser['usuario']);
            _resetAuthState();
            return;
          }
          debugPrint('✅ Token validado con servidor');
        } catch (e) {
          debugPrint('⚠️ Error validando token: $e');
          // Continuar con autologin si hay error de red
        }
      }

      debugPrint('✅ Auto-login exitoso para usuario: ${localUser['nombre']}');
      _token = localUser['token'];
      _user = {
        'id': localUser['id'],
        'nombre': localUser['nombre'],
        'correo': localUser['correo'],
        'usuario': localUser['usuario'],
      };
      _sede = {'id': localUser['sede_id']};
      
      // Guardar username para posible re-login
      _lastUsername = localUser['usuario'];
      
      // ✅ NOTIFICAR INMEDIATAMENTE
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error en autoLogin: $e');
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
        debugPrint('Error al actualizar perfil: $e');
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

  // ✅ MÉTODO LOGOUT COMPLETAMENTE CORREGIDO
  Future<void> logout() async {
    try {
      debugPrint('🔄 AuthProvider: Iniciando proceso de logout...');
      
      final userId = _user?['id']?.toString();
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Intentar logout en servidor si hay conexión
      if (connectivityResult != ConnectivityResult.none && _token != null) {
        try {
          debugPrint('🌐 Intentando logout en servidor...');
          await ApiService.logout(_token!);
          debugPrint('✅ Logout exitoso en servidor');
        } catch (e) {
          debugPrint('⚠️ Error al hacer logout en servidor: $e');
        }
      }
      
      // Actualizar estado en base de datos local
      if (userId != null) {
        try {
          await _dbHelper.updateUserLoginStatus(userId, false);
          debugPrint('✅ Estado de usuario actualizado en DB local');
        } catch (e) {
          debugPrint('⚠️ Error actualizando estado en DB: $e');
        }
      }
      
      // Limpiar tokens expirados
      try {
        await _dbHelper.limpiarTokensExpirados();
        debugPrint('✅ Tokens expirados limpiados');
      } catch (e) {
        debugPrint('⚠️ Error limpiando tokens: $e');
      }
      
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
    } finally {
      // ✅ RESETEAR ESTADO INMEDIATAMENTE
      _token = null;
      _user = null;
      _sede = null;
      _userId = null;
      
      // ✅ NOTIFICAR MÚLTIPLES VECES PARA ASEGURAR PROPAGACIÓN
      notifyListeners();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
        debugPrint('✅ Logout completado con notificación forzada');
      });
    }
  }

  bool get isReallyAuthenticated {
    final hasToken = _token != null && _token!.isNotEmpty;
    final hasUser = _user != null && _user!['id'] != null;
    final result = hasToken && hasUser;
    
    debugPrint('🔍 isReallyAuthenticated: $result (token: $hasToken, user: $hasUser)');
    return result;
  }

  get usuario => null;

  // ✅ MÉTODO ADICIONAL PARA FORZAR LOGOUT SI ES NECESARIO
  Future<void> forceLogout() async {
    debugPrint('🚨 Forzando logout inmediato...');
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
      debugPrint('Error en clearOldSessions: $e');
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
