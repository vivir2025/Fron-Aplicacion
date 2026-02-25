import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../api/api_service.dart';
import 'auth_provider.dart';
import '../database/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PacienteProvider with ChangeNotifier {
  List<Paciente> _pacientes = [];
  List<Map<String, dynamic>> _sedes = [];
  bool _isLoading = false;
  bool _isLoadingSedes = false;
  bool _isLoaded = false;
  final AuthProvider _authProvider;

  PacienteProvider(this._authProvider);

  List<Paciente> get pacientes => _pacientes;
  List<Map<String, dynamic>> get sedes => _sedes;
  bool get isLoading => _isLoading;
  bool get isLoadingSedes => _isLoadingSedes;
  bool get isLoaded => _isLoaded;
  
  // ✅ MÉTODO DE SEDES SIN CAMBIOS (ESTÁ BIEN)
  Future<void> loadSedes() async {
    _isLoadingSedes = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      final connectivity = await Connectivity().checkConnectivity();
      
      await db.ensureSedesTableExists();
      
      if (!connectivity.contains(ConnectivityResult.none) && _authProvider.isAuthenticated) {
        try {
          final response = await ApiService.getSedes(_authProvider.token!);
          
          if (response != null && response is List) {
            _sedes = response.map<Map<String, dynamic>>((sede) => {
              'id': sede['id']?.toString() ?? '',
              'nombresede': sede['nombresede']?.toString() ?? '',
              'direccion': sede['direccion']?.toString() ?? '',
            }).toList();

            await db.saveSedes(_sedes);
          } else {
            _sedes = await db.getSedes();
          }
        } catch (e) {
          _sedes = await db.getSedes();
        }
      } else {
        _sedes = await db.getSedes();
      }

      if (_sedes.isEmpty) {
        await db.insertDefaultSedes();
        _sedes = await db.getSedes();
      }

      await db.debugListSedes();

    } catch (e) {
      _sedes = [];
      
      try {
        final db = DatabaseHelper.instance;
        await db.ensureSedesTableExists();
        await db.insertDefaultSedes();
        _sedes = await db.getSedes();
      } catch (emergencyError) {
      }
    } finally {
      _isLoadingSedes = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO PRINCIPAL CORREGIDO - SOLO CARGA LOCAL
  Future<void> loadPacientes() async {
    if (_isLoaded && !_isLoading) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ SOLO CARGAR DESDE BASE DE DATOS LOCAL
      await loadPacientesFromDB();
      
      _isLoaded = true;
    } catch (e) {
      _pacientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO MEJORADO PARA CARGAR SOLO DESDE DB LOCAL
  Future<void> loadPacientesFromDB() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final pacientesLocales = await dbHelper.readAllPacientes();
      
      // ✅ ELIMINAR DUPLICADOS
      _pacientes = _removeDuplicates(pacientesLocales);
      
    } catch (e) {
      _pacientes = [];
    }
  }

  // ✅ NUEVO MÉTODO PARA SINCRONIZACIÓN MANUAL COMPLETA
  Future<void> syncPacientesFromServer() async {
    if (!_authProvider.isAuthenticated) {
      return;
    }

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        return;
      }

      // ✅ OBTENER PACIENTES DEL SERVIDOR
      final response = await ApiService.getPacientes(_authProvider.token!);
      final serverPacientes = response.map<Paciente>((json) => Paciente.fromJson(json)).toList();

      // ✅ GUARDAR EN BASE DE DATOS LOCAL
      final db = DatabaseHelper.instance;
      for (final paciente in serverPacientes) {
        await db.upsertPaciente(paciente);
      }

      // ✅ SINCRONIZAR PACIENTES OFFLINE PENDIENTES
      await syncPacientes();
      
      // ✅ RECARGAR DESDE DB LOCAL
      await loadPacientesFromDB();
      
      notifyListeners();
      
    } catch (e) {
    }
  }

  // ✅ MÉTODOS SIN CAMBIOS (ESTÁN BIEN)
  List<Paciente> _removeDuplicates(List<Paciente> pacientes) {
    final Map<String, Paciente> pacienteMap = {};
    
    for (final paciente in pacientes) {
      final identificacion = paciente.identificacion;
      
      if (!pacienteMap.containsKey(identificacion)) {
        pacienteMap[identificacion] = paciente;
      } else {
        final existing = pacienteMap[identificacion]!;
        final betterPaciente = _selectBetterPaciente(existing, paciente);
        pacienteMap[identificacion] = betterPaciente;
        
        if (betterPaciente.id != existing.id) {
          _markForDeletion(existing.id);
        }
        if (betterPaciente.id != paciente.id) {
          _markForDeletion(paciente.id);
        }
      }
    }
    
    return pacienteMap.values.toList();
  }

  Paciente _selectBetterPaciente(Paciente existing, Paciente candidate) {
    if (existing.syncStatus == 1 && candidate.syncStatus != 1) {
      return existing;
    }
    if (candidate.syncStatus == 1 && existing.syncStatus != 1) {
      return candidate;
    }
    
    final existingIsOffline = existing.id.startsWith('offline_');
    final candidateIsOffline = candidate.id.startsWith('offline_');
    
    if (!existingIsOffline && candidateIsOffline) {
      return existing;
    }
    if (!candidateIsOffline && existingIsOffline) {
      return candidate;
    }
    
    if (existingIsOffline && candidateIsOffline) {
      final existingTimestamp = _extractTimestampFromOfflineId(existing.id);
      final candidateTimestamp = _extractTimestampFromOfflineId(candidate.id);
      return candidateTimestamp > existingTimestamp ? candidate : existing;
    }
    
    return existing;
  }

  int _extractTimestampFromOfflineId(String offlineId) {
    try {
      final parts = offlineId.split('_');
      if (parts.length >= 2) {
        return int.parse(parts[1]);
      }
    } catch (e) {
    }
    return 0;
  }

  void _markForDeletion(String id) {
    Future.microtask(() async {
      try {
        await DatabaseHelper.instance.deletePaciente(id);
      } catch (e) {
      }
    });
  }

  // ✅ MÉTODO MEJORADO - SOLO SINCRONIZA OFFLINE PENDIENTES
  Future<void> syncPacientes() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none) || !_authProvider.isAuthenticated) {
        return;
      }

      final unsyncedPacientes = await DatabaseHelper.instance.getUnsyncedPacientes();
      if (unsyncedPacientes.isEmpty) {
        return;
      }

      final syncedIds = <String>[];
      
      for (final paciente in unsyncedPacientes) {
        try {
          final existingOnServer = await _checkPacienteExistsOnServer(paciente.identificacion);
          
          if (existingOnServer != null) {
            await DatabaseHelper.instance.deletePaciente(paciente.id);
            await DatabaseHelper.instance.upsertPaciente(existingOnServer);
            continue;
          }
          
          if (paciente.id.startsWith('offline_')) {
            final createdPaciente = await ApiService.createPaciente(
              _authProvider.token!, 
              paciente.toJson()
            );
            syncedIds.add(paciente.id);
            await DatabaseHelper.instance.deletePaciente(paciente.id);
            await DatabaseHelper.instance.upsertPaciente(
              Paciente.fromJson(createdPaciente)
            );
          } else {
            await ApiService.updatePaciente(
              _authProvider.token!,
              paciente.id,
              paciente.toJson()
            );
            syncedIds.add(paciente.id);
          }
        } catch (e) {
        }
      }

      if (syncedIds.isNotEmpty) {
        await DatabaseHelper.instance.markPacientesAsSynced(syncedIds);
      }
    } catch (e) {
    }
  }

  Future<Paciente?> _checkPacienteExistsOnServer(String identificacion) async {
    try {
      final response = await ApiService.getPacientes(_authProvider.token!);
      final serverPacientes = response.map<Paciente>((json) => Paciente.fromJson(json)).toList();
      
      return serverPacientes.firstWhere(
        (p) => p.identificacion == identificacion,
        orElse: () => null as Paciente,
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ MÉTODOS DE AGREGAR, ACTUALIZAR Y ELIMINAR SIN CAMBIOS (ESTÁN BIEN)
  Future<void> addPaciente(Paciente paciente) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      
      final duplicateCheck = await _checkForDuplicates(paciente.identificacion);
      if (duplicateCheck.hasLocal || duplicateCheck.hasServer) {
        throw Exception('Ya existe un paciente con esta identificación');
      }

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      // ✅ SI ESTAMOS ONLINE, CREAR DIRECTAMENTE EN SERVIDOR (MÁS RÁPIDO Y SEGURO)
      if (isOnline && _authProvider.isAuthenticated) {
        try {
          final createdPaciente = await ApiService.createPaciente(
            _authProvider.token!, 
            paciente.toJson()
          );
          
          final newPaciente = Paciente.fromJson(createdPaciente);
          await db.upsertPaciente(newPaciente);
          _pacientes.add(newPaciente);
          
          return; // ✅ SALIR AQUÍ - NO CREAR VERSIÓN OFFLINE
        } catch (apiError) {
          // Si falla el servidor, continuar con modo offline
        }
      }
      
      // ✅ MODO OFFLINE O SI FALLÓ EL SERVIDOR
      final offlinePaciente = await _createPacienteOffline(paciente, db);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      
      // ✅ INTENTO DE SINCRONIZACIÓN EN SEGUNDO PLANO
      // Si el paciente se creó offline pero el internet vuelve al instante,
      // esto intentará subirlo de fondo silenciosamente.
      Future.microtask(() => syncPacientes());
    }
  }

  Future<DuplicateCheckResult> _checkForDuplicates(String identificacion) async {
    final db = DatabaseHelper.instance;
    bool hasLocal = false;
    bool hasServer = false;
    
    final localPaciente = await db.getPacienteByIdentificacion(identificacion);
    hasLocal = localPaciente != null;
    
    final inMemory = _pacientes.any((p) => p.identificacion == identificacion);
    hasLocal = hasLocal || inMemory;
    
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);
    
    if (isOnline && _authProvider.isAuthenticated) {
      try {
        final serverPaciente = await _checkPacienteExistsOnServer(identificacion);
        hasServer = serverPaciente != null;
      } catch (e) {
      }
    }
    
    return DuplicateCheckResult(hasLocal: hasLocal, hasServer: hasServer);
  }

  Future<Paciente> _createPacienteOffline(Paciente paciente, DatabaseHelper db) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp.toString().substring(8);
      final offlineId = 'offline_${timestamp}_${paciente.identificacion.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}_$randomSuffix';
      
      final offlinePaciente = paciente.copyWith(
        id: offlineId,
        syncStatus: 0,
      );
      
      await db.upsertPaciente(offlinePaciente);
      
      _pacientes.add(offlinePaciente);
      return offlinePaciente;
    } catch (e) {
      throw Exception('Error al guardar paciente offline: $e');
    }
  }

  Future<void> updatePaciente(Paciente paciente) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      final duplicateCheck = await _checkForDuplicatesExcluding(
        paciente.identificacion, 
        paciente.id
      );
      if (duplicateCheck.hasLocal || duplicateCheck.hasServer) {
        throw Exception('Ya existe otro paciente con esta identificación');
      }

      await _updatePacienteOffline(paciente, db);

      if (isOnline && _authProvider.isAuthenticated) {
        Future.microtask(() async {
          try {
            final updatedPaciente = await ApiService.updatePaciente(
              _authProvider.token!,
              paciente.id,
              paciente.toJson(),
            );
            
            final serverPaciente = Paciente.fromJson(updatedPaciente);
            await db.upsertPaciente(serverPaciente);
            
            final index = _pacientes.indexWhere((p) => p.id == paciente.id);
            if (index != -1) {
              _pacientes[index] = serverPaciente;
            }
            
            notifyListeners();
          } catch (apiError) {
          }
        });
      }
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DuplicateCheckResult> _checkForDuplicatesExcluding(
    String identificacion, 
    String excludeId
  ) async {
    final db = DatabaseHelper.instance;
    bool hasLocal = false;
    bool hasServer = false;
    
    final localPaciente = await db.getPacienteByIdentificacion(identificacion);
    hasLocal = localPaciente != null && localPaciente.id != excludeId;
    
    final inMemory = _pacientes.any((p) => 
      p.identificacion == identificacion && p.id != excludeId
    );
    hasLocal = hasLocal || inMemory;
    
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);
    
    if (isOnline && _authProvider.isAuthenticated) {
      try {
        final serverPaciente = await _checkPacienteExistsOnServer(identificacion);
        hasServer = serverPaciente != null && serverPaciente.id != excludeId;
      } catch (e) {
      }
    }
    
    return DuplicateCheckResult(hasLocal: hasLocal, hasServer: hasServer);
  }

  Future<void> _updatePacienteOffline(Paciente paciente, DatabaseHelper db) async {
    final updatedPaciente = paciente.syncStatus == 1 
      ? paciente.copyWith(syncStatus: 0) 
      : paciente;
    
    await db.upsertPaciente(updatedPaciente);
    
    final index = _pacientes.indexWhere((p) => p.id == paciente.id);
    if (index != -1) {
      _pacientes[index] = updatedPaciente;
    }
    
  }

  Future<void> deletePaciente(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      
      await db.deletePaciente(id);
      _pacientes.removeWhere((p) => p.id == id);
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline && _authProvider.isAuthenticated) {
        Future.microtask(() async {
          try {
            await ApiService.deletePaciente(_authProvider.token!, id);
          } catch (apiError) {
          }
        });
      }
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO CORREGIDO - SIN CARGA AUTOMÁTICA
  Future<void> syncData() async {
    if (_authProvider.isAuthenticated) {
      await loadSedes(); // ✅ Sedes sí se pueden cargar automáticamente
      
      // ❌ ELIMINADO: Carga automática de pacientes
      // _isLoaded = false;
      // await loadPacientes();
      
      // ✅ SOLO CARGAR DESDE DB LOCAL
      await loadPacientesFromDB();
    }
  }

  // ✅ RESTO DE MÉTODOS SIN CAMBIOS
  void clearData() {
    _pacientes = [];
    _sedes = [];
    _isLoading = false;
    _isLoadingSedes = false;
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> cleanDuplicates() async {
    try {
      final db = DatabaseHelper.instance;
      final allPacientes = await db.readAllPacientes();
      
      final groups = <String, List<Paciente>>{};
      for (final paciente in allPacientes) {
        groups.putIfAbsent(paciente.identificacion, () => []).add(paciente);
      }
      
      for (final group in groups.values) {
        if (group.length > 1) {
          final best = group.reduce((a, b) => _selectBetterPaciente(a, b));
          for (final paciente in group) {
            if (paciente.id != best.id) {
              await db.deletePaciente(paciente.id);
            }
          }
        }
      }
      
      await loadPacientesFromDB(); // ✅ Solo recargar desde DB local
    } catch (e) {
    }
  }

  Future<Paciente?> getPacienteByIdentificacion(String identificacion) async {
    final db = DatabaseHelper.instance;
    return await db.getPacienteByIdentificacion(identificacion);
  }

  Map<String, dynamic>? getSedeById(String sedeId) {
    try {
      return _sedes.firstWhere((sede) => sede['id'] == sedeId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshSedes() async {
    await loadSedes();
  }

  // ✅ MÉTODO CORREGIDO - SIN CARGA AUTOMÁTICA DE PACIENTES
  Future<void> forceReloadAll() async {
    _isLoading = true;
    _isLoadingSedes = true;
    _isLoaded = false;
    notifyListeners();
    
    try {
      await loadSedes(); // ✅ Sedes sí se pueden recargar
      await loadPacientesFromDB(); // ✅ Solo desde DB local
    } catch (e) {
    } finally {
      _isLoading = false;
      _isLoadingSedes = false;
      notifyListeners();
    }
  }

  Future<bool> isConnected() async {
    final connectivity = await Connectivity().checkConnectivity();
    return !connectivity.contains(ConnectivityResult.none);
  }

  Future<int> getUnsyncedPacientesCount() async {
    try {
      final unsyncedPacientes = await DatabaseHelper.instance.getUnsyncedPacientes();
      return unsyncedPacientes.length;
    } catch (e) {
      return 0;
    }
  }

  Future<DuplicateStats> getDuplicateStats() async {
    try {
      final db = DatabaseHelper.instance;
      final allPacientes = await db.readAllPacientes();
      
      final identificationCounts = <String, int>{};
      int offlineCount = 0;
      
      for (final paciente in allPacientes) {
        identificationCounts[paciente.identificacion] = 
          (identificationCounts[paciente.identificacion] ?? 0) + 1;
        
        if (paciente.id.startsWith('offline_')) {
          offlineCount++;
        }
      }
      
      final duplicateGroups = identificationCounts.values.where((count) => count > 1).length;
      final totalDuplicates = identificationCounts.values.fold(0, (sum, count) => sum + (count > 1 ? count - 1 : 0));
      
      return DuplicateStats(
        totalPacientes: allPacientes.length,
        duplicateGroups: duplicateGroups,
        totalDuplicates: totalDuplicates,
        offlineCount: offlineCount,
      );
    } catch (e) {
      return DuplicateStats(
        totalPacientes: 0,
        duplicateGroups: 0,
        totalDuplicates: 0,
        offlineCount: 0,
      );
    }
  }
  
  void resetLoadState() {
    _isLoaded = false;
  }
}

// ✅ CLASES SIN CAMBIOS
class DuplicateCheckResult {
  final bool hasLocal;
  final bool hasServer;
  
  DuplicateCheckResult({required this.hasLocal, required this.hasServer});
  
  bool get hasDuplicate => hasLocal || hasServer;
}

class DuplicateStats {
  final int totalPacientes;
  final int duplicateGroups;
  final int totalDuplicates;
  final int offlineCount;
  
  DuplicateStats({
    required this.totalPacientes,
    required this.duplicateGroups,
    required this.totalDuplicates,
    required this.offlineCount,
  });
}