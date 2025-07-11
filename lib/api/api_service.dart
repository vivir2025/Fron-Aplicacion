import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://fnpvi.nacerparavivir.org/api';

  // Helper method to handle responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }

  // Login method
  static Future<Map<String, dynamic>> login(String usuario, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuario': usuario,
        'contrasena': contrasena,
      }),
    );
    return _handleResponse(response);
  }

  // Logout method
  static Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(response);
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/perfil'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena_actual': contrasenaActual,
        'contrasena_nueva': contrasenaNueva,
      }),
    );
    return _handleResponse(response);
  }
}