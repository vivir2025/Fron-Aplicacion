import 'dart:convert';
import 'package:uuid/uuid.dart';

class EnvioMuestra {
  final String id;
  final String codigo;
  final DateTime fecha;
  final String version;
  final String lugarTomaMuestras;
  final String? horaSalida;
  final DateTime? fechaSalida;
  final double? temperaturaSalida;
  final String? responsableTomaId; // ✅ Se llena automáticamente
  final String? responsableTransporteId; // ✅ Ahora es String normal
  final DateTime? fechaLlegada;
  final String? horaLlegada;
  final double? temperaturaLlegada;
  final String? lugarLlegada;
  final String? responsableRecepcionId; // ✅ Ahora es String normal
  final String? observaciones;
  final String idsede;
  final List<DetalleEnvioMuestra> detalles;
  final int syncStatus;

  EnvioMuestra({
    required this.id,
    required this.codigo,
    required this.fecha,
    required this.version,
    required this.lugarTomaMuestras,
    this.horaSalida,
    this.fechaSalida,
    this.temperaturaSalida,
    this.responsableTomaId, // ✅ Opcional porque se llena automáticamente
    this.responsableTransporteId, // ✅ Campo de texto
    this.fechaLlegada,
    this.horaLlegada,
    this.temperaturaLlegada,
    this.lugarLlegada,
    this.responsableRecepcionId, // ✅ Campo de texto
    this.observaciones,
    required this.idsede,
    required this.detalles,
    this.syncStatus = 0,
  });

  // ✅ MÉTODO PARA SERVIDOR SIN responsable_toma_id (se llena automáticamente)
  Map<String, dynamic> toServerJson() {
    return {
      'codigo': codigo,
      'fecha': fecha.toIso8601String().split('T')[0],
      'version': version,
      'lugar_toma_muestras': lugarTomaMuestras,
      'hora_salida': horaSalida,
      'fecha_salida': fechaSalida?.toIso8601String().split('T')[0],
      'temperatura_salida': temperaturaSalida,
      // ✅ NO ENVIAR responsable_toma_id - se asigna automáticamente en el backend
      'responsable_transporte_id': responsableTransporteId, // ✅ String
      'fecha_llegada': fechaLlegada?.toIso8601String().split('T')[0],
      'hora_llegada': horaLlegada,
      'temperatura_llegada': temperaturaLlegada,
      'lugar_llegada': lugarLlegada,
      'responsable_recepcion_id': responsableRecepcionId, // ✅ String
      'observaciones': observaciones,
      'idsede': idsede,
      'detalles': detalles.map((d) => d.toServerJson()).toList(),
    };
  }

