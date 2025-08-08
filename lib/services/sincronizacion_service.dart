import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:fnpv_app/models/paciente_model.dart';
import 'package:fnpv_app/models/visita_model.dart';
import 'package:fnpv_app/services/afinamiento_service.dart';
import 'package:fnpv_app/services/brigada_service.dart';
import 'package:fnpv_app/services/encuesta_service.dart';
import 'package:fnpv_app/services/envio_muestra_service.dart';
import 'package:fnpv_app/services/findrisk_service.dart';
import 'package:fnpv_app/services/medicamento_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'file_service.dart'; 

class SincronizacionService {
  // Singleton para evitar múltiples instancias
  static final SincronizacionService _instance = SincronizacionService._internal();
  factory SincronizacionService() => _instance;
  SincronizacionService._internal();

  // Variables para controlar el estado de la sincronización
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isListening = false;
  bool _isSyncInProgress = false;
  Timer? _retryTimer;


  
  // 🆕 MÉTODO PARA SINCRONIZAR MEDICAMENTOS (DENTRO DE LA CLASE)
  static Future<Map<String, dynamic>> sincronizarMedicamentos(String token) async {
    try {
      debugPrint('💊 Sincronizando medicamentos desde servidor...');
      
      final success = await MedicamentoService.loadMedicamentosFromServer(token);
      
      if (success) {
        final dbHelper = DatabaseHelper.instance;
        final count = await dbHelper.countMedicamentos();
        
        debugPrint('✅ $count medicamentos sincronizados desde servidor');
        
        return {
          'exitosas': count,
          'fallidas': 0,
          'errores': [],
          'total': count,
        };
      } else {
        debugPrint('⚠️ No se pudieron cargar medicamentos desde el servidor');
        return {
          'exitosas': 0,
          'fallidas': 1,
          'errores': ['No se pudieron cargar medicamentos desde el servidor'],
          'total': 1,
        };
      }
    } catch (e) {
      debugPrint('❌ Error sincronizando medicamentos: $e');
      return {
        'exitosas': 0,
        'fallidas': 1,
        'errores': ['Error: $e'],
        'total': 1,
      };
    }
  }
  static Future<Map<String, dynamic>> sincronizarBrigadasPendientes(String token) async {
  try {
    debugPrint('🏥 Iniciando sincronización de brigadas...');
    
    final resultado = await BrigadaService.sincronizarBrigadasPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
      debugPrint('✅ $exitosas brigadas sincronizadas exitosamente');
    }
    
    if (fallidas > 0) {
      debugPrint('⚠️ $fallidas brigadas fallaron en la sincronización');
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
        debugPrint('❌ Error: $error');
      }
    }
    
    return resultado;
  } catch (e) {
    debugPrint('💥 Error en sincronización de brigadas: $e');
    return {
      'exitosas': 0,
      'fallidas': 1,
      'errores': ['Error general: $e'],
      'total': 1,
    };
  }
}
// Método para sincronizar encuestas (agregar dentro de la clase)
static Future<Map<String, dynamic>> sincronizarEncuestasPendientes(String token) async {
  try {
    debugPrint('📋 Iniciando sincronización de encuestas...');
    
    final resultado = await EncuestaService.sincronizarEncuestasPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
      debugPrint('✅ $exitosas encuestas sincronizadas exitosamente');
    }
    
    if (fallidas > 0) {
      debugPrint('⚠️ $fallidas encuestas fallaron en la sincronización');
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
        debugPrint('❌ Error: $error');
      }
    }
    
    return resultado;
  } catch (e) {
    debugPrint('💥 Error en sincronización de encuestas: $e');
    return {
      'exitosas': 0,
      'fallidas': 1,
      'errores': ['Error general: $e'],
      'total': 1,
    };
  }
}
// services/sincronizacion_service.dart - MÉTODO CORREGIDO
static Future<Map<String, dynamic>> sincronizarFindriskTestsPendientes(String token) async {
  try {
    debugPrint('🔍 Iniciando sincronización de tests FINDRISK...');
    
    // ✅ VALIDAR QUE EL TOKEN NO ESTÉ VACÍO
    if (token.isEmpty) {
      throw Exception('Token de autenticación requerido para sincronización FINDRISK');
    }
    
    // ✅ PASAR EL TOKEN AL FINDRISK SERVICE
    final resultado = await FindriskService.sincronizarTestsPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
      debugPrint('✅ $exitosas tests FINDRISK sincronizados exitosamente');
    }
    
    if (fallidas > 0) {
      debugPrint('⚠️ $fallidas tests FINDRISK fallaron en la sincronización');
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
        debugPrint('❌ Error: $error');
      }
    }
    
    return resultado;
  } catch (e) {
    debugPrint('💥 Error en sincronización de tests FINDRISK: $e');
    return {
      'exitosas': 0,
      'fallidas': 1,
      'errores': ['Error general: $e'],
      'total': 1,
    };
  }
}
// Método para sincronizar afinamientos (agregar dentro de la clase)
static Future<Map<String, dynamic>> sincronizarAfinamientosPendientes(String token) async {
  try {
    debugPrint('🩺 Iniciando sincronización de afinamientos...');
    
    final resultado = await AfinamientoService.sincronizarAfinamientosPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
      debugPrint('✅ $exitosas afinamientos sincronizados exitosamente');
    }
    
    if (fallidas > 0) {
      debugPrint('⚠️ $fallidas afinamientos fallaron en la sincronización');
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
        debugPrint('❌ Error: $error');
      }
    }
    
    return resultado;
  } catch (e) {
    debugPrint('💥 Error en sincronización de afinamientos: $e');
    return {
      'exitosas': 0,
      'fallidas': 1,
      'errores': ['Error general: $e'],
      'total': 1,
    };
  }
}


