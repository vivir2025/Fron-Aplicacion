import 'package:flutter/foundation.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import 'package:fnpv_app/models/visita_model.dart';

class SincronizacionService {
  
  static Future<bool> guardarVisita(Visita visita, String? token) async {
    try {
      // 1. Guardar siempre en SQLite primero
      final dbHelper = DatabaseHelper.instance;
      final savedLocally = await dbHelper.createVisita(visita);
      
      if (!savedLocally) {
        debugPrint('❌ No se pudo guardar localmente');
        return false;
      }
      
      debugPrint('✅ Visita guardada localmente');
      
      // 2. Intentar subir al servidor si hay token
      if (token != null) {
        try {
          // Verificar conectividad antes de intentar sincronizar
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            // Usar toServerJson() para el formato correcto
            final serverData = await ApiService.guardarVisita(
              visita.toServerJson(),
              token
            );
            
            if (serverData != null) {
              // Marcar como sincronizada
              await dbHelper.marcarVisitaComoSincronizada(visita.id);
              debugPrint('✅ Visita sincronizada con servidor. Ahora intentando sincronizar geolocalización del paciente...');
              // --- AÑADIR ESTA LÍNEA ---
              // Después de sincronizar la visita, intenta sincronizar los datos pendientes del paciente.
              await sincronizarPacientesPendientes(token);

              debugPrint('✅ Visita sincronizada con servidor');
              return true;
            }
          } else {
            debugPrint('📵 Sin conexión a internet - Visita quedará pendiente');
          }
        } catch (e) {
          debugPrint('⚠️ Error al subir al servidor: $e');
          // La visita ya está guardada localmente, no es un error crítico
        }
      } else {
        debugPrint('🔑 No hay token de autenticación - Visita quedará pendiente');
      }
      
      return true; // Éxito si al menos se guardó localmente
    } catch (e) {
      debugPrint('💥 Error completo al guardar visita: $e');
      return false;
    }
  }

  
  
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
          // Usar toServerJson() para el formato correcto
          final serverData = await ApiService.guardarVisita(
            visita.toServerJson(),
            token
          );
          
          if (serverData != null) {
            await dbHelper.marcarVisitaComoSincronizada(visita.id);
            exitosas++;
            debugPrint('✅ Visita ${visita.id} sincronizada');
          } else {
            fallidas++;
            errores.add('Servidor respondió con error para visita ${visita.id}');
            debugPrint('❌ Falló visita ${visita.id}');
          }
          
          // Pequeña pausa entre sincronizaciones para no saturar
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          fallidas++;
          errores.add('Error en visita ${visita.id}: $e');
          debugPrint('💥 Error sincronizando visita ${visita.id}: $e');
        }
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

  static Future<Map<String, dynamic>> sincronizarPacientesPendientes(String token) async {
    final dbHelper = DatabaseHelper.instance;
    final pacientesPendientes = await dbHelper.getUnsyncedPacientes();

    int exitosas = 0;
    int fallidas = 0;
    List<String> errores = [];

    debugPrint('📊 Sincronizando ${pacientesPendientes.length} pacientes pendientes...');

    for (final paciente in pacientesPendientes) {
      try {
        debugPrint('📡 Sincronizando geolocalización del paciente ${paciente.id}: latitud=${paciente.latitud}, longitud=${paciente.longitud}');
        
        final serverData = await ApiService.updatePaciente(
          token, 
          paciente.id, 
          {
            'latitud': paciente.latitud, 
            'longitud': paciente.longitud
          }
        );
        
        if (serverData != null) {
          await dbHelper.markPacientesAsSynced([paciente.id]);
          exitosas++;
          debugPrint('✅ Geolocalización del paciente ${paciente.id} sincronizada exitosamente');
          // Add a specific log message for successful geolocalization update
          debugPrint('🌍 Geolocalización del paciente ${paciente.id} actualizada en el backend.');
        } else {
          fallidas++;
          errores.add('Servidor respondió con error para paciente ${paciente.id}');
          debugPrint('❌ Falló paciente ${paciente.id}');
        }
      } catch (e) {
        fallidas++;
        errores.add('Error en paciente ${paciente.id}: $e');
        debugPrint('💥 Error sincronizando paciente ${paciente.id}: $e');
      }
    }

    return {
      'exitosas': exitosas,
      'fallidas': fallidas,
      'errores': errores,
    };
  }
}