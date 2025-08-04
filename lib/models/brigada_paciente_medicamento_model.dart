class BrigadaPacienteMedicamento {
  final String id;
  final String brigadaId;
  final String pacienteId;
  final String medicamentoId;
  final String? dosis;
  final int? cantidad;
  final String? indicaciones;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrigadaPacienteMedicamento({
    required this.id,
    required this.brigadaId,
    required this.pacienteId,
    required this.medicamentoId,
    this.dosis,
    this.cantidad,
    this.indicaciones,
    this.createdAt,
    this.updatedAt,
  });

  factory BrigadaPacienteMedicamento.fromJson(Map<String, dynamic> json) {
    return BrigadaPacienteMedicamento(
      id: json['id']?.toString() ?? '',
      brigadaId: json['brigada_id']?.toString() ?? '',
      pacienteId: json['paciente_id']?.toString() ?? '',
      medicamentoId: json['medicamento_id']?.toString() ?? '',
      dosis: json['dosis']?.toString(),
      cantidad: json['cantidad'] as int?,
      indicaciones: json['indicaciones']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brigada_id': brigadaId,
      'paciente_id': pacienteId,
      'medicamento_id': medicamentoId,
      'dosis': dosis,
      'cantidad': cantidad,
      'indicaciones': indicaciones,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
