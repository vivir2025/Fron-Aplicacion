// models/encuesta_model.dart
import 'dart:convert';

class Encuesta {
  final String id;
  final String idpaciente;
  final String idsede;
  final String domicilio;
  final String entidadAfiliada;
  final DateTime fecha;
  final Map<String, String> respuestasCalificacion;
  final Map<String, String> respuestasAdicionales;
  final String? sugerencias;
  final int syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Encuesta({
    required this.id,
    required this.idpaciente,
    required this.idsede,
    required this.domicilio,
    this.entidadAfiliada = 'ASMET',
    required this.fecha,
    required this.respuestasCalificacion,
    required this.respuestasAdicionales,
    this.sugerencias,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Encuesta.fromJson(Map<String, dynamic> json) {
    return Encuesta(
      id: json['id']?.toString() ?? '',
      idpaciente: json['idpaciente']?.toString() ?? '',
      idsede: json['idsede']?.toString() ?? '',
      domicilio: json['domicilio']?.toString() ?? '',
      entidadAfiliada: json['entidad_afiliada']?.toString() ?? 'ASMET',
      fecha: DateTime.parse(json['fecha']?.toString() ?? DateTime.now().toString()),
      respuestasCalificacion: _parseRespuestas(json['respuestas_calificacion']),
      respuestasAdicionales: _parseRespuestas(json['respuestas_adicionales']),
      sugerencias: json['sugerencias']?.toString(),
      syncStatus: json['sync_status'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : null,
    );
  }

  static Map<String, String> _parseRespuestas(dynamic respuestas) {
    if (respuestas == null) return {};
    
    if (respuestas is String) {
      try {
        final decoded = jsonDecode(respuestas);
        return Map<String, String>.from(decoded);
      } catch (e) {
        return {};
      }
    }
    
    if (respuestas is Map) {
      return Map<String, String>.from(respuestas);
    }
    
    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idpaciente': idpaciente,
      'idsede': idsede,
      'domicilio': domicilio,
      'entidad_afiliada': entidadAfiliada,
      'fecha': fecha.toIso8601String().split('T')[0],
      'respuestas_calificacion': jsonEncode(respuestasCalificacion),
      'respuestas_adicionales': jsonEncode(respuestasAdicionales),
      'sugerencias': sugerencias,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toServerJson() {
    final data = toJson();
    data.remove('sync_status');
    data.remove('created_at');
    data.remove('updated_at');
    return data;
  }

  Encuesta copyWith({
    String? id,
    String? idpaciente,
    String? idsede,
    String? domicilio,
    String? entidadAfiliada,
    DateTime? fecha,
    Map<String, String>? respuestasCalificacion,
    Map<String, String>? respuestasAdicionales,
    String? sugerencias,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Encuesta(
      id: id ?? this.id,
      idpaciente: idpaciente ?? this.idpaciente,
      idsede: idsede ?? this.idsede,
      domicilio: domicilio ?? this.domicilio,
      entidadAfiliada: entidadAfiliada ?? this.entidadAfiliada,
      fecha: fecha ?? this.fecha,
      respuestasCalificacion: respuestasCalificacion ?? this.respuestasCalificacion,
      respuestasAdicionales: respuestasAdicionales ?? this.respuestasAdicionales,
      sugerencias: sugerencias ?? this.sugerencias,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Métodos de utilidad para las opciones
  static const List<String> opcionesCalificacion = [
    'Excelente',
    'Bueno',
    'Regular',
    'Malo'
  ];

  static const List<String> opcionesEntendimiento = [
    'Si entendí',
    'No entendí'
  ];

  static const List<String> opcionesCaracteristicas = [
    'Amabilidad',
    'Confianza',
    'Agilidad',
    'Seguridad',
    'Otra'
  ];

  static const List<String> opcionesRecomendacion = [
    'Definitivamente sí',
    'Definitivamente no'
  ];

  static const List<String> opcionesSiNo = [
    'Sí',
    'No'
  ];

  // Preguntas para calificación
  static const List<String> preguntasCalificacion = [
    '¿El trato que recibió fue?',
    '¿Cómo definiría el tiempo en espera para la atención?',
    '¿Durante la consulta, el profesional le permitió expresar sus dudas o inquietudes con respecto a su enfermedad, a los exámenes y al tratamiento?',
    '¿Oportunidad en la asignación de citas?',
    '¿Cómo es el trato por parte del personal de la IPS?',
    '¿Cómo califica la limpieza y aseo de las instalaciones?',
    '¿Fue claro el personal administrativo en la información brindada?',
    '¿Cómo calificaría su experiencia Global respecto a los servicios de Salud en la Fundación Nacer para Vivir?'
  ];

  // Preguntas adicionales
  static const List<String> preguntasAdicionales = [
    '¿Entendió la información recibida con respecto al tratamiento?',
    '¿Cuál de estas características encontró en el profesional que lo atendió?',
    '¿Recomendaría a sus familiares y amigos esta IPS?',
    '¿Durante la atención se ha sentido usted discriminado?'
  ];
}
