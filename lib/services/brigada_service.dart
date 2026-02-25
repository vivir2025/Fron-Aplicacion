import 'dart:convert';
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
            // ✅ OBTENER MEDICAMENTOS DE CADA PACIENTE
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
                  'indicaciones': m['indicaciones']?.toString() ?? '', // ✅ INCLUIR INDICACIONES
                }).toList();
                
                medicamentosPorPaciente[pacienteId] = medicamentosLimpios;
              }
            }
            
            // ✅ USAR EL MÉTODO CORREGIDO
            final brigadaData = brigada.toServerJson(
              medicamentosPorPaciente: medicamentosPorPaciente,
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
              await dbHelper.marcarBrigadaComoSincronizada(brigada.id);
              return true;
            } else {
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
    
    // Verificar conectividad
    final hasConnection = await ApiService.verificarConectividad();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }
    
    for (final brigada in brigadasPendientes) {
      try {
        // 🆕 OBTENER MEDICAMENTOS DE CADA PACIENTE
        Map<String, List<Map<String, dynamic>>> medicamentosPorPaciente = {};
        
        if (brigada.pacientesIds != null && brigada.pacientesIds!.isNotEmpty) {
          for (String pacienteId in brigada.pacientesIds!) {
            final medicamentos = await dbHelper.getMedicamentosDePacienteEnBrigada(
              brigada.id, 
              pacienteId
            );
            
            if (medicamentos.isNotEmpty) {
              // 🔧 LIMPIAR DATOS - Solo campos que existen en BD
              List<Map<String, dynamic>> medicamentosLimpios = medicamentos.map((m) => {
                'medicamento_id': m['medicamento_id']?.toString() ?? '',
                'dosis': m['dosis']?.toString() ?? '',
                'cantidad': (m['cantidad'] is String) 
                    ? int.tryParse(m['cantidad']) ?? 0 
                    : m['cantidad'] ?? 0,
                // 🚫 NO incluir 'indicaciones' si no existe en la BD
              }).toList();
              
              medicamentosPorPaciente[pacienteId] = medicamentosLimpios;
            }
          }
        }
        
        // ✅ USAR EL MÉTODO CORRECTO DEL MODELO
        final brigadaData = brigada.toServerJson(
          medicamentosPorPaciente: medicamentosPorPaciente,
        );
        
        // 2. Subir brigada completa al servidor
        final response = await http.post(
          Uri.parse('$baseUrl/brigadas'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(brigadaData),
        ).timeout(const Duration(seconds: 30));
        
        // 🔧 VERIFICAR CORRECTAMENTE LA RESPUESTA
        if (response.statusCode == 200 || response.statusCode == 201) {
          // ✅ Solo marcar como sincronizada si el servidor respondió OK
          await dbHelper.marcarBrigadaComoSincronizada(brigada.id);
          exitosas++;
        } else {
          // ❌ Error del servidor - NO marcar como sincronizada
          fallidas++;
          String errorMsg = 'Servidor respondió con error ${response.statusCode}: ${response.body}';
          errores.add(errorMsg);
        }
        
        // Pausa entre sincronizaciones
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        fallidas++;
        String errorMsg = 'Error en brigada ${brigada.id}: $e';
        errores.add(errorMsg);
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
