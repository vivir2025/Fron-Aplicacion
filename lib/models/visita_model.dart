class Visita {
  final String id;
  final String nombreApellido;
  final String identificacion;
  final String? hta;
  final String? dm;
  final DateTime fecha;
  final String? telefono;
  final String? zona;
  final double? peso;
  final double? talla;
  final double? imc;
  final double? perimetroAbdominal;
  final int? frecuenciaCardiaca;
  final int? frecuenciaRespiratoria;
  final String? tensionArterial;
  final double? glucometria;
  final double? temperatura;
  final String? familiar;
  final String? riesgoFotografico;
  final String? abandonoSocial;
  final String? motivo;
  final String? medicamentos;
  final String? factores;
  final String? conductas;
  final String? novedades;
  final DateTime? proximoControl;
  final String idusuario;
  final String idpaciente;
  final int syncStatus;

  Visita({
    required this.id,
    required this.nombreApellido,
    required this.identificacion,
    this.hta,
    this.dm,
    required this.fecha,
    this.telefono,
    this.zona,
    this.peso,
    this.talla,
    this.imc,
    this.perimetroAbdominal,
    this.frecuenciaCardiaca,
    this.frecuenciaRespiratoria,
    this.tensionArterial,
    this.glucometria,
    this.temperatura,
    this.familiar,
    this.riesgoFotografico,
    this.abandonoSocial,
    this.motivo,
    this.medicamentos,
    this.factores,
    this.conductas,
    this.novedades,
    this.proximoControl,
    required this.idusuario,
    required this.idpaciente,
    this.syncStatus = 0, // Por defecto no sincronizado
  });

  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id']?.toString() ?? '',
      nombreApellido: json['nombre_apellido']?.toString() ?? '',
      identificacion: json['identificacion']?.toString() ?? '',
      hta: json['hta']?.toString(),
      dm: json['dm']?.toString(),
      fecha: DateTime.parse(json['fecha']?.toString() ?? DateTime.now().toString()),
      telefono: json['telefono']?.toString(),
      zona: json['zona']?.toString(),
      peso: double.tryParse(json['peso']?.toString() ?? ''),
      talla: double.tryParse(json['talla']?.toString() ?? ''),
      imc: double.tryParse(json['imc']?.toString() ?? ''),
      perimetroAbdominal: double.tryParse(json['perimetro_abdominal']?.toString() ?? ''),
      frecuenciaCardiaca: int.tryParse(json['frecuencia_cardiaca']?.toString() ?? ''),
      frecuenciaRespiratoria: int.tryParse(json['frecuencia_respiratoria']?.toString() ?? ''),
      tensionArterial: json['tension_arterial']?.toString(),
      glucometria: double.tryParse(json['glucometria']?.toString() ?? ''),
      temperatura: double.tryParse(json['temperatura']?.toString() ?? ''),
      familiar: json['familiar']?.toString(),
      riesgoFotografico: json['riesgo_fotografico']?.toString(),
      abandonoSocial: json['abandono_social']?.toString(),
      motivo: json['motivo']?.toString(),
      medicamentos: json['medicamentos']?.toString(),
      factores: json['factores']?.toString(),
      conductas: json['conductas']?.toString(),
      novedades: json['novedades']?.toString(),
      proximoControl: json['proximo_control'] != null 
          ? DateTime.parse(json['proximo_control']?.toString() ?? '')
          : null,
      idusuario: json['idusuario']?.toString() ?? '',
      idpaciente: json['idpaciente']?.toString() ?? '',
      syncStatus: json['sync_status'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_apellido': nombreApellido,
      'identificacion': identificacion,
      'hta': hta,
      'dm': dm,
      'fecha': fecha.toIso8601String(),
      'telefono': telefono,
      'zona': zona,
      'peso': peso,
      'talla': talla,
      'imc': imc,
      'perimetro_abdominal': perimetroAbdominal,
      'frecuencia_cardiaca': frecuenciaCardiaca,
      'frecuencia_respiratoria': frecuenciaRespiratoria,
      'tension_arterial': tensionArterial,
      'glucometria': glucometria,
      'temperatura': temperatura,
      'familiar': familiar,
      'riesgo_fotografico': riesgoFotografico,
      'abandono_social': abandonoSocial,
      'motivo': motivo,
      'medicamentos': medicamentos,
      'factores': factores,
      'conductas': conductas,
      'novedades': novedades,
      'proximo_control': proximoControl?.toIso8601String(),
      'idusuario': idusuario,
      'idpaciente': idpaciente,
      'sync_status': syncStatus,
    };
  }
}