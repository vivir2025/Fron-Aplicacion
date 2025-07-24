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
  
  Future<void> loadSedes() async {
    _isLoadingSedes = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      final connectivity = await Connectivity().checkConnectivity();
      
      await db.ensureSedesTableExists();
      
      if (connectivity != ConnectivityResult.none && _authProvider.isAuthenticated) {
        try {
          debugPrint('Cargando sedes desde API...');
          final response = await ApiService.getSedes(_authProvider.token!);
          
          if (response != null && response is List) {
            _sedes = response.map<Map<String, dynamic>>((sede) => {
              'id': sede['id']?.toString() ?? '',
              'nombresede': sede['nombresede']?.toString() ?? '',
              'direccion': sede['direccion']?.toString() ?? '',
            }).toList();

            await db.saveSedes(_sedes);
            debugPrint('Sedes cargadas desde API y guardadas: ${_sedes.length}');
          } else {
            debugPrint('Respuesta de API de sedes vacía o inválida');
            _sedes = await db.getSedes();
          }
        } catch (e) {
          debugPrint('Error al cargar sedes desde API: $e');
          _sedes = await db.getSedes();
          debugPrint('Cargando sedes desde base de datos local: ${_sedes.length}');
        }
      } else {
        debugPrint('Modo offline, cargando sedes desde base de datos local...');
        _sedes = await db.getSedes();
        debugPrint('Sedes cargadas desde DB local: ${_sedes.length}');
      }

      if (_sedes.isEmpty) {
        debugPrint('No hay sedes disponibles, insertando por defecto');
        await db.insertDefaultSedes();
        _sedes = await db.getSedes();
        debugPrint('Sedes por defecto insertadas: ${_sedes.length}');
      }

      debugPrint('Sedes finalmente cargadas: ${_sedes.length}');
      await db.debugListSedes();

    } catch (e) {
      debugPrint('Error crítico en loadSedes: $e');
      _sedes = [];
      
      try {
        final db = DatabaseHelper.instance;
        await db.ensureSedesTableExists();
        await db.insertDefaultSedes();
        _sedes = await db.getSedes();
        debugPrint('Sedes de emergencia creadas: ${_sedes.length}');
      } catch (emergencyError) {
        debugPrint('Error al crear sedes de emergencia: $emergencyError');
      }
    } finally {
      _isLoadingSedes = false;
      notifyListeners();
    }
  }

  Future<void> loadPacientes() async {
    if (_isLoaded && !_isLoading) {
      debugPrint('Pacientes ya cargados, omitiendo carga duplicada');
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final db = DatabaseHelper.instance;
      
      if (connectivity != ConnectivityResult.none && _authProvider.isAuthenticated) {
        try {
          final response = await ApiService.getPacientes(_authProvider.token!);
          final serverPacientes = response.map<Paciente>((json) => Paciente.fromJson(json)).toList();

          for (final paciente in serverPacientes) {
            await db.upsertPaciente(paciente);
          }

          await syncPacientes();
          
          _pacientes = await db.readAllPacientes();
        } catch (e) {
          debugPrint('Error al cargar pacientes online: $e');
          _pacientes = await db.readAllPacientes();
        }
      } else {
        _pacientes = await db.readAllPacientes();
      }

      _pacientes = _removeDuplicates(_pacientes);
      
      debugPrint('Pacientes cargados: ${_pacientes.length}');
      
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading pacientes: $e');
      _pacientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      debugPrint('Error extrayendo timestamp de ID offline: $e');
    }
    return 0;
  }

  void _markForDeletion(String id) {
    Future.microtask(() async {
      try {
        await DatabaseHelper.instance.deletePaciente(id);
        debugPrint('Paciente duplicado eliminado: $id');
      } catch (e) {
        debugPrint('Error eliminando paciente duplicado $id: $e');
      }
    });
  }

  Future<void> syncPacientes() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none || !_authProvider.isAuthenticated) {
        return;
      }

      final unsyncedPacientes = await DatabaseHelper.instance.getUnsyncedPacientes();
      if (unsyncedPacientes.isEmpty) return;

      final syncedIds = <String>[];
      
      for (final paciente in unsyncedPacientes) {
        try {
          final existingOnServer = await _checkPacienteExistsOnServer(paciente.identificacion);
          
          if (existingOnServer != null) {
            debugPrint('Paciente ya existe en servidor, eliminando local: ${paciente.id}');
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
          debugPrint('Error sincronizando paciente ${paciente.id}: $e');
        }
      }

      if (syncedIds.isNotEmpty) {
        await DatabaseHelper.instance.markPacientesAsSynced(syncedIds);
        await loadPacientes();
      }
    } catch (e) {
      debugPrint('Error en syncPacientes: $e');
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
      debugPrint('Error verificando paciente en servidor: $e');
      return null;
    }
  }

  Future<void> addPaciente(Paciente paciente) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      
      final duplicateCheck = await _checkForDuplicates(paciente.identificacion);
      if (duplicateCheck.hasLocal || duplicateCheck.hasServer) {
        throw Exception('Ya existe un paciente con esta identificación');
      }

      // Siempre crear primero localmente para respuesta instantánea
      debugPrint('Creando paciente localmente primero...');
      final offlinePaciente = await _createPacienteOffline(paciente, db);
      
      // Verificar conectividad para sincronización en segundo plano
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline && _authProvider.isAuthenticated) {
        // No esperar la respuesta del servidor (usar Future.microtask)
        Future.microtask(() async {
          try {
            debugPrint('Sincronizando paciente con el servidor en segundo plano...');
            final createdPaciente = await ApiService.createPaciente(
              _authProvider.token!, 
              paciente.toJson()
            );
            
            // Reemplazar la versión local con la del servidor
            final newPaciente = Paciente.fromJson(createdPaciente);
            await db.deletePaciente(offlinePaciente.id); // Eliminar versión temporal
            await db.upsertPaciente(newPaciente); // Guardar versión del servidor
            
            // Actualizar la lista en memoria
            final index = _pacientes.indexWhere((p) => p.id == offlinePaciente.id);
            if (index != -1) {
              _pacientes[index] = newPaciente;
            } else {
              _pacientes.add(newPaciente);
            }
            
            debugPrint('Paciente sincronizado exitosamente con el servidor');
            notifyListeners(); // Notificar cambios después de sincronizar
          } catch (apiError) {
            debugPrint('Error al sincronizar paciente con servidor: $apiError');
            // El paciente ya está guardado localmente, así que no hay problema
          }
        });
      }
      
      debugPrint('Paciente agregado exitosamente (versión local)');
      
    } catch (e) {
      debugPrint('Error adding paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    
    if (await isConnected() && _authProvider.isAuthenticated) {
      try {
        final serverPaciente = await _checkPacienteExistsOnServer(identificacion);
        hasServer = serverPaciente != null;
      } catch (e) {
        debugPrint('Error verificando duplicados en servidor: $e');
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
      debugPrint('Paciente creado offline con ID: $offlineId');
      return offlinePaciente; // Devolver el paciente creado
    } catch (e) {
      debugPrint('Error al crear paciente offline: $e');
      throw Exception('Error al guardar paciente offline: $e');
    }
  }

  Future<void> updatePaciente(Paciente paciente) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      final duplicateCheck = await _checkForDuplicatesExcluding(
        paciente.identificacion, 
        paciente.id
      );
      if (duplicateCheck.hasLocal || duplicateCheck.hasServer) {
        throw Exception('Ya existe otro paciente con esta identificación');
      }

      // Primero actualizar localmente para respuesta instantánea
      await _updatePacienteOffline(paciente, db);

      if (isOnline && _authProvider.isAuthenticated) {
        // Sincronizar en segundo plano
        Future.microtask(() async {
          try {
            debugPrint('Sincronizando actualización con el servidor en segundo plano...');
            final updatedPaciente = await ApiService.updatePaciente(
              _authProvider.token!,
              paciente.id,
              paciente.toJson(),
            );
            
            // Actualizar en local con la respuesta del servidor
            final serverPaciente = Paciente.fromJson(updatedPaciente);
            await db.upsertPaciente(serverPaciente);
            
            // Actualizar en memoria
            final index = _pacientes.indexWhere((p) => p.id == paciente.id);
            if (index != -1) {
              _pacientes[index] = serverPaciente;
            }
            
            debugPrint('Actualización sincronizada con el servidor');
            notifyListeners();
          } catch (apiError) {
            debugPrint('Error al sincronizar actualización: $apiError');
            // Ya se actualizó localmente, así que no hay problema
          }
        });
      }
      
      debugPrint('Paciente actualizado localmente');
    } catch (e) {
      debugPrint('Error updating paciente: $e');
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
    
    if (await isConnected() && _authProvider.isAuthenticated) {
      try {
        final serverPaciente = await _checkPacienteExistsOnServer(identificacion);
        hasServer = serverPaciente != null && serverPaciente.id != excludeId;
      } catch (e) {
        debugPrint('Error verificando duplicados en servidor: $e');
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
    
    debugPrint('Paciente actualizado offline');
  }

  Future<void> deletePaciente(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      
      // Primero eliminar localmente para respuesta instantánea
      await db.deletePaciente(id);
      _pacientes.removeWhere((p) => p.id == id);
      debugPrint('Paciente eliminado localmente');
      
      // Verificar conectividad para sincronización en segundo plano
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline && _authProvider.isAuthenticated) {
        // Sincronizar eliminación en segundo plano
        Future.microtask(() async {
          try {
            await ApiService.deletePaciente(_authProvider.token!, id);
            debugPrint('Paciente eliminado del servidor');
          } catch (apiError) {
            debugPrint('Error al eliminar paciente del servidor: $apiError');
            // Ya se eliminó localmente, así que no hay problema
          }
        });
      }
      
    } catch (e) {
      debugPrint('Error deleting paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncData() async {
    if (_authProvider.isAuthenticated) {
      await loadSedes();
      
      _isLoaded = false;
      await loadPacientes();
    }
  }

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
              debugPrint('Duplicado eliminado: ${paciente.id}');
            }
          }
        }
      }
      
      _isLoaded = false;
      await loadPacientes();
      debugPrint('Limpieza de duplicados completada');
    } catch (e) {
      debugPrint('Error en cleanDuplicates: $e');
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
      debugPrint('Sede no encontrada: $sedeId');
      return null;
    }
  }

  Future<void> refreshSedes() async {
    await loadSedes();
  }

  Future<void> forceReloadAll() async {
    _isLoading = true;
    _isLoadingSedes = true;
    _isLoaded = false;
    notifyListeners();
    
    try {
      await loadSedes();
      await loadPacientes();
    } catch (e) {
      debugPrint('Error en forceReloadAll: $e');
    } finally {
      _isLoading = false;
      _isLoadingSedes = false;
      notifyListeners();
    }
  }

  Future<bool> isConnected() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }

  Future<int> getUnsyncedPacientesCount() async {
    try {
      final unsyncedPacientes = await DatabaseHelper.instance.getUnsyncedPacientes();
      return unsyncedPacientes.length;
    } catch (e) {
      debugPrint('Error obteniendo pacientes no sincronizados: $e');
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
      debugPrint('Error obteniendo estadísticas de duplicados: $e');
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
