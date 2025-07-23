import 'dart:convert';

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
final String? riesgoFotografico; // Ruta local del archivo
final String? riesgoFotograficoUrl; // URL del servidor
final String? abandonoSocial;
final String? motivo; // JSON string de array
final String? medicamentos;
final String? factores; // JSON string de array
final String? conductas; // JSON string de array
final String? novedades;
final DateTime? proximoControl;
final String? firma; // Ruta local del archivo (LEGACY)
final String? firmaUrl; // URL del servidor (LEGACY)

// 🆕 NUEVOS CAMPOS PARA MANEJO MEJORADO DE ARCHIVOS
final String? firmaPath; // Nueva ruta local de firma
final String? firmaBase64; // Firma en base64
final List<String>? fotosPaths; // Lista de rutas locales de fotos
final List<String>? fotosBase64; // Lista de fotos en base64
final Map<String, dynamic>? opcionesMultiples; // Opciones múltiples como mapa
final List<String>? archivosAdjuntos; // Lista de archivos adjuntos adicionales

// Campos adicionales
final String idusuario;
final String idpaciente;
final int syncStatus;
final double? latitud;
final double? longitud;
final DateTime? createdAt;
final DateTime? updatedAt;
final String? estado;
final String? observacionesAdicionales;
final String? tipoVisita;

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
  this.riesgoFotograficoUrl,
  this.abandonoSocial,
  this.motivo,
  this.medicamentos,
  this.factores,
  this.conductas,
  this.novedades,
  this.proximoControl,
  this.firma, // LEGACY
  this.firmaUrl, // LEGACY
  // 🆕 Nuevos parámetros
  this.firmaPath,
  this.firmaBase64,
  this.fotosPaths,
  this.fotosBase64,
  this.opcionesMultiples,
  this.archivosAdjuntos,
  required this.idusuario,
  required this.idpaciente,
  this.syncStatus = 0,
  this.latitud,
  this.longitud,
  this.createdAt,
  this.updatedAt,
  this.estado,
  this.observacionesAdicionales,
  this.tipoVisita,
});

// Método para convertir a JSON para el servidor (snake_case)
Map<String, dynamic> toServerJson() {
  return {
    'id': id,
    'nombre_apellido': nombreApellido,
    'identificacion': identificacion,
    'hta': hta,
    'dm': dm,
    'fecha': fecha.toIso8601String().split('T')[0],
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
    'riesgo_fotografico_url': riesgoFotograficoUrl, // URL del servidor
    'abandono_social': abandonoSocial,
    'motivo': motivo, // JSON string
    'medicamentos': medicamentos,
    'factores': factores, // JSON string
    'conductas': conductas, // JSON string
    'novedades': novedades,
    'proximo_control': proximoControl?.toIso8601String().split('T')[0],
    'firma_url': firmaUrl, // URL del servidor (LEGACY)
    // 🆕 Nuevos campos para servidor
    'firma_base64': firmaBase64,
    'fotos_base64': fotosBase64,
    'opciones_multiples': opcionesMultiples != null ? jsonEncode(opcionesMultiples) : null,
    'archivos_adjuntos': archivosAdjuntos,
    'idusuario': idusuario,
    'idpaciente': idpaciente,
    'estado': estado,
    'observaciones_adicionales': observacionesAdicionales,
    'tipo_visita': tipoVisita,
  };
}

