// services/envio_muestra_service.dart - VERSIÓN CORREGIDA CON o24h
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../api/api_service.dart';
import '../database/database_helper.dart';
import '../models/envio_muestra_model.dart';

class EnvioMuestraService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static final Uuid _uuid = Uuid();

  // ✅ MÉTODO CORREGIDO PARA GUARDAR Y SINCRONIZAR
  static Future<bool> guardarEnvioMuestra(EnvioMuestra envio, String? token) async {
    try {
      debugPrint('💾 Iniciando guardado de envío de muestra...');
      
      // 1. Guardar siempre localmente primero
      final savedLocally = await _dbHelper.createEnvioMuestra(envio);
      
      if (!savedLocally) {
        debugPrint('❌ No se pudo guardar envío localmente');
        return false;
      }
      
      debugPrint('✅ Envío guardado localmente con ${envio.detalles.length} muestras');
      
      // 2. Intentar subir al servidor si hay token y conexión
      if (token != null) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            debugPrint('🌐 Intentando sincronizar con servidor...');
            
            // ✅ PREPARAR DATOS CORRECTAMENTE PARA EL SERVIDOR
            final envioDataForServer = _prepararDatosParaServidor(envio);
            
            final serverData = await ApiService.createEnvioMuestra(token, envioDataForServer);
            
            if (serverData != null) {
              // Marcar como sincronizado
              await _dbHelper.marcarEnvioMuestraComoSincronizado(envio.id);
              debugPrint('✅ Envío sincronizado exitosamente con el servidor');
              return true;
            } else {
              debugPrint('⚠️ Error del servidor - Envío quedará pendiente de sincronización');
            }
          } else {
            debugPrint('📵 Sin conexión - Envío quedará pendiente de sincronización');
          }
        } catch (e) {
          debugPrint('⚠️ Error al subir al servidor: $e');
        }
      } else {
        debugPrint('🔑 Sin token - Envío quedará pendiente de sincronización');
      }
      
      return true; // Éxito si al menos se guardó localmente
    } catch (e) {
      debugPrint('💥 Error completo al guardar envío: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA PREPARAR DATOS PARA EL SERVIDOR
  static Map<String, dynamic> _prepararDatosParaServidor(EnvioMuestra envio) {
    final Map<String, dynamic> envioData = {
      'id': envio.id,
      'codigo': envio.codigo,
      'fecha': envio.fecha.toIso8601String().split('T')[0],
      'version': envio.version,
      'lugar_toma_muestras': envio.lugarTomaMuestras,
      'hora_salida': envio.horaSalida,
      'fecha_salida': envio.fechaSalida?.toIso8601String().split('T')[0],
      'temperatura_salida': envio.temperaturaSalida,
      'responsable_toma_id': envio.responsableTomaId,
      'responsable_transporte_id': envio.responsableTransporteId,
      'fecha_llegada': envio.fechaLlegada?.toIso8601String().split('T')[0],
      'hora_llegada': envio.horaLlegada,
      'temperatura_llegada': envio.temperaturaLlegada,
      'lugar_llegada': envio.lugarLlegada,
      'responsable_recepcion_id': envio.responsableRecepcionId,
      'observaciones': envio.observaciones,
      'idsede': envio.idsede,
      'sync_status': 0, // Pendiente hasta confirmar del servidor
    };

    // ✅ AGREGAR DETALLES CORRECTAMENTE
    List<Map<String, dynamic>> detallesData = [];
    for (final detalle in envio.detalles) {
      detallesData.add({
        'id': detalle.id,
        'paciente_id': detalle.pacienteId,
        'numero_orden': detalle.numeroOrden,
        'dm': detalle.dm,
        'hta': detalle.hta,
        'num_muestras_enviadas': detalle.numMuestrasEnviadas,
        'tubo_lila': detalle.tuboLila,
        'tubo_amarillo': detalle.tuboAmarillo,
        'tubo_amarillo_forrado': detalle.tuboAmarilloForrado,
        'orina_esp': detalle.orinaEsp,
        'orina_24h': detalle.orina24h,
        'a': detalle.a,
        'm': detalle.m,
        'oe': detalle.oe,
        'o24h': detalle.o24h, // ✅ CORREGIDO: Usar o24h como está en la BD
        'po': detalle.po,
        'h3': detalle.h3,
        'hba1c': detalle.hba1c,
        'pth': detalle.pth,
        'glu': detalle.glu,
        'crea': detalle.crea,
        'pl': detalle.pl,
        'au': detalle.au,
        'bun': detalle.bun,
        'relacion_crea_alb': detalle.relacionCreaAlb,
        'dcre24h': detalle.dcre24h,
        'alb24h': detalle.alb24h,
        'buno24h': detalle.buno24h,
        'fer': detalle.fer,
        'tra': detalle.tra,
        'fosfat': detalle.fosfat,
        'alb': detalle.alb,
        'fe': detalle.fe,
        'tsh': detalle.tsh,
        'p': detalle.p,
        'ionograma': detalle.ionograma,
        'b12': detalle.b12,
        'acido_folico': detalle.acidoFolico,
        'peso': detalle.peso,
        'talla': detalle.talla,
        'volumen': detalle.volumen,
      });
    }

    envioData['detalles'] = detallesData;
    
    debugPrint('📤 Datos preparados para servidor: ${envioData.keys}');
    debugPrint('📊 Detalles incluidos: ${detallesData.length}');
    
    return envioData;
  }

  // ✅ SINCRONIZAR ENVÍOS PENDIENTES CORREGIDO
  static Future<Map<String, dynamic>> sincronizarEnviosPendientes(String token) async {
    final enviosPendientes = await _dbHelper.getEnviosMuestrasNoSincronizados();
    
    int exitosas = 0;
    int fallidas = 0;
    List<String> errores = [];
    
    debugPrint('📊 Sincronizando ${enviosPendientes.length} envíos pendientes...');
    
    try {
      final hasConnection = await ApiService.verificarConectividad();
      if (!hasConnection) {
        throw Exception('No hay conexión a internet');
      }
      
      for (final envio in enviosPendientes) {
        try {
          debugPrint('🔄 Sincronizando envío ${envio.id}...');
          
          // ✅ USAR EL MÉTODO PREPARADO
          final envioDataForServer = _prepararDatosParaServidor(envio);
          
          final serverData = await ApiService.createEnvioMuestra(token, envioDataForServer);
          
          if (serverData != null) {
            await _dbHelper.marcarEnvioMuestraComoSincronizado(envio.id);
            exitosas++;
            debugPrint('✅ Envío ${envio.id} sincronizado exitosamente');
          } else {
            fallidas++;
            errores.add('Servidor respondió con error para envío ${envio.id}');
            debugPrint('❌ Error del servidor para envío ${envio.id}');
          }
          
          // Pausa entre sincronizaciones
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          fallidas++;
          errores.add('Error en envío ${envio.id}: $e');
          debugPrint('💥 Error sincronizando envío ${envio.id}: $e');
        }
      }
    } catch (e) {
      errores.add('Error general de conexión: $e');
      debugPrint('💥 Error general en sincronización: $e');
    }
    
    debugPrint('📈 Resultado sincronización: $exitosas exitosas, $fallidas fallidas');
    
    return {
      'exitosas': exitosas,
      'fallidas': fallidas,
      'errores': errores,
      'total': enviosPendientes.length
    };
  }

  // Generar ID único para envío
  static String generarIdUnico() {
    return 'env_${_uuid.v4()}';
  }

  // Obtener todos los envíos
  static Future<List<EnvioMuestra>> obtenerTodosLosEnvios() async {
    return await _dbHelper.getAllEnviosMuestras();
  }

  // Obtener envíos pendientes
  static Future<List<EnvioMuestra>> obtenerEnviosPendientes() async {
    return await _dbHelper.getEnviosMuestrasNoSincronizados();
  }

  // Obtener estado de sincronización
  static Future<Map<String, int>> obtenerEstadoSincronizacion() async {
    final todosLosEnvios = await _dbHelper.getAllEnviosMuestras();
    
    int sincronizados = 0;
    int pendientes = 0;
    
    for (final envio in todosLosEnvios) {
      if (envio.syncStatus == 1) {
        sincronizados++;
      } else {
        pendientes++;
      }
    }
    
    debugPrint('📊 Estado envíos: $sincronizados sincronizados, $pendientes pendientes');
    
    return {
      'sincronizados': sincronizados,
      'pendientes': pendientes,
      'total': todosLosEnvios.length
    };
  }
}
