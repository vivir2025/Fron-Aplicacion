import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';


class ApiService {
  static const String baseUrl = 'http://fnpvi.nacerparavivir.org/api';
  
  // ✅ Callback para manejar expiración de token
  static Function()? onTokenExpired;
  static DateTime? _lastTokenCheck;
  static const _tokenCheckInterval = Duration(minutes: 5);

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
  
  // ✅ MANEJO ESPECIAL PARA TOKEN EXPIRADO
  if (statusCode == 401) {
    debugPrint('🔴 Token expirado o inválido - Disparando callback de logout');
    // Notificar al provider para que haga logout
    if (onTokenExpired != null) {
      Future.delayed(Duration.zero, () => onTokenExpired!());
    }
    throw TokenExpiredException('Sesión expirada. Por favor inicia sesión nuevamente.');
  }
  
  // Manejo específico de errores conocidos
  switch(statusCode) {
    case 400:
      throw Exception('Solicitud incorrecta');
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
// Crear encuesta
static Future<Map<String, dynamic>?> createEncuesta(
  Map<String, dynamic> encuestaData,
  String token,
) async {
  try {
    debugPrint('📤 Enviando encuesta al servidor...');
    debugPrint('📋 Datos de encuesta: ${encuestaData['id']}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/encuestas'),
      headers: _buildHeaders(token),
      body: jsonEncode(encuestaData),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('📥 Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ Encuesta creada exitosamente en servidor');
      return responseData;
    } else {
      debugPrint('❌ Error del servidor: ${response.statusCode}');
      debugPrint('📄 Respuesta: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('💥 Excepción al crear encuesta: $e');
    return null;
  }
}

// Obtener encuestas
static Future<List<dynamic>> getEncuestas(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/encuestas'),
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
    debugPrint('❌ Error obteniendo encuestas: $e');
    return [];
  }
}

// Obtener encuestas por paciente
static Future<List<dynamic>> getEncuestasByPaciente(String token, String pacienteId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/encuestas/paciente/$pacienteId'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo encuestas por paciente: $e');
    return [];
  }
}

// Obtener encuestas por sede
static Future<List<dynamic>> getEncuestasBySede(String token, String sedeId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/encuestas/sede/$sedeId'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo encuestas por sede: $e');
    return [];
  }
}

// Actualizar encuesta
static Future<Map<String, dynamic>?> updateEncuesta(
  String encuestaId,
  Map<String, dynamic> encuestaData,
  String token,
) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/encuestas/$encuestaId'),
      headers: _buildHeaders(token),
      body: jsonEncode(encuestaData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error actualizando encuesta: $e');
    return null;
  }
}

// Eliminar encuesta
static Future<bool> deleteEncuesta(String encuestaId, String token) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/encuestas/$encuestaId'),
      headers: _buildHeaders(token),
    );
    
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    debugPrint('❌ Error eliminando encuesta: $e');
    return false;
  }
}
// ==================== MÉTODOS PARA FINDRISK ====================

// Crear test FINDRISK
static Future<Map<String, dynamic>?> createFindriskTest(
  Map<String, dynamic> findriskData,
  String token,
) async {
  try {
    debugPrint('📤 Enviando test FINDRISK al servidor...');
    debugPrint('📋 Datos del test: ${findriskData['id']}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/findrisk'),
      headers: _buildHeaders(token),
      body: jsonEncode(findriskData),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('📥 Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ Test FINDRISK creado exitosamente en servidor');
      return responseData;
    } else {
      debugPrint('❌ Error del servidor: ${response.statusCode}');
      debugPrint('📄 Respuesta: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('💥 Excepción al crear test FINDRISK: $e');
    return null;
  }
}

// Obtener tests FINDRISK
static Future<List<dynamic>> getFindriskTests(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/findrisk'),
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
    debugPrint('❌ Error obteniendo tests FINDRISK: $e');
    return [];
  }
}

// Obtener tests FINDRISK por paciente
static Future<List<dynamic>> getFindriskTestsByPaciente(String token, String pacienteId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/findrisk/paciente/$pacienteId'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo tests FINDRISK por paciente: $e');
    return [];
  }
}

// Obtener tests FINDRISK por sede
static Future<List<dynamic>> getFindriskTestsBySede(String token, String sedeId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/findrisk/sede/$sedeId'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo tests FINDRISK por sede: $e');
    return [];
  }
}

