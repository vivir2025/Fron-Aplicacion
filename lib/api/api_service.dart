import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';


class ApiService {
  static const String baseUrl = 'http://fnpvi.nacerparavivir.org/api';

  // Método privado para construir headers
  static Map<String, String> _buildHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  

  static dynamic _handleResponse(http.Response response) {
  final statusCode = response.statusCode;
  final responseBody = response.body;
  
  debugPrint('📡 Respuesta HTTP $statusCode: ${response.request?.url}');
  
  if (statusCode >= 200 && statusCode < 300) {
    try {
      return jsonDecode(responseBody);
    } catch (e) {
      debugPrint('❌ Error decodificando JSON: $e');
      return responseBody; // Devuelve el cuerpo sin decodificar si no es JSON
    }
  }
  
  // Manejo específico de errores conocidos
  switch(statusCode) {
    case 400:
      throw Exception('Solicitud incorrecta');
    case 401:
      throw Exception('Autenticación requerida');
    case 403:
      throw Exception('No autorizado');
    case 404:
      throw Exception('Recurso no encontrado');
    case 500:
      throw Exception('Error interno del servidor');
    default:
      throw Exception('Error $statusCode: ${responseBody.length > 100 ? responseBody.substring(0, 100) + '...' : responseBody}');
  }
}
 static Future<Map<String, dynamic>> login(String usuario, String contrasena) async {
  try {
    // Verificar conexión primero
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No hay conexión a internet');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario': usuario, 'contrasena': contrasena}),
    ).timeout(const Duration(seconds: 10)); // Añadir timeout
    
    print('Respuesta del login: ${response.body}');
    return _handleResponse(response) as Map<String, dynamic>;
  } on SocketException catch (e) {
    print('Error de conexión: $e');
    throw Exception('No se pudo conectar al servidor. Verifica tu conexión a internet.');
  } on TimeoutException catch (e) {
    print('Tiempo de espera agotado: $e');
    throw Exception('El servidor no respondió a tiempo. Intenta nuevamente.');
  } catch (e) {
    print('Error en login: $e');
    rethrow;
  }
}
  // Logout method
  static Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: _buildHeaders(token),
    );
    _handleResponse(response);
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/perfil'),
      headers: _buildHeaders(token),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  // Update profile
  static Future<Map<String, dynamic>> updateProfile(
    String token, {
    String? nombre,
    String? correo,
    String? contrasenaActual,
    String? contrasenaNueva, String? sedeId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/actualizar-perfil'),
      headers: _buildHeaders(token),
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena_actual': contrasenaActual,
        'contrasena_nueva': contrasenaNueva,
      }),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }
// Modificar en ApiService

static Future<Map<String, dynamic>?> guardarVisita(Map<String, dynamic> visitaData, String token) async {
  try {
    debugPrint('📤 Enviando visita al servidor...');
    debugPrint('🔑 Token presente: ${token.isNotEmpty}');
    debugPrint('📊 Datos de visita: ${visitaData['id']}');
    
    // Asegurar que medicamentos sea un string
    if (visitaData['medicamentos'] != null && visitaData['medicamentos'] is! String) {
      visitaData['medicamentos'] = jsonEncode(visitaData['medicamentos']);
    }
    
    // Limpiar datos innecesarios
    final Map<String, dynamic> datosLimpiados = Map.from(visitaData);
    
    // Eliminar campos que no necesita el servidor
    datosLimpiados.remove('sync_status');
    datosLimpiados.remove('created_at');
    datosLimpiados.remove('updated_at');
    
    debugPrint('📋 Datos limpiados: ${datosLimpiados.length} campos');
    debugPrint('📄 Payload completo: ${jsonEncode(datosLimpiados)}');
    
    final url = Uri.parse('${ApiService.baseUrl}/visitas');
    
    debugPrint('🌐 URL completa: $url');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(datosLimpiados),
    );
    
    debugPrint('📥 Respuesta del servidor: ${response.statusCode}');
    debugPrint('📄 Respuesta completa: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      debugPrint('❌ Error del servidor: ${response.statusCode}');
      debugPrint('📄 Error detallado: ${response.body}');
      throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    debugPrint('💥 Excepción al guardar visita: $e');
    debugPrint('🔍 Tipo de error: ${e.runtimeType}');
    return null;
  }
}


