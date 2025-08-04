class BrigadaPaciente {
  final String id;
  final String brigadaId;
  final String pacienteId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrigadaPaciente({
    required this.id,
    required this.brigadaId,
    required this.pacienteId,
    this.createdAt,
    this.updatedAt,
  });

  factory BrigadaPaciente.fromJson(Map<String, dynamic> json) {
    return BrigadaPaciente(
      id: json['id']?.toString() ?? '',
      brigadaId: json['brigada_id']?.toString() ?? '',
      pacienteId: json['paciente_id']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brigada_id': brigadaId,
      'paciente_id': pacienteId,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
