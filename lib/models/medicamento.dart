// models/medicamento.dart
import 'dart:convert';

class Medicamento {
  final String id;
  final String nombmedicamento;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  Medicamento({
    required this.id,
    required this.nombmedicamento,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  // Convertir a JSON para el servidor
  Map<String, dynamic> toServerJson() {
    return {
      'id': id,
      'nombmedicamento': nombmedicamento,
    };
  }

  // Convertir a JSON para SQLite local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombmedicamento': nombmedicamento,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      id: json['id'],
      nombmedicamento: json['nombmedicamento'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      syncStatus: json['sync_status'] ?? 0,
    );
  }

  Medicamento copyWith({
    String? id,
    String? nombmedicamento,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return Medicamento(
      id: id ?? this.id,
      nombmedicamento: nombmedicamento ?? this.nombmedicamento,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'Medicamento(id: $id, nombre: $nombmedicamento)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Medicamento && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
