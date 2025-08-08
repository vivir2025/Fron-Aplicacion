import 'dart:convert';

class Afinamiento {
  final String id;
  final String idpaciente;
  final String idusuario;
  final String procedencia;
  final DateTime fechaTamizaje;
  final String presionArterialTamiz;
  
  // Primer afinamiento
  final DateTime? primerAfinamientoFecha;
  final int? presionSistolica1;
  final int? presionDiastolica1;
  
  // Segundo afinamiento
  final DateTime? segundoAfinamientoFecha;
  final int? presionSistolica2;
  final int? presionDiastolica2;
  
  // Tercer afinamiento
  final DateTime? tercerAfinamientoFecha;
  final int? presionSistolica3;
  final int? presionDiastolica3;
  
  // Promedios
  final double? presionSistolicaPromedio;
  final double? presionDiastolicaPromedio;
  
  final String? conducta;
  final int syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Datos adicionales del paciente (solo para mostrar)
  final String? nombrePaciente;
  final String? identificacionPaciente;
  final int? edadPaciente;
  final String? promotorVida;

  Afinamiento({
    required this.id,
    required this.idpaciente,
    required this.idusuario,
    required this.procedencia,
    required this.fechaTamizaje,
    required this.presionArterialTamiz,
    this.primerAfinamientoFecha,
    this.presionSistolica1,
    this.presionDiastolica1,
    this.segundoAfinamientoFecha,
    this.presionSistolica2,
    this.presionDiastolica2,
    this.tercerAfinamientoFecha,
    this.presionSistolica3,
    this.presionDiastolica3,
    this.presionSistolicaPromedio,
    this.presionDiastolicaPromedio,
    this.conducta,
    this.syncStatus = 0,
    this.createdAt,
    this.updatedAt,
    this.nombrePaciente,
    this.identificacionPaciente,
    this.edadPaciente,
    this.promotorVida,
  });