// 🆕 MÉTODO ACTUALIZADO PARA SINCRONIZACIÓN COMPLETA
static Future<Map<String, dynamic>> sincronizacionCompleta(String token) async {
  debugPrint('🔄 Iniciando sincronización completa...');
  
  final Map<String, dynamic> resultado = {
    'medicamentos': {'exitosas': 0, 'fallidas': 0, 'errores': []}, 
    'visitas': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'pacientes': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'envios_muestras': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'brigadas': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'encuestas': {'exitosas': 0, 'fallidas': 0, 'errores': []}, 
    'findrisk_tests': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'afinamientos': {'exitosas': 0, 'fallidas': 0, 'errores': []}, 
    'archivos': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'tiempo_total': 0,
    'exito_general': false,
  };
  
  final stopwatch = Stopwatch()..start();
  
  try {
    // 🆕 1. Sincronizar medicamentos primero
    debugPrint('💊 Sincronizando medicamentos...');
    resultado['medicamentos'] = await sincronizarMedicamentos(token);
    
    final medicamentosExitosos = resultado['medicamentos']['exitosas'] ?? 0;
    if (medicamentosExitosos > 0) {
      debugPrint('✅ $medicamentosExitosos medicamentos sincronizados exitosamente');
    }
    
    // 2. Sincronizar visitas pendientes
    debugPrint('1️⃣ Sincronizando visitas pendientes...');
    resultado['visitas'] = await sincronizarVisitasPendientes(token);
    
    final visitasExitosas = resultado['visitas']['exitosas'] ?? 0;
    if (visitasExitosas > 0) {
      debugPrint('✅ $visitasExitosas visitas sincronizadas exitosamente');
    }
    
    // 3. Sincronizar pacientes pendientes
    debugPrint('2️⃣ Sincronizando pacientes pendientes...');
    resultado['pacientes'] = await sincronizarPacientesPendientes(token);
    
    final pacientesExitosos = resultado['pacientes']['exitosas'] ?? 0;
    if (pacientesExitosos > 0) {
      debugPrint('✅ $pacientesExitosos pacientes sincronizados exitosamente');
    }
    
    // 4. 🆕 Sincronizar envíos de muestras pendientes
    debugPrint('3️⃣ Sincronizando envíos de muestras pendientes...');
    resultado['envios_muestras'] = await sincronizarEnviosMuestrasPendientes(token);

    // 5. 🆕 Sincronizar brigadas pendientes
    debugPrint('4️⃣ Sincronizando brigadas pendientes...');
    resultado['brigadas'] = await sincronizarBrigadasPendientes(token);

    // 6. 🆕 Sincronizar encuestas pendientes
    debugPrint('5️⃣ Sincronizando encuestas pendientes...');
    resultado['encuestas'] = await sincronizarEncuestasPendientes(token);

    // 7. 🆕 Sincronizar tests FINDRISK pendientes
    debugPrint('6️⃣ Sincronizando tests FINDRISK pendientes...');
    resultado['findrisk_tests'] = await sincronizarFindriskTestsPendientes(token);

     debugPrint('8️⃣ Sincronizando afinamientos pendientes...');
     resultado['afinamientos'] = await sincronizarAfinamientosPendientes(token);

    // 8. Sincronizar archivos pendientes
    debugPrint('7️⃣ Sincronizando archivos pendientes...');
    resultado['archivos'] = await sincronizarArchivosPendientes(token);
    
    final archivosExitosos = resultado['archivos']['exitosas'] ?? 0;
    if (archivosExitosos > 0) {
      debugPrint('✅ $archivosExitosos archivos sincronizados exitosamente');
    }
    
    // 9. Limpiar archivos antiguos
    debugPrint('8️⃣ Limpiando archivos antiguos...');
    await limpiarArchivosLocales();
    
    stopwatch.stop();
    resultado['tiempo_total'] = stopwatch.elapsedMilliseconds;
    
    // Determinar éxito general
    final enviosExitosos = resultado['envios_muestras']['exitosas'] ?? 0; // 🆕
    final brigadasExitosas = resultado['brigadas']['exitosas'] ?? 0; // 🆕
    final encuestasExitosas = resultado['encuestas']['exitosas'] ?? 0;
    final findriskExitosos = resultado['findrisk_tests']['exitosas'] ?? 0; 
    final afinamientosExitosos = resultado['afinamientos']['exitosas'] ?? 0;// 🆕 FINDRISK
    final totalExitosas = medicamentosExitosos + visitasExitosas + pacientesExitosos + 
    archivosExitosos + brigadasExitosas + enviosExitosos + encuestasExitosas + findriskExitosos
    + afinamientosExitosos; 
    
    resultado['exito_general'] = totalExitosas > 0;
    
    if (resultado['exito_general']) {
      debugPrint('🎉 Sincronización completa finalizada exitosamente en ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Resumen: $medicamentosExitosos medicamentos, $visitasExitosas visitas, $pacientesExitosos pacientes, $enviosExitosos envíos, $brigadasExitosas brigadas, $encuestasExitosas encuestas, $findriskExitosos tests FINDRISK, $afinamientosExitosos afinamientos, $archivosExitosos archivos sincronizados');
    } else {
      debugPrint('⚠️ Sincronización completa finalizada sin elementos para sincronizar en ${stopwatch.elapsedMilliseconds}ms');
    }
    
  } catch (e) {
    stopwatch.stop();
    resultado['tiempo_total'] = stopwatch.elapsedMilliseconds;
    resultado['error_general'] = e.toString();
    debugPrint('💥 Error en sincronización completa: $e');
  }
  
  return resultado;
}




 // ✅ MÉTODO CORREGIDO PARA connectivity_plus ^6.1.4
Future<void> scheduleSync() async {
  debugPrint('🔄 Programando sincronización automática...');
  
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pendingSyncTasks', true);
    await prefs.setString('lastSyncRequest', DateTime.now().toIso8601String());
    debugPrint('✅ Marcado como pendiente de sincronización');
  } catch (e) {
    debugPrint('⚠️ Error al guardar estado de sincronización: $e');
  }

  if (_isListening) {
    debugPrint('ℹ️ Ya estamos escuchando cambios de conectividad');
    return;
  }

  try {
    _isListening = true;
    
    // ✅ CORRECTO PARA connectivity_plus ^6.1.4
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // Tomar el primer resultado (el más relevante)
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        
        debugPrint('📶 Cambio de conectividad detectado: $result');
        debugPrint('📶 Todos los resultados: $results');
        
        if (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
          debugPrint('🌐 Detectada conexión a internet. Verificando conexión real...');
          
          try {
            final hasRealConnection = await _checkRealConnection();
            if (hasRealConnection) {
              debugPrint('✅ Conexión real confirmada. Iniciando sincronización automática...');
              await _startSyncProcess();
            } else {
              debugPrint('⚠️ Sin conexión real a pesar del cambio detectado');
            }
          } catch (e) {
            debugPrint('❌ Error al verificar conexión real: $e');
          }
        } else {
          debugPrint('📵 Sin conexión de red detectada');
        }
      },
      onError: (error) {
        debugPrint('❌ Error en listener de conectividad: $error');
      },
    ) as StreamSubscription<ConnectivityResult>?;
    
    // ✅ VERIFICAR CONEXIÓN INICIAL - CORRECTO PARA ^6.1.4
    try {
      final List<ConnectivityResult> currentConnectivity = await Connectivity().checkConnectivity();
      final ConnectivityResult firstResult = currentConnectivity.isNotEmpty 
          ? currentConnectivity.first 
          : ConnectivityResult.none;
      
      debugPrint('📶 Conectividad inicial: $firstResult');
      debugPrint('📶 Todas las conexiones iniciales: $currentConnectivity');
      
      if (firstResult == ConnectivityResult.wifi || firstResult == ConnectivityResult.mobile) {
        debugPrint('🌐 Ya hay conexión disponible. Verificando conexión real...');
        
        try {
          final hasRealConnection = await _checkRealConnection();
          if (hasRealConnection) {
            debugPrint('✅ Conexión real confirmada. Iniciando sincronización inmediata...');
            await _startSyncProcess();
          } else {
            debugPrint('⚠️ Sin conexión real detectada inicialmente');
          }
        } catch (connectionError) {
          debugPrint('❌ Error verificando conexión real inicial: $connectionError');
        }
      } else {
        debugPrint('📵 Sin conexión detectada actualmente');
      }
    } catch (connectivityError) {
      debugPrint('⚠️ Error al verificar conectividad inicial: $connectivityError');
    }
    
    debugPrint('👂 Escuchando cambios de conectividad correctamente');
  } catch (e) {
    _isListening = false;
    debugPrint('❌ Error al programar sincronización: $e');
    debugPrint('❌ Stack trace: ${e.toString()}');
  }
}

  // Método para verificar conexión real (no solo estado del adaptador)
  Future<bool> _checkRealConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
