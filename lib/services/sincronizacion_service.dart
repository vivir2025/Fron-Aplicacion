import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:Bornive/api/api_service.dart';
import 'package:Bornive/database/database_helper.dart';
import 'package:Bornive/models/paciente_model.dart';
import 'package:Bornive/models/visita_model.dart';
import 'package:Bornive/services/afinamiento_service.dart';
import 'package:Bornive/services/brigada_service.dart';
import 'package:Bornive/services/encuesta_service.dart';
import 'package:Bornive/services/envio_muestra_service.dart';
import 'package:Bornive/services/findrisk_service.dart';
import 'package:Bornive/services/medicamento_service.dart';
import 'package:Bornive/services/tamizaje_service.dart';
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
      final success = await MedicamentoService.loadMedicamentosFromServer(token);
      
      if (success) {
        final dbHelper = DatabaseHelper.instance;
        final count = await dbHelper.countMedicamentos();
        
        return {
          'exitosas': count,
          'fallidas': 0,
          'errores': [],
          'total': count,
        };
      } else {
        return {
          'exitosas': 0,
          'fallidas': 1,
          'errores': ['No se pudieron cargar medicamentos desde el servidor'],
          'total': 1,
        };
      }
    } catch (e) {
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
    final resultado = await BrigadaService.sincronizarBrigadasPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
    }
    
    if (fallidas > 0) {
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
      }
    }
    
    return resultado;
  } catch (e) {
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
    final resultado = await EncuestaService.sincronizarEncuestasPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
    }
    
    if (fallidas > 0) {
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
      }
    }
    
    return resultado;
  } catch (e) {
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
    // ✅ VALIDAR QUE EL TOKEN NO ESTÉ VACÍO
    if (token.isEmpty) {
      throw Exception('Token de autenticación requerido para sincronización FINDRISK');
    }
    
    // ✅ PASAR EL TOKEN AL FINDRISK SERVICE
    final resultado = await FindriskService.sincronizarTestsPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
    }
    
    if (fallidas > 0) {
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
      }
    }
    
    return resultado;
  } catch (e) {
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
    final resultado = await AfinamientoService.sincronizarAfinamientosPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
    }
    
    if (fallidas > 0) {
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
      }
    }
    
    return resultado;
  } catch (e) {
    return {
      'exitosas': 0,
      'fallidas': 1,
      'errores': ['Error general: $e'],
      'total': 1,
    };
  }
}
static Future<Map<String, dynamic>> sincronizarTamizajesPendientes(String token) async {
  try {
    final resultado = await TamizajeService.sincronizarTamizajesPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    
    if (exitosas > 0) {
    }
    
    if (fallidas > 0) {
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) {
      }
    }
    
    return resultado;
  } catch (e) {
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
  final Map<String, dynamic> resultado = {
    'medicamentos': {'exitosas': 0, 'fallidas': 0, 'errores': []}, 
    'visitas': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'pacientes': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'envios_muestras': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'brigadas': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'encuestas': {'exitosas': 0, 'fallidas': 0, 'errores': []}, 
    'findrisk_tests': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'afinamientos': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'tamizajes': {'exitosas': 0, 'fallidas': 0, 'errores': []}, 
    'archivos': {'exitosas': 0, 'fallidas': 0, 'errores': []},
    'tiempo_total': 0,
    'exito_general': false,
  };
  
  final stopwatch = Stopwatch()..start();
  
  try {
    // 🆕 1. Sincronizar medicamentos primero
    resultado['medicamentos'] = await sincronizarMedicamentos(token);
    
    final medicamentosExitosos = resultado['medicamentos']['exitosas'] ?? 0;
    if (medicamentosExitosos > 0) {
    }
    
    // 2. Sincronizar visitas pendientes
    resultado['visitas'] = await sincronizarVisitasPendientes(token);
    
    final visitasExitosas = resultado['visitas']['exitosas'] ?? 0;
    if (visitasExitosas > 0) {
    }
    
    // 3. Sincronizar pacientes pendientes
    resultado['pacientes'] = await sincronizarPacientesPendientes(token);
    
    final pacientesExitosos = resultado['pacientes']['exitosas'] ?? 0;
    if (pacientesExitosos > 0) {
    }
    
    // 4. 🆕 Sincronizar envíos de muestras pendientes
    resultado['envios_muestras'] = await sincronizarEnviosMuestrasPendientes(token);

    // 5. 🆕 Sincronizar brigadas pendientes
    resultado['brigadas'] = await sincronizarBrigadasPendientes(token);

    // 6. 🆕 Sincronizar encuestas pendientes
    resultado['encuestas'] = await sincronizarEncuestasPendientes(token);

    // 7. 🆕 Sincronizar tests FINDRISK pendientes
    resultado['findrisk_tests'] = await sincronizarFindriskTestsPendientes(token);

     resultado['afinamientos'] = await sincronizarAfinamientosPendientes(token);

    resultado['tamizajes'] = await sincronizarTamizajesPendientes(token);

    // 8. Sincronizar archivos pendientes
    resultado['archivos'] = await sincronizarArchivosPendientes(token);
    
    final archivosExitosos = resultado['archivos']['exitosas'] ?? 0;
    if (archivosExitosos > 0) {
    }
    
    // 9. Limpiar archivos antiguos
    await limpiarArchivosLocales();
    
    stopwatch.stop();
    resultado['tiempo_total'] = stopwatch.elapsedMilliseconds;
    
    // Determinar éxito general
    final enviosExitosos = resultado['envios_muestras']['exitosas'] ?? 0; // 🆕
    final brigadasExitosas = resultado['brigadas']['exitosas'] ?? 0; // 🆕
    final encuestasExitosas = resultado['encuestas']['exitosas'] ?? 0;
    final findriskExitosos = resultado['findrisk_tests']['exitosas'] ?? 0; 
    final afinamientosExitosos = resultado['afinamientos']['exitosas'] ?? 0;// 🆕 FINDRISK
     final tamizajesExitosos = resultado['tamizajes']['exitosas'] ?? 0;
    final totalExitosas = medicamentosExitosos + visitasExitosas + pacientesExitosos + 
    archivosExitosos + brigadasExitosas + enviosExitosos + encuestasExitosas + findriskExitosos
    + afinamientosExitosos + tamizajesExitosos; 
    
    resultado['exito_general'] = totalExitosas > 0;
    
    if (resultado['exito_general']) {
    } else {
    }
    
  } catch (e) {
    stopwatch.stop();
    resultado['tiempo_total'] = stopwatch.elapsedMilliseconds;
    resultado['error_general'] = e.toString();
  }
  
  return resultado;
}
// services/sincronizacion_service.dart - MÉTODO CORREGIDO
// services/sincronizacion_service.dart - MÉTODO CORREGIDO
static Future<Map<String, dynamic>> sincronizarSoloPacientes(String token) async {
  final Map<String, dynamic> resultado = {
    'pacientes': {'exitosas': 0, 'fallidas': 0, 'errores': <String>[]}, // ✅ CORREGIDO: Tipo explícito
    'tiempo_total': 0,
    'exito_general': false,
  };
  
  final stopwatch = Stopwatch()..start();
  
  try {
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet disponible');
    }
    
    // ✅ SINCRONIZAR PACIENTES OFFLINE PENDIENTES
    final pacientesOfflineResult = await sincronizarPacientesOfflinePendientes(token);
    
    // ✅ CARGAR PACIENTES FALTANTES DESDE SERVIDOR
    final pacientesFaltantesResult = await cargarPacientesFaltantesDesdeServidor(token);
    
    // ✅ CONSOLIDAR RESULTADOS CON TIPOS CORRECTOS
    final pacientesSubidos = pacientesOfflineResult['exitosas'] ?? 0;
    final pacientesCargados = pacientesFaltantesResult['cargados'] ?? 0;
    
    // ✅ MANEJO SEGURO DE ERRORES
    List<String> erroresSubida = [];
    List<String> erroresCarga = [];
    
    if (pacientesOfflineResult['errores'] != null) {
      erroresSubida = (pacientesOfflineResult['errores'] as List)
          .map((e) => e.toString())
          .toList();
    }
    
    if (pacientesFaltantesResult['errores'] != null) {
      erroresCarga = (pacientesFaltantesResult['errores'] as List)
          .map((e) => e.toString())
          .toList();
    }
    
    resultado['pacientes'] = {
      'exitosas': pacientesSubidos + pacientesCargados,
      'fallidas': (pacientesOfflineResult['fallidas'] ?? 0),
      'errores': [...erroresSubida, ...erroresCarga],
      'subidos': pacientesSubidos,
      'descargados': pacientesCargados,
    };
    
    stopwatch.stop();
    resultado['tiempo_total'] = stopwatch.elapsedMilliseconds;
    resultado['exito_general'] = (pacientesSubidos + pacientesCargados) > 0;
    
    if (pacientesSubidos > 0) {
    }
    
    if (pacientesCargados > 0) {
    }
    
    if (resultado['exito_general']) {
    } else {
    }
    
  } catch (e) {
    stopwatch.stop();
    resultado['tiempo_total'] = stopwatch.elapsedMilliseconds;
    resultado['error_general'] = e.toString();
    
    // ✅ MANEJO SEGURO DE ERRORES.
    if (resultado['pacientes']['errores'] is List) {
      (resultado['pacientes']['errores'] as List<String>).add('Error general: $e');
    }
    
  }
  
  return resultado;
}
// services/sincronizacion_service.dart - MÉTODO MEJORADO PARA MANEJAR DUPLICADOS
static Future<Map<String, dynamic>> sincronizarPacientesOfflinePendientes(String token) async {
  final dbHelper = DatabaseHelper.instance;
  
  final pacientesLocales = await dbHelper.readAllPacientes();
  final pacientesOffline = pacientesLocales.where((p) => 
    p.id.startsWith('offline_') || p.syncStatus == 0
  ).toList();

  int exitosas = 0;
  int fallidas = 0;
  List<String> errores = [];

  for (final paciente in pacientesOffline) {
    try {
      final pacienteData = {
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
      bool pacienteProcessed = false;
      
      if (paciente.id.startsWith('offline_')) {
        try {
          // ✅ INTENTAR CREAR NUEVO PACIENTE
          serverData = await ApiService.createPaciente(token, pacienteData);
          
          if (serverData != null) {
            await dbHelper.deletePaciente(paciente.id);
            final nuevoPaciente = Paciente.fromJson({
              ...serverData,
              'sync_status': 1,
            });
            await dbHelper.upsertPaciente(nuevoPaciente);
            
            // ✅ MARCAR COMO SINCRONIZADO
            await dbHelper.markPacientesAsSynced([nuevoPaciente.id]);
            
            // 🚀 ESTO ES VITAL: CASCADA DEL NUEVO ID A VISITAS, ENCUESTAS, ETC.
            await dbHelper.actualizarIdPacienteEnCascada(paciente.id, nuevoPaciente.id);
            
            exitosas++;
            pacienteProcessed = true;
          }
        } catch (e) {
          if (e.toString().contains('422') && e.toString().contains('already been taken')) {
            // ✅ PACIENTE YA EXISTE - BUSCAR EN SERVIDOR Y SINCRONIZAR
            try {
              // Obtener pacientes del servidor para encontrar el ID correcto
              final pacientesServidor = await ApiService.getPacientes(token);
              final pacienteExistente = pacientesServidor.firstWhere(
                (p) => p['identificacion'].toString() == paciente.identificacion,
                orElse: () => null,
              );
              
              if (pacienteExistente != null) {
                // Eliminar versión offline y crear versión del servidor
                await dbHelper.deletePaciente(paciente.id);
                final pacienteSincronizado = Paciente.fromJson({
                  ...pacienteExistente,
                  'sync_status': 1,
                });
                await dbHelper.upsertPaciente(pacienteSincronizado);
                
                // ✅ MARCAR COMO SINCRONIZADO
                await dbHelper.markPacientesAsSynced([pacienteSincronizado.id]);
                
                // 🚀 CASCADA DEL NUEVO ID, INCLUSO SI ERA DUPLICADO
                await dbHelper.actualizarIdPacienteEnCascada(paciente.id, pacienteSincronizado.id);
                
                exitosas++;
                pacienteProcessed = true;
              }
            } catch (syncError) {
              errores.add('Error sincronizando duplicado ${paciente.identificacion}: $syncError');
              fallidas++;
            }
          } else {
            // Otro tipo de error
            throw e;
          }
        }
      } else {
        // ✅ ACTUALIZAR PACIENTE EXISTENTE
        serverData = await ApiService.actualizarPaciente(token, paciente.id, pacienteData);
        
        if (serverData != null) {
          await dbHelper.markPacientesAsSynced([paciente.id]);
          exitosas++;
          pacienteProcessed = true;
        }
      }
      
      // ✅ SINCRONIZAR COORDENADAS SI EL PACIENTE FUE PROCESADO
      if (pacienteProcessed && paciente.latitud != null && paciente.longitud != null) {
        try {
          String pacienteId;
          if (paciente.id.startsWith('offline_') && serverData != null) {
            pacienteId = serverData['id'].toString();
          } else {
            pacienteId = paciente.id;
          }
          
          final coordenadasResult = await ApiService.updatePacienteCoordenadas(
            token,
            pacienteId,
            paciente.latitud!,
            paciente.longitud!,
          );
          
          if (coordenadasResult != null) {
          }
        } catch (coordError) {
        }
      }
      
      if (!pacienteProcessed) {
        fallidas++;
        errores.add('No se pudo procesar paciente ${paciente.identificacion}');
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      
    } catch (e) {
      fallidas++;
      errores.add('Error en ${paciente.identificacion}: $e');
    }
  }

  // ✅ LIMPIAR DUPLICADOS AL FINAL SI HUBO SINCRONIZACIONES EXITOSAS
  if (exitosas > 0) {
    try {
      await dbHelper.limpiarPacientesDuplicadosDespuesSincronizacion();
    } catch (e) {
    }
  }

  if (exitosas > 0) {
  }
  if (fallidas > 0) {
  }

  return {
    'exitosas': exitosas,
    'fallidas': fallidas,
    'errores': errores,
    'total': pacientesOffline.length, // ✅ CORREGIDO: era pacientesPendientes.length
  };
}

// 🆕 MÉTODO PARA ACTUALIZAR VISITAS EXISTENTES
static Future<Map<String, dynamic>> actualizarVisitaExistente(
  Visita visita, 
  String token,
  List<Map<String, dynamic>> medicamentosData
) async {
  try {
    // ✅ PREPARAR DATOS IGUAL QUE EN CREATE
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
      'latitud': visita.latitud?.toString() ?? '',
      'longitud': visita.longitud?.toString() ?? '',
    };
    
    // ✅ USAR updateVisitaCompleta CORREGIDO
    final resultado = await FileService.updateVisitaCompleta(
      visitaId: visita.id,
      visitaData: visitaData,
      token: token,
      riskPhotoPath: visita.riesgoFotografico,
      signaturePath: visita.firmaPath ?? visita.firma,
      medicamentosData: medicamentosData,
    );
    
    return resultado ?? {'success': false, 'error': 'No response from server'};
    
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

// services/sincronizacion_service.dart - MÉTODO MEJORADO
static Future<Map<String, dynamic>> cargarPacientesFaltantesDesdeServidor(String token) async {
  try {
    final dbHelper = DatabaseHelper.instance;
    
    // ✅ 1. OBTENER IDENTIFICACIONES DE PACIENTES LOCALES
    final pacientesLocales = await dbHelper.readAllPacientes();
    final identificacionesLocales = pacientesLocales.map((p) => p.identificacion).toSet();
    
    // ✅ 2. OBTENER PACIENTES DEL SERVIDOR
    List<Map<String, dynamic>> pacientesServidor = [];
    
    try {
      final pacientesResponse = await ApiService.getPacientes(token);
      
      pacientesServidor = pacientesResponse.map((paciente) {
        if (paciente is Map<String, dynamic>) {
          return paciente;
        } else {
          return Map<String, dynamic>.from(paciente as Map);
        }
      }).toList();
      
    } catch (e) {
      return {
        'cargados': 0, 
        'errores': ['Error de conexión con servidor: $e']
      };
    }
    
    if (pacientesServidor.isEmpty) {
      return {
        'cargados': 0, 
        'errores': [],
        'mensaje': 'No hay pacientes en el servidor'
      };
    }
    
    // ✅ 3. FILTRAR PACIENTES FALTANTES
    final pacientesFaltantes = pacientesServidor.where((pacienteData) {
      final identificacion = pacienteData['identificacion']?.toString() ?? '';
      return identificacion.isNotEmpty && !identificacionesLocales.contains(identificacion);
    }).toList();
    
    if (pacientesFaltantes.isEmpty) {
      return {
        'cargados': 0,
        'errores': [],
        'total_servidor': pacientesServidor.length,
        'total_locales': identificacionesLocales.length,
        'mensaje': 'Todos los pacientes del servidor ya están localmente'
      };
    }
    
    // ✅ 4. GUARDAR PACIENTES FALTANTES LOCALMENTE
    int cargados = 0;
    List<String> errores = [];
    
    for (final pacienteData in pacientesFaltantes) {
      try {
        // ✅ CREAR PACIENTE CON DATOS COMPLETOS
        final paciente = Paciente.fromJson({
          'id': pacienteData['id']?.toString() ?? '',
          'identificacion': pacienteData['identificacion']?.toString() ?? '',
          'nombre': pacienteData['nombre']?.toString() ?? '',
          'apellido': pacienteData['apellido']?.toString() ?? '',
          'fecnacimiento': pacienteData['fecnacimiento']?.toString() ?? DateTime.now().toIso8601String(),
          'genero': pacienteData['genero']?.toString() ?? 'M',
          'idsede': pacienteData['idsede']?.toString() ?? '',
          'latitud': pacienteData['latitud'],
          'longitud': pacienteData['longitud'],
          'sync_status': 1, // ✅ Marcar como sincronizado desde servidor
        });
        
        await dbHelper.upsertPaciente(paciente);
        cargados++;
        
        if (cargados <= 5) {
        }
        
      } catch (e) {
        errores.add('Error cargando paciente ${pacienteData['identificacion']}: $e');
      }
    }
    
    if (cargados > 5) {
    }
    
    return {
      'cargados': cargados,
      'errores': errores,
      'total_servidor': pacientesServidor.length,
      'total_locales': identificacionesLocales.length,
      'faltantes_encontrados': pacientesFaltantes.length,
    };
    
  } catch (e) {
    return {
      'cargados': 0,
      'errores': ['Error general: $e'],
    };
  }
}




 // ✅ MÉTODO CORREGIDO PARA connectivity_plus ^6.1.4
Future<void> scheduleSync() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pendingSyncTasks', true);
    await prefs.setString('lastSyncRequest', DateTime.now().toIso8601String());
  } catch (e) {
  }

  if (_isListening) {
    return;
  }

  try {
    _isListening = true;
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        
        if (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
          // ✅ SOLO VERIFICAR CONEXIÓN, NO SINCRONIZAR AUTOMÁTICAMENTE
          try {
            final hasRealConnection = await _checkRealConnection();
            if (hasRealConnection) {
              await _startSyncProcess();
            } else {
            }
          } catch (e) {
          }
        } else {
        }
      },
      onError: (error) {
      },
    ) as StreamSubscription<ConnectivityResult>?;
    
    // ✅ VERIFICAR CONEXIÓN INICIAL SIN SINCRONIZAR
    try {
      final List<ConnectivityResult> currentConnectivity = await Connectivity().checkConnectivity();
      final ConnectivityResult firstResult = currentConnectivity.isNotEmpty 
          ? currentConnectivity.first 
          : ConnectivityResult.none;
      
      if (firstResult == ConnectivityResult.wifi || firstResult == ConnectivityResult.mobile) {
        final hasRealConnection = await _checkRealConnection();
        if (hasRealConnection) {
          await _startSyncProcess();
        }
      } else {
      }
    } catch (connectivityError) {
    }
    
  } catch (e) {
    _isListening = false;
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
    // ✅ USAR EL SERVICIO ESPECÍFICO
    final resultado = await EnvioMuestraService.sincronizarEnviosPendientes(token);
    
    final exitosas = resultado['exitosas'] ?? 0;
    final fallidas = resultado['fallidas'] ?? 0;
    final total = resultado['total'] ?? 0;
    
    if (exitosas > 0) {
    }
    
    if (fallidas > 0) {
      final errores = resultado['errores'] as List<String>? ?? [];
      for (final error in errores.take(3)) { // Mostrar solo los primeros 3 errores
      }
    }
    
    return resultado;
  } catch (e) {
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
      return;
    }

    _isSyncInProgress = true;
    
    try {
      // Verificar si realmente hay tareas pendientes
      final prefs = await SharedPreferences.getInstance();
      final hasPendingTasks = prefs.getBool('pendingSyncTasks') ?? false;
      
      if (!hasPendingTasks) {
        _cleanupAfterSync();
        return;
      }
      
      // Obtener token para la sincronización
      final token = await _getAuthToken();
      
      if (token == null) {
        // Programar reintento después
        _scheduleRetry();
        return;
      }
      
      // Ejecutar sincronización completa
      final resultado = await sincronizacionCompleta(token);
      
if (resultado['exito_general'] == true) {
  // Mostrar resumen de lo sincronizado
  final visitasSync = resultado['visitas']['exitosas'] ?? 0;
  final pacientesSync = resultado['pacientes']['exitosas'] ?? 0;
  final archivosSync = resultado['archivos']['exitosas'] ?? 0;
  final medicamentosSync = resultado['medicamentos']['exitosas'] ?? 0; // 🆕 Nueva línea
  
  if (medicamentosSync > 0) { // 🆕 Nuevo bloque
  }
  if (visitasSync > 0) {
  }
  if (pacientesSync > 0) {
  }
  if (archivosSync > 0) {
  }
  
  // Limpiar estado de sincronización pendiente
  await prefs.setBool('pendingSyncTasks', false);
  await prefs.setString('lastSuccessfulSync', DateTime.now().toIso8601String());
  
  // Verificar si aún hay pendientes
  final estadoActual = await obtenerEstadoSincronizacion();
  final pendientesRestantes = estadoActual['pendientes'] ?? 0;
  
  if (pendientesRestantes > 0) {
    await prefs.setBool('pendingSyncTasks', true);
  } else {
    // Todo sincronizado, limpiar listeners
    _cleanupAfterSync();
  }
} else {
  _scheduleRetry();
}
      
    } catch (e) {
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
      return null;
    }
  }

  // Programar reintento
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 15), () {
      _startSyncProcess();
    });
  }

  // Limpiar recursos después de sincronización
  void _cleanupAfterSync() {
    if (_connectivitySubscription != null) {
      _connectivitySubscription!.cancel();
      _connectivitySubscription = null;
    }
    _retryTimer?.cancel();
    _isListening = false;
  }

  // Método para forzar una sincronización manual
  Future<Map<String, dynamic>> syncNow(String token) async {
    _isSyncInProgress = true;
    try {
      final resultado = await sincronizacionCompleta(token);
      
      // Mostrar resumen de la sincronización manual
      final visitasSync = resultado['visitas']['exitosas'] ?? 0;
      final pacientesSync = resultado['pacientes']['exitosas'] ?? 0;
      final archivosSync = resultado['archivos']['exitosas'] ?? 0;
      
      if (resultado['exito_general'] == true) {
        if (visitasSync > 0) {
        }
        if (pacientesSync > 0) {
        }
        if (archivosSync > 0) {
        }
        
        if (visitasSync == 0 && pacientesSync == 0 && archivosSync == 0) {
        }
      } else {
      }
      
      // Actualizar estado en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final estadoActual = await obtenerEstadoSincronizacion();
      final pendientesRestantes = estadoActual['pendientes'] ?? 0;
      
      if (pendientesRestantes > 0) {
        await prefs.setBool('pendingSyncTasks', true);
      } else {
        await prefs.setBool('pendingSyncTasks', false);
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
      return false;
    }
    
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
            // Sincronizar pacientes pendientes
            await sincronizarPacientesPendientes(token);
            
            return true;
          }
        } else {
        }
      } catch (e) {
        // La visita ya está guardada localmente, no es un error crítico
      }
    } else {
    }
    
    return true; // Éxito si al menos se guardó localmente
  } catch (e) {
    return false;
  }
}


 static Future<Visita> _subirArchivosDeVisita(Visita visita, String token) async {
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
        try {
          riesgoFotograficoUrl = await FileService.uploadRiskPhoto(
            visita.riesgoFotografico!,
            token
          );
          if (riesgoFotograficoUrl != null) {
          } else {
          }
        } catch (e) {
        }
      } else {
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
        try {
          firmaUrl = await FileService.uploadSignature(
            visita.firma!,
            token
          );
          if (firmaUrl != null) {
          } else {
          }
        } catch (e) {
        }
      } else {
      }
    }

    // 3. Verificar y subir nueva firma (firmaPath)
    if (visita.firmaPath != null && 
        visita.firmaPath!.isNotEmpty &&
        !visita.firmaPath!.startsWith('http')) {
      
      // Verificar que el archivo exista antes de intentar subirlo
      final file = File(visita.firmaPath!);
      if (await file.exists()) {
        try {
          firmaPathUrl = await FileService.uploadSignature(
            visita.firmaPath!,
            token
          );
          if (firmaPathUrl != null) {
          } else {
          }
        } catch (e) {
        }
      } else {
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
              final fotoUrl = await FileService.uploadPhoto(fotoPath, token);
              if (fotoUrl != null) {
                fotosPathsUrls.add(fotoUrl);
                fotosSubidas++;
              } else {
                fotosPathsUrls.add(fotoPath); // Mantener path local si falla
              }
            } else {
              fotosPathsUrls.add(fotoPath); // Mantener path local si no existe
            }
          } catch (e) {
            fotosPathsUrls.add(fotoPath); // Mantener path local si falla
          }
        } else {
          fotosPathsUrls.add(fotoPath); // Ya es URL o está vacío
        }
      }
      if (fotosSubidas > 0) {
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
              final archivoUrl = await FileService.uploadFileByType(archivoPath, token);
              if (archivoUrl != null) {
                // Asegurar que archivoUrl es un string
                archivosAdjuntosUrls.add(archivoUrl.toString());
                archivosSubidos++;
              } else {
                archivosAdjuntosUrls.add(archivoPath); // Mantener path local si falla
              }
            } else {
              archivosAdjuntosUrls.add(archivoPath); // Mantener path local si no existe
            }
          } catch (e) {
            archivosAdjuntosUrls.add(archivoPath); // Mantener path local si falla
          }
        } else {
          archivosAdjuntosUrls.add(archivoPath); // Ya es URL o está vacío
        }
      }
      if (archivosSubidos > 0) {
      }
    } else if (visita.archivosAdjuntos != null) {
      archivosAdjuntosUrls = visita.archivosAdjuntos!;
    }

  } catch (e) {
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

// services/sincronizacion_service.dart - MÉTODO COMPLETAMENTE CORREGIDO
static Future<Map<String, dynamic>> sincronizarVisitasPendientes(String token) async {
  final dbHelper = DatabaseHelper.instance;
  final visitasPendientes = await dbHelper.getVisitasNoSincronizadas();
  
  int exitosas = 0;
  int fallidas = 0;
  List<String> errores = [];
  
  // ✅ Expresión regular para validar formato UUID v4
  final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
  
  // Verificar conectividad primero
  try {
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }
    
    for (final visita in visitasPendientes) {
      try {
        // ✅ VALIDAR FORMATO UUID ANTES DE SINCRONIZAR
        if (!uuidPattern.hasMatch(visita.id)) {
          errores.add('Visita ${visita.id} tiene formato UUID inválido');
          fallidas++;
          continue; // Saltar esta visita
        }
        
        // ✅ DEBUG: Mostrar coordenadas de la visita
        // 1. ✅ PRIMERO: Actualizar coordenadas del paciente si existen
        if (visita.latitud != null && visita.longitud != null) {
          try {
            final coordenadasResult = await ApiService.updatePacienteCoordenadas(
              token,
              visita.idpaciente,
              visita.latitud!,
              visita.longitud!,
            );
            
            if (coordenadasResult != null && coordenadasResult['success'] == true) {
            } else {
            }
          } catch (coordError) {
            // No es crítico, continúa con la visita
          }
        }
        
        // 2. Obtener medicamentos asociados a esta visita
        final medicamentos = await dbHelper.getMedicamentosDeVisita(visita.id);
        // 3. Preparar medicamentos para envío
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
        
        // 4. ✅ PREPARAR DATOS CON COORDENADAS INCLUIDAS (FUNCIÓN AUXILIAR)
        Map<String, String> visitaData = _prepararDatosVisita(visita);
        
        // ✅ DEBUG: Confirmar que las coordenadas están en visitaData
       // 5. ✅ DECIDIR SI ES CREATE O UPDATE
Map<String, dynamic>? resultado;

// ✅ VERIFICAR SI LA VISITA YA EXISTE EN EL SERVIDOR
try {
  final visitaExiste = await ApiService.getVisitaById(token, visita.id);
  
  if (visitaExiste != null) {
    // ✅ LA VISITA EXISTE - USAR UPDATE
    resultado = await _actualizarVisitaExistente(visita, token, medicamentosData, visitaData);
  } else {
    // ✅ LA VISITA NO EXISTE - USAR CREATE
    resultado = await FileService.createVisitaCompleta(
      visitaData: visitaData,
      token: token,
      riskPhotoPath: visita.riesgoFotografico,
      signaturePath: visita.firmaPath ?? visita.firma,
      medicamentosData: medicamentosData,
    );
  }
} catch (verificacionError) {
  // ✅ SI HAY ERROR AL VERIFICAR (404, timeout, etc), USAR CREATE COMO FALLBACK
  try {
    resultado = await FileService.createVisitaCompleta(
      visitaData: visitaData,
      token: token,
      riskPhotoPath: visita.riesgoFotografico,
      signaturePath: visita.firmaPath ?? visita.firma,
      medicamentosData: medicamentosData,
    );
  } catch (createError) {
    // ✅ SI CREATE FALLA CON ERROR DE DUPLICADO, INTENTAR UPDATE
    if (createError.toString().contains('already exists') || 
        createError.toString().contains('duplicate') ||
        createError.toString().contains('Duplicate entry')) {
      resultado = await _actualizarVisitaExistente(visita, token, medicamentosData, visitaData);
    } else {
      rethrow; // Lanzar otros errores
    }
  }
}
        
        // 6. ✅ PROCESAR RESULTADO
        if (resultado != null && resultado['success'] == true) {
          await dbHelper.marcarVisitaComoSincronizada(visita.id);
          exitosas++;
        } else {
          fallidas++;
          final error = resultado?['error'] ?? 'Servidor respondió con error';
          errores.add('Error en visita ${visita.id}: $error');
        }
        
        // Pequeña pausa entre sincronizaciones para no saturar
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        fallidas++;
        errores.add('Error en visita ${visita.id}: $e');
      }
    }
    
    if (exitosas > 0) {
    }
    if (fallidas > 0) {
    }
    
  } catch (e) {
    errores.add('Error general de conexión: $e');
  }
  
  return {
    'exitosas': exitosas,
    'fallidas': fallidas,
    'errores': errores,
    'total': visitasPendientes.length
  };
}