// Método para SQLite local (snake_case para compatibilidad con DB)
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
    'motivo': motivo, // JSON string
    'medicamentos': medicamentos,
    'factores': factores, // JSON string
    'conductas': conductas, // JSON string
    'novedades': novedades,
    'proximo_control': proximoControl?.toIso8601String(),
    'firma': firma,
    // 🆕 Nuevos campos
    'firma_path': firmaPath,
    'firma_base64': firmaBase64,
    'fotos_paths': fotosPaths, // Se convertirá a JSON en DatabaseHelper
    'fotos_base64': fotosBase64, // Se convertirá a JSON en DatabaseHelper
    'opciones_multiples': opcionesMultiples, // Se convertirá a JSON en DatabaseHelper
    'archivos_adjuntos': archivosAdjuntos, // Se convertirá a JSON en DatabaseHelper
    'idusuario': idusuario,
    'idpaciente': idpaciente,
    'latitud': latitud,
    'longitud': longitud,
    'sync_status': syncStatus,
    'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'estado': estado ?? 'pendiente',
    'observaciones_adicionales': observacionesAdicionales,
    'tipo_visita': tipoVisita ?? 'domiciliaria',
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
    riesgoFotograficoUrl: json['riesgo_fotografico_url'],
    abandonoSocial: json['abandono_social'],
    motivo: json['motivo'],
    medicamentos: json['medicamentos'],
    factores: json['factores'],
    conductas: json['conductas'],
    novedades: json['novedades'],
    proximoControl: json['proximo_control'] != null 
        ? DateTime.parse(json['proximo_control']) 
        : null,
    firma: json['firma'], // LEGACY
    firmaUrl: json['firma_url'], // LEGACY
    // 🆕 Nuevos campos desde JSON
    firmaPath: json['firma_path'],
    firmaBase64: json['firma_base64'],
    fotosPaths: _parseStringListFromJson(json['fotos_paths']),
    fotosBase64: _parseStringListFromJson(json['fotos_base64']),
    opcionesMultiples: _parseMapFromJson(json['opciones_multiples']),
    archivosAdjuntos: _parseStringListFromJson(json['archivos_adjuntos']),
    idusuario: json['idusuario'],
    idpaciente: json['idpaciente'],
    syncStatus: json['sync_status'] ?? 0,
    latitud: json['latitud']?.toDouble(),
    longitud: json['longitud']?.toDouble(),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    estado: json['estado'],
    observacionesAdicionales: json['observaciones_adicionales'],
    tipoVisita: json['tipo_visita'],
  );
}

// 🆕 MÉTODO COPYWITH COMPLETO
Visita copyWith({
  String? id,
  String? nombreApellido,
  String? identificacion,
  String? hta,
  String? dm,
  DateTime? fecha,
  String? telefono,
  String? zona,
  double? peso,
  double? talla,
  double? imc,
  double? perimetroAbdominal,
  int? frecuenciaCardiaca,
  int? frecuenciaRespiratoria,
  String? tensionArterial,
  double? glucometria,
  double? temperatura,
  String? familiar,
  String? riesgoFotografico,
  String? riesgoFotograficoUrl,
  String? abandonoSocial,
  String? motivo,
  String? medicamentos,
  String? factores,
  String? conductas,
  String? novedades,
  DateTime? proximoControl,
  String? firma,
  String? firmaUrl,
  String? firmaPath,
  String? firmaBase64,
  List<String>? fotosPaths,
  List<String>? fotosBase64,
  Map<String, dynamic>? opcionesMultiples,
  List<String>? archivosAdjuntos,
  String? idusuario,
  String? idpaciente,
  int? syncStatus,
  double? latitud,
  double? longitud,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? estado,
  String? observacionesAdicionales,
  String? tipoVisita,
}) {
  return Visita(
    id: id ?? this.id,
    nombreApellido: nombreApellido ?? this.nombreApellido,
    identificacion: identificacion ?? this.identificacion,
    hta: hta ?? this.hta,
    dm: dm ?? this.dm,
    fecha: fecha ?? this.fecha,
    telefono: telefono ?? this.telefono,
    zona: zona ?? this.zona,
    peso: peso ?? this.peso,
    talla: talla ?? this.talla,
    imc: imc ?? this.imc,
    perimetroAbdominal: perimetroAbdominal ?? this.perimetroAbdominal,
    frecuenciaCardiaca: frecuenciaCardiaca ?? this.frecuenciaCardiaca,
    frecuenciaRespiratoria: frecuenciaRespiratoria ?? this.frecuenciaRespiratoria,
    tensionArterial: tensionArterial ?? this.tensionArterial,
    glucometria: glucometria ?? this.glucometria,
    temperatura: temperatura ?? this.temperatura,
    familiar: familiar ?? this.familiar,
    riesgoFotografico: riesgoFotografico ?? this.riesgoFotografico,
    riesgoFotograficoUrl: riesgoFotograficoUrl ?? this.riesgoFotograficoUrl,
    abandonoSocial: abandonoSocial ?? this.abandonoSocial,
    motivo: motivo ?? this.motivo,
    medicamentos: medicamentos ?? this.medicamentos,
    factores: factores ?? this.factores,
    conductas: conductas ?? this.conductas,
    novedades: novedades ?? this.novedades,
    proximoControl: proximoControl ?? this.proximoControl,
    firma: firma ?? this.firma,
    firmaUrl: firmaUrl ?? this.firmaUrl,
    firmaPath: firmaPath ?? this.firmaPath,
    firmaBase64: firmaBase64 ?? this.firmaBase64,
    fotosPaths: fotosPaths ?? this.fotosPaths,
    fotosBase64: fotosBase64 ?? this.fotosBase64,
    opcionesMultiples: opcionesMultiples ?? this.opcionesMultiples,
    archivosAdjuntos: archivosAdjuntos ?? this.archivosAdjuntos,
    idusuario: idusuario ?? this.idusuario,
    idpaciente: idpaciente ?? this.idpaciente,
    syncStatus: syncStatus ?? this.syncStatus,
    latitud: latitud ?? this.latitud,
    longitud: longitud ?? this.longitud,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    estado: estado ?? this.estado,
    observacionesAdicionales: observacionesAdicionales ?? this.observacionesAdicionales,
    tipoVisita: tipoVisita ?? this.tipoVisita,
  );
}

