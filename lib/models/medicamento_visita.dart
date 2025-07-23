// models/medicamento_visita.dart
import 'dart:convert';

class MedicamentoVisita {
  final String medicamentoId;
  final String visitaId;
  final String? indicaciones;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicamentoVisita({
    required this.medicamentoId,
    required this.visitaId,
    this.indicaciones,
    this.createdAt,
    this.updatedAt,
  });

  // Convertir a JSON para el servidor
  Map<String, dynamic> toServerJson() {
    return {
      'medicamento_id': medicamentoId,
      'visita_id': visitaId,
      'indicaciones': indicaciones,
    };
  }

  // Convertir a JSON para SQLite local
  Map<String, dynamic> toJson() {
    return {
      'medicamento_id': medicamentoId,
      'visita_id': visitaId,
      'indicaciones': indicaciones,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory MedicamentoVisita.fromJson(Map<String, dynamic> json) {
    return MedicamentoVisita(
      medicamentoId: json['medicamento_id'],
      visitaId: json['visita_id'],
      indicaciones: json['indicaciones'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  @override
  String toString() {
    return 'MedicamentoVisita(medicamentoId: $medicamentoId, visitaId: $visitaId, indicaciones: $indicaciones)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicamentoVisita && 
      runtimeType == other.runtimeType && 
      medicamentoId == other.medicamentoId && 
      visitaId == other.visitaId;

  @override
  int get hashCode => medicamentoId.hashCode ^ visitaId.hashCode;
}
