// models/medicamento_con_indicaciones.dart
import 'medicamento.dart';

class MedicamentoConIndicaciones {
  final Medicamento medicamento;
  String? indicaciones; // 🔥 NO FINAL - debe ser mutable
  bool isSelected;      // 🔥 NO FINAL - debe ser mutable

  MedicamentoConIndicaciones({
    required this.medicamento,
    this.indicaciones,
    this.isSelected = false,
  });

  // 🆕 Método para formato del servidor (ACTUALIZADO)
  Map<String, dynamic> toServerFormat() {
    return {
      'id': medicamento.id,
      'nombre': medicamento.nombmedicamento, // 🔥 INCLUIR NOMBRE
      'indicaciones': indicaciones ?? '',
    };
  }

  // 🆕 Métodos adicionales necesarios
  Map<String, dynamic> toJson() {
    return {
      'medicamento': medicamento.toJson(),
      'indicaciones': indicaciones,
      'isSelected': isSelected,
    };
  }

  factory MedicamentoConIndicaciones.fromJson(Map<String, dynamic> json) {
    return MedicamentoConIndicaciones(
      medicamento: Medicamento.fromJson(json['medicamento']),
      indicaciones: json['indicaciones'],
      isSelected: json['isSelected'] ?? false,
    );
  }

  MedicamentoConIndicaciones copyWith({
    Medicamento? medicamento,
    String? indicaciones,
    bool? isSelected,
  }) {
    return MedicamentoConIndicaciones(
      medicamento: medicamento ?? this.medicamento,
      indicaciones: indicaciones ?? this.indicaciones,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() {
    return 'MedicamentoConIndicaciones(medicamento: ${medicamento.nombmedicamento}, indicaciones: $indicaciones, selected: $isSelected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicamentoConIndicaciones &&
        other.medicamento.id == medicamento.id &&
        other.indicaciones == indicaciones &&
        other.isSelected == isSelected;
  }

  @override
  int get hashCode {
    return medicamento.id.hashCode ^
        indicaciones.hashCode ^
        isSelected.hashCode;
  }
}