  factory Afinamiento.fromJson(Map<String, dynamic> json) {
    return Afinamiento(
      id: json['id']?.toString() ?? '',
      idpaciente: json['idpaciente']?.toString() ?? '',
      idusuario: json['idusuario']?.toString() ?? '',
      procedencia: json['procedencia']?.toString() ?? '',
      fechaTamizaje: DateTime.parse(json['fecha_tamizaje']?.toString() ?? DateTime.now().toString()),
      presionArterialTamiz: json['presion_arterial_tamiz']?.toString() ?? '',
      
      primerAfinamientoFecha: json['primer_afinamiento_fecha'] != null 
          ? DateTime.parse(json['primer_afinamiento_fecha'].toString()) 
          : null,
      presionSistolica1: json['presion_sistolica_1'] != null 
          ? int.tryParse(json['presion_sistolica_1'].toString()) 
          : null,
      presionDiastolica1: json['presion_diastolica_1'] != null 
          ? int.tryParse(json['presion_diastolica_1'].toString()) 
          : null,
      
      segundoAfinamientoFecha: json['segundo_afinamiento_fecha'] != null 
          ? DateTime.parse(json['segundo_afinamiento_fecha'].toString()) 
          : null,
      presionSistolica2: json['presion_sistolica_2'] != null 
          ? int.tryParse(json['presion_sistolica_2'].toString()) 
          : null,
      presionDiastolica2: json['presion_diastolica_2'] != null 
          ? int.tryParse(json['presion_diastolica_2'].toString()) 
          : null,
      
      tercerAfinamientoFecha: json['tercer_afinamiento_fecha'] != null 
          ? DateTime.parse(json['tercer_afinamiento_fecha'].toString()) 
          : null,
      presionSistolica3: json['presion_sistolica_3'] != null 
          ? int.tryParse(json['presion_sistolica_3'].toString()) 
          : null,
      presionDiastolica3: json['presion_diastolica_3'] != null 
          ? int.tryParse(json['presion_diastolica_3'].toString()) 
          : null,
      
      presionSistolicaPromedio: json['presion_sistolica_promedio'] != null 
          ? double.tryParse(json['presion_sistolica_promedio'].toString()) 
          : null,
      presionDiastolicaPromedio: json['presion_diastolica_promedio'] != null 
          ? double.tryParse(json['presion_diastolica_promedio'].toString()) 
          : null,
      
      conducta: json['conducta']?.toString(),
      syncStatus: json['sync_status'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : null,
      
      // Datos adicionales del paciente
      nombrePaciente: json['nombre_paciente']?.toString(),
      identificacionPaciente: json['identificacion_paciente']?.toString(),
      edadPaciente: json['edad_paciente'] != null 
          ? int.tryParse(json['edad_paciente'].toString()) 
          : null,
      promotorVida: json['promotor_vida']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idpaciente': idpaciente,
      'idusuario': idusuario,
      'procedencia': procedencia,
      'fecha_tamizaje': fechaTamizaje.toIso8601String().split('T')[0],
      'presion_arterial_tamiz': presionArterialTamiz,
      
      'primer_afinamiento_fecha': primerAfinamientoFecha?.toIso8601String().split('T')[0],
      'presion_sistolica_1': presionSistolica1,
      'presion_diastolica_1': presionDiastolica1,
      
      'segundo_afinamiento_fecha': segundoAfinamientoFecha?.toIso8601String().split('T')[0],
      'presion_sistolica_2': presionSistolica2,
      'presion_diastolica_2': presionDiastolica2,
      
      'tercer_afinamiento_fecha': tercerAfinamientoFecha?.toIso8601String().split('T')[0],
      'presion_sistolica_3': presionSistolica3,
      'presion_diastolica_3': presionDiastolica3,
      
      'presion_sistolica_promedio': presionSistolicaPromedio,
      'presion_diastolica_promedio': presionDiastolicaPromedio,
      
      'conducta': conducta,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Afinamiento copyWith({
    String? id,
    String? idpaciente,
    String? idusuario,
    String? procedencia,
    DateTime? fechaTamizaje,
    String? presionArterialTamiz,
    DateTime? primerAfinamientoFecha,
    int? presionSistolica1,
    int? presionDiastolica1,
    DateTime? segundoAfinamientoFecha,
    int? presionSistolica2,
    int? presionDiastolica2,
    DateTime? tercerAfinamientoFecha,
    int? presionSistolica3,
    int? presionDiastolica3,
    double? presionSistolicaPromedio,
    double? presionDiastolicaPromedio,
    String? conducta,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nombrePaciente,
    String? identificacionPaciente,
    int? edadPaciente,
    String? promotorVida,
  }) {
    return Afinamiento(
      id: id ?? this.id,
      idpaciente: idpaciente ?? this.idpaciente,
      idusuario: idusuario ?? this.idusuario,
      procedencia: procedencia ?? this.procedencia,
      fechaTamizaje: fechaTamizaje ?? this.fechaTamizaje,
      presionArterialTamiz: presionArterialTamiz ?? this.presionArterialTamiz,
      primerAfinamientoFecha: primerAfinamientoFecha ?? this.primerAfinamientoFecha,
      presionSistolica1: presionSistolica1 ?? this.presionSistolica1,
      presionDiastolica1: presionDiastolica1 ?? this.presionDiastolica1,
      segundoAfinamientoFecha: segundoAfinamientoFecha ?? this.segundoAfinamientoFecha,
      presionSistolica2: presionSistolica2 ?? this.presionSistolica2,
      presionDiastolica2: presionDiastolica2 ?? this.presionDiastolica2,
      tercerAfinamientoFecha: tercerAfinamientoFecha ?? this.tercerAfinamientoFecha,
      presionSistolica3: presionSistolica3 ?? this.presionSistolica3,
      presionDiastolica3: presionDiastolica3 ?? this.presionDiastolica3,
      presionSistolicaPromedio: presionSistolicaPromedio ?? this.presionSistolicaPromedio,
      presionDiastolicaPromedio: presionDiastolicaPromedio ?? this.presionDiastolicaPromedio,
      conducta: conducta ?? this.conducta,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nombrePaciente: nombrePaciente ?? this.nombrePaciente,
      identificacionPaciente: identificacionPaciente ?? this.identificacionPaciente,
      edadPaciente: edadPaciente ?? this.edadPaciente,
      promotorVida: promotorVida ?? this.promotorVida,
    );
  }

  // Métodos de utilidad
  bool get tienePromedios => presionSistolicaPromedio != null && presionDiastolicaPromedio != null;
  
  bool get estaSincronizado => syncStatus == 1;
  
  String get resumenPresiones {
    List<String> presiones = [];
    if (presionSistolica1 != null && presionDiastolica1 != null) {
      presiones.add('${presionSistolica1}/${presionDiastolica1}');
    }
    if (presionSistolica2 != null && presionDiastolica2 != null) {
      presiones.add('${presionSistolica2}/${presionDiastolica2}');
    }
    if (presionSistolica3 != null && presionDiastolica3 != null) {
      presiones.add('${presionSistolica3}/${presionDiastolica3}');
    }
    return presiones.join(' - ');
  }
  
  String get promedioFormateado {
    if (tienePromedios) {
      return '${presionSistolicaPromedio!.toStringAsFixed(1)}/${presionDiastolicaPromedio!.toStringAsFixed(1)}';
    }
    return 'N/A';
  }

  // Calcular promedios automáticamente
  Map<String, double?> calcularPromedios() {
    List<int> sistolicas = [];
    List<int> diastolicas = [];
    
    if (presionSistolica1 != null) sistolicas.add(presionSistolica1!);
    if (presionSistolica2 != null) sistolicas.add(presionSistolica2!);
    if (presionSistolica3 != null) sistolicas.add(presionSistolica3!);
    
    if (presionDiastolica1 != null) diastolicas.add(presionDiastolica1!);
    if (presionDiastolica2 != null) diastolicas.add(presionDiastolica2!);
    if (presionDiastolica3 != null) diastolicas.add(presionDiastolica3!);
    
    double? promedioSistolica;
    double? promedioDiastolica;
    
    if (sistolicas.isNotEmpty) {
      promedioSistolica = sistolicas.reduce((a, b) => a + b) / sistolicas.length;
    }
    
    if (diastolicas.isNotEmpty) {
      promedioDiastolica = diastolicas.reduce((a, b) => a + b) / diastolicas.length;
    }
    
    return {
      'sistolica': promedioSistolica,
      'diastolica': promedioDiastolica,
    };
  }
}