// Actualizar test FINDRISK
static Future<Map<String, dynamic>?> updateFindriskTest(
  String testId,
  Map<String, dynamic> findriskData,
  String token,
) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/findrisk/$testId'),
      headers: _buildHeaders(token),
      body: jsonEncode(findriskData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error actualizando test FINDRISK: $e');
    return null;
  }
}

// Eliminar test FINDRISK
static Future<bool> deleteFindriskTest(String testId, String token) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/findrisk/$testId'),
      headers: _buildHeaders(token),
    );
    
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    debugPrint('❌ Error eliminando test FINDRISK: $e');
    return false;
  }
}

// Obtener estadísticas FINDRISK
static Future<Map<String, dynamic>> getFindriskEstadisticas(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/findrisk-estadisticas'),
      headers: _buildHeaders(token),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  } catch (e) {
    debugPrint('❌ Error obteniendo estadísticas FINDRISK: $e');
    return {};
  }
}

// Obtener estadísticas FINDRISK por sede
static Future<Map<String, dynamic>> getFindriskEstadisticasBySede(String token, String sedeId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/findrisk-estadisticas/sede/$sedeId'),
      headers: _buildHeaders(token),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  } catch (e) {
    debugPrint('❌ Error obteniendo estadísticas FINDRISK por sede: $e');
    return {};
  }
}

// Obtener paciente con sede por identificación
static Future<Map<String, dynamic>?> getPacienteConSede(String token, String identificacion) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/findrisk/paciente-sede/$identificacion'),
      headers: _buildHeaders(token),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error obteniendo paciente con sede: $e');
    return null;
  }
}


// ==================== MÉTODOS PARA AFINAMIENTOS ====================

// Crear afinamiento
static Future<Map<String, dynamic>?> createAfinamiento(
  Map<String, dynamic> afinamientoData,
  String token,
) async {
  try {
    debugPrint('📤 Enviando afinamiento al servidor...');
    debugPrint('📋 Datos de afinamiento: ${afinamientoData['id']}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/afinamientos'),
      headers: _buildHeaders(token),
      body: jsonEncode(afinamientoData),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('📥 Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ Afinamiento creado exitosamente en servidor');
      return responseData;
    } else {
      debugPrint('❌ Error del servidor: ${response.statusCode}');
      debugPrint('📄 Respuesta: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('💥 Excepción al crear afinamiento: $e');
    return null;
  }
}

// Obtener afinamientos
static Future<List<dynamic>> getAfinamientos(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/afinamientos'),
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
    debugPrint('❌ Error obteniendo afinamientos: $e');
    return [];
  }
}

// Obtener afinamiento específico
static Future<Map<String, dynamic>?> getAfinamientoById(String id, String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/afinamientos/$id'),
      headers: _buildHeaders(token),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error obteniendo afinamiento por ID: $e');
    return null;
  }
}

// Actualizar afinamiento
static Future<Map<String, dynamic>?> updateAfinamiento(
  String id,
  Map<String, dynamic> afinamientoData,
  String token,
) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/afinamientos/$id'),
      headers: _buildHeaders(token),
      body: jsonEncode(afinamientoData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error actualizando afinamiento: $e');
    return null;
  }
}

// Eliminar afinamiento
static Future<bool> deleteAfinamiento(String id, String token) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/afinamientos/$id'),
      headers: _buildHeaders(token),
    );
    
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    debugPrint('❌ Error eliminando afinamiento: $e');
    return false;
  }
}

// Obtener afinamientos por paciente
static Future<List<dynamic>> getAfinamientosByPaciente(String token, String pacienteId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/afinamientos/paciente/$pacienteId'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo afinamientos por paciente: $e');
    return [];
  }
}

// Obtener mis afinamientos
static Future<List<dynamic>> getMisAfinamientos(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/mis-afinamientos'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo mis afinamientos: $e');
    return [];
  }
}

// ==================== MÉTODOS PARA TAMIZAJES ====================

