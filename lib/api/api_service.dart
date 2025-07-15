import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  if (response.statusCode == 401 || response.statusCode == 403) {
    throw Exception('Credenciales inválidas');
  }
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error: ${response.statusCode}');
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
    String? contrasenaNueva,
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

  static Future<Map<String, dynamic>?> guardarVisita(Map<String, dynamic> visitaData, String? token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/visitas'),
        headers: token != null ? _buildHeaders(token) : {'Content-Type': 'application/json'},
        body: jsonEncode(visitaData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Error al guardar visita: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepción al guardar visita: $e');
      return null;
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
}