// models/findrisk_test_model.dart
import 'dart:convert';

class FindriskTest {
  final String id;
  final String idpaciente;
  final String idsede;
  final String? vereda;
  final String? telefono;
  
  // Pregunta 1: Actividad física
  final String actividadFisica; // 'si' o 'no'
  final int puntajeActividadFisica;
  
  // Pregunta 2: Medicamentos hipertensión
  final String medicamentosHipertension; // 'si' o 'no'
  final int puntajeMedicamentos;
  
  // Pregunta 3: Frecuencia frutas y verduras
  final String frecuenciaFrutasVerduras; // 'diariamente' o 'no_diariamente'
  final int puntajeFrutasVerduras;
  
  // Pregunta 4: Azúcar alto detectado
  final String azucarAltoDetectado; // 'si' o 'no'
  final int puntajeAzucarAlto;
  
  // Datos físicos
  final double peso;
  final double talla;
  final double imc;
  final int puntajeImc;
  
  final double perimetroAbdominal;
  final int puntajePerimetro;
  
  // Pregunta 5: Antecedentes familiares
  final String antecedentesFamiliares; // 'no', 'abuelos_tios_primos', 'padres_hermanos_hijos'
  final int puntajeAntecedentes;
  
  // Puntajes calculados
  final int puntajeEdad;
  final int puntajeFinal;
  
  // Campos adicionales
  final String? conducta;
  final String? promotorVida;
  
