// services/medicamento_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../models/medicamento.dart';

class MedicamentoService {
  static const String baseUrl = 'http://fnpvi.nacerparavivir.org/api';

  // Cargar medicamentos desde el servidor
  static Future<bool> loadMedicamentosFromServer(String token) async {
    try {
      debugPrint('📥 Cargando medicamentos desde servidor...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/medicamentos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        List<Map<String, dynamic>> medicamentos = [];
        
        // Manejar diferentes formatos de respuesta
        if (responseData is List) {
          medicamentos = responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map && responseData['data'] != null) {
          medicamentos = (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData is Map && responseData['medicamentos'] != null) {
          medicamentos = (responseData['medicamentos'] as List).cast<Map<String, dynamic>>();
        }

        if (medicamentos.isNotEmpty) {
          // Guardar en base de datos local
          await DatabaseHelper.instance.syncMedicamentosFromServer(medicamentos);
          debugPrint('✅ ${medicamentos.length} medicamentos cargados exitosamente');
          return true;
        } else {
          debugPrint('⚠️ No se encontraron medicamentos en el servidor');
          return false;
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        debugPrint('❌ Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error cargando medicamentos: $e');
      return false;
    }
  }

  // Verificar y cargar medicamentos si es necesario
  static Future<bool> ensureMedicamentosLoaded(String? token) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final hasMedicamentos = await dbHelper.hasMedicamentos();
      
      if (!hasMedicamentos && token != null) {
        debugPrint('📋 No hay medicamentos locales, intentando cargar desde servidor...');
        return await loadMedicamentosFromServer(token);
      } else if (hasMedicamentos) {
        final count = await dbHelper.countMedicamentos();
        debugPrint('✅ $count medicamentos disponibles localmente');
        return true;
      } else {
        debugPrint('⚠️ No hay token disponible para cargar medicamentos');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verificando medicamentos: $e');
      return false;
    }
  }
}
