// services/envio_muestra_service.dart - VERSIÓN CORREGIDA CON o24h
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../api/api_service.dart';
import '../database/database_helper.dart';
import '../models/envio_muestra_model.dart';
import '../models/paciente_model.dart'; // ✅ IMPORTAR MODELO PACIENTE

class EnvioMuestraService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static final Uuid _uuid = Uuid();

  // ✅ MÉTODO CORREGIDO PARA GUARDAR Y SINCRONIZAR
  static Future<bool> guardarEnvioMuestra(EnvioMuestra envio, String? token) async {
    try {
      debugPrint('💾 Iniciando guardado de envío de muestra...');
      
      // ✅ PASO 1: VERIFICAR SI HAY PACIENTES OFFLINE Y SINCRONIZARLOS PRIMERO
      if (token != null) {
        final tienePacientesOffline = envio.detalles.any((d) => d.pacienteId.startsWith('offline_'));
        
        if (tienePacientesOffline) {
          debugPrint('⚠️ Detectados pacientes offline en el envío. Intentando sincronizar primero...');
          
          try {
            final hasConnection = await ApiService.verificarConectividad();
            if (hasConnection) {
              // Sincronizar solo los pacientes offline de este envío
              await _sincronizarPacientesDelEnvio(envio, token);
              debugPrint('✅ Pacientes offline sincronizados antes de guardar envío');
            } else {
              debugPrint('📵 Sin conexión - Los pacientes offline se sincronizarán después');
            }
          } catch (e) {
            debugPrint('⚠️ Error sincronizando pacientes offline: $e');
            // Continuar de todas formas, se sincronizará después
          }
        }
      }
      
      // ✅ PASO 2: Guardar siempre localmente primero
      final savedLocally = await _dbHelper.createEnvioMuestra(envio);
      
      if (!savedLocally) {
        debugPrint('❌ No se pudo guardar envío localmente');
        return false;
      }
      
      debugPrint('✅ Envío guardado localmente con ${envio.detalles.length} muestras');
      
      // ✅ PASO 3: Intentar subir al servidor si hay token y conexión
      if (token != null) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            debugPrint('🌐 Intentando sincronizar con servidor...');
            
            // Actualizar referencias offline antes de enviar
            final envioActualizado = await _actualizarReferenciasOffline(envio, token);
            final envioDataForServer = _prepararDatosParaServidor(envioActualizado);
            
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

  // ✅ NUEVO MÉTODO: Sincronizar pacientes offline específicos del envío
  static Future<void> _sincronizarPacientesDelEnvio(EnvioMuestra envio, String token) async {
    for (final detalle in envio.detalles) {
      if (detalle.pacienteId.startsWith('offline_')) {
        await _sincronizarPacienteOffline(detalle.pacienteId, token);
      }
    }
  }

  // ✅ NUEVO MÉTODO: Sincronizar un paciente offline específico
  static Future<Paciente?> _sincronizarPacienteOffline(String pacienteIdOffline, String token) async {
    try {
      debugPrint('🔄 Sincronizando paciente offline: $pacienteIdOffline');
      
      // Buscar el paciente en la BD local
      final paciente = await _dbHelper.getPacienteById(pacienteIdOffline);
      
      if (paciente == null) {
        debugPrint('❌ Paciente no encontrado en BD local: $pacienteIdOffline');
        return null;
      }
      
      // Intentar crear el paciente en el servidor
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
      
      final serverData = await ApiService.createPaciente(token, pacienteData);
      
      if (serverData != null) {
        // Actualizar en BD local con el nuevo ID del servidor
        final pacienteServidor = Paciente.fromJson(serverData);
        await _dbHelper.deletePaciente(pacienteIdOffline); // Eliminar versión offline
        await _dbHelper.upsertPaciente(pacienteServidor); // Insertar versión del servidor
        
        debugPrint('✅ Paciente ${paciente.identificacion} sincronizado: $pacienteIdOffline → ${pacienteServidor.id}');
        return pacienteServidor;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error sincronizando paciente $pacienteIdOffline: $e');
      return null;
    }
  }

  // ✅ MÉTODO PARA ACTUALIZAR REFERENCIAS DE PACIENTES OFFLINE A IDs DEL SERVIDOR
  static Future<EnvioMuestra> _actualizarReferenciasOffline(EnvioMuestra envio, String token) async {
    debugPrint('🔍 Verificando referencias de pacientes offline en envío ${envio.id}...');
    
    List<DetalleEnvioMuestra> detallesActualizados = [];
    
    for (final detalle in envio.detalles) {
      String pacienteIdActualizado = detalle.pacienteId;
      
      // ✅ SI EL PACIENTE TIENE ID OFFLINE, SINCRONIZARLO PRIMERO
      if (detalle.pacienteId.startsWith('offline_')) {
        debugPrint('⚠️ Encontrado paciente offline: ${detalle.pacienteId}');
        
        // Extraer la identificación del paciente del ID offline
        // Formato: offline_timestamp_identificacion_randomSuffix
        final parts = detalle.pacienteId.split('_');
        if (parts.length >= 3) {
          final identificacion = parts[2];
          
          // ✅ INTENTAR SINCRONIZAR EL PACIENTE PRIMERO
          debugPrint('🔄 Sincronizando paciente offline: $identificacion');
          final pacienteServidor = await _sincronizarPacienteOffline(detalle.pacienteId, token);
          
          if (pacienteServidor != null) {
            pacienteIdActualizado = pacienteServidor.id;
            debugPrint('✅ Paciente sincronizado: ${detalle.pacienteId} → $pacienteIdActualizado');
            
            // Actualizar también en la BD local
            await _dbHelper.actualizarPacienteIdEnDetalle(detalle.id, pacienteIdActualizado);
          } else {
            debugPrint('❌ No se pudo sincronizar paciente offline: $identificacion');
            throw Exception('No se pudo sincronizar el paciente $identificacion');
          }
        }
      }
      
      // Crear detalle actualizado
      detallesActualizados.add(
        DetalleEnvioMuestra(
          id: detalle.id,
          envioMuestraId: detalle.envioMuestraId,
          pacienteId: pacienteIdActualizado, // ✅ ID ACTUALIZADO
          numeroOrden: detalle.numeroOrden,
          dm: detalle.dm,
          hta: detalle.hta,
          numMuestrasEnviadas: detalle.numMuestrasEnviadas,
          tuboLila: detalle.tuboLila,
          tuboAmarillo: detalle.tuboAmarillo,
          tuboAmarilloForrado: detalle.tuboAmarilloForrado,
          orinaEsp: detalle.orinaEsp,
          orina24h: detalle.orina24h,
          a: detalle.a,
          m: detalle.m,
          oe: detalle.oe,
          o24h: detalle.o24h,
          po: detalle.po,
          h3: detalle.h3,
          hba1c: detalle.hba1c,
          pth: detalle.pth,
          glu: detalle.glu,
          crea: detalle.crea,
          pl: detalle.pl,
          au: detalle.au,
          bun: detalle.bun,
          relacionCreaAlb: detalle.relacionCreaAlb,
          dcre24h: detalle.dcre24h,
          alb24h: detalle.alb24h,
          buno24h: detalle.buno24h,
          fer: detalle.fer,
          tra: detalle.tra,
          fosfat: detalle.fosfat,
          alb: detalle.alb,
          fe: detalle.fe,
          tsh: detalle.tsh,
          p: detalle.p,
          ionograma: detalle.ionograma,
          b12: detalle.b12,
          acidoFolico: detalle.acidoFolico,
          peso: detalle.peso,
          talla: detalle.talla,
          volumen: detalle.volumen,
          microo: detalle.microo,
          creaori: detalle.creaori,
        ),
      );
    }
    
    // Retornar envío con detalles actualizados
    return EnvioMuestra(
      id: envio.id,
      codigo: envio.codigo,
      fecha: envio.fecha,
      version: envio.version,
      lugarTomaMuestras: envio.lugarTomaMuestras,
      horaSalida: envio.horaSalida,
      fechaSalida: envio.fechaSalida,
      temperaturaSalida: envio.temperaturaSalida,
      responsableTomaId: envio.responsableTomaId,
      responsableTransporteId: envio.responsableTransporteId,
      fechaLlegada: envio.fechaLlegada,
      horaLlegada: envio.horaLlegada,
      temperaturaLlegada: envio.temperaturaLlegada,
      lugarLlegada: envio.lugarLlegada,
      responsableRecepcionId: envio.responsableRecepcionId,
      observaciones: envio.observaciones,
      idsede: envio.idsede,
      detalles: detallesActualizados, // ✅ DETALLES CON IDs ACTUALIZADOS
      syncStatus: envio.syncStatus,
    );
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
        'microo': detalle.microo,
        'creaori': detalle.creaori,
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
          
          // ✅ PASO 1: VERIFICAR Y ACTUALIZAR IDs DE PACIENTES OFFLINE
          final envioActualizado = await _actualizarReferenciasOffline(envio, token);
          
          // ✅ PASO 2: USAR EL MÉTODO PREPARADO CON DATOS ACTUALIZADOS
          final envioDataForServer = _prepararDatosParaServidor(envioActualizado);
          
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
 // 🆕 MÉTODO PARA ELIMINAR ENVÍO
  static Future<bool> eliminarEnvio(String envioId) async {
    try {
      debugPrint('🗑️ Iniciando eliminación de envío: $envioId');
      
      final db = DatabaseHelper.instance;
      
      // 1. Verificar que el envío existe
      final envios = await db.getAllEnviosMuestras();
      final envioExiste = envios.any((e) => e.id == envioId);
      
      if (!envioExiste) {
        debugPrint('❌ Envío no encontrado: $envioId');
        return false;
      }
      
      // 2. Obtener información del envío antes de eliminar
      final envio = envios.firstWhere((e) => e.id == envioId);
      debugPrint('📋 Eliminando envío: ${envio.codigo} con ${envio.detalles.length} muestras');
      
      // 3. Eliminar de la base de datos local
      final database = await db.database;
      
      await database.transaction((txn) async {
        // Eliminar detalles primero (por la foreign key)
        final detallesEliminados = await txn.delete(
          'detalle_envio_muestras',
          where: 'envio_muestra_id = ?',
          whereArgs: [envioId],
        );
        
        debugPrint('🗑️ Detalles eliminados: $detallesEliminados');
        
        // Eliminar envío principal
        final envioEliminado = await txn.delete(
          'envio_muestras',
          where: 'id = ?',
          whereArgs: [envioId],
        );
        
        debugPrint('🗑️ Envío eliminado: $envioEliminado');
        
        if (envioEliminado == 0) {
          throw Exception('No se pudo eliminar el envío de la base de datos');
        }
      });
      
      debugPrint('✅ Envío $envioId eliminado exitosamente de la base de datos local');
      
      // 4. Si el envío estaba sincronizado, intentar eliminarlo del servidor
      if (envio.syncStatus == 1) {
        debugPrint('🌐 Envío estaba sincronizado, intentando eliminar del servidor...');
        
        try {
          // Aquí podrías agregar la llamada al API para eliminar del servidor
          // Por ahora solo registramos que estaba sincronizado
          debugPrint('ℹ️ Nota: El envío estaba sincronizado con el servidor');
          debugPrint('ℹ️ Considera implementar eliminación en servidor si es necesario');
        } catch (e) {
          debugPrint('⚠️ Error al comunicarse con servidor para eliminación: $e');
          // No fallar la operación local por error del servidor
        }
      }
      
      return true;
      
    } catch (e) {
      debugPrint('💥 Error al eliminar envío $envioId: $e');
      debugPrint('💥 Stack trace: ${StackTrace.current}');
      return false;
    }
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