// services/sincronizacion_service.dart - MÉTODO CORREGIDO PARA ENVÍOS
static Future<Map<String, dynamic>> sincronizarEnviosMuestrasPendientes(String token) async {
  try {
    debugPrint('🧪 Iniciando sincronización de envíos de muestras...');
    
    // ✅ USAR EL SERVICIO ESPECÍFICO
    final resultado = await EnvioMuestraService.sincronizarEnviosPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    final total = resultado['total'] ?? 0;
    
    if (exitosas > 0) {
      debugPrint('✅ $exitosas envíos de muestras sincronizados exitosamente');
    }
    
    if (fallidas > 0) {
      debugPrint('⚠️ $fallidas envíos de muestras fallaron en la sincronización');
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) { // Mostrar solo los primeros 3 errores
        debugPrint('❌ Error: $error');
      }
    }
    
    return resultado;
  } catch (e) {
    debugPrint('💥 Error en sincronización de envíos de muestras: $e');
    return {
      'exitosas': 0,
      'fallidas': 1,
      'errores': ['Error general: $e'],
      'total': 1,
    };
  }
}


  // Método para iniciar el proceso de sincronización
  Future<void> _startSyncProcess() async {
    // Evitar múltiples sincronizaciones simultáneas
    if (_isSyncInProgress) {
      debugPrint('⚠️ Ya hay una sincronización en progreso. Ignorando...');
      return;
    }

    _isSyncInProgress = true;
    
    try {
      // Verificar si realmente hay tareas pendientes
      final prefs = await SharedPreferences.getInstance();
      final hasPendingTasks = prefs.getBool('pendingSyncTasks') ?? false;
      
      if (!hasPendingTasks) {
        debugPrint('ℹ️ No hay tareas pendientes de sincronización');
        _cleanupAfterSync();
        return;
      }
      
      debugPrint('🔄 Iniciando proceso de sincronización automática...');
      
      // Obtener token para la sincronización
      final token = await _getAuthToken();
      
      if (token == null) {
        debugPrint('⚠️ No hay token disponible. No se puede sincronizar.');
        // Programar reintento después
        _scheduleRetry();
        return;
      }
      
      // Ejecutar sincronización completa
      final resultado = await sincronizacionCompleta(token);
      
if (resultado['exito_general'] == true) {
  debugPrint('✅ Sincronización automática completada exitosamente');
  
  // Mostrar resumen de lo sincronizado
  final visitasSync = resultado['visitas']['exitosas'] ?? 0;
  final pacientesSync = resultado['pacientes']['exitosas'] ?? 0;
  final archivosSync = resultado['archivos']['exitosas'] ?? 0;
  final medicamentosSync = resultado['medicamentos']['exitosas'] ?? 0; // 🆕 Nueva línea
  
  if (medicamentosSync > 0) { // 🆕 Nuevo bloque
    debugPrint('💊 $medicamentosSync medicamentos sincronizados exitosamente');
  }
  if (visitasSync > 0) {
    debugPrint('📋 $visitasSync visitas sincronizadas exitosamente');
  }
  if (pacientesSync > 0) {
    debugPrint('👥 $pacientesSync pacientes sincronizados exitosamente');
  }
  if (archivosSync > 0) {
    debugPrint('📁 $archivosSync archivos sincronizados exitosamente');
  }
  
  // Limpiar estado de sincronización pendiente
  await prefs.setBool('pendingSyncTasks', false);
  await prefs.setString('lastSuccessfulSync', DateTime.now().toIso8601String());
  
  // Verificar si aún hay pendientes
  final estadoActual = await obtenerEstadoSincronizacion();
  final pendientesRestantes = estadoActual['pendientes'] ?? 0;
  
  if (pendientesRestantes > 0) {
    debugPrint('⚠️ Aún quedan $pendientesRestantes elementos por sincronizar');
    await prefs.setBool('pendingSyncTasks', true);
  } else {
    debugPrint('🎉 ¡Toda la información ha sido sincronizada exitosamente!');
    // Todo sincronizado, limpiar listeners
    _cleanupAfterSync();
  }
} else {
  debugPrint('⚠️ Sincronización completada con algunos problemas');
  _scheduleRetry();
}
      
    } catch (e) {
      debugPrint('❌ Error durante sincronización automática: $e');
      _scheduleRetry();
    } finally {
      _isSyncInProgress = false;
    }
  }

  // Obtener token de autenticación
  Future<String?> _getAuthToken() async {
    try {
      // Intenta obtener token de SharedPreferences primero
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      
      if (savedToken != null && savedToken.isNotEmpty) {
        return savedToken;
      }
      
      // Si no hay token guardado, devolver null
      return null;
    } catch (e) {
      debugPrint('❌ Error al obtener token: $e');
      return null;
    }
  }

  // Programar reintento
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 15), () {
      debugPrint('⏰ Reintentando sincronización programada...');
      _startSyncProcess();
    });
    debugPrint('⏰ Sincronización programada para reintentar en 15 minutos');
  }

  // Limpiar recursos después de sincronización
  void _cleanupAfterSync() {
    if (_connectivitySubscription != null) {
      _connectivitySubscription!.cancel();
      _connectivitySubscription = null;
    }
    _retryTimer?.cancel();
    _isListening = false;
    debugPrint('🧹 Limpieza de recursos de sincronización completada');
  }

  // Método para forzar una sincronización manual
  Future<Map<String, dynamic>> syncNow(String token) async {
    _isSyncInProgress = true;
    try {
      debugPrint('🔄 Iniciando sincronización manual...');
      
      final resultado = await sincronizacionCompleta(token);
      
      // Mostrar resumen de la sincronización manual
      final visitasSync = resultado['visitas']['exitosas'] ?? 0;
      final pacientesSync = resultado['pacientes']['exitosas'] ?? 0;
      final archivosSync = resultado['archivos']['exitosas'] ?? 0;
      
      if (resultado['exito_general'] == true) {
        debugPrint('✅ Sincronización manual completada exitosamente');
        
        if (visitasSync > 0) {
          debugPrint('📋 $visitasSync visitas sincronizadas manualmente');
        }
        if (pacientesSync > 0) {
          debugPrint('👥 $pacientesSync pacientes sincronizados manualmente');
        }
        if (archivosSync > 0) {
          debugPrint('📁 $archivosSync archivos sincronizados manualmente');
        }
        
        if (visitasSync == 0 && pacientesSync == 0 && archivosSync == 0) {
          debugPrint('ℹ️ No había elementos pendientes por sincronizar');
        }
      } else {
        debugPrint('⚠️ Sincronización manual completada con problemas');
      }
      
      // Actualizar estado en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final estadoActual = await obtenerEstadoSincronizacion();
      final pendientesRestantes = estadoActual['pendientes'] ?? 0;
      
      if (pendientesRestantes > 0) {
        await prefs.setBool('pendingSyncTasks', true);
        debugPrint('⚠️ Quedan $pendientesRestantes elementos por sincronizar');
      } else {
        await prefs.setBool('pendingSyncTasks', false);
        debugPrint('🎉 ¡Toda la información está sincronizada!');
      }
      
      await prefs.setString('lastManualSync', DateTime.now().toIso8601String());
      
      return resultado;
    } finally {
      _isSyncInProgress = false;
    }
  }

  // ==================== MÉTODOS ESTÁTICOS EXISTENTES ====================

  static Future<bool> guardarVisita(Visita visita, String? token) async {
  try {
    // 1. Guardar siempre en SQLite primero
    final dbHelper = DatabaseHelper.instance;
    final savedLocally = await dbHelper.createVisita(visita);
    
    if (!savedLocally) {
      debugPrint('❌ No se pudo guardar visita localmente');
      return false;
    }
    
    debugPrint('✅ Visita guardada localmente');
    
    // 2. Intentar subir al servidor si hay token
    if (token != null) {
      try {
        // Verificar conectividad antes de intentar sincronizar
        final hasConnection = await ApiService.verificarConectividad();
        
        if (hasConnection) {
          // 🆕 Subir archivos mejorado con múltiples fotos y archivos
          final visitaConUrls = await _subirArchivosDeVisita(visita, token);
          
          // Actualizar en base de datos local con URLs
          await dbHelper.updateVisita(visitaConUrls);
          
          // Preparar datos para el servidor
          Map<String, dynamic> visitaData = visitaConUrls.toServerJson();
          
          // Verificar si medicamentos es un array y convertirlo a string
          if (visitaData['medicamentos'] != null && visitaData['medicamentos'] is! String) {
            visitaData['medicamentos'] = jsonEncode(visitaData['medicamentos']);
          }
          
          // Usar toServerJson() para el formato correcto
          final serverData = await ApiService.guardarVisita(visitaData, token);
          
          if (serverData != null) {
            // Marcar como sincronizada
            await dbHelper.marcarVisitaComoSincronizada(visita.id);
            debugPrint('✅ Visita sincronizada exitosamente con el servidor');
            
            // Sincronizar pacientes pendientes
            await sincronizarPacientesPendientes(token);
            
            return true;
          }
        } else {
          debugPrint('📵 Sin conexión a internet - Visita quedará pendiente de sincronización');
        }
      } catch (e) {
        debugPrint('⚠️ Error al subir al servidor: $e');
        // La visita ya está guardada localmente, no es un error crítico
      }
    } else {
      debugPrint('🔑 No hay token de autenticación - Visita quedará pendiente de sincronización');
    }
    
    return true; // Éxito si al menos se guardó localmente
  } catch (e) {
    debugPrint('💥 Error completo al guardar visita: $e');
    return false;
  }
}


 static Future<Visita> _subirArchivosDeVisita(Visita visita, String token) async {
  debugPrint('📁 Iniciando subida de archivos para visita ${visita.id}');

  // URLs que se actualizarán
  String? riesgoFotograficoUrl = visita.riesgoFotograficoUrl;
  String? firmaUrl = visita.firmaUrl;
  String? firmaPathUrl = visita.firmaPath != null && visita.firmaPath!.startsWith('http') 
      ? visita.firmaPath 
      : null;
  List<String> fotosPathsUrls = [];
  List<String> archivosAdjuntosUrls = [];

  try {
    // 1. Verificar y subir foto de riesgo (LEGACY)
    if (visita.riesgoFotografico != null && 
        visita.riesgoFotografico!.isNotEmpty &&
        !visita.riesgoFotografico!.startsWith('http') &&
        riesgoFotograficoUrl == null) {
      
      // Verificar que el archivo exista antes de intentar subirlo
      final file = File(visita.riesgoFotografico!);
      if (await file.exists()) {
        debugPrint('📸 Subiendo foto de riesgo: ${visita.riesgoFotografico}');
        try {
          riesgoFotograficoUrl = await FileService.uploadRiskPhoto(
            visita.riesgoFotografico!,
            token
          );
          if (riesgoFotograficoUrl != null) {
            debugPrint('✅ Foto de riesgo sincronizada exitosamente: $riesgoFotograficoUrl');
          } else {
            debugPrint('⚠️ No se pudo subir la foto de riesgo');
          }
        } catch (e) {
          debugPrint('❌ Error al subir foto de riesgo: $e');
        }
      } else {
        debugPrint('⚠️ El archivo de foto de riesgo no existe: ${visita.riesgoFotografico}');
      }
    }

    // 2. Verificar y subir firma (LEGACY)
    if (visita.firma != null && 
        visita.firma!.isNotEmpty &&
        !visita.firma!.startsWith('http') &&
        firmaUrl == null) {
      
      // Verificar que el archivo exista antes de intentar subirlo
      final file = File(visita.firma!);
      if (await file.exists()) {
        debugPrint('✍️ Subiendo firma legacy: ${visita.firma}');
        try {
          firmaUrl = await FileService.uploadSignature(
            visita.firma!,
            token
          );
          if (firmaUrl != null) {
            debugPrint('✅ Firma legacy sincronizada exitosamente: $firmaUrl');
          } else {
            debugPrint('⚠️ No se pudo subir la firma legacy');
          }
        } catch (e) {
          debugPrint('❌ Error al subir firma legacy: $e');
        }
      } else {
        debugPrint('⚠️ El archivo de firma legacy no existe: ${visita.firma}');
      }
    }

    // 3. Verificar y subir nueva firma (firmaPath)
    if (visita.firmaPath != null && 
        visita.firmaPath!.isNotEmpty &&
        !visita.firmaPath!.startsWith('http')) {
      
      // Verificar que el archivo exista antes de intentar subirlo
      final file = File(visita.firmaPath!);
      if (await file.exists()) {
        debugPrint('✍️ Subiendo nueva firma: ${visita.firmaPath}');
        try {
          firmaPathUrl = await FileService.uploadSignature(
            visita.firmaPath!,
            token
          );
          if (firmaPathUrl != null) {
            debugPrint('✅ Nueva firma sincronizada exitosamente: $firmaPathUrl');
          } else {
            debugPrint('⚠️ No se pudo subir la nueva firma');
          }
        } catch (e) {
          debugPrint('❌ Error al subir nueva firma: $e');
        }
      } else {
        debugPrint('⚠️ El archivo de nueva firma no existe: ${visita.firmaPath}');
      }
    }

    // 4. Verificar y subir múltiples fotos (fotosPaths)
    if (visita.fotosPaths != null && visita.fotosPaths!.isNotEmpty) {
      int fotosSubidas = 0;
      for (int i = 0; i < visita.fotosPaths!.length; i++) {
        final fotoPath = visita.fotosPaths![i];
        if (fotoPath.isNotEmpty && !fotoPath.startsWith('http')) {
          try {
            // Verificar que el archivo exista antes de intentar subirlo
            final file = File(fotoPath);
            if (await file.exists()) {
              debugPrint('📸 Subiendo foto ${i + 1}: $fotoPath');
              final fotoUrl = await FileService.uploadPhoto(fotoPath, token);
              if (fotoUrl != null) {
                fotosPathsUrls.add(fotoUrl);
                fotosSubidas++;
                debugPrint('✅ Foto ${i + 1} sincronizada exitosamente: $fotoUrl');
              } else {
                debugPrint('⚠️ No se pudo subir la foto ${i + 1}');
                fotosPathsUrls.add(fotoPath); // Mantener path local si falla
              }
            } else {
              debugPrint('⚠️ El archivo de foto ${i + 1} no existe: $fotoPath');
              fotosPathsUrls.add(fotoPath); // Mantener path local si no existe
            }
          } catch (e) {
            debugPrint('❌ Error sincronizando foto ${i + 1}: $e');
            fotosPathsUrls.add(fotoPath); // Mantener path local si falla
          }
        } else {
          fotosPathsUrls.add(fotoPath); // Ya es URL o está vacío
        }
      }
      if (fotosSubidas > 0) {
        debugPrint('📸 $fotosSubidas fotos sincronizadas exitosamente');
      }
    } else if (visita.fotosPaths != null) {
      fotosPathsUrls = visita.fotosPaths!;
    }

    // 5. Verificar y subir archivos adjuntos
    if (visita.archivosAdjuntos != null && visita.archivosAdjuntos!.isNotEmpty) {
      int archivosSubidos = 0;
      for (int i = 0; i < visita.archivosAdjuntos!.length; i++) {
        final archivoPath = visita.archivosAdjuntos![i];
        if (archivoPath.isNotEmpty && !archivoPath.startsWith('http')) {
          try {
            // Verificar que el archivo exista antes de intentar subirlo
            final file = File(archivoPath);
            if (await file.exists()) {
              debugPrint('📎 Subiendo archivo adjunto ${i + 1}: $archivoPath');
              final archivoUrl = await FileService.uploadFileByType(archivoPath, token);
              if (archivoUrl != null) {
                // Asegurar que archivoUrl es un string
                archivosAdjuntosUrls.add(archivoUrl.toString());
                archivosSubidos++;
                debugPrint('✅ Archivo adjunto ${i + 1} sincronizado exitosamente: $archivoUrl');
              } else {
                debugPrint('⚠️ No se pudo subir el archivo adjunto ${i + 1}');
                archivosAdjuntosUrls.add(archivoPath); // Mantener path local si falla
              }
            } else {
              debugPrint('⚠️ El archivo adjunto ${i + 1} no existe: $archivoPath');
              archivosAdjuntosUrls.add(archivoPath); // Mantener path local si no existe
            }
          } catch (e) {
            debugPrint('❌ Error sincronizando archivo adjunto ${i + 1}: $e');
            archivosAdjuntosUrls.add(archivoPath); // Mantener path local si falla
          }
        } else {
          archivosAdjuntosUrls.add(archivoPath); // Ya es URL o está vacío
        }
      }
      if (archivosSubidos > 0) {
        debugPrint('📎 $archivosSubidos archivos adjuntos sincronizados exitosamente');
      }
    } else if (visita.archivosAdjuntos != null) {
      archivosAdjuntosUrls = visita.archivosAdjuntos!;
    }

  } catch (e) {
    debugPrint('❌ Error general sincronizando archivos: $e');
  }

  // Crear visita actualizada con todas las URLs
  return visita.copyWith(
    riesgoFotograficoUrl: riesgoFotograficoUrl,
    firmaUrl: firmaUrl,
    firmaPath: firmaPathUrl ?? visita.firmaPath,
    fotosPaths: fotosPathsUrls.isNotEmpty ? fotosPathsUrls : visita.fotosPaths,
    archivosAdjuntos: archivosAdjuntosUrls.isNotEmpty ? archivosAdjuntosUrls : visita.archivosAdjuntos,
  );
}

 // services/sincronizacion_service.dart - MÉTODO CORREGIDO