// Corregir también el método de verificación
static Future<bool> verificarSaludServidor() async {
  try {
    debugPrint('🔍 Verificando disponibilidad del servidor...');
    
    // Ahora probamos con el endpoint correcto
    final response = await http.get(
      Uri.parse('$baseUrl/health'),  // ← Usar /health ahora que existe
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    
    // Consideramos éxito cualquier respuesta 2xx
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('✅ Servidor disponible');
      return true;
    }
    
    debugPrint('⚠️ Servidor respondió con código: ${response.statusCode}');
    return false;
  } catch (e) {
    debugPrint('❌ Error verificando servidor: ${e.toString()}');
    return false;
  }
}
  static Future<bool> verificarConectividad() async {
  try {
    debugPrint('🔄 Verificando conectividad...');
    
    // 1. Primero verifica si hay conexión de red básica
    final hasNetwork = await Connectivity().checkConnectivity() != ConnectivityResult.none;
    if (!hasNetwork) {
      debugPrint('📵 No hay conexión de red');
      return false;
    }

    // 2. Verificar acceso a Internet (ping a servidor confiable)
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        debugPrint('🌐 Sin acceso a Internet');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Falló el ping a Internet: $e');
      return false;
    }
    

    // 3. Verificar endpoint específico del API (con timeout generoso)
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 25)); // Aumentamos timeout

    // Solo considerar como exitoso si es 200
    if (response.statusCode == 200) {
      debugPrint('✅ Servidor disponible');
      return true;
    }

    debugPrint('⚠️ Servidor respondió con código: ${response.statusCode}');
    return false;
  } catch (e) {
    debugPrint('💥 Error en verificación de conectividad: $e');
    return false;
  }
}


  // Métodos para pacientes
  static Future<List<dynamic>> getPacientes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pacientes'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    throw Exception('Formato de respuesta inesperado');
  }

  static Future<Map<String, dynamic>> createPaciente(String token, Map<String, dynamic> pacienteData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pacientes'),
      headers: _buildHeaders(token),
      body: jsonEncode(pacienteData),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updatePaciente(String token, String id, Map<String, dynamic> pacienteData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/pacientes/$id'),
      headers: _buildHeaders(token),
      body: jsonEncode(pacienteData),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<void> deletePaciente(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/pacientes/$id'),
      headers: _buildHeaders(token),
    );
    _handleResponse(response);
  }

  static Future<List<dynamic>> getSedes(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/sedes'),
    headers: _buildHeaders(token),
  );
  
  final decoded = _handleResponse(response);

  // Si la respuesta es un mapa con 'data'
  if (decoded is Map && decoded.containsKey('data')) {
    return decoded['data'] as List;
  }
  // Si la respuesta es una lista directamente
  if (decoded is List) {
    return decoded;
  }
  // Si la respuesta es un mapa pero no tiene 'data', intenta convertir los valores en lista
  if (decoded is Map) {
    return decoded.values.toList();
  }
  throw Exception('Formato de respuesta inesperado para sedes');
}

    static Future<Map<String, dynamic>> actualizarPaciente(String token, String id, Map<String, dynamic> pacienteData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pacientes/$id'),
        headers: _buildHeaders(token),
        body: jsonEncode(pacienteData),
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error al actualizar paciente: $e');
      rethrow;
    }
  }


  static Future<Map<String, dynamic>?> updatePacienteCoordenadas(
  String token, 
  String pacienteId, 
  double latitud, 
  double longitud
) async {
  try {
    debugPrint('📍 Actualizando coordenadas del paciente $pacienteId');
    
    final response = await http.put(
      Uri.parse('$baseUrl/pacientes/$pacienteId/coordenadas'),
      headers: _buildHeaders(token),
      body: jsonEncode({
        'latitud': latitud,
        'longitud': longitud,
      }),
    );
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ Coordenadas actualizadas en servidor');
      return responseData;
    } else {
      debugPrint('❌ Error actualizando coordenadas: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('❌ Excepción actualizando coordenadas: $e');
    return null;
  }
}
// api/api_service.dart - VALIDACIÓN MEJORADA
static Future<Map<String, dynamic>?> createEnvioMuestra(
  String token, 
  Map<String, dynamic> envioData
) async {
  try {
    debugPrint('📤 Enviando envío de muestras al servidor...');
    
    // ✅ VALIDAR LONGITUD DE IDs ANTES DE ENVIAR
    if (envioData['id'] != null && envioData['id'].toString().length > 36) {
      debugPrint('⚠️ ID de envío demasiado largo, truncando...');
      envioData['id'] = envioData['id'].toString().substring(0, 36);
    }
    
    if (envioData['detalles'] is List) {
      final detalles = envioData['detalles'] as List;
      for (int i = 0; i < detalles.length; i++) {
        if (detalles[i]['id'] != null && detalles[i]['id'].toString().length > 20) {
          debugPrint('⚠️ ID de detalle $i demasiado largo, truncando...');
          detalles[i]['id'] = detalles[i]['id'].toString().substring(0, 20);
        }
      }
    }
    
    debugPrint('📋 Payload validado: ${jsonEncode(envioData)}');
    
    final url = Uri.parse('${ApiService.baseUrl}/envio-muestras');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(envioData),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('📥 Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ Envío de muestras creado exitosamente');
      return responseData;
    } else {
      debugPrint('❌ Error del servidor: ${response.statusCode}');
      debugPrint('📄 Respuesta: ${response.body}');
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('💥 Excepción al crear envío de muestras: $e');
    rethrow;
  }
}


// Obtener responsables
static Future<List<dynamic>> getResponsables(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/responsables'),
      headers: _buildHeaders(token),
    );
    
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo responsables: $e');
    return [];
  }
}