// 🆕 FUNCIÓN AUXILIAR PARA PREPARAR DATOS DE VISITA
static Map<String, String> _prepararDatosVisita(Visita visita) {
  return {
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
    // 🆕 COORDENADAS INCLUIDAS:
    'latitud': visita.latitud?.toString() ?? '',
    'longitud': visita.longitud?.toString() ?? '',
  };
}

// 🆕 FUNCIÓN AUXILIAR PARA ACTUALIZAR VISITA EXISTENTE - CORREGIDA
static Future<Map<String, dynamic>?> _actualizarVisitaExistente(
  Visita visita, 
  String token, 
  List<Map<String, dynamic>> medicamentosData,
  Map<String, String> visitaData
) async {
  try {
    // ✅ USAR updateVisitaCompleta CORREGIDO
    final resultado = await FileService.updateVisitaCompleta(
      visitaId: visita.id,
      visitaData: visitaData,
      token: token,
      riskPhotoPath: visita.riesgoFotografico,
      signaturePath: visita.firmaPath ?? visita.firma,
      medicamentosData: medicamentosData,
    );
    
    return resultado;
    
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
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

  // ✅ VERIFICAR CONECTIVIDAD PRIMERO
  try {
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }

    for (final paciente in pacientesPendientes) {
      try {
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
          }
        } else {
          // Actualizar paciente existente
          serverData = await ApiService.actualizarPaciente(token, paciente.id, pacienteData);
          
          if (serverData != null) {
            await dbHelper.markPacientesAsSynced([paciente.id]);
            exitosas++;
          }
        }
        
        // 🆕 SINCRONIZAR COORDENADAS ESPECÍFICAMENTE
        if (serverData != null && paciente.latitud != null && paciente.longitud != null) {
          try {
            final coordenadasResult = await ApiService.updatePacienteCoordenadas(
              token,
              paciente.id.startsWith('offline_') ? serverData['id'].toString() : paciente.id,
              paciente.latitud!,
              paciente.longitud!,
            );
            
            if (coordenadasResult != null && coordenadasResult['success'] == true) {
            } else {
              // No marcamos como error crítico, solo advertencia
            }
          } catch (coordError) {
            // No afecta el éxito general del paciente
          }
        }
        
        if (serverData == null) {
          fallidas++;
          errores.add('Servidor respondió con error para paciente ${paciente.identificacion}');
        }
        
        // Pausa entre sincronizaciones
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        fallidas++;
        errores.add('Error en paciente ${paciente.identificacion}: $e');
      }
    }
    
  } catch (e) {
    errores.add('Error general de conexión: $e');
  }

  if (exitosas > 0) {
  }
  if (fallidas > 0) {
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
  
  try {
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }
    
    for (final visita in visitasPendientes) {
      try {
        bool needsUpdate = false;
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
          }
        }
        
        if (!needsUpdate) {
        }
        
      } catch (e, stackTrace) {
        fallidas++;
        errores.add('Error en archivos de visita ${visita.id}: $e');
      }
    }
    
    if (exitosas > 0) {
    }
    
  } catch (e) {
    errores.add('Error general de conexión: $e');
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
              }
            }
            
            // Eliminar firma legacy local si existe URL
            if (visita.firmaUrl != null && 
                visita.firma != null &&
                !visita.firma!.startsWith('http')) {
              final eliminado = await FileService.deleteLocalFile(visita.firma!);
              if (eliminado) {
                archivosEliminados++;
              }
            }
            
            // 🆕 Eliminar nueva firma local
            if (visita.firmaPath != null &&
                !visita.firmaPath!.startsWith('http')) {
              final eliminado = await FileService.deleteLocalFile(visita.firmaPath!);
              if (eliminado) {
                archivosEliminados++;
              }
            }
            
            // 🆕 Eliminar fotos múltiples locales
            if (visita.fotosPaths != null && visita.fotosPaths!.isNotEmpty) {
              for (final fotoPath in visita.fotosPaths!) {
                if (fotoPath.isNotEmpty && !fotoPath.startsWith('http')) {
                  final eliminado = await FileService.deleteLocalFile(fotoPath);
                  if (eliminado) {
                    archivosEliminados++;
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
                  }
                }
              }
            }
          }
        }
      }
      
      // Limpiar archivos huérfanos
      await FileService.cleanOldFiles(daysOld: diasAntiguos);
      
    } catch (e) {
    }
  }

  // 🆕 MÉTODO MEJORADO PARA ESTADÍSTICAS DE ARCHIVOS
  static Future<Map<String, dynamic>> obtenerEstadisticasArchivos() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final estadisticas = await dbHelper.obtenerEstadisticasArchivos();
      return estadisticas;
    } catch (e) {
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
      final estadoSincronizacion = await obtenerEstadoSincronizacion();
      final estadisticasArchivos = await obtenerEstadisticasArchivos();
      
      final pendientes = estadoSincronizacion['pendientes'] ?? 0;
      final sincronizadas = estadoSincronizacion['sincronizadas'] ?? 0;
      final total = estadoSincronizacion['total'] ?? 0;
      
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
      return false;
    }
  }

  // 🆕 MÉTODO PARA CANCELAR SINCRONIZACIÓN AUTOMÁTICA
  void cancelarSincronizacionAutomatica() {
    _cleanupAfterSync();
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
