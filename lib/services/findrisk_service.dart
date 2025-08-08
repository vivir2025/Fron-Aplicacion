// services/findrisk_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../database/database_helper.dart';
import '../models/findrisk_test_model.dart';
import '../models/paciente_model.dart';

class FindriskService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Crear test FINDRISK
  static Future<Map<String, dynamic>> crearFindriskTest({
    required String pacienteId,
    required String sedeId,
    String? vereda,
    String? telefono,
    required String actividadFisica,
    required String medicamentosHipertension,
    required String frecuenciaFrutasVerduras,
    required String azucarAltoDetectado,
    required double peso,
    required double talla,
    required double perimetroAbdominal,
    required String antecedentesFamiliares,
    String? conducta,
    String? promotorVida,
    String? token,
  }) async {
    try {
      debugPrint('🧪 Creando test FINDRISK para paciente: $pacienteId');

      // Obtener datos del paciente para calcular edad
      final paciente = await _dbHelper.getPacienteById(pacienteId);
      if (paciente == null) {
        throw Exception('Paciente no encontrado');
      }

      // Calcular edad
      final edad = DateTime.now().year - paciente.fecnacimiento.year;
      
      // Crear test con cálculos automáticos
      final test = _crearTestConCalculos(
        pacienteId: pacienteId,
        sedeId: sedeId,
        vereda: vereda,
        telefono: telefono,
        actividadFisica: actividadFisica,
        medicamentosHipertension: medicamentosHipertension,
        frecuenciaFrutasVerduras: frecuenciaFrutasVerduras,
        azucarAltoDetectado: azucarAltoDetectado,
        peso: peso,
        talla: talla,
        perimetroAbdominal: perimetroAbdominal,
        antecedentesFamiliares: antecedentesFamiliares,
        conducta: conducta,
        promotorVida: promotorVida,
        edad: edad,
        genero: paciente.genero,
      );

      // Guardar localmente primero
      final savedLocally = await _dbHelper.createFindriskTest(test);
      if (!savedLocally) {
        throw Exception('No se pudo guardar el test localmente');
      }

      debugPrint('✅ Test FINDRISK guardado localmente con ID: ${test.id}');

      // Intentar sincronizar si hay token
      if (token != null) {
        try {
          debugPrint('🔍 Verificando conectividad...');
          final hasConnection = await ApiService.verificarConectividad();
          if (hasConnection) {
            debugPrint('✅ Servidor disponible');
            debugPrint('📤 Enviando test FINDRISK al servidor...');
            debugPrint('📋 Datos del test: ${test.id}');
            
            final serverData = await ApiService.createFindriskTest(test.toJson(), token);
            if (serverData != null) {
              await _dbHelper.marcarFindriskTestComoSincronizado(test.id);
              debugPrint('✅ Test FINDRISK sincronizado con el servidor');
              
              return {
                'success': true,
                'test': test,
                'sincronizado': true,
                'server_data': serverData,
              };
            }
          } else {
            debugPrint('📵 Sin conexión - Test quedará pendiente de sincronización');
          }
        } catch (e) {
          debugPrint('⚠️ Error al sincronizar con servidor: $e');
        }
      }

      return {
        'success': true,
        'test': test,
        'sincronizado': false,
        'message': 'Test guardado localmente, se sincronizará cuando haya conexión',
      };

    } catch (e) {
      debugPrint('💥 Error al crear test FINDRISK: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Método privado para crear test con todos los cálculos
  static FindriskTest _crearTestConCalculos({
    required String pacienteId,
    required String sedeId,
    String? vereda,
    String? telefono,
    required String actividadFisica,
    required String medicamentosHipertension,
    required String frecuenciaFrutasVerduras,
    required String azucarAltoDetectado,
    required double peso,
    required double talla,
    required double perimetroAbdominal,
    required String antecedentesFamiliares,
    String? conducta,
    String? promotorVida,
    required int edad,
    required String genero,
  }) {
    // 🔧 GENERAR ID MÁS CORTO
    final String testId = 'fr_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
    
    // Calcular IMC
    final tallaMetros = talla / 100;
    final imc = double.parse((peso / (tallaMetros * tallaMetros)).toStringAsFixed(2));

    // Calcular puntajes
    final puntajeEdad = _calcularPuntajeEdad(edad);
    final puntajeImc = _calcularPuntajeIMC(imc, genero);
    final puntajePerimetro = _calcularPuntajePerimetro(perimetroAbdominal, genero);
    final puntajeActividad = actividadFisica == 'no' ? 2 : 0;
    final puntajeFrutas = frecuenciaFrutasVerduras == 'no_diariamente' ? 1 : 0;
    final puntajeMedicamentos = medicamentosHipertension == 'si' ? 2 : 0;
    final puntajeAzucar = azucarAltoDetectado == 'si' ? 5 : 0;
    final puntajeAntecedentes = _calcularPuntajeAntecedentes(antecedentesFamiliares);

    // Calcular puntaje final
    final puntajeFinal = puntajeEdad + puntajeImc + puntajePerimetro + 
                        puntajeActividad + puntajeFrutas + puntajeMedicamentos + 
                        puntajeAzucar + puntajeAntecedentes;

    return FindriskTest(
      id: testId, // 🔧 ID más corto
      idpaciente: pacienteId,
      idsede: sedeId,
      vereda: vereda,
      telefono: telefono,
      actividadFisica: actividadFisica,
      puntajeActividadFisica: puntajeActividad,
      medicamentosHipertension: medicamentosHipertension,
      puntajeMedicamentos: puntajeMedicamentos,
      frecuenciaFrutasVerduras: frecuenciaFrutasVerduras,
      puntajeFrutasVerduras: puntajeFrutas,
      azucarAltoDetectado: azucarAltoDetectado,
      puntajeAzucarAlto: puntajeAzucar,
      peso: peso,
      talla: talla,
      imc: imc,
      puntajeImc: puntajeImc,
      perimetroAbdominal: perimetroAbdominal,
      puntajePerimetro: puntajePerimetro,
      antecedentesFamiliares: antecedentesFamiliares,
      puntajeAntecedentes: puntajeAntecedentes,
      puntajeEdad: puntajeEdad,
      puntajeFinal: puntajeFinal,
      conducta: conducta,
      promotorVida: promotorVida,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Métodos de cálculo de puntajes
  static int _calcularPuntajeEdad(int edad) {
    if (edad < 45) return 0;
    if (edad >= 45 && edad <= 54) return 2;
    if (edad >= 55 && edad <= 64) return 3;
    return 4; // >= 65
  }

  static int _calcularPuntajeIMC(double imc, String genero) {
    if (imc < 25) return 0;
    if (imc >= 25 && imc < 30) return 1;
    return 3; // >= 30
  }

  static int _calcularPuntajePerimetro(double perimetro, String genero) {
    if (genero.toLowerCase() == 'masculino') {
      if (perimetro < 94) return 0;
      if (perimetro >= 94 && perimetro <= 102) return 3;
      return 4; // > 102
    } else { // femenino
      if (perimetro < 80) return 0;
      if (perimetro >= 80 && perimetro <= 88) return 3;
      return 4; // > 88
    }
  }

  static int _calcularPuntajeAntecedentes(String antecedentes) {
    switch (antecedentes) {
      case 'no':
        return 0;
      case 'abuelos_tios_primos':
        return 3;
      case 'padres_hermanos_hijos':
        return 5;
      default:
        return 0;
    }
  }

  // Obtener tests por paciente
  static Future<List<FindriskTest>> getTestsByPaciente(String pacienteId) async {
    try {
      return await _dbHelper.getFindriskTestsByPaciente(pacienteId);
    } catch (e) {
      debugPrint('❌ Error obteniendo tests FINDRISK por paciente: $e');
      return [];
    }
  }

  // Obtener todos los tests
  static Future<List<FindriskTest>> getAllTests() async {
    try {
      return await _dbHelper.getAllFindriskTests();
    } catch (e) {
      debugPrint('❌ Error obteniendo todos los tests FINDRISK: $e');
      return [];
    }
  }

  // Sincronizar tests pendientes
  static Future<Map<String, dynamic>> sincronizarTestsPendientes(String token) async {
    try {
      debugPrint('🔄 Iniciando sincronización de tests FINDRISK...');
      
      final testsPendientes = await _dbHelper.getFindriskTestsNoSincronizados();
      
      int exitosas = 0;
      int fallidas = 0;
      List<String> errores = [];
      
      debugPrint('📊 Sincronizando ${testsPendientes.length} tests FINDRISK pendientes...');
      
      final hasConnection = await ApiService.verificarConectividad();
      if (!hasConnection) {
        throw Exception('No hay conexión a internet');
      }
      
      for (final test in testsPendientes) {
        try {
          debugPrint('🔄 Sincronizando test FINDRISK ${test.id}...');
          
          final serverData = await ApiService.createFindriskTest(test.toJson(), token);
          
          if (serverData != null) {
            await _dbHelper.marcarFindriskTestComoSincronizado(test.id);
            exitosas++;
            debugPrint('✅ Test FINDRISK ${test.id} sincronizado exitosamente');
          } else {
            fallidas++;
            errores.add('Servidor respondió con error para test ${test.id}');
            debugPrint('❌ Falló sincronización de test FINDRISK ${test.id}');
          }
          
          // Pausa entre sincronizaciones
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          fallidas++;
          errores.add('Error en test ${test.id}: $e');
          debugPrint('💥 Error sincronizando test FINDRISK ${test.id}: $e');
        }
      }
      
      if (exitosas > 0) {
        debugPrint('🎉 $exitosas tests FINDRISK sincronizados exitosamente');
      }
      if (fallidas > 0) {
        debugPrint('⚠️ $fallidas tests FINDRISK fallaron en la sincronización');
      }
      
      return {
        'exitosas': exitosas,
        'fallidas': fallidas,
        'errores': errores,
        'total': testsPendientes.length,
      };
      
    } catch (e) {
      debugPrint('💥 Error en sincronización de tests FINDRISK: $e');
      return {
        'exitosas': 0,
        'fallidas': 1,
        'errores': ['Error general: $e'],
        'total': 1,
      };
    }
  }

  // Obtener estadísticas
  static Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      return await _dbHelper.getFindriskEstadisticasLocales();
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas FINDRISK: $e');
      return {};
    }
  }

  // Eliminar test
  static Future<bool> eliminarTest(String testId) async {
    try {
      return await _dbHelper.deleteFindriskTest(testId);
    } catch (e) {
      debugPrint('❌ Error eliminando test FINDRISK: $e');
      return false;
    }
  }

  // Buscar paciente por identificación
  static Future<Paciente?> buscarPacientePorIdentificacion(String identificacion) async {
    try {
      return await _dbHelper.getPacienteByIdentificacion(identificacion);
    } catch (e) {
      debugPrint('❌ Error buscando paciente: $e');
      return null;
    }
  }
}