// Obtener envíos por sede
static Future<List<dynamic>> getEnviosPorSede(String token, String sedeId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/envio-muestras/sede/$sedeId'),
      headers: _buildHeaders(token),
    );
    
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    }
    
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo envíos por sede: $e');
    return [];
  }
}

// ==================== MÉTODOS PARA BRIGADAS ====================

// Crear brigada
static Future<Map<String, dynamic>?> createBrigada(
  Map<String, dynamic> brigadaData,
  String token,
) async {
  try {
    debugPrint('📤 Enviando brigada al servidor...');
    debugPrint('📋 Datos de brigada: ${brigadaData['tema']}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/brigadas'),
      headers: _buildHeaders(token),
      body: jsonEncode(brigadaData),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('📥 Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ Brigada creada exitosamente en servidor');
      return responseData;
    } else {
      debugPrint('❌ Error del servidor: ${response.statusCode}');
      debugPrint('📄 Respuesta: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('💥 Excepción al crear brigada: $e');
    return null;
  }
}

// Obtener brigadas
static Future<List<dynamic>> getBrigadas(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/brigadas'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    throw Exception('Formato de respuesta inesperado');
  } catch (e) {
    debugPrint('❌ Error obteniendo brigadas: $e');
    return [];
  }
}

// Asignar pacientes a brigada
static Future<Map<String, dynamic>?> assignPacientesToBrigada(
  String brigadaId,
  List<String> pacientesIds,
  String token,
) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/brigadas/$brigadaId/pacientes'),
      headers: _buildHeaders(token),
      body: jsonEncode({'pacientes': pacientesIds}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error asignando pacientes a brigada: $e');
    return null;
  }
}

// Asignar medicamentos a paciente en brigada
static Future<Map<String, dynamic>?> assignMedicamentosToPacienteInBrigada(
  String brigadaId,
  String pacienteId,
  List<Map<String, dynamic>> medicamentos,
  String token,
) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/brigadas/$brigadaId/pacientes/$pacienteId/medicamentos'),
      headers: _buildHeaders(token),
      body: jsonEncode({'medicamentos': medicamentos}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error asignando medicamentos a paciente en brigada: $e');
    return null;
  }
}

// Eliminar brigada
static Future<bool> deleteBrigada(String brigadaId, String token) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/brigadas/$brigadaId'),
      headers: _buildHeaders(token),
    );
    
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('❌ Error eliminando brigada: $e');
    return false;
  }
}

}