  // Control de sincronización
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  FindriskTest({
    required this.id,
    required this.idpaciente,
    required this.idsede,
    this.vereda,
    this.telefono,
    required this.actividadFisica,
    this.puntajeActividadFisica = 0,
    required this.medicamentosHipertension,
    this.puntajeMedicamentos = 0,
    required this.frecuenciaFrutasVerduras,
    this.puntajeFrutasVerduras = 0,
    required this.azucarAltoDetectado,
    this.puntajeAzucarAlto = 0,
    required this.peso,
    required this.talla,
    this.imc = 0,
    this.puntajeImc = 0,
    required this.perimetroAbdominal,
    this.puntajePerimetro = 0,
    required this.antecedentesFamiliares,
    this.puntajeAntecedentes = 0,
    this.puntajeEdad = 0,
    this.puntajeFinal = 0,
    this.conducta,
    this.promotorVida,
    this.syncStatus = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FindriskTest.fromJson(Map<String, dynamic> json) {
    return FindriskTest(
      id: json['id']?.toString() ?? '',
      idpaciente: json['idpaciente']?.toString() ?? '',
      idsede: json['idsede']?.toString() ?? '',
      vereda: json['vereda']?.toString(),
      telefono: json['telefono']?.toString(),
      actividadFisica: json['actividad_fisica']?.toString() ?? 'no',
      puntajeActividadFisica: json['puntaje_actividad_fisica'] as int? ?? 0,
      medicamentosHipertension: json['medicamentos_hipertension']?.toString() ?? 'no',
      puntajeMedicamentos: json['puntaje_medicamentos'] as int? ?? 0,
      frecuenciaFrutasVerduras: json['frecuencia_frutas_verduras']?.toString() ?? 'no_diariamente',
      puntajeFrutasVerduras: json['puntaje_frutas_verduras'] as int? ?? 0,
      azucarAltoDetectado: json['azucar_alto_detectado']?.toString() ?? 'no',
      puntajeAzucarAlto: json['puntaje_azucar_alto'] as int? ?? 0,
      peso: double.tryParse(json['peso']?.toString() ?? '0') ?? 0,
      talla: double.tryParse(json['talla']?.toString() ?? '0') ?? 0,
      imc: double.tryParse(json['imc']?.toString() ?? '0') ?? 0,
      puntajeImc: json['puntaje_imc'] as int? ?? 0,
      perimetroAbdominal: double.tryParse(json['perimetro_abdominal']?.toString() ?? '0') ?? 0,
      puntajePerimetro: json['puntaje_perimetro'] as int? ?? 0,
      antecedentesFamiliares: json['antecedentes_familiares']?.toString() ?? 'no',
      puntajeAntecedentes: json['puntaje_antecedentes'] as int? ?? 0,
      puntajeEdad: json['puntaje_edad'] as int? ?? 0,
      puntajeFinal: json['puntaje_final'] as int? ?? 0,
      conducta: json['conducta']?.toString(),
      promotorVida: json['promotor_vida']?.toString(),
      syncStatus: json['sync_status'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idpaciente': idpaciente,
      'idsede': idsede,
      'vereda': vereda,
      'telefono': telefono,
      'actividad_fisica': actividadFisica,
      'puntaje_actividad_fisica': puntajeActividadFisica,
      'medicamentos_hipertension': medicamentosHipertension,
      'puntaje_medicamentos': puntajeMedicamentos,
      'frecuencia_frutas_verduras': frecuenciaFrutasVerduras,
      'puntaje_frutas_verduras': puntajeFrutasVerduras,
      'azucar_alto_detectado': azucarAltoDetectado,
      'puntaje_azucar_alto': puntajeAzucarAlto,
      'peso': peso,
      'talla': talla,
      'imc': imc,
      'puntaje_imc': puntajeImc,
      'perimetro_abdominal': perimetroAbdominal,
      'puntaje_perimetro': puntajePerimetro,
      'antecedentes_familiares': antecedentesFamiliares,
      'puntaje_antecedentes': puntajeAntecedentes,
      'puntaje_edad': puntajeEdad,
      'puntaje_final': puntajeFinal,
      'conducta': conducta,
      'promotor_vida': promotorVida,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FindriskTest copyWith({
    String? id,
    String? idpaciente,
    String? idsede,
    String? vereda,
    String? telefono,
    String? actividadFisica,
    int? puntajeActividadFisica,
    String? medicamentosHipertension,
    int? puntajeMedicamentos,
    String? frecuenciaFrutasVerduras,
    int? puntajeFrutasVerduras,
    String? azucarAltoDetectado,
    int? puntajeAzucarAlto,
    double? peso,
    double? talla,
    double? imc,
    int? puntajeImc,
    double? perimetroAbdominal,
    int? puntajePerimetro,
    String? antecedentesFamiliares,
    int? puntajeAntecedentes,
    int? puntajeEdad,
    int? puntajeFinal,
    String? conducta,
    String? promotorVida,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FindriskTest(
      id: id ?? this.id,
      idpaciente: idpaciente ?? this.idpaciente,
      idsede: idsede ?? this.idsede,
      vereda: vereda ?? this.vereda,
      telefono: telefono ?? this.telefono,
      actividadFisica: actividadFisica ?? this.actividadFisica,
      puntajeActividadFisica: puntajeActividadFisica ?? this.puntajeActividadFisica,
      medicamentosHipertension: medicamentosHipertension ?? this.medicamentosHipertension,
      puntajeMedicamentos: puntajeMedicamentos ?? this.puntajeMedicamentos,
      frecuenciaFrutasVerduras: frecuenciaFrutasVerduras ?? this.frecuenciaFrutasVerduras,
      puntajeFrutasVerduras: puntajeFrutasVerduras ?? this.puntajeFrutasVerduras,
      azucarAltoDetectado: azucarAltoDetectado ?? this.azucarAltoDetectado,
      puntajeAzucarAlto: puntajeAzucarAlto ?? this.puntajeAzucarAlto,
      peso: peso ?? this.peso,
      talla: talla ?? this.talla,
      imc: imc ?? this.imc,
      puntajeImc: puntajeImc ?? this.puntajeImc,
      perimetroAbdominal: perimetroAbdominal ?? this.perimetroAbdominal,
      puntajePerimetro: puntajePerimetro ?? this.puntajePerimetro,
      antecedentesFamiliares: antecedentesFamiliares ?? this.antecedentesFamiliares,
      puntajeAntecedentes: puntajeAntecedentes ?? this.puntajeAntecedentes,
      puntajeEdad: puntajeEdad ?? this.puntajeEdad,
      puntajeFinal: puntajeFinal ?? this.puntajeFinal,
      conducta: conducta ?? this.conducta,
      promotorVida: promotorVida ?? this.promotorVida,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Método para calcular IMC
  double calcularIMC() {
    if (peso > 0 && talla > 0) {
      double tallaMetros = talla / 100;
      return double.parse((peso / (tallaMetros * tallaMetros)).toStringAsFixed(2));
    }
    return 0;
  }

  // Método para calcular puntaje de actividad física
  int calcularPuntajeActividad() {
    return actividadFisica == 'no' ? 2 : 0;
  }

  // Método para calcular puntaje de medicamentos
  int calcularPuntajeMedicamentos() {
    return medicamentosHipertension == 'si' ? 2 : 0;
  }

  // Método para calcular puntaje de frutas y verduras
  int calcularPuntajeFrutas() {
    return frecuenciaFrutasVerduras == 'no_diariamente' ? 1 : 0;
  }

  // Método para calcular puntaje de azúcar alto
  int calcularPuntajeAzucar() {
    return azucarAltoDetectado == 'si' ? 5 : 0;
  }

  // Método para calcular puntaje de antecedentes familiares
  int calcularPuntajeAntecedentes() {
    switch (antecedentesFamiliares) {
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

  // Método para interpretar el riesgo
  Map<String, dynamic> interpretarRiesgo() {
    if (puntajeFinal < 7) {
      return {
        'nivel': 'Bajo',
        'riesgo': '1%',
        'descripcion': 'Riesgo bajo de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFF4CAF50, // Verde
      };
    } else if (puntajeFinal >= 7 && puntajeFinal <= 11) {
      return {
        'nivel': 'Ligeramente elevado',
        'riesgo': '4%',
        'descripcion': 'Riesgo ligeramente elevado de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFFFFEB3B, // Amarillo
      };
    } else if (puntajeFinal >= 12 && puntajeFinal <= 14) {
      return {
        'nivel': 'Moderado',
        'riesgo': '17%',
        'descripcion': 'Riesgo moderado de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFFFF9800, // Naranja
      };
    } else if (puntajeFinal >= 15 && puntajeFinal <= 20) {
      return {
        'nivel': 'Alto',
        'riesgo': '33%',
        'descripcion': 'Riesgo alto de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFFF44336, // Rojo
      };
    } else {
      return {
        'nivel': 'Muy alto',
        'riesgo': '50%',
        'descripcion': 'Riesgo muy alto de desarrollar diabetes tipo 2 en los próximos 10 años',
        'color': 0xFF9C27B0, // Púrpura
      };
    }
  }
}

// Clase para manejar la interpretación del riesgo
class InterpretacionRiesgo {
  final String nivel;
  final String riesgo;
  final String descripcion;
  final int color;

  InterpretacionRiesgo({
    required this.nivel,
    required this.riesgo,
    required this.descripcion,
    required this.color,
  });

  factory InterpretacionRiesgo.fromJson(Map<String, dynamic> json) {
    return InterpretacionRiesgo(
      nivel: json['nivel']?.toString() ?? '',
      riesgo: json['riesgo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      color: json['color'] as int? ?? 0xFF4CAF50,
    );
  }
}
