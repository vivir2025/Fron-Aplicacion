// lib/services/afinamiento_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../api/api_service.dart';
import '../database/database_helper.dart';
import '../models/afinamiento_model.dart';

class AfinamientoService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== MÉTODOS PRINCIPALES ====================

  // Guardar afinamiento (funciona offline y online)
  static Future<bool> guardarAfinamiento(Afinamiento afinamiento, String? token) async {
    try {
      debugPrint('💾 Guardando afinamiento...');
      
      // 1. Siempre guardar localmente primero
      final savedLocally = await _dbHelper.createAfinamiento(afinamiento);
      
      if (!savedLocally) {
        debugPrint('❌ No se pudo guardar afinamiento localmente');
        return false;
      }
      
      debugPrint('✅ Afinamiento guardado localmente con ID: ${afinamiento.id}');
      debugPrint('✅ Afinamiento guardado localmente');
      
      // 2. Intentar sincronizar con servidor si hay token y conexión
      if (token != null && token.isNotEmpty) {
        try {
          debugPrint('🔍 Verificando conectividad...');
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            debugPrint('✅ Servidor disponible');
            debugPrint('📡 Enviando afinamiento al servidor...');
            
            // Preparar datos para el servidor
            final afinamientoData = afinamiento.toJson();
            debugPrint('📋 Datos de afinamiento: ${afinamiento.id}');
            
            final serverData = await ApiService.createAfinamiento(
              afinamientoData,
              token,
            );
            
            if (serverData != null) {
              // Marcar como sincronizado
              await _dbHelper.marcarAfinamientoComoSincronizado(afinamiento.id);
              debugPrint('✅ Afinamiento sincronizado exitosamente con el servidor');
            } else {
              debugPrint('⚠️ No se pudo sincronizar con el servidor - quedará pendiente');
            }
          } else {
            debugPrint('📵 Sin conexión - Afinamiento quedará pendiente de sincronización');
          }
        } catch (e) {
          debugPrint('⚠️ Error al sincronizar con servidor: $e');
          // No es crítico, ya está guardado localmente
        }
      } else {
        debugPrint('🔑 No hay token - Afinamiento quedará pendiente de sincronización');
      }
      
      return true;
    } catch (e) {
      debugPrint('💥 Error completo al guardar afinamiento: $e');
      return false;
    }
  }

  // Actualizar afinamiento
  static Future<bool> actualizarAfinamiento(Afinamiento afinamiento, String? token) async {
    try {
      debugPrint('🔄 Actualizando afinamiento ${afinamiento.id}...');
      
      // 1. Actualizar localmente
      final updatedLocally = await _dbHelper.updateAfinamiento(
        afinamiento.copyWith(syncStatus: 0) // Marcar como no sincronizado
      );
      
      if (!updatedLocally) {
        debugPrint('❌ No se pudo actualizar afinamiento localmente');
        return false;
      }
      
      debugPrint('✅ Afinamiento actualizado localmente');
      
      // 2. Intentar sincronizar con servidor
      if (token != null && token.isNotEmpty) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            final serverData = await ApiService.updateAfinamiento(
              afinamiento.id,
              afinamiento.toJson(),
              token,
            );
            
            if (serverData != null) {
              await _dbHelper.marcarAfinamientoComoSincronizado(afinamiento.id);
              debugPrint('✅ Afinamiento actualizado en servidor');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error al actualizar en servidor: $e');
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('💥 Error al actualizar afinamiento: $e');
      return false;
    }
  }

  // Eliminar afinamiento
  static Future<bool> eliminarAfinamiento(String id, String? token) async {
    try {
      debugPrint('🗑️ Eliminando afinamiento $id...');
      
      // 1. Si hay conexión, eliminar del servidor primero
      if (token != null && token.isNotEmpty) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            final deletedFromServer = await ApiService.deleteAfinamiento(id, token);
            if (deletedFromServer) {
              debugPrint('✅ Afinamiento eliminado del servidor');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error al eliminar del servidor: $e');
        }
      }
      
      // 2. Eliminar localmente
      final deletedLocally = await _dbHelper.deleteAfinamiento(id);
      
      if (deletedLocally) {
        debugPrint('✅ Afinamiento eliminado localmente');
        return true;
      } else {
        debugPrint('❌ No se pudo eliminar afinamiento localmente');
        return false;
      }
    } catch (e) {
      debugPrint('💥 Error al eliminar afinamiento: $e');
      return false;
    }
  }

  // ==================== MÉTODOS DE CONSULTA ====================

  // Obtener todos los afinamientos
  static Future<List<Afinamiento>> obtenerTodosLosAfinamientos() async {
    try {
      return await _dbHelper.getAllAfinamientos();
    } catch (e) {
      debugPrint('❌ Error al obtener afinamientos: $e');
      return [];
    }
  }

  // Obtener afinamientos con información del paciente
  static Future<List<Map<String, dynamic>>> obtenerAfinamientosConPaciente() async {
    try {
      return await _dbHelper.getAfinamientosConPaciente();
    } catch (e) {
      debugPrint('❌ Error al obtener afinamientos con paciente: $e');
      return [];
    }
  }

  // Obtener afinamiento por ID
  static Future<Afinamiento?> obtenerAfinamientoPorId(String id) async {
    try {
      return await _dbHelper.getAfinamientoById(id);
    } catch (e) {
      debugPrint('❌ Error al obtener afinamiento por ID: $e');
      return null;
    }
  }

  // Obtener afinamientos por paciente
  static Future<List<Afinamiento>> obtenerAfinamientosPorPaciente(String pacienteId) async {
    try {
      return await _dbHelper.getAfinamientosByPaciente(pacienteId);
    } catch (e) {
      debugPrint('❌ Error al obtener afinamientos por paciente: $e');
      return [];
    }
  }

  // Obtener afinamientos por usuario
  static Future<List<Afinamiento>> obtenerAfinamientosPorUsuario(String usuarioId) async {
    try {
      return await _dbHelper.getAfinamientosByUsuario(usuarioId);
    } catch (e) {
      debugPrint('❌ Error al obtener afinamientos por usuario: $e');
      return [];
    }
  }

  // ==================== MÉTODOS DE SINCRONIZACIÓN ====================

  // Sincronizar afinamientos pendientes
  static Future<Map<String, dynamic>> sincronizarAfinamientosPendientes(String token) async {
    try {
      debugPrint('🔄 Iniciando sincronización de afinamientos pendientes...');
      
      final afinamientosPendientes = await _dbHelper.getAfinamientosNoSincronizados();
      
      int exitosas = 0;
      int fallidas = 0;
      List<String> errores = [];
      
      debugPrint('📊 Sincronizando ${afinamientosPendientes.length} afinamientos pendientes...');
      
      // Verificar conectividad
      final hasConnection = await ApiService.verificarConectividad();
      if (!hasConnection) {
        throw Exception('No hay conexión a internet');
      }
      
      for (final afinamiento in afinamientosPendientes) {
        try {
          debugPrint('🔄 Sincronizando afinamiento ${afinamiento.id}...');
          
          // Preparar datos para el servidor
          final afinamientoData = afinamiento.toJson();
          
          // Verificar si es un afinamiento offline (nuevo) o existente
          Map<String, dynamic>? serverData;
          
          if (afinamiento.id.startsWith('afin_')) {
            // Crear nuevo afinamiento en servidor
            serverData = await ApiService.createAfinamiento(afinamientoData, token);
          } else {
            // Actualizar afinamiento existente
            serverData = await ApiService.updateAfinamiento(
              afinamiento.id,
              afinamientoData,
              token,
            );
          }
          
          if (serverData != null) {
            // Si es un afinamiento offline, actualizar con el ID del servidor
            if (afinamiento.id.startsWith('afin_') && serverData['data'] != null) {
              final nuevoId = serverData['data']['id'].toString();
              
              // Eliminar versión offline
              await _dbHelper.deleteAfinamiento(afinamiento.id);
              
              // Crear versión con ID del servidor
              final afinamientoServidor = Afinamiento.fromJson(serverData['data']);
              await _dbHelper.createAfinamiento(
                afinamientoServidor.copyWith(syncStatus: 1)
              );
            } else {
              // Marcar como sincronizado
              await _dbHelper.marcarAfinamientoComoSincronizado(afinamiento.id);
            }
            
            exitosas++;
            debugPrint('✅ Afinamiento ${afinamiento.id} sincronizado exitosamente');
          } else {
            fallidas++;
            errores.add('Servidor respondió con error para afinamiento ${afinamiento.id}');
            debugPrint('❌ Falló sincronización de afinamiento ${afinamiento.id}');
          }
          
          // Pausa entre sincronizaciones
          await Future.delayed(const Duration(milliseconds: 300));
          
        } catch (e) {
          fallidas++;
          errores.add('Error en afinamiento ${afinamiento.id}: $e');
          debugPrint('💥 Error sincronizando afinamiento ${afinamiento.id}: $e');
        }
      }
      
      if (exitosas > 0) {
        debugPrint('🎉 $exitosas afinamientos sincronizados exitosamente');
      }
      if (fallidas > 0) {
        debugPrint('⚠️ $fallidas afinamientos fallaron en la sincronización');
      }
      
      return {
        'exitosas': exitosas,
        'fallidas': fallidas,
        'errores': errores,
        'total': afinamientosPendientes.length,
      };
      
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

  // Cargar afinamientos desde el servidor
  static Future<bool> cargarAfinamientosDesdeServidor(String token) async {
    try {
      debugPrint('📥 Cargando afinamientos desde servidor...');
      
      final hasConnection = await ApiService.verificarConectividad();
      if (!hasConnection) {
        debugPrint('📵 Sin conexión para cargar afinamientos');
        return false;
      }
      
      final afinamientosServidor = await ApiService.getAfinamientos(token);
      
      if (afinamientosServidor.isNotEmpty) {
        // Guardar afinamientos del servidor localmente
        for (final afinamientoData in afinamientosServidor) {
          final afinamiento = Afinamiento.fromJson({
            ...afinamientoData,
            'sync_status': 1, // Marcado como sincronizado
          });
          
          await _dbHelper.createAfinamiento(afinamiento);
        }
        
        debugPrint('✅ ${afinamientosServidor.length} afinamientos cargados desde servidor');
        return true;
      } else {
        debugPrint('ℹ️ No hay afinamientos en el servidor');
        return true;
      }
      
    } catch (e) {
      debugPrint('❌ Error cargando afinamientos desde servidor: $e');
      return false;
    }
  }

  // ==================== MÉTODOS DE ESTADÍSTICAS ====================

  // Obtener estadísticas de afinamientos
  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      return await _dbHelper.getAfinamientosEstadisticas();
    } catch (e) {
      debugPrint('❌ Error al obtener estadísticas: $e');
      return {
        'total': 0,
        'sincronizados': 0,
        'pendientes': 0,
      };
    }
  }

  // Contar afinamientos por usuario
  static Future<int> contarAfinamientosPorUsuario(String usuarioId) async {
    try {
      return await _dbHelper.countAfinamientosByUsuario(usuarioId);
    } catch (e) {
      debugPrint('❌ Error al contar afinamientos: $e');
      return 0;
    }
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  // 🔧 GENERAR ID ÚNICO MÁS CORTO PARA AFINAMIENTO OFFLINE
  static String generarIdUnico() {
    final uuid = Uuid();
    final uuidString = uuid.v4();
    // Tomar solo los primeros 8 caracteres del UUID para acortar el ID
    final shortId = uuidString.substring(0, 8);
    return 'afin_$shortId';
  }

  // Validar datos de afinamiento
  static Map<String, String> validarAfinamiento(Afinamiento afinamiento) {
    Map<String, String> errores = {};
    
    if (afinamiento.idpaciente.isEmpty) {
      errores['idpaciente'] = 'Debe seleccionar un paciente';
    }
    
    if (afinamiento.procedencia.isEmpty) {
      errores['procedencia'] = 'La procedencia es requerida';
    }
    
    if (afinamiento.presionArterialTamiz.isEmpty) {
      errores['presion_arterial_tamiz'] = 'La presión arterial del tamizaje es requerida';
    }
    
    // Validar rangos de presión arterial
    if (afinamiento.presionSistolica1 != null) {
      if (afinamiento.presionSistolica1! < 50 || afinamiento.presionSistolica1! > 300) {
        errores['presion_sistolica_1'] = 'La presión sistólica debe estar entre 50 y 300';
      }
    }
    
    if (afinamiento.presionDiastolica1 != null) {
      if (afinamiento.presionDiastolica1! < 30 || afinamiento.presionDiastolica1! > 200) {
        errores['presion_diastolica_1'] = 'La presión diastólica debe estar entre 30 y 200';
      }
    }
    
    // Validar que si hay fecha de afinamiento, también haya presiones
    if (afinamiento.primerAfinamientoFecha != null) {
      if (afinamiento.presionSistolica1 == null || afinamiento.presionDiastolica1 == null) {
        errores['primer_afinamiento'] = 'Si hay fecha de afinamiento, debe incluir las presiones';
      }
    }
    
    return errores;
  }

  // Crear afinamiento desde formulario
  static Afinamiento crearDesdeFormulario({
    required String idpaciente,
    required String idusuario,
    required String procedencia,
    required DateTime fechaTamizaje,
    required String presionArterialTamiz,
    DateTime? primerAfinamientoFecha,
    int? presionSistolica1,
    int? presionDiastolica1,
    DateTime? segundoAfinamientoFecha,
    int? presionSistolica2,
    int? presionDiastolica2,
    DateTime? tercerAfinamientoFecha,
    int? presionSistolica3,
    int? presionDiastolica3,
    String? conducta,
  }) {
    final afinamiento = Afinamiento(
      id: generarIdUnico(),
      idpaciente: idpaciente,
      idusuario: idusuario,
      procedencia: procedencia,
      fechaTamizaje: fechaTamizaje,
      presionArterialTamiz: presionArterialTamiz,
      primerAfinamientoFecha: primerAfinamientoFecha,
      presionSistolica1: presionSistolica1,
      presionDiastolica1: presionDiastolica1,
      segundoAfinamientoFecha: segundoAfinamientoFecha,
      presionSistolica2: presionSistolica2,
      presionDiastolica2: presionDiastolica2,
      tercerAfinamientoFecha: tercerAfinamientoFecha,
      presionSistolica3: presionSistolica3,
      presionDiastolica3: presionDiastolica3,
      conducta: conducta,
      syncStatus: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Calcular promedios automáticamente
    final promedios = afinamiento.calcularPromedios();
    
    return afinamiento.copyWith(
      presionSistolicaPromedio: promedios['sistolica'],
      presionDiastolicaPromedio: promedios['diastolica'],
    );
  }
}
