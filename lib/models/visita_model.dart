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
  final String? firma;
  final String idusuario;
  final String idpaciente;
  final int syncStatus;
  final double? latitud;
  final double? longitud;

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
    this.firma,
    required this.idusuario,
    required this.idpaciente,
    this.syncStatus = 0,
    this.latitud,
    this.longitud,
  });

  // Método para convertir a JSON para el servidor (snake_case)
  Map<String, dynamic> toServerJson() {
    return {
      'id': id,
      'nombre_apellido': nombreApellido,  // ← Convertir a snake_case
      'identificacion': identificacion,
      'hta': hta,
      'dm': dm,
      'fecha': fecha.toIso8601String().split('T')[0], // Solo la fecha
      'telefono': telefono,
      'zona': zona,
      'peso': peso,
      'talla': talla,
      'imc': imc,
      'perimetro_abdominal': perimetroAbdominal,  // ← snake_case
      'frecuencia_cardiaca': frecuenciaCardiaca,  // ← snake_case
      'frecuencia_respiratoria': frecuenciaRespiratoria,  // ← snake_case
      'tension_arterial': tensionArterial,  // ← snake_case
      'glucometria': glucometria,
      'temperatura': temperatura,
      'familiar': familiar,
      'riesgo_fotografico': riesgoFotografico,  // ← snake_case
      'abandono_social': abandonoSocial,  // ← snake_case
      'motivo': motivo,
      'medicamentos': medicamentos,
      'factores': factores,
      'conductas': conductas,
      'novedades': novedades,
      'proximo_control': proximoControl?.toIso8601String().split('T')[0],  // ← snake_case
      'firma': firma,
      'idusuario': idusuario,
      'idpaciente': idpaciente,
    };
  }

  // Método para SQLite local (camelCase)
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
      'firma': firma,
      'idusuario': idusuario,
      'idpaciente': idpaciente,
      'latitud': latitud,
      'longitud': longitud,
      'sync_status': syncStatus,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id'],
      nombreApellido: json['nombre_apellido'],
      identificacion: json['identificacion'],
      hta: json['hta'],
      dm: json['dm'],
      fecha: DateTime.parse(json['fecha']),
      telefono: json['telefono'],
      zona: json['zona'],
      peso: json['peso']?.toDouble(),
      talla: json['talla']?.toDouble(),
      imc: json['imc']?.toDouble(),
      perimetroAbdominal: json['perimetro_abdominal']?.toDouble(),
      frecuenciaCardiaca: json['frecuencia_cardiaca']?.toInt(),
      frecuenciaRespiratoria: json['frecuencia_respiratoria']?.toInt(),
      tensionArterial: json['tension_arterial'],
      glucometria: json['glucometria']?.toDouble(),
      temperatura: json['temperatura']?.toDouble(),
      familiar: json['familiar'],
      riesgoFotografico: json['riesgo_fotografico'],
      abandonoSocial: json['abandono_social'],
      motivo: json['motivo'],
      medicamentos: json['medicamentos'],
      factores: json['factores'],
      conductas: json['conductas'],
      novedades: json['novedades'],
      proximoControl: json['proximo_control'] != null 
          ? DateTime.parse(json['proximo_control']) 
          : null,
      firma: json['firma'],
      idusuario: json['idusuario'],
      idpaciente: json['idpaciente'],
      syncStatus: json['sync_status'] ?? 0,
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
    );
  }
  

}