import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api_service.dart';
import '../database/database_helper.dart';
import '../models/brigada_model.dart';
import '../models/paciente_model.dart';

class BrigadaService {
  static const String baseUrl = 'http://fnpvi.nacerparavivir.org/api';

  // Crear brigada (offline/online)
 static Future<bool> crearBrigada({
    required Brigada brigada,
    required List<String> pacientesIds,
    String? token,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // 1. Guardar localmente
      final savedLocally = await dbHelper.createBrigada(brigada);
      if (!savedLocally) {
        return false;
      }
      
      // 2. Asignar pacientes localmente
      if (pacientesIds.isNotEmpty) {
        await dbHelper.asignarPacientesABrigada(brigada.id, pacientesIds);
      }
      
      // 3. Intentar sincronizar con servidor si hay token
      if (token != null) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            // 🆕 PASO A: Identificar pacientes offline y cargar sus datos completos
            List<Map<String, dynamic>> pacientesData = [];
            for (String pacienteId in pacientesIds) {
              if (pacienteId.startsWith('offline_')) {
                final paciente = await dbHelper.getPacienteById(pacienteId);
                if (paciente != null) {
                  pacientesData.add({
                    'id': paciente.id,
                    'identificacion': paciente.identificacion,
                    'nombre': paciente.nombre,
                    'apellido': paciente.apellido,
                    'fecnacimiento': paciente.fecnacimiento.toIso8601String().split('T')[0],
                    'genero': paciente.genero,
                    'idsede': paciente.idsede,
                    'latitud': paciente.latitud,
                    'longitud': paciente.longitud,
                  });
                }
              }
            }

            // PASO B: Obtener medicamentos de cada paciente
            Map<String, List<Map<String, dynamic>>> medicamentosPorPaciente = {};
            
            for (String pacienteId in pacientesIds) {
              final medicamentos = await dbHelper.getMedicamentosDePacienteEnBrigada(
                brigada.id, 
                pacienteId
              );
              
              if (medicamentos.isNotEmpty) {
                List<Map<String, dynamic>> medicamentosLimpios = medicamentos.map((m) => {
                  'medicamento_id': m['medicamento_id']?.toString() ?? '',
                  'dosis': m['dosis']?.toString() ?? '',
                  'cantidad': (m['cantidad'] is String) 
                      ? int.tryParse(m['cantidad']) ?? 0 
                      : m['cantidad'] ?? 0,
                  'indicaciones': m['indicaciones']?.toString() ?? '',
                }).toList();
                
                medicamentosPorPaciente[pacienteId] = medicamentosLimpios;
              }
            }
            
            // PASO C: Construir payload con pacientes_data para resolver IDs offline
            final brigadaData = brigada.toServerJson(
              medicamentosPorPaciente: medicamentosPorPaciente,
              pacientesData: pacientesData, // 🆕
            );
            
            final response = await http.post(
              Uri.parse('$baseUrl/brigadas'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(brigadaData),
            ).timeout(const Duration(seconds: 30));
            
            if (response.statusCode == 200 || response.statusCode == 201) {
              final responseBody = jsonDecode(response.body);
              
              // ✅ Marcar sincronizada PRIMERO (el servidor ya la creó)
              await dbHelper.marcarBrigadaComoSincronizada(brigada.id);
              
              // ✅ FIX: verificación de tipo segura (PHP [] vacío ≠ Map en Dart)
              final rawMapa = responseBody['mapa_pacientes'];
              if (rawMapa is Map) {
                final mapaPacientes = Map<String, dynamic>.from(rawMapa);
                for (final entry in mapaPacientes.entries) {
                  final oldId = entry.key;
                  final newId = entry.value?.toString() ?? '';
                  if (newId.isNotEmpty) {
                    await dbHelper.actualizarIdPacienteEnCascada(oldId, newId);
                  }
                }
              }
              
              return true;
            }
          }
        } catch (e) {
        }
      }
      
