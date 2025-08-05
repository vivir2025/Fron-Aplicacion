// services/encuesta_service.dart
import 'package:flutter/foundation.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:fnpv_app/models/encuesta_model.dart';
import 'package:uuid/uuid.dart';

class EncuestaService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 🆕 MÉTODO CORREGIDO PARA GENERAR ID MÁS CORTO
  static String generarIdUnico() {
    final uuid = Uuid();
    final fullUuid = uuid.v4();
    
    // Generar ID más corto para compatibilidad con servidor
    // Formato: enc_[8 caracteres] = 12 caracteres total
    final shortId = fullUuid.replaceAll('-', '').substring(0, 8);
    return 'enc_$shortId';
  }

  // 🆕 MÉTODO ALTERNATIVO SI NECESITAS MÁS UNICIDAD
  static String generarIdUnicoAlternativo() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 100000).toString().padLeft(5, '0');
    return 'enc_$random'; // Formato: enc_12345 = 9 caracteres total
  }

  // Guardar encuesta (local y servidor si hay conexión)
  static Future<bool> guardarEncuesta(Encuesta encuesta, String? token) async {
    try {
      debugPrint('💾 Guardando encuesta...');
      
      // 1. Guardar siempre en SQLite primero
      final savedLocally = await _dbHelper.createEncuesta(encuesta);
      
      if (!savedLocally) {
        debugPrint('❌ No se pudo guardar encuesta localmente');
        return false;
      }
      
      debugPrint('✅ Encuesta guardada localmente con ID: ${encuesta.id}');
      
      // 2. Intentar subir al servidor si hay token
      if (token != null) {
        try {
          // Verificar conectividad antes de intentar sincronizar
          debugPrint('🔍 Verificando conectividad...');
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            debugPrint('✅ Servidor disponible');
            debugPrint('📡 Enviando encuesta al servidor...');
            debugPrint('📊 Datos de encuesta: ${encuesta.id}');
            
            // 🆕 VERIFICAR LONGITUD DEL ID ANTES DE ENVIAR
            if (encuesta.id.length > 20) {
              debugPrint('⚠️ ID de encuesta demasiado largo: ${encuesta.id} (${encuesta.id.length} chars)');
              
              // Generar nuevo ID más corto
              final nuevoId = generarIdUnico();
              debugPrint('🔄 Generando nuevo ID más corto: $nuevoId (${nuevoId.length} chars)');
              
              // Crear encuesta con nuevo ID para enviar al servidor
              final encuestaParaServidor = encuesta.copyWith(id: nuevoId);
              
              final serverData = await ApiService.createEncuesta(
                encuestaParaServidor.toServerJson(),
                token,
              );
              
              if (serverData != null) {
                // Actualizar encuesta local con el nuevo ID
                await _dbHelper.updateEncuesta(encuestaParaServidor);
                await _dbHelper.marcarEncuestaComoSincronizada(nuevoId);
                debugPrint('✅ Encuesta sincronizada exitosamente con ID corto: $nuevoId');
              } else {
                debugPrint('❌ Error del servidor al sincronizar encuesta');
              }
            } else {
              // ID tiene longitud aceptable
              final serverData = await ApiService.createEncuesta(
                encuesta.toServerJson(),
                token,
              );
              
              if (serverData != null) {
                // Marcar como sincronizada
                await _dbHelper.marcarEncuestaComoSincronizada(encuesta.id);
                debugPrint('✅ Encuesta sincronizada exitosamente con el servidor');
              } else {
                debugPrint('❌ Error del servidor al sincronizar encuesta');
              }
            }
          } else {
            debugPrint('📵 Sin conexión a internet - Encuesta quedará pendiente de sincronización');
          }
        } catch (e) {
          debugPrint('⚠️ Error al subir al servidor: $e');
          // La encuesta ya está guardada localmente, no es un error crítico
        }
      } else {
        debugPrint('🔑 No hay token de autenticación - Encuesta quedará pendiente de sincronización');
      }
      
      return true; // Éxito si al menos se guardó localmente
    } catch (e) {
      debugPrint('💥 Error completo al guardar encuesta: $e');
      return false;
    }
  }

  // Obtener todas las encuestas
  static Future<List<Encuesta>> obtenerTodasLasEncuestas() async {
    return await _dbHelper.getAllEncuestas();
  }

  // Obtener encuestas por paciente
  static Future<List<Encuesta>> obtenerEncuestasPorPaciente(String pacienteId) async {
    return await _dbHelper.getEncuestasByPaciente(pacienteId);
  }

  // Obtener encuestas por sede
  static Future<List<Encuesta>> obtenerEncuestasPorSede(String sedeId) async {
    return await _dbHelper.getEncuestasBySede(sedeId);
  }

  // 🆕 MÉTODO MEJORADO PARA SINCRONIZACIÓN CON MEJOR MANEJO DE IDS
  static Future<Map<String, dynamic>> sincronizarEncuestasPendientes(String token) async {
    try {
      debugPrint('📋 Iniciando sincronización de encuestas...');
      
      final encuestasPendientes = await _dbHelper.getEncuestasNoSincronizadas();
      
      int exitosas = 0;
      int fallidas = 0;
      List<String> errores = [];
      
      debugPrint('📊 Sincronizando ${encuestasPendientes.length} encuestas pendientes...');
      
      // Verificar conectividad primero
      final hasConnection = await ApiService.verificarConectividad();
      if (!hasConnection) {
        throw Exception('No hay conexión a internet');
      }
      
      for (final encuesta in encuestasPendientes) {
        try {
          debugPrint('🔄 Sincronizando encuesta ${encuesta.id} (${encuesta.id.length} chars)...');
          
          // 🆕 VERIFICAR LONGITUD DEL ID ANTES DE ENVIAR
          if (encuesta.id.length > 20) {
            debugPrint('⚠️ ID de encuesta demasiado largo: ${encuesta.id} (${encuesta.id.length} chars)');
            
            // Generar nuevo ID más corto
            final nuevoId = generarIdUnico();
            debugPrint('🔄 Generando nuevo ID más corto: $nuevoId (${nuevoId.length} chars)');
            
            // Actualizar encuesta con nuevo ID
            final encuestaActualizada = encuesta.copyWith(id: nuevoId);
            await _dbHelper.updateEncuesta(encuestaActualizada);
            
            // Usar la encuesta actualizada para enviar
            final serverData = await ApiService.createEncuesta(
              encuestaActualizada.toServerJson(),
              token,
            );
            
            if (serverData != null) {
              await _dbHelper.marcarEncuestaComoSincronizada(nuevoId);
              exitosas++;
              debugPrint('✅ Encuesta ${nuevoId} sincronizada exitosamente con ID corto');
            } else {
              fallidas++;
              errores.add('Servidor respondió con error para encuesta ${nuevoId}');
              debugPrint('❌ Falló sincronización de encuesta ${nuevoId}');
            }
          } else {
            // ID tiene longitud aceptable
            final serverData = await ApiService.createEncuesta(
              encuesta.toServerJson(),
              token,
            );
            
            if (serverData != null) {
              await _dbHelper.marcarEncuestaComoSincronizada(encuesta.id);
              exitosas++;
              debugPrint('✅ Encuesta ${encuesta.id} sincronizada exitosamente');
            } else {
              fallidas++;
              errores.add('Servidor respondió con error para encuesta ${encuesta.id}');
              debugPrint('❌ Falló sincronización de encuesta ${encuesta.id}');
            }
          }
          
          // Pequeña pausa entre sincronizaciones para no saturar
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          fallidas++;
          errores.add('Error en encuesta ${encuesta.id}: $e');
          debugPrint('💥 Error sincronizando encuesta ${encuesta.id}: $e');
        }
      }
      
      if (exitosas > 0) {
        debugPrint('🎉 $exitosas encuestas sincronizadas exitosamente');
      }
      if (fallidas > 0) {
        debugPrint('⚠️ $fallidas encuestas fallaron en la sincronización');
        for (final error in errores.take(3)) {
          debugPrint('❌ Error: $error');
        }
      }
      
      return {
        'exitosas': exitosas,
        'fallidas': fallidas,
        'errores': errores,
        'total': encuestasPendientes.length,
      };
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

  // Eliminar encuesta
  static Future<bool> eliminarEncuesta(String id) async {
    try {
      final result = await _dbHelper.deleteEncuesta(id);
      if (result) {
        debugPrint('✅ Encuesta eliminada: $id');
      } else {
        debugPrint('❌ No se pudo eliminar encuesta: $id');
      }
      return result;
    } catch (e) {
      debugPrint('💥 Error eliminando encuesta $id: $e');
      return false;
    }
  }

  // Actualizar encuesta
  static Future<bool> actualizarEncuesta(Encuesta encuesta) async {
    try {
      final result = await _dbHelper.updateEncuesta(encuesta);
      if (result) {
        debugPrint('✅ Encuesta actualizada: ${encuesta.id}');
      } else {
        debugPrint('❌ No se pudo actualizar encuesta: ${encuesta.id}');
      }
      return result;
    } catch (e) {
      debugPrint('💥 Error actualizando encuesta ${encuesta.id}: $e');
      return false;
    }
  }

  // Obtener encuesta por ID
  static Future<Encuesta?> obtenerEncuestaPorId(String id) async {
    try {
      final encuesta = await _dbHelper.getEncuestaById(id);
      if (encuesta != null) {
        debugPrint('✅ Encuesta encontrada: $id');
      } else {
        debugPrint('⚠️ Encuesta no encontrada: $id');
      }
      return encuesta;
    } catch (e) {
      debugPrint('💥 Error obteniendo encuesta $id: $e');
      return null;
    }
  }

  // 🆕 MÉTODO PARA OBTENER ESTADÍSTICAS DE ENCUESTAS
  static Future<Map<String, dynamic>> obtenerEstadisticasEncuestas() async {
    try {
      final todasLasEncuestas = await obtenerTodasLasEncuestas();
      final encuestasSincronizadas = todasLasEncuestas.where((e) => e.syncStatus == 1).length;
      final encuestasPendientes = todasLasEncuestas.where((e) => e.syncStatus == 0).length;
      
      return {
        'total': todasLasEncuestas.length,
        'sincronizadas': encuestasSincronizadas,
        'pendientes': encuestasPendientes,
      };
    } catch (e) {
      debugPrint('💥 Error obteniendo estadísticas de encuestas: $e');
      return {
        'total': 0,
        'sincronizadas': 0,
        'pendientes': 0,
      };
    }
  }

 // 🆕 MÉTODO ALTERNATIVO MÁS ROBUSTO
static Future<int> limpiarEncuestasAntiguasSincronizadas({int diasAntiguedad = 30}) async {
  try {
    final fechaLimite = DateTime.now().subtract(Duration(days: diasAntiguedad));
    
    final todasLasEncuestas = await obtenerTodasLasEncuestas();
    int eliminadas = 0;
    
    for (final encuesta in todasLasEncuestas) {
      try {
        // 🔧 MÚLTIPLES VERIFICACIONES DE SEGURIDAD
        if (encuesta.syncStatus == 1) {
          DateTime? fechaCreacion;
          
          // Intentar obtener la fecha de creación
          if (encuesta.createdAt != null) {
            fechaCreacion = encuesta.createdAt;
          } else if (encuesta.fecha != null) {
            // Usar fecha de la encuesta como fallback
            fechaCreacion = encuesta.fecha;
          }
          
          // Verificar si la fecha es válida y es anterior al límite
          if (fechaCreacion != null && fechaCreacion.isBefore(fechaLimite)) {
            final eliminada = await eliminarEncuesta(encuesta.id);
            if (eliminada) {
              eliminadas++;
              debugPrint('🗑️ Encuesta antigua eliminada: ${encuesta.id} (${fechaCreacion.toString().split(' ')[0]})');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error procesando encuesta ${encuesta.id}: $e');
        // Continuar con la siguiente encuesta
        continue;
      }
    }
    
    debugPrint('🧹 Total: $eliminadas encuestas antiguas eliminadas (más de $diasAntiguedad días)');
    return eliminadas;
  } catch (e) {
    debugPrint('💥 Error general limpiando encuestas antiguas: $e');
    return 0;
  }
}

}
