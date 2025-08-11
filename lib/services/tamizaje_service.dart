// services/tamizaje_service.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../api/api_service.dart';
import '../database/database_helper.dart';
import '../models/tamizaje_model.dart';
import '../models/paciente_model.dart';

class TamizajeService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Generar ID más corto para evitar problemas con la base de datos
  static String _generarIdTamizaje() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'TAM${timestamp}$random';
  }

  // Crear tamizaje (funciona online y offline)
  static Future<Map<String, dynamic>> crearTamizaje({
    required String pacienteId,
    required String usuarioId,
    required String veredaResidencia,
    String? telefono,
    required String brazoToma,
    required String posicionPersona,
    required String reposoCincoMinutos,
    required DateTime fechaPrimeraToma,
    required int paSistolica,
    required int paDiastolica,
    String? conducta,
    String? token,
  }) async {
    try {
      // Validar datos antes de proceder
      final erroresValidacion = validarDatosTamizaje(
        veredaResidencia: veredaResidencia,
        telefono: telefono,
        paSistolica: paSistolica,
        paDiastolica: paDiastolica,
      );

      if (erroresValidacion.isNotEmpty) {
        return {
          'success': false,
          'message': 'Datos inválidos: ${erroresValidacion.values.first}',
          'tamizaje': null,
          'errors': erroresValidacion,
        };
      }

      // Generar ID único más corto
      final tamizajeId = _generarIdTamizaje();
      
      // Crear objeto tamizaje
      final tamizaje = Tamizaje(
        id: tamizajeId,
        idpaciente: pacienteId,
        idusuario: usuarioId,
        veredaResidencia: veredaResidencia.trim(),
        telefono: telefono?.trim(),
        brazoToma: brazoToma,
        posicionPersona: posicionPersona,
        reposoCincoMinutos: reposoCincoMinutos,
        fechaPrimeraToma: fechaPrimeraToma,
        paSistolica: paSistolica,
        paDiastolica: paDiastolica,
        conducta: conducta?.trim(),
        syncStatus: 0, // Inicialmente no sincronizado
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Guardar localmente siempre
      final savedLocally = await _dbHelper.createTamizaje(tamizaje);
      
      if (!savedLocally) {
        return {
          'success': false,
          'message': 'Error al guardar tamizaje localmente',
          'tamizaje': null,
        };
      }

      debugPrint('✅ Tamizaje guardado localmente: $tamizajeId');

      // 2. Intentar sincronizar con servidor si hay token
      if (token != null && token.isNotEmpty) {
        try {
          debugPrint('🔍 Verificando conectividad...');
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            debugPrint('✅ Servidor disponible');
            debugPrint('📤 Enviando tamizaje al servidor...');
            debugPrint('📊 Datos de tamizaje: $tamizajeId');
            
            final serverResponse = await ApiService.createTamizaje(
              tamizaje.toJson(),
              token,
            );

            if (serverResponse != null) {
              // Marcar como sincronizado
              await _dbHelper.marcarTamizajeComoSincronizado(tamizajeId);
              
              debugPrint('✅ Tamizaje sincronizado con servidor: $tamizajeId');
              
              return {
                'success': true,
                'message': 'Tamizaje creado y sincronizado exitosamente',
                'tamizaje': tamizaje.copyWith(syncStatus: 1),
                'synced': true,
              };
            } else {
              debugPrint('⚠️ Error al sincronizar con servidor, quedará pendiente');
            }
          } else {
            debugPrint('📵 Sin conexión, tamizaje quedará pendiente de sincronización');
          }
        } catch (e) {
          debugPrint('! Error al sincronizar con servidor, quedará pendiente');
          debugPrint('💥 Detalles del error: $e');
        }
      }

      return {
        'success': true,
        'message': 'Tamizaje guardado localmente, pendiente de sincronización',
        'tamizaje': tamizaje,
        'synced': false,
      };

    } catch (e) {
      debugPrint('💥 Error al crear tamizaje: $e');
      return {
        'success': false,
        'message': 'Error al crear tamizaje: ${e.toString()}',
        'tamizaje': null,
      };
    }
  }

  // Obtener tamizajes con información del paciente
  static Future<List<Tamizaje>> obtenerTamizajesConPaciente() async {
    try {
      final tamizajesData = await _dbHelper.getTamizajesConPaciente();
      
      return tamizajesData.map((data) {
        try {
          return Tamizaje.fromJson(data);
        } catch (e) {
          debugPrint('⚠️ Error parseando tamizaje: $e');
          debugPrint('📊 Datos problemáticos: $data');
          // Retornar un tamizaje con datos por defecto en caso de error
          return Tamizaje(
            id: data['id']?.toString() ?? 'unknown',
            idpaciente: data['idpaciente']?.toString() ?? '',
            idusuario: data['idusuario']?.toString() ?? '',
            veredaResidencia: data['vereda_residencia']?.toString() ?? '',
            brazoToma: data['brazo_toma']?.toString() ?? '',
            posicionPersona: data['posicion_persona']?.toString() ?? '',
            reposoCincoMinutos: data['reposo_cinco_minutos']?.toString() ?? '',
            fechaPrimeraToma: DateTime.tryParse(data['fecha_primera_toma']?.toString() ?? '') ?? DateTime.now(),
            paSistolica: int.tryParse(data['pa_sistolica']?.toString() ?? '0') ?? 0,
            paDiastolica: int.tryParse(data['pa_diastolica']?.toString() ?? '0') ?? 0,
            syncStatus: int.tryParse(data['sync_status']?.toString() ?? '0') ?? 0,
            createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ?? DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo tamizajes con paciente: $e');
      return [];
    }
  }

  // Obtener tamizajes por usuario
  static Future<List<Tamizaje>> obtenerTamizajesPorUsuario(String usuarioId) async {
    try {
      if (usuarioId.isEmpty) {
        debugPrint('⚠️ ID de usuario vacío');
        return [];
      }
      return await _dbHelper.getTamizajesByUsuario(usuarioId);
    } catch (e) {
      debugPrint('❌ Error obteniendo tamizajes por usuario: $e');
      return [];
    }
  }

  // Sincronizar tamizajes pendientes
  static Future<Map<String, dynamic>> sincronizarTamizajesPendientes(String token) async {
    try {
      debugPrint('🩺 Iniciando sincronización de tamizajes...');
      
      if (token.isEmpty) {
        throw Exception('Token de autenticación requerido');
      }

      final tamizajesPendientes = await _dbHelper.getTamizajesNoSincronizados();
      
      int exitosas = 0;
      int fallidas = 0;
      List<String> errores = [];
      
      debugPrint('📊 Sincronizando ${tamizajesPendientes.length} tamizajes pendientes...');
      
      if (tamizajesPendientes.isEmpty) {
        return {
          'exitosas': 0,
          'fallidas': 0,
          'errores': [],
          'total': 0,
          'message': 'No hay tamizajes pendientes de sincronización',
        };
      }
      
      // Verificar conectividad
      final hasConnection = await ApiService.verificarConectividad();
      if (!hasConnection) {
        throw Exception('No hay conexión a internet');
      }
      
      for (final tamizaje in tamizajesPendientes) {
        try {
          debugPrint('🔄 Sincronizando tamizaje ${tamizaje.id}...');
          
          final serverResponse = await ApiService.createTamizaje(
            tamizaje.toJson(),
            token,
          );
          
          if (serverResponse != null) {
            await _dbHelper.marcarTamizajeComoSincronizado(tamizaje.id);
            exitosas++;
            debugPrint('✅ Tamizaje ${tamizaje.id} sincronizado exitosamente');
          } else {
            fallidas++;
            errores.add('Servidor respondió con error para tamizaje ${tamizaje.id}');
            debugPrint('❌ Falló sincronización de tamizaje ${tamizaje.id}');
          }
          
          // Pausa entre sincronizaciones para evitar sobrecarga
          await Future.delayed(const Duration(milliseconds: 500));
          
        } catch (e) {
          fallidas++;
          final errorMsg = 'Error en tamizaje ${tamizaje.id}: ${e.toString()}';
          errores.add(errorMsg);
          debugPrint('💥 $errorMsg');
        }
      }
      
      if (exitosas > 0) {
        debugPrint('🎉 $exitosas tamizajes sincronizados exitosamente');
      }
      if (fallidas > 0) {
        debugPrint('⚠️ $fallidas tamizajes fallaron en la sincronización');
      }
      
      return {
        'exitosas': exitosas,
        'fallidas': fallidas,
        'errores': errores,
        'total': tamizajesPendientes.length,
        'message': exitosas > 0 
          ? '$exitosas tamizajes sincronizados exitosamente'
          : 'No se pudieron sincronizar los tamizajes',
      };
      
    } catch (e) {
      debugPrint('💥 Error en sincronización de tamizajes: $e');
      return {
        'exitosas': 0,
        'fallidas': 1,
        'errores': ['Error general: ${e.toString()}'],
        'total': 1,
        'message': 'Error en la sincronización: ${e.toString()}',
      };
    }
  }

  // Obtener estadísticas
  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final estadisticas = await _dbHelper.getTamizajesEstadisticas();
      
      // Asegurar que las estadísticas tengan valores por defecto
      return {
        'total': estadisticas['total'] ?? 0,
        'sincronizados': estadisticas['sincronizados'] ?? 0,
        'pendientes': estadisticas['pendientes'] ?? 0,
        'hoy': estadisticas['hoy'] ?? 0,
        'esta_semana': estadisticas['esta_semana'] ?? 0,
        'este_mes': estadisticas['este_mes'] ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return {
        'total': 0,
        'sincronizados': 0,
        'pendientes': 0,
        'hoy': 0,
        'esta_semana': 0,
        'este_mes': 0,
      };
    }
  }

  // Eliminar tamizaje
  static Future<bool> eliminarTamizaje(String tamizajeId) async {
    try {
      if (tamizajeId.isEmpty) {
        debugPrint('⚠️ ID de tamizaje vacío');
        return false;
      }
      
      final resultado = await _dbHelper.deleteTamizaje(tamizajeId);
      
      if (resultado) {
        debugPrint('✅ Tamizaje eliminado: $tamizajeId');
      } else {
        debugPrint('⚠️ No se pudo eliminar el tamizaje: $tamizajeId');
      }
      
      return resultado;
    } catch (e) {
      debugPrint('❌ Error eliminando tamizaje: $e');
      return false;
    }
  }

  // Buscar paciente por identificación
  static Future<Paciente?> buscarPacientePorIdentificacion(String identificacion) async {
    try {
      if (identificacion.trim().isEmpty) {
        debugPrint('⚠️ Identificación vacía');
        return null;
      }
      
      final paciente = await _dbHelper.getPacienteByIdentificacion(identificacion.trim());
      
      if (paciente != null) {
        debugPrint('✅ Paciente encontrado: ${paciente.nombre}');
      } else {
        debugPrint('⚠️ Paciente no encontrado con identificación: $identificacion');
      }
      
      return paciente;
    } catch (e) {
      debugPrint('❌ Error buscando paciente: $e');
      return null;
    }
  }

  // Validar datos de tamizaje
  static Map<String, String?> validarDatosTamizaje({
    required String veredaResidencia,
    String? telefono,
    required int paSistolica,
    required int paDiastolica,
  }) {
    Map<String, String?> errores = {};

    // Validar vereda de residencia
    if (veredaResidencia.trim().isEmpty) {
      errores['vereda_residencia'] = 'La vereda de residencia es requerida';
    } else if (veredaResidencia.trim().length < 2) {
      errores['vereda_residencia'] = 'La vereda debe tener al menos 2 caracteres';
    } else if (veredaResidencia.trim().length > 100) {
      errores['vereda_residencia'] = 'La vereda no puede tener más de 100 caracteres';
    }

    // Validar teléfono si se proporciona
    if (telefono != null && telefono.isNotEmpty) {
      final telefonoLimpio = telefono.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (telefonoLimpio.length < 7) {
        errores['telefono'] = 'El teléfono debe tener al menos 7 dígitos';
      } else if (telefonoLimpio.length > 15) {
        errores['telefono'] = 'El teléfono no puede tener más de 15 dígitos';
      }
    }

    // Validar presión sistólica
    if (paSistolica < 50 || paSistolica > 300) {
      errores['pa_sistolica'] = 'La presión sistólica debe estar entre 50 y 300 mmHg';
    }

    // Validar presión diastólica
    if (paDiastolica < 30 || paDiastolica > 200) {
      errores['pa_diastolica'] = 'La presión diastólica debe estar entre 30 y 200 mmHg';
    }

    // Validar relación entre presiones
    if (paSistolica <= paDiastolica) {
      errores['presion_arterial'] = 'La presión sistólica debe ser mayor que la diastólica';
    }

    // Validar diferencia mínima entre presiones
    if ((paSistolica - paDiastolica) < 10) {
      errores['diferencia_presion'] = 'La diferencia entre presiones debe ser de al menos 10 mmHg';
    }

    return errores;
  }

  // Obtener clasificación de presión arterial
  static Map<String, dynamic> clasificarPresionArterial(int sistolica, int diastolica) {
    String clasificacion = '';
    String recomendacion = '';
    String color = 'green';
    int riesgo = 1; // 1=bajo, 2=medio, 3=alto, 4=muy alto

    if (sistolica < 120 && diastolica < 80) {
      clasificacion = 'NORMAL';
      recomendacion = 'Mantener hábitos saludables';
      color = 'green';
      riesgo = 1;
    } else if (sistolica < 130 && diastolica < 80) {
      clasificacion = 'ELEVADA';
      recomendacion = 'Cambios en el estilo de vida';
      color = 'orange';
      riesgo = 2;
    } else if ((sistolica >= 130 && sistolica <= 139) || (diastolica >= 80 && diastolica <= 89)) {
      clasificacion = 'HIPERTENSIÓN ESTADIO 1';
      recomendacion = 'Consultar con médico, cambios en estilo de vida';
      color = 'red';
      riesgo = 3;
    } else if (sistolica >= 140 || diastolica >= 90) {
      clasificacion = 'HIPERTENSIÓN ESTADIO 2';
      recomendacion = 'Consultar médico urgente, medicación probable';
      color = 'darkred';
      riesgo = 3;
    } else if (sistolica >= 180 || diastolica >= 120) {
      clasificacion = 'CRISIS HIPERTENSIVA';
      recomendacion = 'ATENCIÓN MÉDICA INMEDIATA';
      color = 'darkred';
      riesgo = 4;
    }

    return {
      'clasificacion': clasificacion,
      'recomendacion': recomendacion,
      'color': color,
      'riesgo': riesgo,
      'sistolica': sistolica,
      'diastolica': diastolica,
    };
  }

  // Obtener conteo de tamizajes pendientes
  static Future<int> obtenerTamizajesPendientesCount() async {
    try {
      final tamizajes = await _dbHelper.getTamizajesNoSincronizados();
      return tamizajes.length;
    } catch (e) {
      debugPrint('❌ Error obteniendo conteo de tamizajes pendientes: $e');
      return 0;
    }
  }
}
