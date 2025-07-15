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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      
      'identificacion': identificacion,
      'fecnacimiento': fecnacimiento.toIso8601String(),
      'nombre': nombre,
      'apellido': apellido,
      'genero': genero,
      'longitud': longitud,
      'latitud': latitud,
      'idsede': idsede,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
  String get infoBasica => 'ID: $identificacion | ${fecnacimiento.year}';
}