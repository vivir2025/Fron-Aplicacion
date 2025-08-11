// models/tamizaje_model.dart
import 'dart:convert';

class Tamizaje {
  final String id;
  final String idpaciente;
  final String idusuario;
  final String veredaResidencia;
  final String? telefono;
  final String brazoToma;
  final String posicionPersona;
  final String reposoCincoMinutos;
  final DateTime fechaPrimeraToma;
  final int paSistolica;
  final int paDiastolica;
  final String? conducta;
  final int syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos adicionales para mostrar información del paciente
  final String? nombrePaciente;
  final String? identificacionPaciente;
  final int? edadPaciente;
  final String? sexoPaciente;
  final String? sedePaciente;
  final String? promotorVida;

  Tamizaje({
    required this.id,
    required this.idpaciente,
    required this.idusuario,
    required this.veredaResidencia,
    this.telefono,
    required this.brazoToma,
    required this.posicionPersona,
    required this.reposoCincoMinutos,
    required this.fechaPrimeraToma,
    required this.paSistolica,
    required this.paDiastolica,
    this.conducta,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
    this.nombrePaciente,
    this.identificacionPaciente,
    this.edadPaciente,
    this.sexoPaciente,
    this.sedePaciente,
    this.promotorVida,
  });

  factory Tamizaje.fromJson(Map<String, dynamic> json) {
    return Tamizaje(
      id: json['id']?.toString() ?? '',
      idpaciente: json['idpaciente']?.toString() ?? '',
      idusuario: json['idusuario']?.toString() ?? '',
      veredaResidencia: json['vereda_residencia']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      brazoToma: json['brazo_toma']?.toString() ?? 'derecho',
      posicionPersona: json['posicion_persona']?.toString() ?? 'sentado',
      reposoCincoMinutos: json['reposo_cinco_minutos']?.toString() ?? 'si',
      fechaPrimeraToma: json['fecha_primera_toma'] != null
          ? DateTime.parse(json['fecha_primera_toma'].toString())
          : DateTime.now(),
      paSistolica: int.tryParse(json['pa_sistolica']?.toString() ?? '0') ?? 0,
      paDiastolica: int.tryParse(json['pa_diastolica']?.toString() ?? '0') ?? 0,
      conducta: json['conducta']?.toString(),
      syncStatus: int.tryParse(json['sync_status']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      nombrePaciente: json['nombre_paciente']?.toString(),
      identificacionPaciente: json['identificacion_paciente']?.toString(),
      edadPaciente: int.tryParse(json['edad_paciente']?.toString() ?? '0'),
      sexoPaciente: json['sexo_paciente']?.toString(),
      sedePaciente: json['sede_paciente']?.toString(),
      promotorVida: json['promotor_vida']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idpaciente': idpaciente,
      'idusuario': idusuario,
      'vereda_residencia': veredaResidencia,
      'telefono': telefono,
      'brazo_toma': brazoToma,
      'posicion_persona': posicionPersona,
      'reposo_cinco_minutos': reposoCincoMinutos,
      'fecha_primera_toma': fechaPrimeraToma.toIso8601String().split('T')[0],
      'pa_sistolica': paSistolica,
      'pa_diastolica': paDiastolica,
      'conducta': conducta,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Tamizaje copyWith({
    String? id,
    String? idpaciente,
    String? idusuario,
    String? veredaResidencia,
    String? telefono,
    String? brazoToma,
    String? posicionPersona,
    String? reposoCincoMinutos,
    DateTime? fechaPrimeraToma,
    int? paSistolica,
    int? paDiastolica,
    String? conducta,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nombrePaciente,
    String? identificacionPaciente,
    int? edadPaciente,
    String? sexoPaciente,
    String? sedePaciente,
    String? promotorVida,
  }) {
    return Tamizaje(
      id: id ?? this.id,
      idpaciente: idpaciente ?? this.idpaciente,
      idusuario: idusuario ?? this.idusuario,
      veredaResidencia: veredaResidencia ?? this.veredaResidencia,
      telefono: telefono ?? this.telefono,
      brazoToma: brazoToma ?? this.brazoToma,
      posicionPersona: posicionPersona ?? this.posicionPersona,
      reposoCincoMinutos: reposoCincoMinutos ?? this.reposoCincoMinutos,
      fechaPrimeraToma: fechaPrimeraToma ?? this.fechaPrimeraToma,
      paSistolica: paSistolica ?? this.paSistolica,
      paDiastolica: paDiastolica ?? this.paDiastolica,
      conducta: conducta ?? this.conducta,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nombrePaciente: nombrePaciente ?? this.nombrePaciente,
      identificacionPaciente: identificacionPaciente ?? this.identificacionPaciente,
      edadPaciente: edadPaciente ?? this.edadPaciente,
      sexoPaciente: sexoPaciente ?? this.sexoPaciente,
      sedePaciente: sedePaciente ?? this.sedePaciente,
      promotorVida: promotorVida ?? this.promotorVida,
    );
  }

  String get presionArterial => '$paSistolica/$paDiastolica';
  
  String get clasificacionPresion {
    if (paSistolica < 120 && paDiastolica < 80) {
      return 'Normal';
    } else if (paSistolica < 130 && paDiastolica < 80) {
      return 'Elevada';
    } else if ((paSistolica >= 130 && paSistolica <= 139) || 
               (paDiastolica >= 80 && paDiastolica <= 89)) {
      return 'Hipertensión Etapa 1';
    } else if (paSistolica >= 140 || paDiastolica >= 90) {
      return 'Hipertensión Etapa 2';
    } else {
      return 'Crisis Hipertensiva';
    }
  }

  bool get isSincronizado => syncStatus == 1;
}
