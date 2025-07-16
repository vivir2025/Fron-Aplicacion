class Paciente {
  final String id;
  final String identificacion;
  final DateTime fecnacimiento;
  final String nombre;
  final String apellido;
  final String genero;
  final double? longitud;
  final double? latitud;
  final String idsede;
  final String? nombreSede;
  final int syncStatus;

  Paciente({
    required this.id,
    required this.identificacion,
    required this.fecnacimiento,
    required this.nombre,
    required this.apellido,
    required this.genero,
    this.longitud,
    this.latitud,
    required this.idsede,
    this.nombreSede,
    this.syncStatus = 1, // Por defecto asumimos que está sincronizado
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id']?.toString() ?? '',
      identificacion: json['identificacion']?.toString() ?? '',
      fecnacimiento: DateTime.parse(json['fecnacimiento']?.toString() ?? DateTime.now().toString()),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      genero: json['genero']?.toString() ?? 'Masculino',
      longitud: double.tryParse(json['longitud']?.toString() ?? ''),
      latitud: double.tryParse(json['latitud']?.toString() ?? ''),
      idsede: json['idsede']?.toString() ?? '',
      nombreSede: json['sede']?['nombresede']?.toString(),
      syncStatus: json['sync_status'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identificacion': identificacion,
      'fecnacimiento': fecnacimiento.toIso8601String(),
      'nombre': nombre,
      'apellido': apellido,
      'genero': genero,
      'longitud': longitud,
      'latitud': latitud,
      'idsede': idsede,
      'sync_status': syncStatus,
    };
  }

  Paciente copyWith({
    String? id,
    String? identificacion,
    DateTime? fecnacimiento,
    String? nombre,
    String? apellido,
    String? genero,
    double? longitud,
    double? latitud,
    String? idsede,
    String? nombreSede,
    int? syncStatus,
  }) {
    return Paciente(
      id: id ?? this.id,
      identificacion: identificacion ?? this.identificacion,
      fecnacimiento: fecnacimiento ?? this.fecnacimiento,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      genero: genero ?? this.genero,
      longitud: longitud ?? this.longitud,
      latitud: latitud ?? this.latitud,
      idsede: idsede ?? this.idsede,
      nombreSede: nombreSede ?? this.nombreSede,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  bool get tieneGeolocalizacion => latitud != null && longitud != null;
  String? get coordenadas => tieneGeolocalizacion ? '$latitud, $longitud' : null;
  String get nombreCompleto => '$nombre $apellido';
  String get infoBasica => 'ID: $identificacion | ${fecnacimiento.year}';
}