static Future<Map<String, dynamic>> sincronizarVisitasPendientes(String token) async {
  final dbHelper = DatabaseHelper.instance;
  final visitasPendientes = await dbHelper.getVisitasNoSincronizadas();
  
  int exitosas = 0;
  int fallidas = 0;
  List<String> errores = [];
  
  debugPrint('📊 Sincronizando ${visitasPendientes.length} visitas pendientes...');
  
  // Verificar conectividad primero
  try {
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }
    
    for (final visita in visitasPendientes) {
      try {
        debugPrint('🔄 Sincronizando visita ${visita.id}...');

           
        // 1. ✅ PRIMERO: Actualizar coordenadas del paciente si existen
        if (visita.latitud != null && visita.longitud != null) {
          try {
            debugPrint('📍 Actualizando coordenadas del paciente ${visita.idpaciente}...');
            
            final coordenadasResult = await ApiService.updatePacienteCoordenadas(
              token,
              visita.idpaciente,
              visita.latitud!,
              visita.longitud!,
            );
            
            if (coordenadasResult != null && coordenadasResult['success'] == true) {
              debugPrint('✅ Coordenadas del paciente actualizadas exitosamente');
            } else {
              debugPrint('⚠️ No se pudieron actualizar las coordenadas del paciente');
            }
          } catch (coordError) {
            debugPrint('⚠️ Error actualizando coordenadas del paciente: $coordError');
            // No es crítico, continúa con la visita
          }
        }
        
        // 1. Obtener medicamentos asociados a esta visita
        final medicamentos = await dbHelper.getMedicamentosDeVisita(visita.id);
        debugPrint('💊 Encontrados ${medicamentos.length} medicamentos para visita ${visita.id}');
        
        // 2. Preparar medicamentos para envío
        List<Map<String, dynamic>> medicamentosData = [];
        for (var medicamentoConIndicaciones in medicamentos) {
          if (medicamentoConIndicaciones.isSelected) {
            medicamentosData.add({
              'id': medicamentoConIndicaciones.medicamento.id.toString(),
              'nombre': medicamentoConIndicaciones.medicamento.nombmedicamento.toString(),
              'indicaciones': (medicamentoConIndicaciones.indicaciones ?? '').toString(),
            });
          }
        }
        
        // 3. Preparar datos para enviar al servidor
        Map<String, String> visitaData = {
          'id': visita.id,
          'nombre_apellido': visita.nombreApellido,
          'identificacion': visita.identificacion,
          'fecha': visita.fecha.toIso8601String().split('T')[0],
          'idusuario': visita.idusuario,
          'idpaciente': visita.idpaciente,
          'hta': visita.hta ?? '',
          'dm': visita.dm ?? '',
          'telefono': visita.telefono ?? '',
          'zona': visita.zona ?? '',
          'peso': visita.peso?.toString() ?? '',
          'talla': visita.talla?.toString() ?? '',
          'imc': visita.imc?.toString() ?? '',
          'perimetro_abdominal': visita.perimetroAbdominal?.toString() ?? '',
          'frecuencia_cardiaca': visita.frecuenciaCardiaca?.toString() ?? '',
          'frecuencia_respiratoria': visita.frecuenciaRespiratoria?.toString() ?? '',
          'tension_arterial': visita.tensionArterial ?? '',
          'glucometria': visita.glucometria?.toString() ?? '',
          'temperatura': visita.temperatura?.toString() ?? '',
          'familiar': visita.familiar ?? '',
          'abandono_social': visita.abandonoSocial ?? '',
          'motivo': visita.motivo ?? '',
          'factores': visita.factores ?? '',
          'conductas': visita.conductas ?? '',
          'novedades': visita.novedades ?? '',
          'proximo_control': visita.proximoControl?.toIso8601String().split('T')[0] ?? '',
          
        };
        
        // 4. 🆕 USAR createVisitaCompleta PARA MANEJAR ARCHIVOS CORRECTAMENTE
        Map<String, dynamic>? resultado = await FileService.createVisitaCompleta(
          visitaData: visitaData,
          token: token,
          riskPhotoPath: visita.riesgoFotografico, // 🆕 Pasar ruta de foto
          signaturePath: visita.firmaPath ?? visita.firma, // 🆕 Pasar ruta de firma
          medicamentosData: medicamentosData,
        );
        
        if (resultado != null && resultado['success'] == true) {
          // 5. Marcar como sincronizada
          await dbHelper.marcarVisitaComoSincronizada(visita.id);
          exitosas++;
          debugPrint('✅ Visita ${visita.id} sincronizada exitosamente con archivos y medicamentos');
        } else {
          fallidas++;
          errores.add('Servidor respondió con error para visita ${visita.id}');
          debugPrint('❌ Falló sincronización de visita ${visita.id}');
        }
        
        // Pequeña pausa entre sincronizaciones para no saturar
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        fallidas++;
        errores.add('Error en visita ${visita.id}: $e');
        debugPrint('💥 Error sincronizando visita ${visita.id}: $e');
      }
    }
    
    if (exitosas > 0) {
      debugPrint('🎉 $exitosas visitas sincronizadas exitosamente');
    }
    if (fallidas > 0) {
      debugPrint('⚠️ $fallidas visitas fallaron en la sincronización');
    }
    
  } catch (e) {
    errores.add('Error general de conexión: $e');
    debugPrint('💥 Error general en sincronización: $e');
  }
  
  return {
    'exitosas': exitosas,
    'fallidas': fallidas,
    'errores': errores,
    'total': visitasPendientes.length
  };
}

  static Future<Map<String, int>> obtenerEstadoSincronizacion() async {
    final dbHelper = DatabaseHelper.instance;
    final todasLasVisitas = await dbHelper.getAllVisitas();
    
    int sincronizadas = 0;
    int pendientes = 0;
    
    for (final visita in todasLasVisitas) {
      if (visita.syncStatus == 1) {
        sincronizadas++;
      } else {
        pendientes++;
      }
    }
    
    return {
      'sincronizadas': sincronizadas, 
      'pendientes': pendientes,
      'total': todasLasVisitas.length
    };
  }

  // ✅ MÉTODO MEJORADO PARA SINCRONIZAR PACIENTES