// Crear tamizaje
static Future<Map<String, dynamic>?> createTamizaje(
  Map<String, dynamic> tamizajeData,
  String token,
) async {
  try {
    debugPrint('📤 Enviando tamizaje al servidor...');
    debugPrint('📋 Datos de tamizaje: ${tamizajeData['id']}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/tamizajes'),
      headers: _buildHeaders(token),
      body: jsonEncode(tamizajeData),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('📥 Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      debugPrint('✅ Tamizaje creado exitosamente en servidor');
      return responseData;
    } else {
      debugPrint('❌ Error del servidor: ${response.statusCode}');
      debugPrint('📄 Respuesta: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('💥 Excepción al crear tamizaje: $e');
    return null;
  }
}

// Obtener tamizajes
static Future<List<dynamic>> getTamizajes(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/tamizajes'),
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
    debugPrint('❌ Error obteniendo tamizajes: $e');
    return [];
  }
}

// Obtener tamizajes por paciente
static Future<List<dynamic>> getTamizajesByPaciente(String token, String pacienteId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/tamizajes/paciente/$pacienteId'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo tamizajes por paciente: $e');
    return [];
  }
}

// Obtener mis tamizajes
static Future<List<dynamic>> getMisTamizajes(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/mis-tamizajes'),
      headers: _buildHeaders(token),
    );
    
    final decoded = _handleResponse(response);
    
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List;
    } else if (decoded is List) {
      return decoded;
    }
    return [];
  } catch (e) {
    debugPrint('❌ Error obteniendo mis tamizajes: $e');
    return [];
  }
}

// Actualizar tamizaje
static Future<Map<String, dynamic>?> updateTamizaje(
  String tamizajeId,
  Map<String, dynamic> tamizajeData,
  String token,
) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/tamizajes/$tamizajeId'),
      headers: _buildHeaders(token),
      body: jsonEncode(tamizajeData),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error actualizando tamizaje: $e');
    return null;
  }
}

// Eliminar tamizaje
static Future<bool> deleteTamizaje(String tamizajeId, String token) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/tamizajes/$tamizajeId'),
      headers: _buildHeaders(token),
    );
    
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    debugPrint('❌ Error eliminando tamizaje: $e');
    return false;
  }
}

// Obtener estadísticas de tamizajes
static Future<Map<String, dynamic>> getTamizajesEstadisticas(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/tamizajes/estadisticas'),
      headers: _buildHeaders(token),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  } catch (e) {
    debugPrint('❌ Error obteniendo estadísticas de tamizajes: $e');
    return {};
  }
}
// En api_service.dart - AGREGAR SI NO EXISTE
static Future<Map<String, dynamic>?> getVisitaById(String token, String visitaId) async {
  try {
    debugPrint('🔍 Verificando existencia de visita: $visitaId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/visitas/$visitaId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        debugPrint('✅ Visita encontrada en servidor: $visitaId');
        return data['data'];
      }
    } else if (response.statusCode == 404) {
      debugPrint('❌ Visita no encontrada en servidor: $visitaId');
      return null;
    }
    
    debugPrint('⚠️ Respuesta inesperada del servidor: ${response.statusCode}');
    return null;
    
  } catch (e) {
    debugPrint('❌ Error verificando visita: $e');
    return null; // Asumir que no existe si hay error
  }
}

// ✅ MÉTODO PARA VALIDAR TOKEN ANTES DE LLAMADAS
static Future<bool> validateToken(String token) async {
  try {
    // Evitar validaciones muy frecuentes
    if (_lastTokenCheck != null && 
        DateTime.now().difference(_lastTokenCheck!) < _tokenCheckInterval) {
      return true;
    }
    
    debugPrint('🔍 Validando token...');
    final response = await http.get(
      Uri.parse('$baseUrl/perfil'),
      headers: _buildHeaders(token),
    ).timeout(const Duration(seconds: 5));
    
    _lastTokenCheck = DateTime.now();
    
    if (response.statusCode == 401) {
      debugPrint('❌ Token inválido o expirado');
      if (onTokenExpired != null) {
        Future.delayed(Duration.zero, () => onTokenExpired!());
      }
      return false;
    }
    
    debugPrint('✅ Token válido');
    return response.statusCode == 200;
    
  } catch (e) {
    debugPrint('⚠️ Error validando token: $e');
    // No invalidar token por errores de red
    if (e is SocketException || e is TimeoutException) {
      return true; // Asumir válido si hay problemas de red
    }
    return false;
  }
}

}

// ✅ EXCEPCIÓN PERSONALIZADA PARA TOKEN EXPIRADO
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}