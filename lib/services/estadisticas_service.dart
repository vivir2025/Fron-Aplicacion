// services/estadisticas_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class EstadisticasService {
  static const String baseUrl = 'http://fnpvi.nacerparavivir.org/api';
  static const Duration timeoutDuration = Duration(seconds: 15);

  // ========================================
  // 🌐 OBTENER ESTADÍSTICAS DESDE LA API
  // ========================================
  
  /// Obtiene estadísticas desde la API con soporte para filtros de fecha
  /// 
  /// [token] - Token de autenticación Bearer
  /// [fechaInicio] - Fecha de inicio del rango (opcional)
  /// [fechaFin] - Fecha fin del rango (opcional)
  /// 
  /// Retorna un Map con las estadísticas o lanza una excepción
  static Future<Map<String, dynamic>> getEstadisticasDesdeApi(
    String token, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      print('🌐 Intentando obtener estadísticas desde API...');
      print('🔑 Token: ${token.substring(0, 20)}...');
      
      // Construir URL con parámetros de fecha si existen
      String url = '$baseUrl/estadisticas';
      
      if (fechaInicio != null && fechaFin != null) {
        final inicio = DateFormat('yyyy-MM-dd').format(fechaInicio);
        final fin = DateFormat('yyyy-MM-dd').format(fechaFin);
        url += '?fecha_inicio=$inicio&fecha_fin=$fin';
        print('📅 Filtro de fechas: $inicio a $fin');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // ✅ VERIFICAR ESTRUCTURA DE RESPUESTA
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          
          // ✅ CONVERTIR CORRECTAMENTE A ENTEROS
          return {
            'pacientes': _toInt(data['total_pacientes'] ?? data['pacientes']),
            'visitas': _toInt(data['total_visitas'] ?? data['visitas']),
            'laboratorios': _toInt(data['total_laboratorios'] ?? data['total_envio_muestras'] ?? data['laboratorios']),
            'encuestas': _toInt(data['total_encuestas'] ?? data['encuestas']),
            'visitas_mes': _toInt(data['visitas_mes']),
            'laboratorios_mes': _toInt(data['laboratorios_mes']),
            'fecha_consulta': data['fecha_consulta'] ?? DateTime.now().toIso8601String(),
          };
        } else {
          throw Exception('Respuesta de API inválida: ${jsonData['message'] ?? 'Sin mensaje'}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticación inválido o expirado');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para acceder a esta información');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint de estadísticas no encontrado');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor. Intenta más tarde');
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      print('❌ Error de cliente HTTP: $e');
      throw Exception('Error de conexión: Verifica tu conexión a internet');
    } on FormatException catch (e) {
      print('❌ Error de formato JSON: $e');
      throw Exception('Error al procesar la respuesta del servidor');
    } catch (e) {
      print('❌ Error obteniendo estadísticas desde API: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Tiempo de espera agotado. Intenta nuevamente');
      }
      rethrow;
    }
  }

  // ========================================
  // 💾 OBTENER ESTADÍSTICAS LOCALES
  // ========================================
  
  /// Obtiene estadísticas desde la base de datos local SQLite
  /// 
  /// [fechaInicio] - Fecha de inicio del rango (opcional)
  /// [fechaFin] - Fecha fin del rango (opcional)
  /// 
  /// Retorna un Map con las estadísticas locales
  static Future<Map<String, int>> getEstadisticasLocales({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final db = DatabaseHelper.instance;
      
      // Obtener el usuario logueado para filtrar por ID
      final usuario = await db.getLoggedInUser();
      final usuarioId = usuario?['id'];
      
      if (usuarioId == null) {
        print('⚠️ No hay usuario logueado, retornando estadísticas por defecto');
        return _getEstadisticasPorDefecto();
      }
      
      print('📊 Obteniendo estadísticas locales para usuario: $usuarioId');
      
      // Formatear fechas para consultas SQL si existen
      String? fechaInicioStr;
      String? fechaFinStr;
      
      if (fechaInicio != null && fechaFin != null) {
        fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
        fechaFinStr = DateFormat('yyyy-MM-dd 23:59:59').format(fechaFin);
        print('📅 Filtro de fechas local: $fechaInicioStr a $fechaFinStr');
      }
      
      // Estadísticas filtradas por usuario y opcionalmente por fecha
      final pacientesCount = await db.countPacientesPorUsuario(
        usuarioId,
        fechaInicio: fechaInicioStr,
        fechaFin: fechaFinStr,
      );
      
      final visitasCount = await db.countVisitasPorUsuario(
        usuarioId,
        fechaInicio: fechaInicioStr,
        fechaFin: fechaFinStr,
      );
      

    
      final laboratoriosCount = await db.countLaboratoriosPorUsuario(
        usuarioId,
        fechaInicio: fechaInicioStr,
        fechaFin: fechaFinStr,
      );
      
      final encuestasCount = await db.countEncuestasPorUsuario(
        usuarioId,
        fechaInicio: fechaInicioStr,
        fechaFin: fechaFinStr,
      );
      
      print('✅ Estadísticas locales obtenidas exitosamente');
      
      return {
        'pacientes': pacientesCount,
        'visitas': visitasCount,
        'laboratorios': laboratoriosCount,
        'encuestas': encuestasCount,
        'visitas_mes': 0, // No disponible localmente
        'laboratorios_mes': 0, // No disponible localmente
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas locales: $e');
      return _getEstadisticasPorDefecto();
    }
  }

  // ========================================
  // 🔄 OBTENER ESTADÍSTICAS (HÍBRIDO)
  // ========================================
  
  /// Intenta obtener estadísticas de la API, si falla usa datos locales
  /// 
  /// [token] - Token de autenticación (opcional)
  /// [fechaInicio] - Fecha de inicio del rango (opcional)
  /// [fechaFin] - Fecha fin del rango (opcional)
  /// 
  /// Retorna un Map con las estadísticas y un flag indicando el origen
  static Future<Map<String, dynamic>> getEstadisticasHibridas({
    String? token,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      // Intentar obtener desde API si hay token
      if (token != null && token.isNotEmpty) {
        print('🌐 Intentando obtener estadísticas desde API...');
        final estadisticasApi = await getEstadisticasDesdeApi(
          token,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        );
        
        return {
          ...estadisticasApi,
          'origen': 'api',
          'sincronizado': true,
        };
      }
    } catch (e) {
      print('⚠️ Error obteniendo estadísticas de API, usando datos locales: $e');
    }
    
    // Fallback a datos locales
    print('💾 Obteniendo estadísticas desde base de datos local...');
    final estadisticasLocales = await getEstadisticasLocales(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    
    return {
      ...estadisticasLocales,
      'origen': 'local',
      'sincronizado': false,
    };
  }

  // ========================================
  // 🛠️ MÉTODOS AUXILIARES
  // ========================================
  
  /// Convierte un valor dinámico a entero de forma segura
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
  
  /// Retorna un mapa con estadísticas por defecto (todos en 0)
  static Map<String, int> _getEstadisticasPorDefecto() {
    return {
      'pacientes': 0,
      'visitas': 0,
      'laboratorios': 0,
      'encuestas': 0,
      'visitas_mes': 0,
      'laboratorios_mes': 0,
    };
  }

  // ========================================
  // 📊 OBTENER RESUMEN DE ESTADÍSTICAS
  // ========================================
  
  /// Obtiene un resumen formateado de las estadísticas
  static String getResumenEstadisticas(Map<String, dynamic> estadisticas) {
    final total = _toInt(estadisticas['pacientes']) +
                  _toInt(estadisticas['visitas']) +
                  _toInt(estadisticas['laboratorios']) +
                  _toInt(estadisticas['encuestas']);
    
    return 'Total de registros: $total';
  }

  // ========================================
  // 🔍 VALIDAR DISPONIBILIDAD DE API
  // ========================================
  
  /// Verifica si la API está disponible
  static Future<bool> verificarDisponibilidadApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ API no disponible: $e');
      return false;
    }
  }

  // ========================================
  // 📈 COMPARAR ESTADÍSTICAS
  // ========================================
  
  /// Compara estadísticas actuales con anteriores
  static Map<String, dynamic> compararEstadisticas(
    Map<String, dynamic> actual,
    Map<String, dynamic> anterior,
  ) {
    return {
      'pacientes_diff': _toInt(actual['pacientes']) - _toInt(anterior['pacientes']),
      'visitas_diff': _toInt(actual['visitas']) - _toInt(anterior['visitas']),
      'laboratorios_diff': _toInt(actual['laboratorios']) - _toInt(anterior['laboratorios']),
      'encuestas_diff': _toInt(actual['encuestas']) - _toInt(anterior['encuestas']),
    };
  }
}