  // Resto del código permanece igual...
  factory EnvioMuestra.fromJson(Map<String, dynamic> json) {
    return EnvioMuestra(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? 'PM-CE-TM-F-01',
      fecha: DateTime.parse(json['fecha']?.toString() ?? DateTime.now().toString()),
      version: json['version']?.toString() ?? '1',
      lugarTomaMuestras: json['lugar_toma_muestras']?.toString() ?? '',
      horaSalida: json['hora_salida']?.toString(),
      fechaSalida: json['fecha_salida'] != null 
          ? DateTime.parse(json['fecha_salida'].toString()) 
          : null,
      temperaturaSalida: double.tryParse(json['temperatura_salida']?.toString() ?? ''),
      responsableTomaId: json['responsable_toma_id']?.toString(),
      responsableTransporteId: json['responsable_transporte_id']?.toString(),
      fechaLlegada: json['fecha_llegada'] != null 
          ? DateTime.parse(json['fecha_llegada'].toString()) 
          : null,
      horaLlegada: json['hora_llegada']?.toString(),
      temperaturaLlegada: double.tryParse(json['temperatura_llegada']?.toString() ?? ''),
      lugarLlegada: json['lugar_llegada']?.toString(),
      responsableRecepcionId: json['responsable_recepcion_id']?.toString(),
      observaciones: json['observaciones']?.toString(),
      idsede: json['idsede']?.toString() ?? '',
      detalles: (json['detalles'] as List<dynamic>?)
          ?.map((d) => DetalleEnvioMuestra.fromJson(d))
          .toList() ?? [],
      syncStatus: json['sync_status'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'fecha': fecha.toIso8601String().split('T')[0],
      'version': version,
      'lugar_toma_muestras': lugarTomaMuestras,
      'hora_salida': horaSalida,
      'fecha_salida': fechaSalida?.toIso8601String().split('T')[0],
      'temperatura_salida': temperaturaSalida,
      'responsable_toma_id': responsableTomaId,
      'responsable_transporte_id': responsableTransporteId,
      'fecha_llegada': fechaLlegada?.toIso8601String().split('T')[0],
      'hora_llegada': horaLlegada,
      'temperatura_llegada': temperaturaLlegada,
      'lugar_llegada': lugarLlegada,
      'responsable_recepcion_id': responsableRecepcionId,
      'observaciones': observaciones,
      'idsede': idsede,
      'detalles': detalles.map((d) => d.toJson()).toList(),
      'sync_status': syncStatus,
    };
  }

  EnvioMuestra copyWith({
    String? id,
    String? codigo,
    DateTime? fecha,
    String? version,
    String? lugarTomaMuestras,
    String? horaSalida,
    DateTime? fechaSalida,
    double? temperaturaSalida,
    String? responsableTomaId,
    String? responsableTransporteId,
    DateTime? fechaLlegada,
    String? horaLlegada,
    double? temperaturaLlegada,
    String? lugarLlegada,
    String? responsableRecepcionId,
    String? observaciones,
    String? idsede,
    List<DetalleEnvioMuestra>? detalles,
    int? syncStatus,
  }) {
    return EnvioMuestra(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      fecha: fecha ?? this.fecha,
      version: version ?? this.version,
      lugarTomaMuestras: lugarTomaMuestras ?? this.lugarTomaMuestras,
      horaSalida: horaSalida ?? this.horaSalida,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      temperaturaSalida: temperaturaSalida ?? this.temperaturaSalida,
      responsableTomaId: responsableTomaId ?? this.responsableTomaId,
      responsableTransporteId: responsableTransporteId ?? this.responsableTransporteId,
      fechaLlegada: fechaLlegada ?? this.fechaLlegada,
      horaLlegada: horaLlegada ?? this.horaLlegada,
      temperaturaLlegada: temperaturaLlegada ?? this.temperaturaLlegada,
      lugarLlegada: lugarLlegada ?? this.lugarLlegada,
      responsableRecepcionId: responsableRecepcionId ?? this.responsableRecepcionId,
      observaciones: observaciones ?? this.observaciones,
      idsede: idsede ?? this.idsede,
      detalles: detalles ?? this.detalles,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class DetalleEnvioMuestra {
  final String id;
  final String envioMuestraId;
  final String pacienteId;
  final int numeroOrden;
  
  // DIAGNÓSTICO
  final String? dm;
  final String? hta;
  
  // NÚMERO DE MUESTRAS ENVIADAS
  final String? numMuestrasEnviadas;
  
  // TUBO LILA
  final String? tuboLila;
  
  // TUBO AMARILLO
  final String? tuboAmarillo;
  
  // TUBO AMARILLO FORRADOS
  final String? tuboAmarilloForrado;
  
  // MUESTRA DE ORINA
  final String? orinaEsp;
  final String? orina24h;
  
  // PACIENTES NEFRO (todos los exámenes) - ✅ REORDENADO
  final String? a;
  final String? m;
  final String? oe;
  final String? o24h; // ✅ COLOCADO DESPUÉS DE oe
  final String? po;
  final String? h3;
  final String? hba1c;
  final String? pth;
  final String? glu;
  final String? crea;
  final String? pl;
  final String? au;
  final String? bun;
  final String? relacionCreaAlb;
  final String? dcre24h;
  final String? alb24h;
  final String? buno24h;
  final String? fer;
  final String? tra;
  final String? fosfat;
  final String? alb;
  final String? fe;
  final String? tsh;
  final String? p;
  final String? ionograma;
  final String? b12;
  final String? acidoFolico;
  
  // DATOS FÍSICOS
  final String? peso;
  final String? talla;
  final String? volumen;
  final String? microo;
  final String? creaori;

  // ✅ MÉTODO ESTÁTICO PARA GENERAR ID CORTO
  static String generarIdCorto() {
    final uuid = Uuid();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    // ID corto: det_ + 8 chars del UUID + últimos 4 del timestamp
    return 'det_${uuid.v4().substring(0, 8)}${timestamp.substring(timestamp.length - 4)}';
  }

  DetalleEnvioMuestra({
    String? id, // ✅ CAMBIAR A OPCIONAL
    required this.envioMuestraId,
    required this.pacienteId,
    required this.numeroOrden,
    this.dm,
    this.hta,
    this.numMuestrasEnviadas,
    this.tuboLila,
    this.tuboAmarillo,
    this.tuboAmarilloForrado,
    this.orinaEsp,
    this.orina24h,
    this.a,
    this.m,
    this.oe,
    this.o24h, // ✅ AGREGADO EN LA POSICIÓN CORRECTA
    this.po,
    this.h3,
    this.hba1c,
    this.pth,
    this.glu,
    this.crea,
    this.pl,
    this.au,
    this.bun,
    this.relacionCreaAlb,
    this.dcre24h,
    this.alb24h,
    this.buno24h,
    this.fer,
    this.tra,
    this.fosfat,
    this.alb,
    this.fe,
    this.tsh,
    this.p,
    this.ionograma,
    this.b12,
    this.acidoFolico,
    this.peso,
    this.talla,
    this.volumen,
    this.microo,
    this.creaori,
  }) : id = id ?? generarIdCorto(); // ✅ GENERAR ID AUTOMÁTICAMENTE SI NO SE PROPORCIONA

  factory DetalleEnvioMuestra.fromJson(Map<String, dynamic> json) {
    return DetalleEnvioMuestra(
      id: json['id']?.toString() ?? generarIdCorto(), // ✅ USAR MÉTODO CORTO
      envioMuestraId: json['envio_muestra_id']?.toString() ?? '',
      pacienteId: json['paciente_id']?.toString() ?? '',
      numeroOrden: json['numero_orden'] as int? ?? 1,
      dm: json['dm']?.toString(),
      hta: json['hta']?.toString(),
      numMuestrasEnviadas: json['num_muestras_enviadas']?.toString(),
      tuboLila: json['tubo_lila']?.toString(),
      tuboAmarillo: json['tubo_amarillo']?.toString(),
      tuboAmarilloForrado: json['tubo_amarillo_forrado']?.toString(),
      orinaEsp: json['orina_esp']?.toString(),
      orina24h: json['orina_24h']?.toString(),
      a: json['a']?.toString(),
      m: json['m']?.toString(),
      oe: json['oe']?.toString(),
      o24h: json['o24h']?.toString(), // ✅ CAMBIADO: Leer desde 'o24h' en la BD
      po: json['po']?.toString(),
      h3: json['h3']?.toString(),
      hba1c: json['hba1c']?.toString(),
      pth: json['pth']?.toString(),
      glu: json['glu']?.toString(),
      crea: json['crea']?.toString(),
      pl: json['pl']?.toString(),
      au: json['au']?.toString(),
      bun: json['bun']?.toString(),
      relacionCreaAlb: json['relacion_crea_alb']?.toString(),
      dcre24h: json['dcre24h']?.toString(),
      alb24h: json['alb24h']?.toString(),
      buno24h: json['buno24h']?.toString(),
      fer: json['fer']?.toString(),
      tra: json['tra']?.toString(),
      fosfat: json['fosfat']?.toString(),
      alb: json['alb']?.toString(),
      fe: json['fe']?.toString(),
      tsh: json['tsh']?.toString(),
      p: json['p']?.toString(),
      ionograma: json['ionograma']?.toString(),
      b12: json['b12']?.toString(),
      acidoFolico: json['acido_folico']?.toString(),
      peso: json['peso']?.toString(),
      talla: json['talla']?.toString(),
      volumen: json['volumen']?.toString(),
      microo: json['microo']?.toString(),
      creaori: json['creaori']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.length > 20 ? id.substring(0, 20) : id, // ✅ LIMITAR LONGITUD
      'envio_muestra_id': envioMuestraId,
      'paciente_id': pacienteId,
      'numero_orden': numeroOrden,
      'dm': dm,
      'hta': hta,
      'num_muestras_enviadas': numMuestrasEnviadas,
      'tubo_lila': tuboLila,
      'tubo_amarillo': tuboAmarillo,
      'tubo_amarillo_forrado': tuboAmarilloForrado,
      'orina_esp': orinaEsp,
      'orina_24h': orina24h,
      'a': a,
      'm': m,
      'oe': oe,
      'o24h': o24h, // ✅ CAMBIADO: Guardar como 'o24h' en la BD
      'po': po,
      'h3': h3,
      'hba1c': hba1c,
      'pth': pth,
      'glu': glu,
      'crea': crea,
      'pl': pl,
      'au': au,
      'bun': bun,
      'relacion_crea_alb': relacionCreaAlb,
      'dcre24h': dcre24h,
      'alb24h': alb24h,
      'buno24h': buno24h,
      'fer': fer,
      'tra': tra,
      'fosfat': fosfat,
      'alb': alb,
      'fe': fe,
      'tsh': tsh,
      'p': p,
      'ionograma': ionograma,
      'b12': b12,
      'acido_folico': acidoFolico,
      'peso': peso,
      'talla': talla,
      'volumen': volumen,
      'microo': microo,
      'creaori': creaori,
    };
  }

  // ✅ MÉTODO ESPECÍFICO PARA ENVIAR AL SERVIDOR
  Map<String, dynamic> toServerJson() {
    return {
      'id': id.length > 20 ? id.substring(0, 20) : id, // ✅ LIMITAR A 20 CHARS
      'paciente_id': pacienteId,
      'numero_orden': numeroOrden,
      'dm': dm?.toString() ?? '',
      'hta': hta?.toString() ?? '',
      'num_muestras_enviadas': numMuestrasEnviadas?.toString() ?? '',
      'tubo_lila': tuboLila?.toString() ?? '',
      'tubo_amarillo': tuboAmarillo?.toString() ?? '',
      'tubo_amarillo_forrado': tuboAmarilloForrado?.toString() ?? '',
      'orina_esp': orinaEsp?.toString() ?? '',
      'orina_24h': orina24h?.toString() ?? '',
      'a': a?.toString() ?? '',
      'm': m?.toString() ?? '',
      'oe': oe?.toString() ?? '',
      'o24h': o24h?.toString() ?? '', // ✅ CAMBIADO: Enviar como 'o24h' al servidor
      'po': po?.toString() ?? '',
      'h3': h3?.toString() ?? '',
      'hba1c': hba1c?.toString() ?? '',
      'pth': pth?.toString() ?? '',
      'glu': glu?.toString() ?? '',
      'crea': crea?.toString() ?? '',
      'pl': pl?.toString() ?? '',
      'au': au?.toString() ?? '',
      'bun': bun?.toString() ?? '',
      'relacion_crea_alb': relacionCreaAlb?.toString() ?? '',
      'dcre24h': dcre24h?.toString() ?? '',
      'alb24h': alb24h?.toString() ?? '',
      'buno24h': buno24h?.toString() ?? '',
      'fer': fer?.toString() ?? '',
      'tra': tra?.toString() ?? '',
      'fosfat': fosfat?.toString() ?? '',
      'alb': alb?.toString() ?? '',
      'fe': fe?.toString() ?? '',
      'tsh': tsh?.toString() ?? '',
      'p': p?.toString() ?? '',
      'ionograma': ionograma?.toString() ?? '',
      'b12': b12?.toString() ?? '',
      'acido_folico': acidoFolico?.toString() ?? '',
      // ✅ CAMPOS NUMÉRICOS: Convertir a double o null (no enviar 'x')
      'peso': peso != null ? double.tryParse(peso!) : null,
      'talla': talla != null ? double.tryParse(talla!) : null,
      'volumen': volumen != null ? double.tryParse(volumen!) : null,
      'microo': microo?.toString() ?? '',
      'creaori': creaori?.toString() ?? '',
    };
  }
}
