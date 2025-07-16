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
  final AuthProvider _authProvider;

  PacienteProvider(this._authProvider);

  List<Paciente> get pacientes => _pacientes;
  List<Map<String, dynamic>> get sedes => _sedes;
  bool get isLoading => _isLoading;
  bool get isLoadingSedes => _isLoadingSedes;
  
  // Método para cargar sedes (CORREGIDO)
  Future<void> loadSedes() async {
    _isLoadingSedes = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      final connectivity = await Connectivity().checkConnectivity();
      
      // Asegurar que la tabla existe
      await db.ensureSedesTableExists();
      
      if (connectivity != ConnectivityResult.none && _authProvider.isAuthenticated) {
        try {
          // Online: traer sedes desde API
          debugPrint('Cargando sedes desde API...');
          final response = await ApiService.getSedes(_authProvider.token!);
          
          if (response != null && response is List) {
            _sedes = response.map<Map<String, dynamic>>((sede) => {
              'id': sede['id']?.toString() ?? '',
              'nombresede': sede['nombresede']?.toString() ?? '',
              'direccion': sede['direccion']?.toString() ?? '',
            }).toList();

            // Guardar sedes en SQLite
            await db.saveSedes(_sedes);
            debugPrint('Sedes cargadas desde API y guardadas: ${_sedes.length}');
          } else {
            debugPrint('Respuesta de API de sedes vacía o inválida');
            // Fallback a datos locales
            _sedes = await db.getSedes();
          }
        } catch (e) {
          debugPrint('Error al cargar sedes desde API: $e');
          // Fallback a datos locales
          _sedes = await db.getSedes();
          debugPrint('Cargando sedes desde base de datos local: ${_sedes.length}');
        }
      } else {
        // Offline: cargar desde SQLite
        debugPrint('Modo offline, cargando sedes desde base de datos local...');
        _sedes = await db.getSedes();
        debugPrint('Sedes cargadas desde DB local: ${_sedes.length}');
      }

      // Si no hay sedes, insertar algunas por defecto
      if (_sedes.isEmpty) {
        debugPrint('No hay sedes disponibles, insertando por defecto');
        await db.insertDefaultSedes();
        _sedes = await db.getSedes();
        debugPrint('Sedes por defecto insertadas: ${_sedes.length}');
      }

      debugPrint('Sedes finalmente cargadas: ${_sedes.length}');
      await db.debugListSedes(); // Debug

    } catch (e) {
      debugPrint('Error crítico en loadSedes: $e');
      _sedes = [];
      
      // Intentar crear tabla y sedes por defecto como último recurso
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
    _isLoading = true;
    notifyListeners();

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final db = DatabaseHelper.instance;
      
      if (connectivity != ConnectivityResult.none && _authProvider.isAuthenticated) {
        try {
          // Online: traer desde API
          final response = await ApiService.getPacientes(_authProvider.token!);
          final serverPacientes = response.map<Paciente>((json) => Paciente.fromJson(json)).toList();

          // Guardar pacientes del servidor en SQLite
          for (final paciente in serverPacientes) {
            await db.upsertPaciente(paciente);
          }

          // Sincronizar cambios locales antes de cargar
          await syncPacientes();
          
          // Cargar todos los pacientes desde la base de datos local
          _pacientes = await db.readAllPacientes();
        } catch (e) {
          debugPrint('Error al cargar pacientes online: $e');
          // Fallback a datos locales
          _pacientes = await db.readAllPacientes();
        }
      } else {
        // Offline: cargar desde SQLite
        _pacientes = await db.readAllPacientes();
      }

      // Filtrar duplicados de manera más robusta
      _pacientes = _removeDuplicates(_pacientes);
      
      debugPrint('Pacientes cargados: ${_pacientes.length}');
    } catch (e) {
      debugPrint('Error loading pacientes: $e');
      _pacientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MÉTODO MEJORADO: Eliminar duplicados de manera más robusta
  List<Paciente> _removeDuplicates(List<Paciente> pacientes) {
    final Map<String, Paciente> pacienteMap = {};
    
    // Primero procesar todos los pacientes y mantener el mejor de cada identificación
    for (final paciente in pacientes) {
      final identificacion = paciente.identificacion;
      
      if (!pacienteMap.containsKey(identificacion)) {
        // Primera vez que vemos esta identificación
        pacienteMap[identificacion] = paciente;
      } else {
        // Ya existe un paciente con esta identificación, determinar cuál mantener
        final existing = pacienteMap[identificacion]!;
        final betterPaciente = _selectBetterPaciente(existing, paciente);
        pacienteMap[identificacion] = betterPaciente;
        
        // Si hay duplicados, limpiar el peor de la base de datos
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

  // MÉTODO NUEVO: Seleccionar el mejor paciente entre duplicados
  Paciente _selectBetterPaciente(Paciente existing, Paciente candidate) {
    // Prioridad 1: Paciente sincronizado (syncStatus = 1) sobre no sincronizado
    if (existing.syncStatus == 1 && candidate.syncStatus != 1) {
      return existing;
    }
    if (candidate.syncStatus == 1 && existing.syncStatus != 1) {
      return candidate;
    }
    
    // Prioridad 2: Paciente con ID real sobre ID temporal (offline)
    final existingIsOffline = existing.id.startsWith('offline_');
    final candidateIsOffline = candidate.id.startsWith('offline_');
    
    if (!existingIsOffline && candidateIsOffline) {
      return existing;
    }
    if (!candidateIsOffline && existingIsOffline) {
      return candidate;
    }
    
    // Prioridad 3: Paciente más reciente (por timestamp en ID offline o fecha de modificación)
    if (existingIsOffline && candidateIsOffline) {
      final existingTimestamp = _extractTimestampFromOfflineId(existing.id);
      final candidateTimestamp = _extractTimestampFromOfflineId(candidate.id);
      return candidateTimestamp > existingTimestamp ? candidate : existing;
    }
    
    // Por defecto, mantener el existente
    return existing;
  }

  // MÉTODO AUXILIAR: Extraer timestamp del ID offline
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

  // MÉTODO AUXILIAR: Marcar paciente para eliminación
  void _markForDeletion(String id) {
    // Eliminar de la base de datos de manera asíncrona
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

      // Sincronizar pacientes creados offline
      final unsyncedPacientes = await DatabaseHelper.instance.getUnsyncedPacientes();
      if (unsyncedPacientes.isEmpty) return;

      final syncedIds = <String>[];
      
      for (final paciente in unsyncedPacientes) {
        try {
          // Verificar si ya existe un paciente con la misma identificación en el servidor
          final existingOnServer = await _checkPacienteExistsOnServer(paciente.identificacion);
          
          if (existingOnServer != null) {
            // Ya existe en servidor, eliminar el local y mantener el del servidor
            debugPrint('Paciente ya existe en servidor, eliminando local: ${paciente.id}');
            await DatabaseHelper.instance.deletePaciente(paciente.id);
            await DatabaseHelper.instance.upsertPaciente(existingOnServer);
            continue;
          }
          
          // Si es un paciente offline (ID temporal), crear en servidor
          if (paciente.id.startsWith('offline_')) {
            final createdPaciente = await ApiService.createPaciente(
              _authProvider.token!, 
              paciente.toJson()
            );
            syncedIds.add(paciente.id); // ID temporal a reemplazar
            // Eliminar el temporal y guardar el real
            await DatabaseHelper.instance.deletePaciente(paciente.id);
            await DatabaseHelper.instance.upsertPaciente(
              Paciente.fromJson(createdPaciente)
            );
          } else {
            // Si ya tiene ID real pero no estaba sincronizado, actualizar
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

      // Marcar como sincronizados
      if (syncedIds.isNotEmpty) {
        await DatabaseHelper.instance.markPacientesAsSynced(syncedIds);
        await loadPacientes(); // Refrescar la lista
      }
    } catch (e) {
      debugPrint('Error en syncPacientes: $e');
    }
  }

  // MÉTODO NUEVO: Verificar si un paciente existe en el servidor
  Future<Paciente?> _checkPacienteExistsOnServer(String identificacion) async {
    try {
      // Asumiendo que tienes un endpoint para buscar por identificación
      // Si no existe, puedes usar getPacientes y filtrar localmente
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

  // MÉTODO CORREGIDO: Mejor validación de duplicados
  Future<void> addPaciente(Paciente paciente) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      
      // Verificar duplicados de manera más exhaustiva
      final duplicateCheck = await _checkForDuplicates(paciente.identificacion);
      if (duplicateCheck.hasLocal || duplicateCheck.hasServer) {
        throw Exception('Ya existe un paciente con esta identificación');
      }

      // Verificar conectividad
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline && _authProvider.isAuthenticated) {
        try {
          // Online: enviar al servidor primero
          debugPrint('Creando paciente online...');
          final createdPaciente = await ApiService.createPaciente(
            _authProvider.token!, 
            paciente.toJson()
          );
          // Guardar la respuesta del servidor (con ID real)
          final newPaciente = Paciente.fromJson(createdPaciente);
          await db.upsertPaciente(newPaciente);
          
          // Agregar a la lista en memoria inmediatamente
          _pacientes.add(newPaciente);
          debugPrint('Paciente creado online exitosamente');
        } catch (apiError) {
          debugPrint('Error al crear paciente online: $apiError');
          // Si falla la API, crear offline como fallback
          await _createPacienteOffline(paciente, db);
        }
      } else {
        // Offline: crear paciente con ID temporal
        debugPrint('Creando paciente offline...');
        await _createPacienteOffline(paciente, db);
      }
      
      // Recargar y limpiar duplicados
      await loadPacientes();
      debugPrint('Paciente agregado exitosamente');
      
    } catch (e) {
      debugPrint('Error adding paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MÉTODO NUEVO: Verificación exhaustiva de duplicados
  Future<DuplicateCheckResult> _checkForDuplicates(String identificacion) async {
    final db = DatabaseHelper.instance;
    bool hasLocal = false;
    bool hasServer = false;
    
    // Verificar en base de datos local
    final localPaciente = await db.getPacienteByIdentificacion(identificacion);
    hasLocal = localPaciente != null;
    
    // Verificar en memoria
    final inMemory = _pacientes.any((p) => p.identificacion == identificacion);
    hasLocal = hasLocal || inMemory;
    
    // Verificar en servidor si hay conexión
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

  // Método auxiliar para crear paciente offline
  Future<void> _createPacienteOffline(Paciente paciente, DatabaseHelper db) async {
    try {
      // Generar un ID temporal único con timestamp más preciso
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = timestamp.toString().substring(8); // Últimos dígitos para unicidad
      final offlineId = 'offline_${timestamp}_${paciente.identificacion.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}_$randomSuffix';
      
      final offlinePaciente = paciente.copyWith(
        id: offlineId,
        syncStatus: 0, // Marcar como no sincronizado
      );
      
      await db.upsertPaciente(offlinePaciente);
      
      // Agregar a la lista en memoria inmediatamente
      _pacientes.add(offlinePaciente);
      debugPrint('Paciente creado offline con ID: $offlineId');
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

      // Verificar duplicados al actualizar (excluyendo el paciente actual)
      final duplicateCheck = await _checkForDuplicatesExcluding(
        paciente.identificacion, 
        paciente.id
      );
      if (duplicateCheck.hasLocal || duplicateCheck.hasServer) {
        throw Exception('Ya existe otro paciente con esta identificación');
      }

      if (isOnline && _authProvider.isAuthenticated) {
        try {
          // Online: actualizar en servidor
          final updatedPaciente = await ApiService.updatePaciente(
            _authProvider.token!,
            paciente.id,
            paciente.toJson(),
          );
          // Guardar los cambios en local
          await db.upsertPaciente(Paciente.fromJson(updatedPaciente));
          
          // Actualizar en memoria
          final index = _pacientes.indexWhere((p) => p.id == paciente.id);
          if (index != -1) {
            _pacientes[index] = Paciente.fromJson(updatedPaciente);
          }
        } catch (apiError) {
          debugPrint('Error al actualizar paciente online: $apiError');
          // Si falla la API, actualizar offline
          await _updatePacienteOffline(paciente, db);
        }
      } else {
        // Offline: actualizar localmente
        await _updatePacienteOffline(paciente, db);
      }
      
      // Limpiar duplicados después de actualizar
      await loadPacientes();
    } catch (e) {
      debugPrint('Error updating paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MÉTODO NUEVO: Verificar duplicados excluyendo un ID específico
  Future<DuplicateCheckResult> _checkForDuplicatesExcluding(
    String identificacion, 
    String excludeId
  ) async {
    final db = DatabaseHelper.instance;
    bool hasLocal = false;
    bool hasServer = false;
    
    // Verificar en base de datos local
    final localPaciente = await db.getPacienteByIdentificacion(identificacion);
    hasLocal = localPaciente != null && localPaciente.id != excludeId;
    
    // Verificar en memoria
    final inMemory = _pacientes.any((p) => 
      p.identificacion == identificacion && p.id != excludeId
    );
    hasLocal = hasLocal || inMemory;
    
    // Verificar en servidor si hay conexión
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

  // Método auxiliar para actualizar paciente offline
  Future<void> _updatePacienteOffline(Paciente paciente, DatabaseHelper db) async {
    // Offline: marcar como no sincronizado si ya estaba sincronizado
    final updatedPaciente = paciente.syncStatus == 1 
      ? paciente.copyWith(syncStatus: 0) 
      : paciente;
    
    await db.upsertPaciente(updatedPaciente);
    
    // Actualizar en memoria
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
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline && _authProvider.isAuthenticated) {
        try {
          await ApiService.deletePaciente(_authProvider.token!, id);
          debugPrint('Paciente eliminado del servidor');
        } catch (apiError) {
          debugPrint('Error al eliminar paciente del servidor: $apiError');
          // Continuar con eliminación local aunque falle la API
        }
      }
      
      // Eliminar tanto en local como en memoria
      await db.deletePaciente(id);
      _pacientes.removeWhere((p) => p.id == id);
      
      debugPrint('Paciente eliminado localmente');
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MÉTODO CORREGIDO: Cargar sedes antes que pacientes
  Future<void> syncData() async {
    if (_authProvider.isAuthenticated) {
      await loadSedes(); // Cargar sedes PRIMERO
      await loadPacientes(); // Luego cargar pacientes
    }
  }

  void clearData() {
    _pacientes = [];
    _sedes = [];
    _isLoading = false;
    _isLoadingSedes = false;
    notifyListeners();
  }

  // MÉTODO NUEVO: Limpiar duplicados manualmente
  Future<void> cleanDuplicates() async {
    try {
      final db = DatabaseHelper.instance;
      final allPacientes = await db.readAllPacientes();
      
      // Agrupar por identificación
      final groups = <String, List<Paciente>>{};
      for (final paciente in allPacientes) {
        groups.putIfAbsent(paciente.identificacion, () => []).add(paciente);
      }
      
      // Procesar cada grupo de duplicados
      for (final group in groups.values) {
        if (group.length > 1) {
          // Seleccionar el mejor y eliminar el resto
          final best = group.reduce((a, b) => _selectBetterPaciente(a, b));
          for (final paciente in group) {
            if (paciente.id != best.id) {
              await db.deletePaciente(paciente.id);
              debugPrint('Duplicado eliminado: ${paciente.id}');
            }
          }
        }
      }
      
      // Recargar la lista
      await loadPacientes();
      debugPrint('Limpieza de duplicados completada');
    } catch (e) {
      debugPrint('Error en cleanDuplicates: $e');
    }
  }

  // Método auxiliar para buscar paciente por identificación
  Future<Paciente?> getPacienteByIdentificacion(String identificacion) async {
    final db = DatabaseHelper.instance;
    return await db.getPacienteByIdentificacion(identificacion);
  }

  // Método para obtener una sede por ID
  Map<String, dynamic>? getSedeById(String sedeId) {
    try {
      return _sedes.firstWhere((sede) => sede['id'] == sedeId);
    } catch (e) {
      debugPrint('Sede no encontrada: $sedeId');
      return null;
    }
  }

  // Método para refrescar sedes manualmente
  Future<void> refreshSedes() async {
    await loadSedes();
  }

  // MÉTODO NUEVO: Forzar recarga completa de sedes
  Future<void> forceReloadSedes() async {
    _isLoadingSedes = true;
    notifyListeners();
    
    try {
      final db = DatabaseHelper.instance;
      await db.ensureSedesTableExists();
      await loadSedes();
    } catch (e) {
      debugPrint('Error en forceReloadSedes: $e');
    } finally {
      _isLoadingSedes = false;
      notifyListeners();
    }
  }

  // MÉTODO NUEVO: Verificar estado de conectividad
  Future<bool> isConnected() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }

  // MÉTODO NUEVO: Obtener cantidad de pacientes pendientes de sincronización
  Future<int> getUnsyncedPacientesCount() async {
    try {
      final unsyncedPacientes = await DatabaseHelper.instance.getUnsyncedPacientes();
      return unsyncedPacientes.length;
    } catch (e) {
      debugPrint('Error obteniendo pacientes no sincronizados: $e');
      return 0;
    }
  }

  // MÉTODO NUEVO: Obtener estadísticas de duplicados
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
}

// Clase auxiliar para el resultado de verificación de duplicados
class DuplicateCheckResult {
  final bool hasLocal;
  final bool hasServer;
  
  DuplicateCheckResult({required this.hasLocal, required this.hasServer});
  
  bool get hasDuplicate => hasLocal || hasServer;
}

// Clase auxiliar para estadísticas de duplicados
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