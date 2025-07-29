import 'package:flutter/material.dart';
import 'package:fnpv_app/services/medicamento_service.dart';
import '../api/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? get userId => _userId;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sede;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get sede => _sede;
  bool get isAuthenticated => _token != null;
  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }
 Future<bool> login(String usuario, String contrasena) async {
    bool needsInitialSync = false; // Flag para saber si se necesita la carga inicial

    try {
      _resetAuthState();
      final connectivity = await _connectivity.checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline) {
        // Antes de hacer login online, verificamos si ya hay datos locales.
        // Si no hay pacientes, es muy probable que sea el primer login.
        final hasLocalData = await _dbHelper.hasPacientes();
        
        await _onlineLogin(usuario, contrasena);
        // Si el login fue exitoso y no había datos, marcamos para sincronizar
        if (!hasLocalData) {
          needsInitialSync = true;
        }

      } else {
        await _offlineLogin(usuario, contrasena);
      }
      
      // 👇 CAMBIO 2: YA NO llamamos a _loadInitialMedicamentos aquí.
      // Se llamará desde la pantalla de sincronización.
      // await _loadInitialMedicamentos();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Devolvemos el flag
      return needsInitialSync;

    } catch (e) {
      debugPrint('Error en login: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        await _tryOfflineFallback(usuario, contrasena);
        return false; // El modo offline no necesita sincronización inicial
      } else {
        _resetAuthState();
        rethrow;
      }
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

    // Guardar credenciales y sedes localmente
    await _saveCredentialsLocally(usuario, contrasena);
    
    // Obtener y guardar sedes
    try {
      final sedes = await ApiService.getSedes(_token!);
      await DatabaseHelper.instance.saveSedes(sedes);
    } catch (e) {
      debugPrint('Error al guardar sedes: $e');
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
