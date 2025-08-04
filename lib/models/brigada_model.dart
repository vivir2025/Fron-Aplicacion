import 'dart:convert';

class Brigada {
  final String id;
  final String lugarEvento;
  final DateTime fechaBrigada;
  final String nombreConductor;
  final String usuariosHta;
  final String usuariosDn;
  final String usuariosHtaRcu;
  final String usuariosDmRcu;
  final String? observaciones;
  final String tema;
  final List<String>? pacientesIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  Brigada({
    required this.id,
    required this.lugarEvento,
    required this.fechaBrigada,
    required this.nombreConductor,
    required this.usuariosHta,
    required this.usuariosDn,
    required this.usuariosHtaRcu,
    required this.usuariosDmRcu,
    this.observaciones,
    required this.tema,
    this.pacientesIds,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  factory Brigada.fromJson(Map<String, dynamic> json) {
    return Brigada(
      id: json['id']?.toString() ?? '',
      lugarEvento: json['lugar_evento']?.toString() ?? '',
      fechaBrigada: DateTime.parse(json['fecha_brigada']?.toString() ?? DateTime.now().toString()),
      nombreConductor: json['nombre_conductor']?.toString() ?? '',
      usuariosHta: json['usuarios_hta']?.toString() ?? '',
      usuariosDn: json['usuarios_dn']?.toString() ?? '',
      usuariosHtaRcu: json['usuarios_hta_rcu']?.toString() ?? '',
      usuariosDmRcu: json['usuarios_dm_rcu']?.toString() ?? '',
      observaciones: json['observaciones']?.toString(),
      tema: json['tema']?.toString() ?? '',
      pacientesIds: json['pacientes_ids'] != null 
          ? (json['pacientes_ids'] is String 
              ? List<String>.from(jsonDecode(json['pacientes_ids']))
              : List<String>.from(json['pacientes_ids']))
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      syncStatus: json['sync_status'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lugar_evento': lugarEvento,
      'fecha_brigada': fechaBrigada.toIso8601String().split('T')[0],
      'nombre_conductor': nombreConductor,
      'usuarios_hta': usuariosHta,
      'usuarios_dn': usuariosDn,
      'usuarios_hta_rcu': usuariosHtaRcu,
      'usuarios_dm_rcu': usuariosDmRcu,
      'observaciones': observaciones,
      'tema': tema,
      'pacientes_ids': pacientesIds != null ? jsonEncode(pacientesIds) : null,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  // ✅ MÉTODO CORREGIDO PARA SERVIDOR CON MEDICAMENTOS
  Map<String, dynamic> toServerJson({
    Map<String, List<Map<String, dynamic>>>? medicamentosPorPaciente,
  }) {
    final json = {
      'lugar_evento': lugarEvento,
      'fecha_brigada': fechaBrigada.toIso8601String().split('T')[0],
      'nombre_conductor': nombreConductor,
      'usuarios_hta': usuariosHta,
      'usuarios_dn': usuariosDn,
      'usuarios_hta_rcu': usuariosHtaRcu,
      'usuarios_dm_rcu': usuariosDmRcu,
      'tema': tema,
      'pacientes': pacientesIds ?? [], // ✅ ENVIAR COMO ARRAY
    };

    // Agregar observaciones solo si no es null y no está vacío
    if (observaciones != null && observaciones!.isNotEmpty) {
      json['observaciones'] = observaciones!;
    }

    // ✅ INCLUIR MEDICAMENTOS EN EL FORMATO CORRECTO
    if (medicamentosPorPaciente != null && medicamentosPorPaciente.isNotEmpty) {
      List<Map<String, dynamic>> medicamentosResumen = [];
      medicamentosPorPaciente.forEach((pacienteId, medicamentos) {
        for (var medicamento in medicamentos) {
          medicamentosResumen.add({
            'paciente_id': pacienteId,
            'medicamento_id': medicamento['medicamento_id'],
            'dosis': medicamento['dosis'] ?? '',
            'cantidad': medicamento['cantidad'] ?? 0,
            'indicaciones': medicamento['indicaciones'] ?? '',
          });
        }
      });
      json['medicamentos_resumen'] = medicamentosResumen;
    }

    return json;
  }

  Brigada copyWith({
    String? id,
    String? lugarEvento,
    DateTime? fechaBrigada,
    String? nombreConductor,
    String? usuariosHta,
    String? usuariosDn,
    String? usuariosHtaRcu,
    String? usuariosDmRcu,
    String? observaciones,
    String? tema,
    List<String>? pacientesIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return Brigada(
      id: id ?? this.id,
      lugarEvento: lugarEvento ?? this.lugarEvento,
      fechaBrigada: fechaBrigada ?? this.fechaBrigada,
      nombreConductor: nombreConductor ?? this.nombreConductor,
      usuariosHta: usuariosHta ?? this.usuariosHta,
      usuariosDn: usuariosDn ?? this.usuariosDn,
      usuariosHtaRcu: usuariosHtaRcu ?? this.usuariosHtaRcu,
      usuariosDmRcu: usuariosDmRcu ?? this.usuariosDmRcu,
      observaciones: observaciones ?? this.observaciones,
      tema: tema ?? this.tema,
      pacientesIds: pacientesIds ?? this.pacientesIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'Brigada(id: $id, lugar: $lugarEvento, fecha: $fechaBrigada, pacientes: ${pacientesIds?.length ?? 0})';
  }
}