      return true; // Éxito si se guardó localmente
    } catch (e) {
      return false;
    }
  }



  // Subir brigada al servidor
  static Future<Map<String, dynamic>?> _subirBrigadaAlServidor(Brigada brigada, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/brigadas'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(brigada.toServerJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Asignar pacientes a brigada
  static Future<bool> asignarPacientesABrigada({
    required String brigadaId,
    required List<String> pacientesIds,
    String? token,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // 1. Guardar localmente
      final savedLocally = await dbHelper.asignarPacientesABrigada(brigadaId, pacientesIds);
      
      if (!savedLocally) {
        return false;
      }
      
      // 2. Intentar sincronizar con servidor
      if (token != null) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
                        await _sincronizarAsignacionPacientes(brigadaId, pacientesIds, token);
          }
        } catch (e) {
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Sincronizar asignación de pacientes con servidor
  static Future<void> _sincronizarAsignacionPacientes(String brigadaId, List<String> pacientesIds, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/brigadas/$brigadaId/pacientes'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'pacientes': pacientesIds}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
      }
    } catch (e) {
    }
  }

  // Asignar medicamentos a paciente en brigada
  static Future<bool> asignarMedicamentosAPaciente({
     required String brigadaId,
    required String pacienteId,
    required List<Map<String, dynamic>> medicamentos,
    String? token,
  }) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // 1. Guardar localmente
      final savedLocally = await dbHelper.asignarMedicamentosAPacienteEnBrigada(
        brigadaId: brigadaId,
        pacienteId: pacienteId,
        medicamentos: medicamentos,
      );
      
      if (!savedLocally) {
        return false;
      }
      
      // 2. Sincronizar si hay conexión
      if (token != null) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            // Preparar datos para enviar
            final requestData = {
              'brigada_id': brigadaId,
              'paciente_id': pacienteId,
              'medicamentos': medicamentos.map((m) => {
                'medicamento_id': m['medicamento_id'],
                'dosis': m['dosis'] ?? '',
                'cantidad': m['cantidad'] ?? 0,
                'indicaciones': m['indicaciones'] ?? '',
              }).toList(),
            };
            
            final response = await http.post(
              Uri.parse('$baseUrl/brigadas/$brigadaId/pacientes/$pacienteId/medicamentos'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestData),
            ).timeout(const Duration(seconds: 30));
            
            if (response.statusCode == 200) {
            }
          }
        } catch (e) {
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Sincronizar medicamentos de paciente con servidor
  static Future<void> _sincronizarMedicamentosPaciente(
    String brigadaId, 
    String pacienteId, 
    List<Map<String, dynamic>> medicamentos, 
    String token
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/brigadas/$brigadaId/pacientes/$pacienteId/medicamentos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'medicamentos': medicamentos}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
      }
    } catch (e) {
    }
  }

