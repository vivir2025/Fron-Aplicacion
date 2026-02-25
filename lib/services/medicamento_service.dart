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
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Verificar y cargar medicamentos si es necesario
  static Future<bool> ensureMedicamentosLoaded(String? token) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final hasMedicamentos = await dbHelper.hasMedicamentos();
      
      if (!hasMedicamentos && token != null) {
        return await loadMedicamentosFromServer(token);
      } else if (hasMedicamentos) {
        final count = await dbHelper.countMedicamentos();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