static Future<Map<String, dynamic>> sincronizarPacientesPendientes(String token) async {
  final dbHelper = DatabaseHelper.instance;
  final pacientesPendientes = await dbHelper.getUnsyncedPacientes();

  int exitosas = 0;
  int fallidas = 0;
  List<String> errores = [];

  debugPrint('📊 Sincronizando ${pacientesPendientes.length} pacientes pendientes...');

  // ✅ VERIFICAR CONECTIVIDAD PRIMERO
  try {
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }

    for (final paciente in pacientesPendientes) {
      try {
        debugPrint('📡 Sincronizando geolocalización del paciente ${paciente.identificacion}...');
        debugPrint('📍 Coordenadas: ${paciente.latitud}, ${paciente.longitud}');
        
        // ✅ PREPARAR DATOS COMPLETOS DEL PACIENTE
        final pacienteData = {
          'id': paciente.id,
          'identificacion': paciente.identificacion,
          'nombre': paciente.nombre,
          'apellido': paciente.apellido,
          'fecnacimiento': paciente.fecnacimiento.toIso8601String().split('T')[0],
          'genero': paciente.genero,
          'idsede': paciente.idsede,
          'latitud': paciente.latitud?.toString() ?? '',
          'longitud': paciente.longitud?.toString() ?? '',
        };
        
        Map<String, dynamic>? serverData;
        
        // ✅ VERIFICAR SI ES PACIENTE OFFLINE O EXISTENTE
        if (paciente.id.startsWith('offline_')) {
          // Crear nuevo paciente en servidor
          serverData = await ApiService.createPaciente(token, pacienteData);
          
          if (serverData != null) {
            // Eliminar versión offline y crear versión del servidor
            await dbHelper.deletePaciente(paciente.id);
            final nuevoPaciente = Paciente.fromJson(serverData);
            await dbHelper.upsertPaciente(nuevoPaciente.copyWith(syncStatus: 1));
            exitosas++;
            debugPrint('✅ Paciente offline sincronizado: ${paciente.identificacion}');
          }
        } else {
          // Actualizar paciente existente
          serverData = await ApiService.actualizarPaciente(token, paciente.id, pacienteData);
          
          if (serverData != null) {
            await dbHelper.markPacientesAsSynced([paciente.id]);
            exitosas++;
            debugPrint('✅ Paciente actualizado: ${paciente.identificacion}');
          }
        }
        
        // 🆕 SINCRONIZAR COORDENADAS ESPECÍFICAMENTE
        if (serverData != null && paciente.latitud != null && paciente.longitud != null) {
          try {
            debugPrint('📍 Sincronizando coordenadas específicamente para paciente ${paciente.identificacion}');
            
            final coordenadasResult = await ApiService.updatePacienteCoordenadas(
              token,
              paciente.id.startsWith('offline_') ? serverData['id'].toString() : paciente.id,
              paciente.latitud!,
              paciente.longitud!,
            );
            
            if (coordenadasResult != null && coordenadasResult['success'] == true) {
              debugPrint('✅ Coordenadas sincronizadas exitosamente para ${paciente.identificacion}');
            } else {
              debugPrint('⚠️ No se pudieron sincronizar las coordenadas para ${paciente.identificacion}');
              // No marcamos como error crítico, solo advertencia
            }
          } catch (coordError) {
            debugPrint('⚠️ Error sincronizando coordenadas para ${paciente.identificacion}: $coordError');
            // No afecta el éxito general del paciente
          }
        }
        
        if (serverData == null) {
          fallidas++;
          errores.add('Servidor respondió con error para paciente ${paciente.identificacion}');
          debugPrint('❌ Falló sincronización de paciente ${paciente.identificacion}');
        }
        
        // Pausa entre sincronizaciones
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        fallidas++;
        errores.add('Error en paciente ${paciente.identificacion}: $e');
        debugPrint('💥 Error sincronizando paciente ${paciente.identificacion}: $e');
      }
    }
    
  } catch (e) {
    errores.add('Error general de conexión: $e');
    debugPrint('💥 Error general en sincronización de pacientes: $e');
  }

  if (exitosas > 0) {
    debugPrint('🎉 $exitosas pacientes sincronizados exitosamente');
  }
  if (fallidas > 0) {
    debugPrint('⚠️ $fallidas pacientes fallaron en la sincronización');
  }

  return {
    'exitosas': exitosas,
    'fallidas': fallidas,
    'errores': errores,
    'total': pacientesPendientes.length,
  };
}


  static Future<Map<String, dynamic>> sincronizarArchivosPendientes(String token) async {
  final dbHelper = DatabaseHelper.instance;
  final visitasPendientes = await dbHelper.getVisitasNoSincronizadas();
  
  int exitosas = 0;
  int fallidas = 0;
  List<String> errores = [];
  
  debugPrint('📁 Sincronizando archivos de ${visitasPendientes.length} visitas...');
  
  try {
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }
    
    for (final visita in visitasPendientes) {
      try {
        bool needsUpdate = false;
        debugPrint('📁 Iniciando subida de archivos para visita ${visita.id}');
        
        // Verificar si hay archivos locales que necesitan subirse
        final tieneArchivosLocales = _verificarArchivosLocalesPendientes(visita);
        
        if (tieneArchivosLocales) {
          // Subir archivos y obtener visita actualizada
          final visitaConUrls = await _subirArchivosDeVisita(visita, token);
          
          // Verificar si hubo cambios
          if (_compararUrls(visita, visitaConUrls)) {
            await dbHelper.updateVisita(visitaConUrls);
            needsUpdate = true;
            exitosas++;
            debugPrint('📁 Archivos sincronizados exitosamente para visita ${visita.id}');
          }
        }
        
        if (!needsUpdate) {
          debugPrint('ℹ️ No hay archivos pendientes para visita ${visita.id}');
        }
        
      } catch (e, stackTrace) {
        fallidas++;
        errores.add('Error en archivos de visita ${visita.id}: $e');
        debugPrint('💥 Error sincronizando archivos de visita ${visita.id}: $e');
        debugPrint('📚 Stack trace: $stackTrace');
      }
    }
    
    if (exitosas > 0) {
      debugPrint('🎉 Archivos de $exitosas visitas sincronizados exitosamente');
    }
    
  } catch (e) {
    errores.add('Error general de conexión: $e');
    debugPrint('💥 Error general en sincronización de archivos: $e');
  }
  
  return {
    'exitosas': exitosas,
    'fallidas': fallidas,
    'errores': errores,
    'total': visitasPendientes.length
  };
}


 static bool _verificarArchivosLocalesPendientes(Visita visita) {
  // Verificar foto de riesgo legacy
  if (visita.riesgoFotografico != null && 
      visita.riesgoFotografico!.isNotEmpty && 
      !visita.riesgoFotografico!.startsWith('http') &&
      visita.riesgoFotograficoUrl == null) {
    return true;
  }
  
  // Verificar firma legacy
  if (visita.firma != null && 
      visita.firma!.isNotEmpty && 
      !visita.firma!.startsWith('http') &&
      visita.firmaUrl == null) {
    return true;
  }
  
  // Verificar nueva firma - CORREGIDO
  if (visita.firmaPath != null && 
      visita.firmaPath!.isNotEmpty && 
      !visita.firmaPath!.startsWith('http')) {
    return true;
  }
  
  // Verificar fotos múltiples
  if (visita.fotosPaths != null && visita.fotosPaths!.isNotEmpty) {
    for (final fotoPath in visita.fotosPaths!) {
      if (fotoPath.isNotEmpty && !fotoPath.startsWith('http')) {
        return true;
      }
    }
  }
  
  // Verificar archivos adjuntos
  if (visita.archivosAdjuntos != null && visita.archivosAdjuntos!.isNotEmpty) {
    for (final archivoPath in visita.archivosAdjuntos!) {
      if (archivoPath.isNotEmpty && !archivoPath.startsWith('http')) {
        return true;
      }
    }
  }
  
  return false;
}

    // 🆕 MÉTODO AUXILIAR PARA COMPARAR URLs
  static bool _compararUrls(Visita visitaOriginal, Visita visitaActualizada) {
    return visitaOriginal.riesgoFotograficoUrl != visitaActualizada.riesgoFotograficoUrl ||
           visitaOriginal.firmaUrl != visitaActualizada.firmaUrl ||
           visitaOriginal.firmaPath != visitaActualizada.firmaPath ||
           _compararListas(visitaOriginal.fotosPaths, visitaActualizada.fotosPaths) ||
           _compararListas(visitaOriginal.archivosAdjuntos, visitaActualizada.archivosAdjuntos);
  }

  static bool _compararListas(List<String>? lista1, List<String>? lista2) {
    if (lista1 == null && lista2 == null) return false;
    if (lista1 == null || lista2 == null) return true;
    if (lista1.length != lista2.length) return true;
    
    for (int i = 0; i < lista1.length; i++) {
      if (lista1[i] != lista2[i]) return true;
    }
    
    return false;
  }

  // 🆕 MÉTODO MEJORADO PARA LIMPIAR ARCHIVOS LOCALES
  static Future<void> limpiarArchivosLocales({int diasAntiguos = 7}) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final visitasSincronizadas = await dbHelper.getAllVisitas();
      
      int archivosEliminados = 0;
      
      debugPrint('🧹 Iniciando limpieza de archivos locales...');
      
      for (final visita in visitasSincronizadas) {
        if (visita.syncStatus == 1) { // Solo visitas sincronizadas
          final fechaVisita = visita.fecha;
          final diasTranscurridos = DateTime.now().difference(fechaVisita).inDays;
          
          if (diasTranscurridos > diasAntiguos) {
            // Eliminar foto de riesgo local si existe URL
            if (visita.riesgoFotograficoUrl != null && 
                visita.riesgoFotografico != null &&
                !visita.riesgoFotografico!.startsWith('http')) {
              final eliminado = await FileService.deleteLocalFile(visita.riesgoFotografico!);
              if (eliminado) {
                archivosEliminados++;
                debugPrint('🗑️ Archivo local eliminado: ${visita.riesgoFotografico}');
              }
            }
            
            // Eliminar firma legacy local si existe URL
            if (visita.firmaUrl != null && 
                visita.firma != null &&
                !visita.firma!.startsWith('http')) {
              final eliminado = await FileService.deleteLocalFile(visita.firma!);
              if (eliminado) {
                archivosEliminados++;
                debugPrint('🗑️ Firma local eliminada: ${visita.firma}');
              }
            }
            
            // 🆕 Eliminar nueva firma local
            if (visita.firmaPath != null &&
                !visita.firmaPath!.startsWith('http')) {
              final eliminado = await FileService.deleteLocalFile(visita.firmaPath!);
              if (eliminado) {
                archivosEliminados++;
                debugPrint('🗑️ Nueva firma local eliminada: ${visita.firmaPath}');
              }
            }
            
            // 🆕 Eliminar fotos múltiples locales
            if (visita.fotosPaths != null && visita.fotosPaths!.isNotEmpty) {
              for (final fotoPath in visita.fotosPaths!) {
                if (fotoPath.isNotEmpty && !fotoPath.startsWith('http')) {
                  final eliminado = await FileService.deleteLocalFile(fotoPath);
                  if (eliminado) {
                    archivosEliminados++;
                    debugPrint('🗑️ Foto local eliminada: $fotoPath');
                  }
                }
              }
            }
            
            // 🆕 Eliminar archivos adjuntos locales
            if (visita.archivosAdjuntos != null && visita.archivosAdjuntos!.isNotEmpty) {
              for (final archivoPath in visita.archivosAdjuntos!) {
                if (archivoPath.isNotEmpty && !archivoPath.startsWith('http')) {
                  final eliminado = await FileService.deleteLocalFile(archivoPath);
                  if (eliminado) {
                    archivosEliminados++;
                    debugPrint('🗑️ Archivo adjunto local eliminado: $archivoPath');
                  }
                }
              }
            }
          }
        }
      }
      
      // Limpiar archivos huérfanos
      await FileService.cleanOldFiles(daysOld: diasAntiguos);
      
      debugPrint('🧹 Limpieza completada exitosamente: $archivosEliminados archivos eliminados');
    } catch (e) {
      debugPrint('❌ Error en limpieza de archivos: $e');
    }
  }

  // 🆕 MÉTODO MEJORADO PARA ESTADÍSTICAS DE ARCHIVOS
  static Future<Map<String, dynamic>> obtenerEstadisticasArchivos() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final estadisticas = await dbHelper.obtenerEstadisticasArchivos();
      debugPrint('📊 Estadísticas de archivos obtenidas exitosamente');
      return estadisticas;
    } catch (e) {
      debugPrint('❌ Error al obtener estadísticas de archivos: $e');
      return {
        'error': true,
        'mensaje': 'Error al obtener estadísticas: ${e.toString()}',
        'fotos': {
          'locales': 0,
          'servidor': 0,
          'total': 0,
          'porcentaje_locales': 0,
          'porcentaje_servidor': 0,
        },
        'firmas': {
          'locales': 0,
          'servidor': 0,
          'total': 0,
          'porcentaje_locales': 0,
          'porcentaje_servidor': 0,
        },
        'archivos_adjuntos': {
          'total': 0,
        },
        'resumen': {
          'total_archivos': 0,
          'total_visitas': 0,
          'archivos_por_visita': '0',
        }
      };
    }
  }
  

  // 🆕 MÉTODO PARA VERIFICAR ESTADO GENERAL
  static Future<Map<String, dynamic>> obtenerEstadoGeneral() async {
    try {
      debugPrint('📊 Obteniendo estado general de sincronización...');
      
      final estadoSincronizacion = await obtenerEstadoSincronizacion();
      final estadisticasArchivos = await obtenerEstadisticasArchivos();
      
      final pendientes = estadoSincronizacion['pendientes'] ?? 0;
      final sincronizadas = estadoSincronizacion['sincronizadas'] ?? 0;
      final total = estadoSincronizacion['total'] ?? 0;
      
      debugPrint('📈 Estado: $sincronizadas sincronizadas, $pendientes pendientes de $total total');
      
      return {
        'sincronizacion': estadoSincronizacion,
        'archivos': estadisticasArchivos,
        'timestamp': DateTime.now().toIso8601String(),
        'estado_resumen': {
          'hay_pendientes': pendientes > 0,
          'porcentaje_sincronizado': total > 0 ? ((sincronizadas / total) * 100).round() : 100,
        }
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estado general: $e');
      return {
        'error': true,
        'mensaje': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  

  // 🆕 MÉTODO PARA OBTENER RESUMEN DE SINCRONIZACIÓN
  static Future<String> obtenerResumenSincronizacion() async {
    try {
      final estado = await obtenerEstadoSincronizacion();
      final sincronizadas = estado['sincronizadas'] ?? 0;
      final pendientes = estado['pendientes'] ?? 0;
      final total = estado['total'] ?? 0;
      
      if (total == 0) {
        return "No hay visitas registradas";
      }
      
      if (pendientes == 0) {
        return "✅ Todas las visitas están sincronizadas ($sincronizadas/$total)";
      } else {
        return "⚠️ $pendientes de $total visitas pendientes de sincronización";
      }
    } catch (e) {
      return "❌ Error al obtener estado de sincronización";
    }
  }

  // 🆕 MÉTODO PARA VERIFICAR SI HAY PENDIENTES
  static Future<bool> hayElementosPendientes() async {
    try {
      final estado = await obtenerEstadoSincronizacion();
      final pendientes = estado['pendientes'] ?? 0;
      return pendientes > 0;
    } catch (e) {
      debugPrint('❌ Error verificando elementos pendientes: $e');
      return false;
    }
  }

  // 🆕 MÉTODO PARA CANCELAR SINCRONIZACIÓN AUTOMÁTICA
  void cancelarSincronizacionAutomatica() {
    debugPrint('🛑 Cancelando sincronización automática...');
    _cleanupAfterSync();
    debugPrint('✅ Sincronización automática cancelada');
  }

  // 🆕 MÉTODO PARA VERIFICAR ESTADO DE SINCRONIZACIÓN AUTOMÁTICA
  bool get isSyncInProgress => _isSyncInProgress;
  bool get isListeningForConnectivity => _isListening;

  // 🆕 MÉTODO PARA OBTENER INFORMACIÓN DE DEBUG
  Future<Map<String, dynamic>> obtenerInfoDebug() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'sync_in_progress': _isSyncInProgress,
        'listening_connectivity': _isListening,
        'pending_tasks': prefs.getBool('pendingSyncTasks') ?? false,
        'last_sync_request': prefs.getString('lastSyncRequest'),
        'last_successful_sync': prefs.getString('lastSuccessfulSync'),
        'last_manual_sync': prefs.getString('lastManualSync'),
        'has_connectivity_subscription': _connectivitySubscription != null,
        'has_retry_timer': _retryTimer != null,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo info de debug: $e');
      return {'error': e.toString()};
    }
  }
}

  class SharedPreferences {
    static SharedPreferences? _instance;
    final Map<String, dynamic> _prefs = {};

    SharedPreferences._();

    static Future<SharedPreferences> getInstance() async {
      _instance ??= SharedPreferences._();
      return _instance!;
    }
  // Métodos para String
    Future<bool> setString(String key, String value) async {
      _prefs[key] = value;
      return true;
    }

    String? getString(String key) {
      return _prefs[key] as String?;
    }

    // Métodos para bool
    Future<bool> setBool(String key, bool value) async {
      _prefs[key] = value;
      return true;
    }

    bool? getBool(String key) {
      return _prefs[key] as bool?;
    }

    // Métodos para int
    Future<bool> setInt(String key, int value) async {
      _prefs[key] = value;
      return true;
    }

    int? getInt(String key) {
      return _prefs[key] as int?;
    }

    // Métodos para double
    Future<bool> setDouble(String key, double value) async {
      _prefs[key] = value;
      return true;
    }

    double? getDouble(String key) {
      return _prefs[key] as double?;
    }

    // Métodos para List<String>
    Future<bool> setStringList(String key, List<String> value) async {
      _prefs[key] = value;
      return true;
    }

    List<String>? getStringList(String key) {
      return _prefs[key] as List<String>?;
    }

    // Método para remover
    Future<bool> remove(String key) async {
      _prefs.remove(key);
      return true;
    }

    // Método para limpiar todo
    Future<bool> clear() async {
      _prefs.clear();
      return true;
    }

    // Verificar si existe una key
    bool containsKey(String key) {
      return _prefs.containsKey(key);
    }

    // Obtener todas las keys
    Set<String> getKeys() {
      return _prefs.keys.toSet();
  }
}