// 🆕 MÉTODOS AUXILIARES PARA PARSING
static List<String>? _parseStringListFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.cast<String>();
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.cast<String>();
    } catch (e) {
      // Si falla el JSON, intentar split por comas (formato legacy)
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
  return null;
}

static Map<String, dynamic>? _parseMapFromJson(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      // Si falla el parsing, retornar null
      return null;
    }
  }
  return null;
}

// 🔧 MÉTODOS LEGACY MANTENIDOS PARA COMPATIBILIDAD
static String arrayToJsonString(List<String> array) {
  if (array.isEmpty) return '';
  return array.join(',');
}

static List<String> jsonStringToArray(String? jsonString) {
  if (jsonString == null || jsonString.isEmpty) return [];
  return jsonString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

// 🆕 MÉTODOS AUXILIARES PARA MANEJO DE ARCHIVOS

/// Obtiene todas las rutas de fotos (incluyendo riesgo fotográfico)
List<String> getAllFotosPaths() {
  List<String> todasLasFotos = [];
  
  // Agregar fotos principales
  if (fotosPaths != null && fotosPaths!.isNotEmpty) {
    todasLasFotos.addAll(fotosPaths!);
  }
  
  // Agregar riesgo fotográfico si existe
  if (riesgoFotografico != null && riesgoFotografico!.isNotEmpty) {
    todasLasFotos.add(riesgoFotografico!);
  }
  
  return todasLasFotos;
}

/// Obtiene todas las fotos en base64
List<String> getAllFotosBase64() {
  List<String> todasLasFotosBase64 = [];
  
  if (fotosBase64 != null && fotosBase64!.isNotEmpty) {
    todasLasFotosBase64.addAll(fotosBase64!);
  }
  
  return todasLasFotosBase64;
}

/// Verifica si la visita tiene archivos locales
bool tieneArchivosLocales() {
  return (fotosPaths != null && fotosPaths!.isNotEmpty) ||
         (firmaPath != null && firmaPath!.isNotEmpty) ||
         (riesgoFotografico != null && riesgoFotografico!.isNotEmpty) ||
         (archivosAdjuntos != null && archivosAdjuntos!.isNotEmpty);
}

/// Verifica si la visita tiene archivos en base64
bool tieneArchivosBase64() {
  return (fotosBase64 != null && fotosBase64!.isNotEmpty) ||
         (firmaBase64 != null && firmaBase64!.isNotEmpty);
}

/// Cuenta el total de archivos
int contarTotalArchivos() {
  int total = 0;
  
  if (fotosPaths != null) total += fotosPaths!.length;
  if (firmaPath != null && firmaPath!.isNotEmpty) total += 1;
  if (riesgoFotografico != null && riesgoFotografico!.isNotEmpty) total += 1;
  if (archivosAdjuntos != null) total += archivosAdjuntos!.length;
  
  return total;
}

/// Obtiene un resumen de los archivos
Map<String, dynamic> getResumenArchivos() {
  return {
    'fotos_principales': fotosPaths?.length ?? 0,
    'fotos_base64': fotosBase64?.length ?? 0,
    'tiene_firma': firmaPath != null || firmaBase64 != null,
    'tiene_riesgo_fotografico': riesgoFotografico != null,
    'archivos_adjuntos': archivosAdjuntos?.length ?? 0,
    'total_archivos': contarTotalArchivos(),
    'tiene_archivos_locales': tieneArchivosLocales(),
    'tiene_archivos_base64': tieneArchivosBase64(),
    'opciones_multiples_count': opcionesMultiples?.length ?? 0,
  };
}

@override
String toString() {
  return 'Visita(id: $id, nombreApellido: $nombreApellido, fecha: $fecha, '
         'syncStatus: $syncStatus, archivos: ${contarTotalArchivos()})';
}

@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is Visita && runtimeType == other.runtimeType && id == other.id;

@override
int get hashCode => id.hashCode;
}