// services/brigada_service.dart - MÉTODO CORREGIDO
static Future<Map<String, dynamic>> sincronizarBrigadasPendientes(String token) async {
  try {
    final dbHelper = DatabaseHelper.instance;
    final brigadasPendientes = await dbHelper.getBrigadasNoSincronizadas();
    
    int exitosas = 0;
    int fallidas = 0;
    List<String> errores = [];
    
    // 🚀 Verificación rápida de red (sin timeout de 25s)
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception('No hay conexión a internet');
    }
    
    for (final brigada in brigadasPendientes) {
      try {
        // 🆕 PASO 1: Recargar lista de pacientes desde brigada_paciente (ya actualizada por cascada)
        final pacientesActualizados = await dbHelper.getPacientesDeBrigada(brigada.id);
        final idsActualizados = pacientesActualizados.map((p) => p.id).toList();

        // 🆕 PASO 2: Identificar pacientes offline y cargar sus datos completos
        List<Map<String, dynamic>> pacientesData = [];
        for (final paciente in pacientesActualizados) {
          if (paciente.id.startsWith('offline_')) {
            pacientesData.add({
              'id': paciente.id,
              'identificacion': paciente.identificacion,
              'nombre': paciente.nombre,
              'apellido': paciente.apellido,
              'fecnacimiento': paciente.fecnacimiento.toIso8601String().split('T')[0],
              'genero': paciente.genero,
              'idsede': paciente.idsede,
              'latitud': paciente.latitud,
              'longitud': paciente.longitud,
            });
          }
        }

        // 🆕 PASO 3: Obtener medicamentos de cada paciente
        Map<String, List<Map<String, dynamic>>> medicamentosPorPaciente = {};
        for (String pacienteId in idsActualizados) {
          final medicamentos = await dbHelper.getMedicamentosDePacienteEnBrigada(
            brigada.id, 
            pacienteId
          );
          
          if (medicamentos.isNotEmpty) {
            List<Map<String, dynamic>> medicamentosLimpios = medicamentos.map((m) => {
              'medicamento_id': m['medicamento_id']?.toString() ?? '',
              'dosis': m['dosis']?.toString() ?? '',
              'cantidad': (m['cantidad'] is String) 
                  ? int.tryParse(m['cantidad']) ?? 0 
                  : m['cantidad'] ?? 0,
              'indicaciones': m['indicaciones']?.toString() ?? '',
            }).toList();
            
            medicamentosPorPaciente[pacienteId] = medicamentosLimpios;
          }
        }

        // 🆕 PASO 4: Construir brigada con IDs actualizados y datos offline
        // Usamos la brigada con los IDs ya actualizados (no los del campo JSON que puede estar desactualizado)
        final brigadaConIds = brigada.copyWith(pacientesIds: idsActualizados);
        
        final brigadaData = brigadaConIds.toServerJson(
          medicamentosPorPaciente: medicamentosPorPaciente,
          pacientesData: pacientesData, // 🆕 datos completos para que el backend resuelva offline IDs
        );
        
        // PASO 5: Subir brigada completa al servidor
        final response = await http.post(
          Uri.parse('$baseUrl/brigadas'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(brigadaData),
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseBody = jsonDecode(response.body);
          
          // ✅ PRIMERO marcar como sincronizada — el servidor ya la creó
          // Esto debe ocurrir ANTES de procesar el mapa para evitar duplicados
          // aunque falle algo más adelante
          await dbHelper.marcarBrigadaComoSincronizada(brigada.id);
          exitosas++;
          
          // PASO 6: Usar mapa_pacientes para actualizar IDs locales
          // ✅ FIX: usar 'is Map' en lugar de cast duro (PHP devuelve [] cuando está vacío)
          final rawMapa = responseBody['mapa_pacientes'];
          if (rawMapa is Map) {
            final mapaPacientes = Map<String, dynamic>.from(rawMapa);
            if (mapaPacientes.isNotEmpty) {
              for (final entry in mapaPacientes.entries) {
                final oldId = entry.key;
                final newId = entry.value?.toString() ?? '';
                if (newId.isNotEmpty) {
                  await dbHelper.actualizarIdPacienteEnCascada(oldId, newId);
                }
              }
            }
          }
          // Si rawMapa es List (PHP array vacío serializado como []) → no hay nada que mapear
          
        } else {
          fallidas++;
          String errorMsg = 'Servidor respondió con error ${response.statusCode}: ${response.body}';
          errores.add(errorMsg);
        }
        
      } catch (e) {
        fallidas++;
        String errorMsg = 'Error en brigada ${brigada.id}: $e';
        errores.add(errorMsg);
      }
    }
    
    return {
      'exitosas': exitosas,
      'fallidas': fallidas,
      'errores': errores,
      'total': brigadasPendientes.length,
    };
    
  } catch (e) {
    return {
      'exitosas': 0,
      'fallidas': 1,
      'errores': ['Error general: $e'],
      'total': 1,
    };
  }
}



  // Obtener brigadas desde servidor
  static Future<List<Brigada>> obtenerBrigadasDesdeServidor(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/brigadas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        List<dynamic> brigadasData = [];
        
        if (responseData is List) {
          brigadasData = responseData;
        } else if (responseData is Map && responseData['data'] != null) {
          brigadasData = responseData['data'];
        }

        final brigadas = brigadasData.map((data) => Brigada.fromJson(data)).toList();
        return brigadas;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Eliminar brigada
  static Future<bool> eliminarBrigada(String brigadaId, {String? token}) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      
      // 1. Eliminar localmente
      final deletedLocally = await dbHelper.deleteBrigada(brigadaId);
      
      if (!deletedLocally) {
        return false;
      }
      
      // 2. Intentar eliminar del servidor
      if (token != null) {
        try {
          final hasConnection = await ApiService.verificarConectividad();
          
          if (hasConnection) {
            final response = await http.delete(
              Uri.parse('$baseUrl/brigadas/$brigadaId'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            ).timeout(const Duration(seconds: 30));
            
            if (response.statusCode == 200) {
            }
          }
        } catch (e) {
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
