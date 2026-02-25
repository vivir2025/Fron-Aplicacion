import 'dart:convert';

import 'package:Bornive/models/afinamiento_model.dart';
import 'package:Bornive/models/brigada_model.dart';
import 'package:Bornive/models/brigada_paciente_medicamento_model.dart';
import 'package:Bornive/models/brigada_paciente_model.dart';
import 'package:Bornive/models/encuesta_model.dart';
import 'package:Bornive/models/envio_muestra_model.dart';
import 'package:Bornive/models/findrisk_test_model.dart';
import 'package:Bornive/models/medicamento.dart';
import 'package:Bornive/models/medicamento_con_indicaciones.dart';
import 'package:Bornive/models/tamizaje_model.dart';
import 'package:Bornive/models/visita_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/paciente_model.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
static final DatabaseHelper instance = DatabaseHelper._init();
static Database? _database;

DatabaseHelper._init();

Future<Database> get database async {
if (_database != null) return _database!;
_database = await _initDB('pacientes.db');
return _database!;
}
// 🆕 GENERADOR DE IDs ÚNICOS PARA VISITAS
String generarIdUnicoVisita() {
  // Utilizar UUID v4 estándar (sin prefijo) compatible con Laravel
  final uuid = Uuid();
  final idUnico = uuid.v4();
  
  return idUnico; // ✅ UUID v4 estándar sin prefijo
}



get totalArchivosAdjuntos => null;

Future<Database> _initDB(String filePath) async {
final dbPath = await getDatabasesPath();
final path = join(dbPath, filePath);

return await openDatabase(
  path,
  version: 16, // 🚀 Incrementado a 16
  onCreate: _createDB,
  onUpgrade: _onUpgrade,
);
}

// Crear todas las tablas desde el principio
Future _createDB(Database db, int version) async {
await db.execute('''
  CREATE TABLE pacientes (
    id TEXT PRIMARY KEY,
    identificacion TEXT,
    fecnacimiento TEXT,
    nombre TEXT,
    apellido TEXT,
    genero TEXT,
    longitud REAL,
    latitud REAL,
    idsede TEXT,
    sync_status INTEGER DEFAULT 0
  )
''');

await db.execute('''
  CREATE TABLE usuarios (
    id TEXT PRIMARY KEY,
    usuario TEXT UNIQUE,
    contrasena TEXT,
    nombre TEXT,
    correo TEXT,
    token TEXT,
    sede_id TEXT,
    last_sync TEXT,
    is_logged_in INTEGER DEFAULT 0,
    last_login TEXT
  )
''');

await db.execute('''
  CREATE TABLE sedes (
    id TEXT PRIMARY KEY,
    nombresede TEXT,
    direccion TEXT
  )
''');

// 🆕 Tabla visitas actualizada con TODAS las columnas necesarias
await db.execute('''
  CREATE TABLE visitas (
    id TEXT PRIMARY KEY,
    nombre_apellido TEXT NOT NULL,
    identificacion TEXT NOT NULL,
    hta TEXT,
    dm TEXT,
    fecha TEXT NOT NULL,
    telefono TEXT,
    zona TEXT,
    peso REAL,
    talla REAL,
    imc REAL,
    perimetro_abdominal REAL,
    frecuencia_cardiaca INTEGER,
    frecuencia_respiratoria INTEGER,
    tension_arterial TEXT,
    glucometria REAL,
    temperatura REAL,
    familiar TEXT,
    riesgo_fotografico TEXT,
    abandono_social TEXT,
    motivo TEXT,
    medicamentos TEXT,
    factores TEXT,
    conductas TEXT,
    novedades TEXT,
    proximo_control TEXT,
    firma TEXT,
    firma_path TEXT,
    firma_base64 TEXT,
    fotos_paths TEXT,
    fotos_base64 TEXT,
    opciones_multiples TEXT,
    archivos_adjuntos TEXT,
    idusuario TEXT NOT NULL,
    idpaciente TEXT NOT NULL,
    latitud REAL,
    longitud REAL,
    sync_status INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    estado TEXT DEFAULT 'pendiente',
    observaciones_adicionales TEXT,
    tipo_visita TEXT DEFAULT 'domiciliaria'
  )
''');

await db.execute('''
  CREATE TABLE medicamentos (
    id TEXT PRIMARY KEY,
    nombmedicamento TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    sync_status INTEGER DEFAULT 0
  )
''');

await db.execute('''
  CREATE TABLE medicamento_visita (
    medicamento_id TEXT NOT NULL,
    visita_id TEXT NOT NULL,
    indicaciones TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (medicamento_id, visita_id),
    FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE,
    FOREIGN KEY (visita_id) REFERENCES visitas (id) ON DELETE CASCADE
  )
''');

await db.execute('''
  CREATE TABLE IF NOT EXISTS envio_muestras (
    id TEXT PRIMARY KEY,
    codigo TEXT DEFAULT 'PM-CE-TM-F-01',
    fecha TEXT NOT NULL,
    version TEXT DEFAULT '1',
    lugar_toma_muestras TEXT,
    hora_salida TEXT,
    fecha_salida TEXT,
    temperatura_salida REAL,
    responsable_toma_id TEXT,
    responsable_transporte_id TEXT,
    fecha_llegada TEXT,
    hora_llegada TEXT,
    temperatura_llegada REAL,
    lugar_llegada TEXT,
    responsable_recepcion_id TEXT,
    observaciones TEXT,
    idsede TEXT NOT NULL,
    sync_status INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');
 // Crear tabla detalle_envio_muestras
   await db.execute('''
  CREATE TABLE IF NOT EXISTS detalle_envio_muestras (
    id TEXT PRIMARY KEY,
    envio_muestra_id TEXT NOT NULL,
    paciente_id TEXT NOT NULL,
    numero_orden INTEGER NOT NULL,
    dm TEXT,
    hta TEXT,
    num_muestras_enviadas INTEGER,
    orina_esp TEXT,
    orina_24h TEXT,
    tubo_lila TEXT,
    tubo_amarillo TEXT,
    tubo_amarillo_forrado TEXT,
    a TEXT,
    m TEXT,
    oe TEXT,
    o24h TEXT,
    po TEXT,
    h3 TEXT,
    hba1c TEXT,
    pth TEXT,
    glu TEXT,
    crea TEXT,
    pl TEXT,
    au TEXT,
    bun TEXT,
    relacion_crea_alb TEXT,
    dcre24h TEXT,
    alb24h TEXT,
    buno24h TEXT,
    fer TEXT,
    tra TEXT,
    fosfat TEXT,
    alb TEXT,
    fe TEXT,
    tsh TEXT,
    p TEXT,
    ionograma TEXT,
    b12 TEXT,
    acido_folico TEXT,
    peso REAL,
    talla REAL,
    volumen TEXT,
    microo TEXT,
    creaori TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (envio_muestra_id) REFERENCES envio_muestras (id) ON DELETE CASCADE,
    FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
  )
''');

await db.execute('''
  CREATE TABLE brigadas (
    id TEXT PRIMARY KEY,
    lugar_evento TEXT NOT NULL,
    fecha_brigada TEXT NOT NULL,
    nombre_conductor TEXT NOT NULL,
    usuarios_hta TEXT NOT NULL,
    usuarios_dn TEXT NOT NULL,
    usuarios_hta_rcu TEXT NOT NULL,
    usuarios_dm_rcu TEXT NOT NULL,
    observaciones TEXT,
    tema TEXT NOT NULL,
    pacientes_ids TEXT,
    sync_status INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');

await db.execute('''
  CREATE TABLE brigada_paciente (
    id TEXT PRIMARY KEY,
    brigada_id TEXT NOT NULL,
    paciente_id TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (brigada_id) REFERENCES brigadas (id) ON DELETE CASCADE,
    FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE,
    UNIQUE(brigada_id, paciente_id)
  )
''');

await db.execute('''
  CREATE TABLE brigada_paciente_medicamento (
    id TEXT PRIMARY KEY,
    brigada_id TEXT NOT NULL,
    paciente_id TEXT NOT NULL,
    medicamento_id TEXT NOT NULL,
    dosis TEXT,
    cantidad INTEGER,
    indicaciones TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (brigada_id) REFERENCES brigadas (id) ON DELETE CASCADE,
    FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE,
    FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE,
    UNIQUE(brigada_id, paciente_id, medicamento_id)
  )
''');

await db.execute('''
  CREATE TABLE encuestas (
    id TEXT PRIMARY KEY,
    idpaciente TEXT NOT NULL,
    idsede TEXT NOT NULL,
    domicilio TEXT NOT NULL,
    entidad_afiliada TEXT DEFAULT 'ASMET',
    fecha TEXT NOT NULL,
    respuestas_calificacion TEXT NOT NULL,
    respuestas_adicionales TEXT NOT NULL,
    sugerencias TEXT,
    sync_status INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
    FOREIGN KEY (idsede) REFERENCES sedes (id) ON DELETE CASCADE
  )
''');

await db.execute('''
  CREATE TABLE findrisk_tests (
    id TEXT PRIMARY KEY,
    idpaciente TEXT NOT NULL,
    idsede TEXT NOT NULL,
    vereda TEXT,
    telefono TEXT,
    actividad_fisica TEXT NOT NULL,
    puntaje_actividad_fisica INTEGER DEFAULT 0,
    medicamentos_hipertension TEXT NOT NULL,
    puntaje_medicamentos INTEGER DEFAULT 0,
    frecuencia_frutas_verduras TEXT NOT NULL,
    puntaje_frutas_verduras INTEGER DEFAULT 0,
    azucar_alto_detectado TEXT NOT NULL,
    puntaje_azucar_alto INTEGER DEFAULT 0,
    peso REAL NOT NULL,
    talla REAL NOT NULL,
    imc REAL DEFAULT 0,
    puntaje_imc INTEGER DEFAULT 0,
    perimetro_abdominal REAL NOT NULL,
    puntaje_perimetro INTEGER DEFAULT 0,
    antecedentes_familiares TEXT NOT NULL,
    puntaje_antecedentes INTEGER DEFAULT 0,
    puntaje_edad INTEGER DEFAULT 0,
    puntaje_final INTEGER DEFAULT 0,
    conducta TEXT,
    promotor_vida TEXT,
    sync_status INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
    FOREIGN KEY (idsede) REFERENCES sedes (id) ON DELETE CASCADE
  )
''');

await db.execute('''
  CREATE TABLE afinamientos (
    id TEXT PRIMARY KEY,
    idpaciente TEXT NOT NULL,
    idusuario TEXT NOT NULL,
    procedencia TEXT NOT NULL,
    fecha_tamizaje TEXT NOT NULL,
    presion_arterial_tamiz TEXT NOT NULL,
    primer_afinamiento_fecha TEXT,
    presion_sistolica_1 INTEGER,
    presion_diastolica_1 INTEGER,
    segundo_afinamiento_fecha TEXT,
    presion_sistolica_2 INTEGER,
    presion_diastolica_2 INTEGER,
    tercer_afinamiento_fecha TEXT,
    presion_sistolica_3 INTEGER,
    presion_diastolica_3 INTEGER,
    presion_sistolica_promedio REAL,
    presion_diastolica_promedio REAL,
    conducta TEXT,
    sync_status INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
    FOREIGN KEY (idusuario) REFERENCES usuarios (id) ON DELETE CASCADE
  )
''');
await db.execute('''
  CREATE TABLE tamizajes (
    id TEXT PRIMARY KEY,
    idpaciente TEXT NOT NULL,
    idusuario TEXT NOT NULL,
    vereda_residencia TEXT NOT NULL,
    telefono TEXT,
    brazo_toma TEXT NOT NULL,
    posicion_persona TEXT NOT NULL,
    reposo_cinco_minutos TEXT NOT NULL,
    fecha_primera_toma TEXT NOT NULL,
    pa_sistolica INTEGER NOT NULL,
    pa_diastolica INTEGER NOT NULL,
    conducta TEXT,
    sync_status INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
    FOREIGN KEY (idusuario) REFERENCES usuarios (id) ON DELETE CASCADE
  )
''');

}

Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
if (oldVersion < 2) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS usuarios (
      id TEXT PRIMARY KEY,
      usuario TEXT UNIQUE,
      contrasena TEXT,
      nombre TEXT,
      correo TEXT,
      token TEXT,
      sede_id TEXT,
      last_sync TEXT,
      is_logged_in INTEGER DEFAULT 0,
      last_login TEXT
    )
  ''');
}

if (oldVersion < 3) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS sedes (
      id TEXT PRIMARY KEY,
      nombresede TEXT,
      direccion TEXT
    )
  ''');
}

if (oldVersion < 4) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS visitas (
      id TEXT PRIMARY KEY,
      nombre_apellido TEXT NOT NULL,
      identificacion TEXT NOT NULL,
      hta TEXT,
      dm TEXT,
      fecha TEXT NOT NULL,
      telefono TEXT,
      zona TEXT,
      peso REAL,
      talla REAL,
      imc REAL,
      perimetro_abdominal REAL,
      frecuencia_cardiaca INTEGER,
      frecuencia_respiratoria INTEGER,
      tension_arterial TEXT,
      glucometria REAL,
      temperatura REAL,
      familiar TEXT,
      riesgo_fotografico TEXT,
      abandono_social TEXT,
      motivo TEXT,
      medicamentos TEXT,
      factores TEXT,
      conductas TEXT,
      novedades TEXT,
      proximo_control TEXT,
      idusuario TEXT NOT NULL,
      idpaciente TEXT NOT NULL,
      sync_status INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''');
}

if (oldVersion < 5) {
  try {
    await db.execute('ALTER TABLE visitas ADD COLUMN firma TEXT');
  } catch (e) {
  }
}

if (oldVersion < 6) {
  try {
    await db.execute('ALTER TABLE visitas ADD COLUMN latitud REAL');
    await db.execute('ALTER TABLE visitas ADD COLUMN longitud REAL');
  } catch (e) {
  }
}

// 🆕 MIGRACIÓN PARA CAMPOS MEJORADOS DE VISITAS
if (oldVersion < 8) {
  try {
    // Agregar nuevas columnas para manejo de archivos y opciones múltiples
    await db.execute('ALTER TABLE visitas ADD COLUMN firma_path TEXT');
    await db.execute('ALTER TABLE visitas ADD COLUMN firma_base64 TEXT');
    await db.execute('ALTER TABLE visitas ADD COLUMN fotos_paths TEXT');
    await db.execute('ALTER TABLE visitas ADD COLUMN fotos_base64 TEXT');
    await db.execute('ALTER TABLE visitas ADD COLUMN opciones_multiples TEXT');
    await db.execute('ALTER TABLE visitas ADD COLUMN archivos_adjuntos TEXT');
    await db.execute('ALTER TABLE visitas ADD COLUMN estado TEXT DEFAULT "pendiente"');
    await db.execute('ALTER TABLE visitas ADD COLUMN observaciones_adicionales TEXT');
    await db.execute('ALTER TABLE visitas ADD COLUMN tipo_visita TEXT DEFAULT "domiciliaria"');
    
  } catch (e) {
  }
}

// 🚀 NUEVA MIGRACIÓN PARA ASEGURAR QUE LA COLUMNA FIRMA EXISTE
if (oldVersion < 9) {
  try {
    // Verificar si la columna firma existe
    final result = await db.rawQuery("PRAGMA table_info(visitas)");
    final columnNames = result.map((column) => column['name'] as String).toList();
    
    if (!columnNames.contains('firma')) {
      await db.execute('ALTER TABLE visitas ADD COLUMN firma TEXT');
    } else {
    }
    
  } catch (e) {
  }
}
  if (oldVersion < 10) { // 🆕 Nueva versión para medicamentos
    try {
      // Crear tabla medicamentos
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medicamentos (
          id TEXT PRIMARY KEY,
          nombmedicamento TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          sync_status INTEGER DEFAULT 0
        )
      ''');

      // Crear tabla pivot medicamento_visita
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medicamento_visita (
          medicamento_id TEXT NOT NULL,
          visita_id TEXT NOT NULL,
          indicaciones TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (medicamento_id, visita_id),
          FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE,
          FOREIGN KEY (visita_id) REFERENCES visitas (id) ON DELETE CASCADE
        )
      ''');

      // Crear índices para mejor rendimiento
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_medicamentos_nombre 
        ON medicamentos (nombmedicamento)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_medicamento_visita_visita 
        ON medicamento_visita (visita_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_medicamento_visita_medicamento 
        ON medicamento_visita (medicamento_id)
      ''');
    

    

  } catch (e) {
  }
// Y agregar en _onUpgrade:
if (oldVersion < 11) {
  try {
    // Recrear tabla envio_muestras con estructura correcta
    await db.execute('DROP TABLE IF EXISTS envio_muestras');
    await db.execute('DROP TABLE IF EXISTS detalle_envio_muestras');
    
    // Crear tablas nuevamente con estructura completa
    await db.execute('''
      CREATE TABLE envio_muestras (
        id TEXT PRIMARY KEY,
        codigo TEXT DEFAULT 'PM-CE-TM-F-01',
        fecha TEXT NOT NULL,
        version TEXT DEFAULT '1',
        lugar_toma_muestras TEXT,
        hora_salida TEXT,
        fecha_salida TEXT,
        temperatura_salida REAL,
        responsable_toma_id TEXT,
        responsable_transporte_id TEXT,
        fecha_llegada TEXT,
        hora_llegada TEXT,
        temperatura_llegada REAL,
        lugar_llegada TEXT,
        responsable_recepcion_id TEXT,
        observaciones TEXT,
        idsede TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE detalle_envio_muestras (
        id TEXT PRIMARY KEY,
        envio_muestra_id TEXT NOT NULL,
        paciente_id TEXT NOT NULL,
        numero_orden INTEGER NOT NULL,
        dm TEXT,
        hta TEXT,
        num_muestras_enviadas INTEGER,
        orina_esp TEXT,
        orina_24h TEXT,
        tubo_lila TEXT,
        tubo_amarillo TEXT,
        tubo_amarillo_forrado TEXT,
        a TEXT,
        m TEXT,
        oe TEXT,
        o24h TEXT,
        po TEXT,
        h3 TEXT,
        hba1c TEXT,
        pth TEXT,
        glu TEXT,
        crea TEXT,
        pl TEXT,
        au TEXT,
        bun TEXT,
        relacion_crea_alb TEXT,
        dcre24h TEXT,
        alb24h TEXT,
        buno24h TEXT,
        fer TEXT,
        tra TEXT,
        fosfat TEXT,
        alb TEXT,
        fe TEXT,
        tsh TEXT,
        p TEXT,
        ionograma TEXT,
        b12 TEXT,
        acido_folico TEXT,
        peso REAL,
        talla REAL,
        volumen TEXT,
        microo TEXT,
        creaori TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (envio_muestra_id) REFERENCES envio_muestras (id) ON DELETE CASCADE,
        FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
      )
    ''');

    

    

  } catch (e) {
  }
}


if (oldVersion < 12) {
  try {
    // Crear tablas de brigadas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS brigadas (
        id TEXT PRIMARY KEY,
        lugar_evento TEXT NOT NULL,
        fecha_brigada TEXT NOT NULL,
        nombre_conductor TEXT NOT NULL,
        usuarios_hta TEXT NOT NULL,
        usuarios_dn TEXT NOT NULL,
        usuarios_hta_rcu TEXT NOT NULL,
        usuarios_dm_rcu TEXT NOT NULL,
        observaciones TEXT,
        tema TEXT NOT NULL,
        pacientes_ids TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS brigada_paciente (
        id TEXT PRIMARY KEY,
        brigada_id TEXT NOT NULL,
        paciente_id TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (brigada_id) REFERENCES brigadas (id) ON DELETE CASCADE,
        FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE,
        UNIQUE(brigada_id, paciente_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS brigada_paciente_medicamento (
        id TEXT PRIMARY KEY,
        brigada_id TEXT NOT NULL,
        paciente_id TEXT NOT NULL,
        medicamento_id TEXT NOT NULL,
        dosis TEXT,
        cantidad INTEGER,
        indicaciones TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (brigada_id) REFERENCES brigadas (id) ON DELETE CASCADE,
        FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE,
        FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE,
        UNIQUE(brigada_id, paciente_id, medicamento_id)
      )
    ''');

  } catch (e) {
  }

  
}
  
if (oldVersion < 13) {
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS encuestas (
        id TEXT PRIMARY KEY,
        idpaciente TEXT NOT NULL,
        idsede TEXT NOT NULL,
        domicilio TEXT NOT NULL,
        entidad_afiliada TEXT DEFAULT 'ASMET',
        fecha TEXT NOT NULL,
        respuestas_calificacion TEXT NOT NULL,
        respuestas_adicionales TEXT NOT NULL,
        sugerencias TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
        FOREIGN KEY (idsede) REFERENCES sedes (id) ON DELETE CASCADE
      )
    ''');

  } catch (e) {
  }
}


if (oldVersion < 14) { // Ajusta el número de versión
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS findrisk_tests (
        id TEXT PRIMARY KEY,
        idpaciente TEXT NOT NULL,
        idsede TEXT NOT NULL,
        vereda TEXT,
        telefono TEXT,
        actividad_fisica TEXT NOT NULL,
        puntaje_actividad_fisica INTEGER DEFAULT 0,
        medicamentos_hipertension TEXT NOT NULL,
        puntaje_medicamentos INTEGER DEFAULT 0,
        frecuencia_frutas_verduras TEXT NOT NULL,
        puntaje_frutas_verduras INTEGER DEFAULT 0,
        azucar_alto_detectado TEXT NOT NULL,
        puntaje_azucar_alto INTEGER DEFAULT 0,
        peso REAL NOT NULL,
        talla REAL NOT NULL,
        imc REAL DEFAULT 0,
        puntaje_imc INTEGER DEFAULT 0,
        perimetro_abdominal REAL NOT NULL,
        puntaje_perimetro INTEGER DEFAULT 0,
        antecedentes_familiares TEXT NOT NULL,
        puntaje_antecedentes INTEGER DEFAULT 0,
        puntaje_edad INTEGER DEFAULT 0,
        puntaje_final INTEGER DEFAULT 0,
        conducta TEXT,
        promotor_vida TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
        FOREIGN KEY (idsede) REFERENCES sedes (id) ON DELETE CASCADE
      )
    ''');

  } catch (e) {
  }
}
if (oldVersion < 15) { // Incrementar número de versión
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS afinamientos (
        id TEXT PRIMARY KEY,
        idpaciente TEXT NOT NULL,
        idusuario TEXT NOT NULL,
        procedencia TEXT NOT NULL,
        fecha_tamizaje TEXT NOT NULL,
        presion_arterial_tamiz TEXT NOT NULL,
        primer_afinamiento_fecha TEXT,
        presion_sistolica_1 INTEGER,
        presion_diastolica_1 INTEGER,
        segundo_afinamiento_fecha TEXT,
        presion_sistolica_2 INTEGER,
        presion_diastolica_2 INTEGER,
        tercer_afinamiento_fecha TEXT,
        presion_sistolica_3 INTEGER,
        presion_diastolica_3 INTEGER,
        presion_sistolica_promedio REAL,
        presion_diastolica_promedio REAL,
        conducta TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
        FOREIGN KEY (idusuario) REFERENCES usuarios (id) ON DELETE CASCADE
      )
    ''');

  } catch (e) {
  }
}
if (oldVersion < 16) { // Incrementar el número de versión
  try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tamizajes (
        id TEXT PRIMARY KEY,
        idpaciente TEXT NOT NULL,
        idusuario TEXT NOT NULL,
        vereda_residencia TEXT NOT NULL,
        telefono TEXT,
        brazo_toma TEXT NOT NULL,
        posicion_persona TEXT NOT NULL,
        reposo_cinco_minutos TEXT NOT NULL,
        fecha_primera_toma TEXT NOT NULL,
        pa_sistolica INTEGER NOT NULL,
        pa_diastolica INTEGER NOT NULL,
        conducta TEXT,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (idpaciente) REFERENCES pacientes (id) ON DELETE CASCADE,
        FOREIGN KEY (idusuario) REFERENCES usuarios (id) ON DELETE CASCADE
      )
    ''');

  } catch (e) {
  }
}
}
}

// Método para verificar si una tabla existe
Future<bool> tableExists(String tableName) async {
final db = await database;
final result = await db.rawQuery(
  "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
);
return result.isNotEmpty;
}

// Método para verificar columnas de una tabla
Future<List<String>> getTableColumns(String tableName) async {
final db = await database;
try {
  final result = await db.rawQuery("PRAGMA table_info($tableName)");
  return result.map((column) => column['name'] as String).toList();
} catch (e) {
  return [];
}
}

// Método para crear tabla sedes si no existe (método de emergencia)
Future<void> ensureSedesTableExists() async {
final db = await database;
try {
  final exists = await tableExists('sedes');
  if (!exists) {
    await db.execute('''
      CREATE TABLE sedes (
        id TEXT PRIMARY KEY,
        nombresede TEXT,
        direccion TEXT
      )
    ''');
  }
} catch (e) {
}
}

// Método para verificar y reparar la tabla visitas si es necesario
Future<void> ensureVisitasTableIntegrity() async {
final db = await database;
try {
  final columns = await getTableColumns('visitas');
  final requiredColumns = [
    'firma', 'firma_path', 'firma_base64', 'fotos_paths', 'fotos_base64',
    'opciones_multiples', 'archivos_adjuntos', 'estado', 'observaciones_adicionales', 'tipo_visita'
  ];
  
  for (String column in requiredColumns) {
    if (!columns.contains(column)) {
      try {
        String defaultValue = '';
        if (column == 'estado') defaultValue = ' DEFAULT "pendiente"';
        if (column == 'tipo_visita') defaultValue = ' DEFAULT "domiciliaria"';
        
        await db.execute('ALTER TABLE visitas ADD COLUMN $column TEXT$defaultValue');
      } catch (e) {
      }
    }
  }
} catch (e) {
}
}

// Métodos para pacientes
Future<int> createPaciente(Paciente paciente) async {
final db = await instance.database;
return await db.insert('pacientes', paciente.toJson());
}

Future<List<Paciente>> readAllPacientes() async {
final db = await instance.database;
final result = await db.query('pacientes');
return result.map((json) => Paciente.fromJson(json)).toList();
}

Future<int> updatePaciente(Paciente paciente) async {
final db = await instance.database;
return await db.update(
  'pacientes',
  paciente.toJson(),
  where: 'id = ?',
  whereArgs: [paciente.id],
);
}

Future<int> upsertPaciente(Paciente paciente) async {
final db = await database;
return await db.insert(
  'pacientes',
  paciente.toJson(),
  conflictAlgorithm: ConflictAlgorithm.replace,
);
}

// ✅ MÉTODO CORREGIDO - SOLO PACIENTES REALMENTE OFFLINE
Future<List<Paciente>> getUnsyncedPacientes() async {
  final db = await database;
  try {
    // ✅ FILTRAR CORRECTAMENTE: Solo pacientes offline O con coordenadas no sincronizadas
    final result = await db.query(
      'pacientes', 
      where: '''
        (id LIKE 'offline_%' AND sync_status = 0) OR 
        (sync_status = 0 AND (latitud IS NOT NULL OR longitud IS NOT NULL))
      ''',
      orderBy: 'identificacion ASC',
    );
    
    final pacientes = result.map((json) => Paciente.fromJson(json)).toList();
    
    for (final p in pacientes) {
    }
    
    return pacientes;
  } catch (e) {
    return [];
  }
}
// ✅ MÉTODO CORREGIDO - SIN updated_at
Future<void> markPacientesAsSynced(List<String> pacienteIds) async {
  if (pacienteIds.isEmpty) return;
  
  final db = await database;
  try {
    await db.transaction((txn) async {
      for (final id in pacienteIds) {
        final result = await txn.update(
          'pacientes',
          {
            'sync_status': 1, // ✅ SOLO sync_status, SIN updated_at
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        if (result > 0) {
        } else {
        }
      }
    });
    
    // ✅ VERIFICAR QUE SE MARCARON CORRECTAMENTE
    final verificacion = await db.query(
      'pacientes',
      where: 'id IN (${List.filled(pacienteIds.length, '?').join(',')}) AND sync_status = 1',
      whereArgs: pacienteIds,
    );
    
  } catch (e) {
    rethrow;
  }
}

// 🆕 MÉTODO PARA LIMPIAR PACIENTES DUPLICADOS DESPUÉS DE SINCRONIZACIÓN
Future<void> limpiarPacientesDuplicadosDespuesSincronizacion() async {
  final db = await database;
  try {
    // Obtener todos los pacientes
    final todosPacientes = await db.query('pacientes');
    
    // Agrupar por identificación
    Map<String, List<Map<String, dynamic>>> grupos = {};
    for (final paciente in todosPacientes) {
      final identificacion = paciente['identificacion'] as String;
      grupos.putIfAbsent(identificacion, () => []).add(paciente);
    }
    
    int eliminados = 0;
    
    // Procesar cada grupo de pacientes con la misma identificación
    for (final entrada in grupos.entries) {
      final identificacion = entrada.key;
      final pacientesGrupo = entrada.value;
      
      if (pacientesGrupo.length > 1) {
        // Encontrar el mejor paciente (prioridad: sincronizado > no offline > más reciente)
        Map<String, dynamic>? mejorPaciente;
        
        for (final paciente in pacientesGrupo) {
          final id = paciente['id'] as String;
          final syncStatus = paciente['sync_status'] as int? ?? 0;
          final isOffline = id.startsWith('offline_');
          
          if (mejorPaciente == null) {
            mejorPaciente = paciente;
          } else {
            final mejorId = mejorPaciente['id'] as String;
            final mejorSyncStatus = mejorPaciente['sync_status'] as int? ?? 0;
            final mejorIsOffline = mejorId.startsWith('offline_');
            
            // Prioridad: sincronizado > no offline
            if (syncStatus == 1 && mejorSyncStatus == 0) {
              mejorPaciente = paciente;
            } else if (syncStatus == mejorSyncStatus && !isOffline && mejorIsOffline) {
              mejorPaciente = paciente;
            }
          }
        }
        
        // Eliminar duplicados (mantener solo el mejor)
        for (final paciente in pacientesGrupo) {
          if (paciente['id'] != mejorPaciente!['id']) {
            await db.delete('pacientes', where: 'id = ?', whereArgs: [paciente['id']]);
            eliminados++;
          }
        }
      }
    }
    
  } catch (e) {
  }
}


Future<int> deletePaciente(String id) async {
final db = await instance.database;
return await db.delete(
  'pacientes',
  where: 'id = ?',
  whereArgs: [id],
);
}

// Buscar paciente por identificación
Future<Paciente?> getPacienteByIdentificacion(String identificacion) async {
final db = await database;
try {
  final result = await db.query(
    'pacientes',
    where: 'identificacion = ?',
    whereArgs: [identificacion],
    limit: 1,
  );
  
  if (result.isNotEmpty) {
    return Paciente.fromJson(result.first);
  }
  return null;
} catch (e) {
  return null;
}
}

// Obtener paciente por ID
Future<Paciente?> getPacienteById(String id) async {
final db = await database;
try {
  final result = await db.query(
    'pacientes',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  
  if (result.isNotEmpty) {
    return Paciente.fromJson(result.first);
  }
  return null;
} catch (e) {
  return null;
}
}

Future<bool> hasPacientes() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pacientes'));
    return count != null && count > 0;
  }
// MÉTODOS PARA SEDES
Future<void> saveSedes(List<dynamic> sedes) async {
final db = await database;

try {
  // Asegurar que la tabla existe
  await ensureSedesTableExists();
  
  // Limpiar sedes anteriores
  await db.delete('sedes');
  // Insertar nuevas sedes
  for (final sede in sedes) {
    final sedeData = {
      'id': sede['id'].toString(),
      'nombresede': sede['nombresede'].toString(),
      'direccion': sede['direccion']?.toString() ?? '',
    };
    
    await db.insert('sedes', sedeData);
  }
  
} catch (e) {
  rethrow;
}
}

Future<List<Map<String, dynamic>>> getSedes() async {
final db = await database;
try {
  // Asegurar que la tabla existe
  await ensureSedesTableExists();
  
  final result = await db.query('sedes');
  return result;
} catch (e) {
  return [];
}
}

// Método para verificar si hay sedes en la base de datos
Future<bool> hasSedesInDB() async {
final sedes = await getSedes();
return sedes.isNotEmpty;
}

// Método para insertar sedes por defecto
Future<void> insertDefaultSedes() async {
final db = await database;

try {
  // Asegurar que la tabla existe
  await ensureSedesTableExists();
  
  // Verificar si ya hay sedes
  final existingSedes = await getSedes();
  if (existingSedes.isNotEmpty) {
    return;
  }
  
  // Insertar sedes por defecto
  final defaultSedes = [
    {'id': 'sede-1', 'nombresede': 'Sede Principal', 'direccion': 'Dirección principal'},
    {'id': 'sede-2', 'nombresede': 'Sede Secundaria', 'direccion': 'Dirección secundaria'},
  ];
  
  for (final sede in defaultSedes) {
    await db.insert('sedes', sede);
  }
  
} catch (e) {
}
}

// Métodos para usuarios
Future<int> createUser(Map<String, dynamic> user) async {
final db = await database;

// Verificar si el usuario ya existe
final existing = await db.query(
  'usuarios',
  where: 'usuario = ?',
  whereArgs: [user['usuario']],
  limit: 1,
);

// Preparar datos para insertar/actualizar
final userData = {
  'id': user['id'],
  'usuario': user['usuario'],
  'contrasena': user['contrasena'],
  'nombre': user['nombre'],
  'correo': user['correo'],
  'token': user['token'],
  'sede_id': user['sede_id'],
  'is_logged_in': user['is_logged_in'] ?? 1,
  'last_login': user['last_login'] ?? DateTime.now().toIso8601String(),
  'last_sync': user['last_sync'] ?? DateTime.now().toIso8601String(),
};

if (existing.isNotEmpty) {
  // Actualizar usuario existente
  return await db.update(
    'usuarios',
    userData,
    where: 'usuario = ?',
    whereArgs: [user['usuario']],
  );
} else {
  // Insertar nuevo usuario
  return await db.insert('usuarios', userData);
}
}

Future<Map<String, dynamic>?> getUserByCredentials(String usuario, String contrasena) async {
final db = await database;
try {
  final result = await db.query(
    'usuarios',
    where: 'usuario = ?',
    whereArgs: [usuario],
    limit: 1,
  );

  if (result.isEmpty) return null;

  final user = result.first;
  
  // Verificar datos mínimos requeridos
  if (user['usuario'] == null || user['contrasena'] == null) {
    return null;
  }
  
  // Comparación directa de credenciales
  if (user['contrasena'] == contrasena) {
    if (user['token'] == null) {
      // ✅ LANZAR EXCEPCIÓN ESPECÍFICA SI EL TOKEN CADUCÓ POR SEGURIDAD
      throw Exception('REQUIRES_ONLINE_LOGIN');
    }

    return {
      'id': user['id'],
      'usuario': user['usuario'],
      'nombre': user['nombre'],
      'correo': user['correo'],
      'token': user['token'],
      'sede_id': user['sede_id'],
      'is_logged_in': user['is_logged_in'],
    };
  } else {
    return null;
  }
} catch (e) {
  if (e.toString().contains('REQUIRES_ONLINE_LOGIN')) {
    rethrow;
  }
  return null;
}
}

Future<void> updateUserLoginStatus(String userId, bool isLoggedIn, {String? token}) async {
final db = await instance.database;

final updateData = {
  'is_logged_in': isLoggedIn ? 1 : 0,
  'last_login': DateTime.now().toIso8601String(),
};

if (token != null) {
  updateData['token'] = token;
}

final rowsUpdated = await db.update(
  'usuarios',
  updateData,
  where: 'id = ?',
  whereArgs: [userId],
);

}

// ✅ MÉTODO CORREGIDO EN database_helper.dart
// ✅ MÉTODO CORREGIDO SIN COLUMNAS PROBLEMÁTICAS
Future<int> updatePacienteGeolocalizacion(String pacienteId, double latitud, double longitud) async {
  final db = await database;
  
  try {
    // ✅ VERIFICAR QUE EL PACIENTE EXISTE PRIMERO
    final existingPaciente = await db.query(
      'pacientes',
      where: 'id = ?',
      whereArgs: [pacienteId],
    );
    
    if (existingPaciente.isEmpty) {
      return 0;
    }
    
    // ✅ VERIFICAR QUE COLUMNAS EXISTEN ANTES DE ACTUALIZAR
    final tableInfo = await db.rawQuery("PRAGMA table_info(pacientes)");
    final columnNames = tableInfo.map((col) => col['name'].toString()).toList();
    
    // ✅ CONSTRUIR UPDATE DINÁMICAMENTE SOLO CON COLUMNAS EXISTENTES
    Map<String, dynamic> updateData = {
      'latitud': latitud,
      'longitud': longitud,
    };
    
    // Solo agregar columnas si existen
    if (columnNames.contains('sync_status')) {
      updateData['sync_status'] = 0;
    } else {
    }
    
    if (columnNames.contains('updated_at')) {
      updateData['updated_at'] = DateTime.now().toIso8601String();
    } else {
    }
    
    // ✅ ACTUALIZAR CON TRANSACCIÓN EXPLÍCITA
    final result = await db.transaction((txn) async {
      final updateResult = await txn.update(
        'pacientes',
        updateData,
        where: 'id = ?',
        whereArgs: [pacienteId],
      );
      
      return updateResult;
    });
    
    // ✅ VERIFICAR QUE LA ACTUALIZACIÓN FUE EXITOSA
    if (result > 0) {
      // Verificar que los datos se guardaron correctamente
      final updatedPaciente = await db.query(
        'pacientes',
        where: 'id = ?',
        whereArgs: [pacienteId],
      );
      
      if (updatedPaciente.isNotEmpty) {
        final paciente = updatedPaciente.first;
        if (columnNames.contains('sync_status')) {
        }
        
        // ✅ VERIFICAR QUE LOS VALORES COINCIDEN
        if (paciente['latitud'] == latitud && paciente['longitud'] == longitud) {
        } else {
        }
      }
    } else {
    }
    
    return result;
    
  } catch (e) {
    rethrow;
  }
}
// 🆕 MÉTODO PARA DEBUG Y VERIFICACIÓN DE ESTADO
Future<void> debugPacientesSyncStatus() async {
  final db = await database;
  try {
    final todosPacientes = await db.query('pacientes', orderBy: 'identificacion');
    
    int sincronizados = 0;
    int pendientes = 0;
    int offline = 0;
    
    for (final paciente in todosPacientes) {
      final id = paciente['id'] as String;
      final identificacion = paciente['identificacion'] as String;
      final syncStatus = paciente['sync_status'] as int? ?? 0;
      final latitud = paciente['latitud'];
      final longitud = paciente['longitud'];
      final isOffline = id.startsWith('offline_');
      
      if (isOffline) {
        offline++;
      } else if (syncStatus == 0) {
        pendientes++;
      } else {
        sincronizados++;
      }
    }
    
  } catch (e) {
  }
}

// ✅ MÉTODO PARA VERIFICAR Y AGREGAR COLUMNAS NECESARIAS
Future<void> verificarYAgregarColumnasGeolocalizacion() async {
  final db = await database;
  
  try {
    // Obtener información de la tabla
    final tableInfo = await db.rawQuery("PRAGMA table_info(pacientes)");
    final columnNames = tableInfo.map((col) => col['name'].toString()).toList();
    
    // Verificar y agregar columnas necesarias
    final columnasNecesarias = {
      'latitud': 'REAL',
      'longitud': 'REAL',
      'sync_status': 'INTEGER DEFAULT 0',
      'updated_at': 'TEXT',
    };
    
    for (final entrada in columnasNecesarias.entries) {
      final nombreColumna = entrada.key;
      final tipoColumna = entrada.value;
      
      if (!columnNames.contains(nombreColumna)) {
        try {
          await db.execute('ALTER TABLE pacientes ADD COLUMN $nombreColumna $tipoColumna');
        } catch (e) {
          if (e.toString().contains('duplicate column name')) {
          } else {
          }
        }
      } else {
      }
    }
    
    // Verificar estructura final
    final finalTableInfo = await db.rawQuery("PRAGMA table_info(pacientes)");
    final finalColumnNames = finalTableInfo.map((col) => col['name'].toString()).toList();
  } catch (e) {
  }
}


Future<Map<String, dynamic>?> getLoggedInUser() async {
final db = await instance.database;
try {
  final result = await db.query(
    'usuarios',
    where: 'is_logged_in = 1',
    orderBy: 'last_login DESC',
    limit: 1,
  );
  
  if (result.isNotEmpty) {
    return result.first;
  }
  
  return null;
} catch (e) {
  return null;
}
}

Future<void> clearOldSessions() async {
final db = await database;
await db.update(
  'usuarios',
  {'is_logged_in': 0},
  where: 'is_logged_in = 1',
);
}

Future<void> debugListUsers() async {
final db = await database;
final users = await db.query('usuarios');
for (final user in users) {
}
}

Future<void> debugListSedes() async {
final sedes = await getSedes();
for (final sede in sedes) {
}
}

Future<List<Map<String, dynamic>>> getAllUsers() async {
final db = await database;
try {
  return await db.query('usuarios');
} catch (e) {
  return [];
}
}

// 🔄 MÉTODO ACTUALIZADO PARA CREAR VISITAS ASEGURANDO ID ÚNICO
Future<bool> createVisita(Visita visita) async {
  try {
    final db = await database;
    
    // Asegurar integridad de la tabla visitas
    await ensureVisitasTableIntegrity();
    
    // Si la visita no tiene ID asignado, generar uno único
    if (visita.id == null || visita.id!.isEmpty) {
      final nuevoId = generarIdUnicoVisita();
      visita = visita.copyWith(id: nuevoId);
    } else {
      // ✅ Validar que el ID tenga formato UUID válido
      final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      if (!uuidPattern.hasMatch(visita.id)) {
        final nuevoId = generarIdUnicoVisita();
        visita = visita.copyWith(id: nuevoId);
      }
      
      // ✅ Verificar si ya existe una visita con este ID
      final visitaExistente = await getVisitaById(visita.id);
      if (visitaExistente != null) {
        return await updateVisita(visita);
      }
    }
    
    // Preparar datos con manejo especial para archivos y opciones múltiples
    final visitaData = _prepareVisitaDataForDB(visita);
    
    final result = await db.insert(
      'visitas', 
      visitaData,
      conflictAlgorithm: ConflictAlgorithm.abort, // ✅ Cambiar a abort para detectar duplicados
    );
    
    return result > 0;
  } catch (e) {
    // ✅ Si falla por duplicado, intentar actualizar
    if (e.toString().contains('UNIQUE constraint failed')) {
      return await updateVisita(visita);
    }
    return false;
  }
}



Future<bool> updateVisita(Visita visita) async {
try {
  final db = await database;
  
  // Asegurar integridad de la tabla visitas
  await ensureVisitasTableIntegrity();
  
  // Preparar datos con manejo especial para archivos y opciones múltiples
  final visitaData = _prepareVisitaDataForDB(visita);
  visitaData['updated_at'] = DateTime.now().toIso8601String();
  
  final result = await db.update(
    'visitas',
    visitaData,
    where: 'id = ?',
    whereArgs: [visita.id],
  );
  
  return result > 0;
} catch (e) {
  return false;
}
}

// 🚀 MÉTODO AUXILIAR PARA PREPARAR DATOS DE VISITA PARA LA BASE DE DATOS
Map<String, dynamic> _prepareVisitaDataForDB(Visita visita) {
final visitaData = visita.toJson();

// Convertir listas a JSON string para almacenamiento
if (visitaData['fotos_paths'] is List) {
  visitaData['fotos_paths'] = _listToJsonString(visitaData['fotos_paths']);
}
if (visitaData['fotos_base64'] is List) {
  visitaData['fotos_base64'] = _listToJsonString(visitaData['fotos_base64']);
}
if (visitaData['opciones_multiples'] is Map) {
  visitaData['opciones_multiples'] = _mapToJsonString(visitaData['opciones_multiples']);
}
if (visitaData['archivos_adjuntos'] is List) {
  visitaData['archivos_adjuntos'] = _listToJsonString(visitaData['archivos_adjuntos']);
}

// Asegurar que las columnas requeridas existan con valores por defecto
visitaData['estado'] ??= 'pendiente';
visitaData['tipo_visita'] ??= 'domiciliaria';
visitaData['sync_status'] ??= 0;

return visitaData;
}

// 🆕 MÉTODO PARA MIGRAR UUIDs ANTIGUOS CON PREFIJO
Future<void> migrarUUIDsAntiguos() async {
  try {
    final db = await database;
    
    // Obtener todas las visitas con prefijo 'vis_'
    final visitasConPrefijo = await db.query(
      'visitas',
      where: 'id LIKE ?',
      whereArgs: ['vis_%'],
    );
    
    if (visitasConPrefijo.isEmpty) {
      return;
    }
    
    for (var visitaData in visitasConPrefijo) {
      final idAntiguo = visitaData['id'] as String;
      // Remover el prefijo 'vis_'
      final idNuevo = idAntiguo.replaceFirst('vis_', '');
      
      // Verificar que el nuevo ID sea un UUID válido
      final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      
      if (uuidPattern.hasMatch(idNuevo)) {
        // Verificar si el nuevo ID ya existe
        final existente = await db.query(
          'visitas',
          where: 'id = ?',
          whereArgs: [idNuevo],
        );
        
        if (existente.isEmpty) {
          // Actualizar el ID
          await db.update(
            'visitas',
            {'id': idNuevo},
            where: 'id = ?',
            whereArgs: [idAntiguo],
          );
        } else {
          await db.delete('visitas', where: 'id = ?', whereArgs: [idAntiguo]);
        }
      } else {
      }
    }
    
  } catch (e) {
  }
}

Future<List<Visita>> getVisitasByUsuario(String usuarioId) async {
try {
  final db = await database;
  final result = await db.query(
    'visitas',
    where: 'idusuario = ?',
    whereArgs: [usuarioId],
    orderBy: 'fecha DESC',
  );
  
  return result.map((json) => _processVisitaFromDB(json)).toList();
} catch (e) {
  return [];
}
}

Future<Visita?> getVisitaById(String id) async {
try {
  final db = await database;
  final result = await db.query(
    'visitas',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  
  if (result.isNotEmpty) {
    return _processVisitaFromDB(result.first);
  }
  return null;
} catch (e) {
  return null;
}
}

Future<List<Visita>> getAllVisitas() async {
try {
  final db = await database;
  final result = await db.query(
    'visitas',
    orderBy: 'fecha DESC',
  );
  
  return result.map((json) => _processVisitaFromDB(json)).toList();
} catch (e) {
  return [];
}
}

Future<List<Visita>> getVisitasByPaciente(String pacienteId) async {
try {
  final db = await database;
  final result = await db.query(
    'visitas',
    where: 'idpaciente = ?',
    whereArgs: [pacienteId],
    orderBy: 'fecha DESC',
  );
  return result.map((json) => _processVisitaFromDB(json)).toList();
} catch (e) {
  return [];
}
}

Future<List<Visita>> getVisitasNoSincronizadas() async {
try {
  final db = await database;
  final result = await db.query(
    'visitas',
    where: 'sync_status = ?',
    whereArgs: [0], // 0 = no sincronizado
    orderBy: 'fecha DESC',
  );
  return result.map((json) => _processVisitaFromDB(json)).toList();
} catch (e) {
  return [];
}
}

Future<bool> deleteVisita(String id) async {
try {
  final db = await database;
  final result = await db.delete(
    'visitas',
    where: 'id = ?',
    whereArgs: [id],
  );
  return result > 0;
} catch (e) {
  return false;
}
}

Future<int> countVisitasByUsuario(String usuarioId) async {
try {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) FROM visitas WHERE idusuario = ?',
    [usuarioId],
  );
  return Sqflite.firstIntValue(result) ?? 0;
} catch (e) {
  return 0;
}
}

Future<List<Visita>> getUltimasVisitas(int limit, {String? usuarioId}) async {
try {
  final db = await database;
  final result = await db.query(
    'visitas',
    where: usuarioId != null ? 'idusuario = ?' : null,
    whereArgs: usuarioId != null ? [usuarioId] : null,
    orderBy: 'fecha DESC',
    limit: limit,
  );
  return result.map((json) => _processVisitaFromDB(json)).toList();
} catch (e) {
  return [];
}
}

Future<bool> marcarVisitasComoSincronizadas(List<String> ids) async {
if (ids.isEmpty) return true;

try {
  final db = await database;
  final result = await db.update(
    'visitas',
    {
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'id IN (${List.filled(ids.length, '?').join(',')})',
    whereArgs: ids,
  );
  return result > 0;
} catch (e) {
  return false;
}
}

Future<bool> marcarVisitaComoSincronizada(String id) async {
try {
  final db = await database;
  final result = await db.update(
    'visitas',
    {
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [id],
  );
  
  return result > 0;
} catch (e) {
  return false;
}
}

// 🆕 MÉTODOS AUXILIARES PARA MANEJO DE DATOS JSON

String _listToJsonString(List<dynamic>? list) {
if (list == null || list.isEmpty) return '[]';
try {
  return jsonEncode(list);
} catch (e) {
  return '[]';
}
}

String _mapToJsonString(Map<String, dynamic>? map) {
if (map == null || map.isEmpty) return '{}';
try {
  return jsonEncode(map);
} catch (e) {
  return '{}';
}
}

List<dynamic> _jsonStringToList(String? jsonString) {
if (jsonString == null || jsonString.isEmpty || jsonString == '[]') return [];
try {
  final decoded = jsonDecode(jsonString);
  return decoded is List ? decoded : [];
} catch (e) {
  return [];
}
}

Map<String, dynamic> _jsonStringToMap(String? jsonString) {
if (jsonString == null || jsonString.isEmpty || jsonString == '{}') return {};
try {
  final decoded = jsonDecode(jsonString);
  return decoded is Map<String, dynamic> ? decoded : {};
} catch (e) {
  return {};
}
}

// Procesar datos de visita desde la base de datos
Visita _processVisitaFromDB(Map<String, dynamic> json) {
// Procesar campos JSON almacenados como strings
final processedJson = Map<String, dynamic>.from(json);

// Convertir campos JSON de vuelta a objetos
if (processedJson['fotos_paths'] is String) {
  processedJson['fotos_paths'] = _jsonStringToList(processedJson['fotos_paths']);
}

if (processedJson['fotos_base64'] is String) {
  processedJson['fotos_base64'] = _jsonStringToList(processedJson['fotos_base64']);
}

if (processedJson['opciones_multiples'] is String) {
  processedJson['opciones_multiples'] = _jsonStringToMap(processedJson['opciones_multiples']);
}

if (processedJson['archivos_adjuntos'] is String) {
  processedJson['archivos_adjuntos'] = _jsonStringToList(processedJson['archivos_adjuntos']);
}

return Visita.fromJson(processedJson);
}

// 🆕 MÉTODOS ESPECÍFICOS PARA MANEJO DE ARCHIVOS EN VISITAS

Future<bool> agregarFotoAVisita(String visitaId, String fotoPath, {String? fotoBase64}) async {
try {
  final visita = await getVisitaById(visitaId);
  if (visita == null) return false;
  
  // Obtener listas actuales de fotos
  List<String> fotosPaths = List<String>.from(visita.fotosPaths ?? []);
  List<String> fotosBase64 = List<String>.from(visita.fotosBase64 ?? []);
  
  // Agregar nueva foto
  fotosPaths.add(fotoPath);
  if (fotoBase64 != null) {
    fotosBase64.add(fotoBase64);
  }
  
  // Actualizar visita
  final visitaActualizada = visita.copyWith(
    fotosPaths: fotosPaths,
    fotosBase64: fotosBase64.isNotEmpty ? fotosBase64 : null,
    opcionesMultiples: visita.opcionesMultiples ?? {},
  );
  
  return await updateVisita(visitaActualizada);
} catch (e) {
  return false;
}
}

Future<bool> eliminarFotoDeVisita(String visitaId, int indice) async {
try {
  final visita = await getVisitaById(visitaId);
  if (visita == null) return false;
  
  // Obtener listas actuales de fotos
  List<String> fotosPaths = List<String>.from(visita.fotosPaths ?? []);
  List<String> fotosBase64 = List<String>.from(visita.fotosBase64 ?? []);
  
  // Eliminar foto por índice
  if (indice >= 0 && indice < fotosPaths.length) {
    fotosPaths.removeAt(indice);
  }
  
  if (indice >= 0 && indice < fotosBase64.length) {
    fotosBase64.removeAt(indice);
  }
  
  // Actualizar visita
  final visitaActualizada = visita.copyWith(
    fotosPaths: fotosPaths,
    fotosBase64: fotosBase64.isNotEmpty ? fotosBase64 : null,
    opcionesMultiples: visita.opcionesMultiples ?? {},
  );
  
  return await updateVisita(visitaActualizada);
} catch (e) {
  return false;
}
}

Future<bool> actualizarFirmaVisita(String visitaId, String? firmaPath, {String? firmaBase64}) async {
try {
  final visita = await getVisitaById(visitaId);
  if (visita == null) return false;
  
  // Actualizar firma
  final visitaActualizada = visita.copyWith(
    firmaPath: firmaPath,
    firmaBase64: firmaBase64,
    fotosPaths: visita.fotosPaths ?? [],
    opcionesMultiples: visita.opcionesMultiples ?? {},
  );
  
  return await updateVisita(visitaActualizada);
} catch (e) {
  return false;
}
}

Future<bool> actualizarOpcionesMultiples(String visitaId, Map<String, dynamic> opciones) async {
try {
  final visita = await getVisitaById(visitaId);
  if (visita == null) return false;
  
  // Combinar opciones existentes con nuevas
  final opcionesActuales = Map<String, dynamic>.from(visita.opcionesMultiples ?? {});
  opcionesActuales.addAll(opciones);
  
  // Actualizar visita
  final visitaActualizada = visita.copyWith(
    opcionesMultiples: opcionesActuales,
    fotosPaths: visita.fotosPaths ?? [],
  );
  
  return await updateVisita(visitaActualizada);
} catch (e) {
  return false;
}
}

// 🆕 MÉTODOS DE ESTADÍSTICAS PARA ARCHIVOS

Future<Map<String, dynamic>> obtenerEstadisticasArchivos() async {
try {
  final todasLasVisitas = await getAllVisitas();
  
  int fotosLocales = 0;
  int fotosEnServidor = 0;
  int firmasLocales = 0;
  int firmasEnServidor = 0;
  int totalArchivosAdjuntos = 0;
  
  for (var visita in todasLasVisitas) {
    // Contar fotos principales (fotosPaths)
    if (visita.fotosPaths != null && visita.fotosPaths!.isNotEmpty) {
      for (var fotoPath in visita.fotosPaths!) {
        if (fotoPath.startsWith('http')) {
          fotosEnServidor++;
        } else {
          fotosLocales++;
        }
      }
    }
    
    // Contar foto de riesgo (legacy)
    if (visita.riesgoFotografico != null && visita.riesgoFotografico!.isNotEmpty) {
      // Verificar si tiene URL del servidor o es local
      final riesgoFoto = visita.riesgoFotografico!;
      if (riesgoFoto.startsWith('http')) {
        fotosEnServidor++;
      } else {
        fotosLocales++;
      }
    }
    
    // Contar firmas (nueva estructura)
    if (visita.firmaPath != null && visita.firmaPath!.isNotEmpty) {
      if (visita.firmaPath!.startsWith('http')) {
        firmasEnServidor++;
      } else {
        firmasLocales++;
      }
    }
    
    // Contar firmas (legacy)
    if (visita.firma != null && visita.firma!.isNotEmpty) {
      // Verificar si la firma legacy tiene URL del servidor
      final firmaLegacy = visita.firma!;
      if (firmaLegacy.startsWith('http')) {
        firmasEnServidor++;
      } else {
        firmasLocales++;
      }
    }
    
    // Contar archivos adjuntos
    if (visita.archivosAdjuntos != null) {
      totalArchivosAdjuntos += visita.archivosAdjuntos!.length;
    }
  }
  
  // Calcular totales
  int totalFotos = fotosLocales + fotosEnServidor;
  int totalFirmas = firmasLocales + firmasEnServidor;
  int totalArchivos = totalFotos + totalFirmas + totalArchivosAdjuntos;
  
  // Calcular porcentajes
  double porcentajeFotosLocales = totalFotos > 0 ? (fotosLocales / totalFotos) * 100 : 0;
  double porcentajeFotosServidor = totalFotos > 0 ? (fotosEnServidor / totalFotos) * 100 : 0;
  double porcentajeFirmasLocales = totalFirmas > 0 ? (firmasLocales / totalFirmas) * 100 : 0;
  double porcentajeFirmasServidor = totalFirmas > 0 ? (firmasEnServidor / totalFirmas) * 100 : 0;
  
  return {
    'fotos': {
      'locales': fotosLocales,
      'servidor': fotosEnServidor,
      'total': totalFotos,
      'porcentaje_locales': porcentajeFotosLocales.round(),
      'porcentaje_servidor': porcentajeFotosServidor.round(),
    },
    'firmas': {
      'locales': firmasLocales,
      'servidor': firmasEnServidor,
      'total': totalFirmas,
      'porcentaje_locales': porcentajeFirmasLocales.round(),
      'porcentaje_servidor': porcentajeFirmasServidor.round(),
    },
    'archivos_adjuntos': {
      'total': totalArchivosAdjuntos,
    },
    'resumen': {
      'total_archivos': totalArchivos,
      'total_visitas': todasLasVisitas.length,
      'archivos_por_visita': todasLasVisitas.length > 0 
          ? (totalArchivos / todasLasVisitas.length).toStringAsFixed(1) 
          : '0',
      'fotos_por_visita': todasLasVisitas.length > 0 
          ? (totalFotos / todasLasVisitas.length).toStringAsFixed(1) 
          : '0',
      'firmas_por_visita': todasLasVisitas.length > 0 
          ? (totalFirmas / todasLasVisitas.length).toStringAsFixed(1) 
          : '0',
    }
  };
  
} catch (e) {
  return {
    'error': true,
    'mensaje': 'Error al obtener estadísticas: ${e.toString()}',
    'fotos': {
      'locales': 0,
      'servidor': 0,
      'total': 0,
      'porcentaje_locales': 0,
      'porcentaje_servidor': 0,
    },
    'firmas': {
      'locales': 0,
      'servidor': 0,
      'total': 0,
      'porcentaje_locales': 0,
      'porcentaje_servidor': 0,
    },
    'archivos_adjuntos': {
      'total': 0,
    },
    'resumen': {
      'total_archivos': 0,
      'total_visitas': 0,
      'archivos_por_visita': '0',
      'fotos_por_visita': '0',
      'firmas_por_visita': '0',
    }
  };
}
}

// 🆕 MÉTODO PARA LIMPIAR ARCHIVOS HUÉRFANOS
Future<Map<String, dynamic>> limpiarArchivosHuerfanos() async {
try {
  final db = await database;
  int visitasLimpiadas = 0;
  int archivosEliminados = 0;
  
  // Obtener todas las visitas
  final visitas = await getAllVisitas();
  
  for (var visita in visitas) {
    bool visitaModificada = false;
    
    // Limpiar fotos paths vacías o inválidas
    if (visita.fotosPaths != null) {
      final fotosLimpias = visita.fotosPaths!
          .where((path) => path.isNotEmpty && path.trim().isNotEmpty)
          .toList();
      
      if (fotosLimpias.length != visita.fotosPaths!.length) {
        archivosEliminados += (visita.fotosPaths!.length - fotosLimpias.length);
        visitaModificada = true;
      }
    }
    
    // Limpiar fotos base64 vacías
    if (visita.fotosBase64 != null) {
      final fotosBase64Limpias = visita.fotosBase64!
          .where((base64) => base64.isNotEmpty && base64.trim().isNotEmpty)
          .toList();
      
      if (fotosBase64Limpias.length != visita.fotosBase64!.length) {
        visitaModificada = true;
      }
    }
    
    // Limpiar archivos adjuntos vacíos
    if (visita.archivosAdjuntos != null) {
      final archivosLimpios = visita.archivosAdjuntos!
          .where((archivo) => archivo.toString().isNotEmpty)
          .toList();
      
      if (archivosLimpios.length != visita.archivosAdjuntos!.length) {
        archivosEliminados += (visita.archivosAdjuntos!.length - archivosLimpios.length);
        visitaModificada = true;
      }
    }
    
    if (visitaModificada) {
      await updateVisita(visita);
      visitasLimpiadas++;
    }
  }
  
  return {
    'exito': true,
    'visitas_limpiadas': visitasLimpiadas,
    'archivos_eliminados': archivosEliminados,
    'mensaje': 'Limpieza completada exitosamente'
  };
  
} catch (e) {
  return {
    'exito': false,
    'error': e.toString(),
    'mensaje': 'Error durante la limpieza'
  };
}
}

// 🆕 MÉTODO PARA OPTIMIZAR LA BASE DE DATOS
Future<bool> optimizarBaseDatos() async {
try {
  final db = await database;
  
  // Ejecutar VACUUM para optimizar la base de datos
  await db.execute('VACUUM');
  
  // Reindexar para mejorar el rendimiento
  await db.execute('REINDEX');
  
  return true;
} catch (e) {
  return false;
}
}

// 🆕 MÉTODO PARA OBTENER INFORMACIÓN DE LA BASE DE DATOS
Future<Map<String, dynamic>> obtenerInfoBaseDatos() async {
try {
  final db = await database;
  
  // Obtener información de las tablas
  final tablas = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  
  Map<String, int> conteoTablas = {};
  for (var tabla in tablas) {
    final nombreTabla = tabla['name'] as String;
    if (!nombreTabla.startsWith('sqlite_')) {
      final resultado = await db.rawQuery('SELECT COUNT(*) as count FROM $nombreTabla');
      conteoTablas[nombreTabla] = resultado.first['count'] as int;
    }
  }
  
  // Obtener tamaño de la base de datos (aproximado)
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'pacientes.db');
  
  return {
    'version': await db.getVersion(),
    'tablas': conteoTablas,
    'ruta': path,
    'total_registros': conteoTablas.values.fold(0, (sum, count) => sum + count),
  };
  
} catch (e) {
  return {
    'error': true,
    'mensaje': e.toString(),
  };
}
}

Future close() async {
final db = await _database;
if (db != null) {
  await db.close();
}
}
// Método para sincronizar medicamentos desde el servidor
Future<void> syncMedicamentosFromServer(List<Map<String, dynamic>> medicamentosServer) async {
  final db = await database;
  
  try {
    // Limpiar medicamentos existentes para evitar duplicados
    await db.delete('medicamentos');
    
    for (final medicamentoData in medicamentosServer) {
      final medicamento = Medicamento.fromJson({
        ...medicamentoData,
        'sync_status': 1, // Marcado como sincronizado
      });
      
      await db.insert(
        'medicamentos',
        medicamento.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
  } catch (e) {
  }
}

// Obtener todos los medicamentos (para mostrar en la UI)
Future<List<Medicamento>> getAllMedicamentos() async {
  final db = await database;
  try {
    final result = await db.query('medicamentos', orderBy: 'nombmedicamento ASC');
    return result.map((json) => Medicamento.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Guardar medicamentos de una visita
Future<void> saveMedicamentosVisita(String visitaId, List<MedicamentoConIndicaciones> medicamentos) async {
  final db = await database;
  
  try {
    // Primero eliminar medicamentos existentes de esta visita
    await db.delete('medicamento_visita', where: 'visita_id = ?', whereArgs: [visitaId]);
    
    // Insertar nuevos medicamentos
    for (final medicamento in medicamentos) {
      if (medicamento.isSelected) {
        await db.insert('medicamento_visita', {
          'medicamento_id': medicamento.medicamento.id,
          'visita_id': visitaId,
          'indicaciones': medicamento.indicaciones,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }
    
  } catch (e) {
  }
}

// Obtener medicamentos de una visita específica
Future<List<MedicamentoConIndicaciones>> getMedicamentosDeVisita(String visitaId) async {
  final db = await database;
  
  try {
    final result = await db.rawQuery('''
      SELECT m.*, mv.indicaciones
      FROM medicamentos m
      INNER JOIN medicamento_visita mv ON m.id = mv.medicamento_id
      WHERE mv.visita_id = ?
      ORDER BY m.nombmedicamento ASC
    ''', [visitaId]);
    
    return result.map((json) {
      final medicamento = Medicamento.fromJson(json);
      return MedicamentoConIndicaciones(
        medicamento: medicamento,
        indicaciones: json['indicaciones'] as String? ?? '',
        isSelected: true,
      );
    }).toList();
  } catch (e) {
    return [];
  }
}

// Verificar si hay medicamentos en la base de datos
Future<bool> hasMedicamentos() async {
  final db = await database;
  try {
    final result = await db.query('medicamentos', limit: 1);
    return result.isNotEmpty;
  } catch (e) {
    return false;
  }
}

// Contar medicamentos disponibles
Future<int> countMedicamentos() async {
  final db = await database;
  try {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM medicamentos');
    return Sqflite.firstIntValue(result) ?? 0;
  } catch (e) {
    return 0;
  }
}

// Insertar relación medicamento-visita
Future<void> insertMedicamentoVisita({
  required String medicamentoId,
  required String visitaId,
  String? indicaciones,
}) async {
  final db = await database;
  
  try {
    await db.insert(
      'medicamento_visita',
      {
        'medicamento_id': medicamentoId,
        'visita_id': visitaId,
        'indicaciones': indicaciones ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
  } catch (e) {
    rethrow;
  }
}
// Métodos para envío de muestras
// database_helper.dart - MÉTODO CORREGIDO PARA GUARDAR
Future<bool> createEnvioMuestra(EnvioMuestra envio) async {
  try {
    final db = await database;
    
    return await db.transaction((txn) async {
      // 1. Preparar datos del envío principal (SIN detalles)
      final envioData = envio.toJson();
      envioData.remove('detalles'); // ✅ Remover detalles del JSON principal
      
      // 2. Insertar envío principal
      await txn.insert(
        'envio_muestras',
        envioData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // 3. Insertar cada detalle por separado con TODOS los campos como TEXT
      for (final detalle in envio.detalles) {
        final detalleData = detalle.toJson(); // ✅ Esto ya mapea o24h → o24h
        
        // ✅ MAPEAR TODOS LOS CAMPOS CORRECTAMENTE
        final detalleCompleto = {
          'id': detalleData['id'],
          'envio_muestra_id': envio.id,
          'paciente_id': detalleData['paciente_id'],
          'numero_orden': detalleData['numero_orden'],
          'dm': detalleData['dm'],
          'hta': detalleData['hta'],
          'num_muestras_enviadas': detalleData['num_muestras_enviadas'],
          'tubo_lila': detalleData['tubo_lila'],
          'tubo_amarillo': detalleData['tubo_amarillo'],
          'tubo_amarillo_forrado': detalleData['tubo_amarillo_forrado'],
          'orina_esp': detalleData['orina_esp'],
          'orina_24h': detalleData['orina_24h'],
          'a': detalleData['a'],
          'm': detalleData['m'],
          'oe': detalleData['oe'],
          'o24h': detalleData['o24h'], // ✅ CORRECTO: Ya viene mapeado desde toJson()
          'po': detalleData['po'],
          'h3': detalleData['h3'],
          'hba1c': detalleData['hba1c'],
          'pth': detalleData['pth'],
          'glu': detalleData['glu'],
          'crea': detalleData['crea'],
          'pl': detalleData['pl'],
          'au': detalleData['au'],
          'bun': detalleData['bun'],
          'relacion_crea_alb': detalleData['relacion_crea_alb'],
          'dcre24h': detalleData['dcre24h'],
          'alb24h': detalleData['alb24h'],
          'buno24h': detalleData['buno24h'],
          'fer': detalleData['fer'],
          'tra': detalleData['tra'],
          'fosfat': detalleData['fosfat'],
          'alb': detalleData['alb'],
          'fe': detalleData['fe'],
          'tsh': detalleData['tsh'],
          'p': detalleData['p'],
          'ionograma': detalleData['ionograma'],
          'b12': detalleData['b12'],
          'acido_folico': detalleData['acido_folico'],
          'peso': detalleData['peso'],
          'talla': detalleData['talla'],
          'volumen': detalleData['volumen'],
          'microo': detalleData['microo'],
          'creaori': detalleData['creaori'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await txn.insert(
          'detalle_envio_muestras',
          detalleCompleto,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      return true;
    });
  } catch (e) {
    return false;
  }
}



Future<List<EnvioMuestra>> getAllEnviosMuestras() async {
  try {
    final db = await database;
    
    // Obtener envíos
    final enviosResult = await db.query(
      'envio_muestras',
      orderBy: 'fecha DESC',
    );
    
    List<EnvioMuestra> envios = [];
    
    for (final envioData in enviosResult) {
      // Obtener detalles para cada envío
      final detallesResult = await db.query(
        'detalle_envio_muestras',
        where: 'envio_muestra_id = ?',
        whereArgs: [envioData['id']],
        orderBy: 'numero_orden ASC',
      );
      
      final detalles = detallesResult
          .map((d) => DetalleEnvioMuestra.fromJson(d))
          .toList();
      
      final envio = EnvioMuestra.fromJson({
        ...envioData,
        'detalles': detalles.map((d) => d.toJson()).toList(),
      });
      
      envios.add(envio);
    }
    
    return envios;
  } catch (e) {
    return [];
  }
}

Future<List<EnvioMuestra>> getEnviosMuestrasNoSincronizados() async {
  try {
    final db = await database;
    
    final enviosResult = await db.query(
      'envio_muestras',
      where: 'sync_status = ?',
      whereArgs: [0],
      orderBy: 'fecha DESC',
    );
    
    List<EnvioMuestra> envios = [];
    
    for (final envioData in enviosResult) {
      final detallesResult = await db.query(
        'detalle_envio_muestras',
        where: 'envio_muestra_id = ?',
        whereArgs: [envioData['id']],
        orderBy: 'numero_orden ASC',
      );
      
      final detalles = detallesResult
          .map((d) => DetalleEnvioMuestra.fromJson(d))
          .toList();
      
      final envio = EnvioMuestra.fromJson({
        ...envioData,
        'detalles': detalles.map((d) => d.toJson()).toList(),
      });
      
      envios.add(envio);
    }
    
    return envios;
  } catch (e) {
    return [];
  }
}

Future<bool> marcarEnvioMuestraComoSincronizado(String id) async {
  try {
    final db = await database;
    final result = await db.update(
      'envio_muestras',
      {
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// ✅ NUEVO MÉTODO: Actualizar paciente_id en detalle de envío de muestra
Future<bool> actualizarPacienteIdEnDetalle(String detalleId, String nuevoPacienteId) async {
  try {
    final db = await database;
    final result = await db.update(
      'detalle_envio_muestras',
      {
        'paciente_id': nuevoPacienteId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [detalleId],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// ==================== MÉTODOS PARA BRIGADAS ====================

// Generador de ID único para brigadas
String generarIdUnicoBrigada() {
  final uuid = Uuid();
  final idUnico = uuid.v4();
  return 'brig_$idUnico';
}

// Crear brigada
Future<bool> createBrigada(Brigada brigada) async {
  try {
    final db = await database;
    
    // Si no tiene ID, generar uno único
    if (brigada.id.isEmpty) {
      final nuevoId = generarIdUnicoBrigada();
      brigada = brigada.copyWith(id: nuevoId);
    }
    
    final result = await db.insert(
      'brigadas',
      brigada.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Actualizar brigada
Future<bool> updateBrigada(Brigada brigada) async {
  try {
    final db = await database;
    
    final brigadaData = brigada.toJson();
    brigadaData['updated_at'] = DateTime.now().toIso8601String();
    
    final result = await db.update(
      'brigadas',
      brigadaData,
      where: 'id = ?',
      whereArgs: [brigada.id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Obtener todas las brigadas
Future<List<Brigada>> getAllBrigadas() async {
  try {
    final db = await database;
    final result = await db.query(
      'brigadas',
      orderBy: 'fecha_brigada DESC',
    );
    
    return result.map((json) => Brigada.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener brigada por ID
Future<Brigada?> getBrigadaById(String id) async {
  try {
    final db = await database;
    final result = await db.query(
      'brigadas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Brigada.fromJson(result.first);
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Obtener brigadas no sincronizadas
Future<List<Brigada>> getBrigadasNoSincronizadas() async {
  try {
    final db = await database;
    final result = await db.query(
      'brigadas',
      where: 'sync_status = ?',
      whereArgs: [0],
      orderBy: 'fecha_brigada DESC',
    );
    return result.map((json) => Brigada.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Eliminar brigada
Future<bool> deleteBrigada(String id) async {
  try {
    final db = await database;
    
    // Eliminar relaciones primero
    await db.delete('brigada_paciente_medicamento', where: 'brigada_id = ?', whereArgs: [id]);
    await db.delete('brigada_paciente', where: 'brigada_id = ?', whereArgs: [id]);
    
    // Eliminar brigada
    final result = await db.delete(
      'brigadas',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Marcar brigada como sincronizada
Future<bool> marcarBrigadaComoSincronizada(String id) async {
  try {
    final db = await database;
    final result = await db.update(
      'brigadas',
      {
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// ==================== MÉTODOS PARA BRIGADA-PACIENTE ====================

// Asignar pacientes a brigada
Future<bool> asignarPacientesABrigada(String brigadaId, List<String> pacientesIds) async {
  try {
    final db = await database;
    
    await db.transaction((txn) async {
      // Eliminar asignaciones anteriores
      await txn.delete('brigada_paciente', where: 'brigada_id = ?', whereArgs: [brigadaId]);
      
      // Insertar nuevas asignaciones
      for (String pacienteId in pacientesIds) {
        final brigadaPaciente = BrigadaPaciente(
          id: Uuid().v4(),
          brigadaId: brigadaId,
          pacienteId: pacienteId,
        );
        
        await txn.insert('brigada_paciente', brigadaPaciente.toJson());
      }
      
      // Actualizar lista de IDs en la brigada
      await txn.update(
        'brigadas',
        {
          'pacientes_ids': jsonEncode(pacientesIds),
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 0, // Marcar como no sincronizada
        },
        where: 'id = ?',
        whereArgs: [brigadaId],
      );
    });
    
    return true;
  } catch (e) {
    return false;
  }
}

// Obtener pacientes de una brigada
Future<List<Paciente>> getPacientesDeBrigada(String brigadaId) async {
  try {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.* FROM pacientes p
      INNER JOIN brigada_paciente bp ON p.id = bp.paciente_id
      WHERE bp.brigada_id = ?
      ORDER BY p.nombre, p.apellido
    ''', [brigadaId]);
    
    return result.map((json) => Paciente.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// ==================== MÉTODOS PARA MEDICAMENTOS DE PACIENTES EN BRIGADAS ====================

// Asignar medicamentos a paciente en brigada
Future<bool> asignarMedicamentosAPacienteEnBrigada({
  required String brigadaId,
  required String pacienteId,
  required List<Map<String, dynamic>> medicamentos,
}) async {
  try {
    final db = await database;
    
    await db.transaction((txn) async {
      // Eliminar medicamentos anteriores para este paciente en esta brigada
      await txn.delete(
        'brigada_paciente_medicamento',
        where: 'brigada_id = ? AND paciente_id = ?',
        whereArgs: [brigadaId, pacienteId],
      );
      
      // Insertar nuevos medicamentos
      for (Map<String, dynamic> medicamentoData in medicamentos) {
        final brigadaPacienteMedicamento = BrigadaPacienteMedicamento(
          id: Uuid().v4(),
          brigadaId: brigadaId,
          pacienteId: pacienteId,
          medicamentoId: medicamentoData['medicamento_id'],
          dosis: medicamentoData['dosis'],
          cantidad: medicamentoData['cantidad'],
          indicaciones: medicamentoData['indicaciones'],
        );
        
        await txn.insert('brigada_paciente_medicamento', brigadaPacienteMedicamento.toJson());
      }
      
      // Marcar brigada como no sincronizada
      await txn.update(
        'brigadas',
        {
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 0,
        },
        where: 'id = ?',
        whereArgs: [brigadaId],
      );
    });
    
    return true;
  } catch (e) {
    return false;
  }
}

// Obtener medicamentos de un paciente en una brigada
Future<List<Map<String, dynamic>>> getMedicamentosDePacienteEnBrigada(String brigadaId, String pacienteId) async {
  try {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        m.id as medicamento_id,
        m.nombmedicamento,
        bpm.dosis,
        bpm.cantidad,
        bpm.indicaciones
      FROM medicamentos m
      INNER JOIN brigada_paciente_medicamento bpm ON m.id = bpm.medicamento_id
      WHERE bpm.brigada_id = ? AND bpm.paciente_id = ?
      ORDER BY m.nombmedicamento
    ''', [brigadaId, pacienteId]);
    
    return result;
  } catch (e) {
    return [];
  }
}

// Obtener resumen completo de brigada con pacientes y medicamentos
Future<Map<String, dynamic>> getResumenCompletoBrigada(String brigadaId) async {
  try {
    final brigada = await getBrigadaById(brigadaId);
    if (brigada == null) return {};
    
    final pacientes = await getPacientesDeBrigada(brigadaId);
    
    List<Map<String, dynamic>> pacientesConMedicamentos = [];
    
    for (Paciente paciente in pacientes) {
      final medicamentos = await getMedicamentosDePacienteEnBrigada(brigadaId, paciente.id);
      
      pacientesConMedicamentos.add({
        'paciente': paciente.toJson(),
        'medicamentos': medicamentos,
      });
    }
    
    return {
      'brigada': brigada.toJson(),
      'pacientes': pacientesConMedicamentos,
      'total_pacientes': pacientes.length,
      'total_medicamentos': pacientesConMedicamentos
          .map((p) => (p['medicamentos'] as List).length)
          .fold(0, (a, b) => a + b),
    };
  } catch (e) {
    return {};
  }
}

// Métodos para encuestas en DatabaseHelper:

// Generador de ID único para encuestas
String generarIdUnicoEncuesta() {
  final uuid = Uuid();
  final idUnico = uuid.v4();
  return 'enc_$idUnico';
}

// Crear encuesta
Future<bool> createEncuesta(Encuesta encuesta) async {
  try {
    final db = await database;
    
    // Si no tiene ID, generar uno único
    if (encuesta.id.isEmpty) {
      final nuevoId = generarIdUnicoEncuesta();
      encuesta = encuesta.copyWith(
        id: nuevoId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    final result = await db.insert(
      'encuestas',
      encuesta.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Actualizar encuesta
Future<bool> updateEncuesta(Encuesta encuesta) async {
  try {
    final db = await database;
    
    final encuestaData = encuesta.toJson();
    encuestaData['updated_at'] = DateTime.now().toIso8601String();
    
    final result = await db.update(
      'encuestas',
      encuestaData,
      where: 'id = ?',
      whereArgs: [encuesta.id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Obtener todas las encuestas
Future<List<Encuesta>> getAllEncuestas() async {
  try {
    final db = await database;
    final result = await db.query(
      'encuestas',
      orderBy: 'fecha DESC',
    );
    
    return result.map((json) => Encuesta.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener encuesta por ID
Future<Encuesta?> getEncuestaById(String id) async {
  try {
    final db = await database;
    final result = await db.query(
      'encuestas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Encuesta.fromJson(result.first);
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Obtener encuestas por paciente
Future<List<Encuesta>> getEncuestasByPaciente(String pacienteId) async {
  try {
    final db = await database;
    final result = await db.query(
      'encuestas',
      where: 'idpaciente = ?',
      whereArgs: [pacienteId],
      orderBy: 'fecha DESC',
    );
    
    return result.map((json) => Encuesta.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener encuestas por sede
Future<List<Encuesta>> getEncuestasBySede(String sedeId) async {
  try {
    final db = await database;
    final result = await db.query(
      'encuestas',
      where: 'idsede = ?',
      whereArgs: [sedeId],
      orderBy: 'fecha DESC',
    );
    
    return result.map((json) => Encuesta.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener encuestas no sincronizadas
Future<List<Encuesta>> getEncuestasNoSincronizadas() async {
  try {
    final db = await database;
    final result = await db.query(
      'encuestas',
      where: 'sync_status = ?',
      whereArgs: [0],
      orderBy: 'fecha DESC',
    );
    return result.map((json) => Encuesta.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Eliminar encuesta
Future<bool> deleteEncuesta(String id) async {
  try {
    final db = await database;
    final result = await db.delete(
      'encuestas',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Marcar encuesta como sincronizada
Future<bool> marcarEncuestaComoSincronizada(String id) async {
  try {
    final db = await database;
    final result = await db.update(
      'encuestas',
      {
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}
// Generador de ID único para tests FINDRISK
String generarIdUnicoFindrisk() {
  final uuid = Uuid();
  final idUnico = uuid.v4();
  return 'findrisk_$idUnico';
}

// Crear test FINDRISK
Future<bool> createFindriskTest(FindriskTest test) async {
  try {
    final db = await database;
    
    // Si no tiene ID, generar uno único
    if (test.id.isEmpty) {
      final nuevoId = generarIdUnicoFindrisk();
      test = test.copyWith(
        id: nuevoId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    final result = await db.insert(
      'findrisk_tests',
      test.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Actualizar test FINDRISK
Future<bool> updateFindriskTest(FindriskTest test) async {
  try {
    final db = await database;
    
    final testData = test.toJson();
    testData['updated_at'] = DateTime.now().toIso8601String();
    
    final result = await db.update(
      'findrisk_tests',
      testData,
      where: 'id = ?',
      whereArgs: [test.id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Obtener todos los tests FINDRISK
Future<List<FindriskTest>> getAllFindriskTests() async {
  try {
    final db = await database;
    final result = await db.query(
      'findrisk_tests',
      orderBy: 'created_at DESC',
    );
    
    return result.map((json) => FindriskTest.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener test FINDRISK por ID
Future<FindriskTest?> getFindriskTestById(String id) async {
  try {
    final db = await database;
    final result = await db.query(
      'findrisk_tests',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return FindriskTest.fromJson(result.first);
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Obtener tests FINDRISK por paciente
Future<List<FindriskTest>> getFindriskTestsByPaciente(String pacienteId) async {
  try {
    final db = await database;
    final result = await db.query(
      'findrisk_tests',
      where: 'idpaciente = ?',
      whereArgs: [pacienteId],
      orderBy: 'created_at DESC',
    );
    
    return result.map((json) => FindriskTest.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}
// Obtener tests FINDRISK por sede
Future<List<FindriskTest>> getFindriskTestsBySede(String sedeId) async {
  try {
    final db = await database;
    final result = await db.query(
      'findrisk_tests',
      where: 'idsede = ?',
      whereArgs: [sedeId],
      orderBy: 'created_at DESC',
    );
    
    return result.map((json) => FindriskTest.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener tests FINDRISK no sincronizados
Future<List<FindriskTest>> getFindriskTestsNoSincronizados() async {
  try {
    final db = await database;
    final result = await db.query(
      'findrisk_tests',
      where: 'sync_status = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => FindriskTest.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Eliminar test FINDRISK
Future<bool> deleteFindriskTest(String id) async {
  try {
    final db = await database;
    final result = await db.delete(
      'findrisk_tests',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Marcar test FINDRISK como sincronizado
Future<bool> marcarFindriskTestComoSincronizado(String id) async {
  try {
    final db = await database;
    final result = await db.update(
      'findrisk_tests',
      {
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Obtener estadísticas locales de tests FINDRISK
Future<Map<String, dynamic>> getFindriskEstadisticasLocales() async {
  try {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM findrisk_tests');
    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final riesgoBajoResult = await db.rawQuery('SELECT COUNT(*) as count FROM findrisk_tests WHERE puntaje_final < 7');
    final riesgoBajo = Sqflite.firstIntValue(riesgoBajoResult) ?? 0;
    
    final riesgoLigeroResult = await db.rawQuery('SELECT COUNT(*) as count FROM findrisk_tests WHERE puntaje_final >= 7 AND puntaje_final <= 11');
    final riesgoLigero = Sqflite.firstIntValue(riesgoLigeroResult) ?? 0;
    
    final riesgoModeradoResult = await db.rawQuery('SELECT COUNT(*) as count FROM findrisk_tests WHERE puntaje_final >= 12 AND puntaje_final <= 14');
    final riesgoModerado = Sqflite.firstIntValue(riesgoModeradoResult) ?? 0;
    
    final riesgoAltoResult = await db.rawQuery('SELECT COUNT(*) as count FROM findrisk_tests WHERE puntaje_final >= 15 AND puntaje_final <= 20');
    final riesgoAlto = Sqflite.firstIntValue(riesgoAltoResult) ?? 0;
    
    final riesgoMuyAltoResult = await db.rawQuery('SELECT COUNT(*) as count FROM findrisk_tests WHERE puntaje_final > 20');
    final riesgoMuyAlto = Sqflite.firstIntValue(riesgoMuyAltoResult) ?? 0;
    
    return {
      'total_tests': total,
      'riesgo_bajo': riesgoBajo,
      'riesgo_ligeramente_elevado': riesgoLigero,
      'riesgo_moderado': riesgoModerado,
      'riesgo_alto': riesgoAlto,
      'riesgo_muy_alto': riesgoMuyAlto,
    };
  } catch (e) {
    return {};
  }
}

// ==================== MÉTODOS PARA AFINAMIENTOS ====================

// Generador de ID único para afinamientos
String generarIdUnicoAfinamiento() {
  final uuid = Uuid();
  final idUnico = uuid.v4();
  return 'afin_$idUnico';
}

// Crear afinamiento
Future<bool> createAfinamiento(Afinamiento afinamiento) async {
  try {
    final db = await database;
    
    // Si no tiene ID, generar uno único
    if (afinamiento.id.isEmpty) {
      final nuevoId = generarIdUnicoAfinamiento();
      afinamiento = afinamiento.copyWith(
        id: nuevoId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    // Calcular promedios automáticamente
    final promedios = afinamiento.calcularPromedios();
    final afinamientoConPromedios = afinamiento.copyWith(
      presionSistolicaPromedio: promedios['sistolica'],
      presionDiastolicaPromedio: promedios['diastolica'],
      updatedAt: DateTime.now(),
    );
    
    final result = await db.insert(
      'afinamientos',
      afinamientoConPromedios.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Actualizar afinamiento
Future<bool> updateAfinamiento(Afinamiento afinamiento) async {
  try {
    final db = await database;
    
    // Calcular promedios automáticamente
    final promedios = afinamiento.calcularPromedios();
    final afinamientoConPromedios = afinamiento.copyWith(
      presionSistolicaPromedio: promedios['sistolica'],
      presionDiastolicaPromedio: promedios['diastolica'],
      updatedAt: DateTime.now(),
    );
    
    final afinamientoData = afinamientoConPromedios.toJson();
    
    final result = await db.update(
      'afinamientos',
      afinamientoData,
      where: 'id = ?',
      whereArgs: [afinamiento.id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Obtener todos los afinamientos
Future<List<Afinamiento>> getAllAfinamientos() async {
  try {
    final db = await database;
    final result = await db.query(
      'afinamientos',
      orderBy: 'fecha_tamizaje DESC',
    );
    
    return result.map((json) => Afinamiento.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener afinamiento por ID
Future<Afinamiento?> getAfinamientoById(String id) async {
  try {
    final db = await database;
    final result = await db.query(
      'afinamientos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Afinamiento.fromJson(result.first);
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Obtener afinamientos por paciente
Future<List<Afinamiento>> getAfinamientosByPaciente(String pacienteId) async {
  try {
    final db = await database;
    final result = await db.query(
      'afinamientos',
      where: 'idpaciente = ?',
      whereArgs: [pacienteId],
      orderBy: 'fecha_tamizaje DESC',
    );
    
    return result.map((json) => Afinamiento.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener afinamientos por usuario
Future<List<Afinamiento>> getAfinamientosByUsuario(String usuarioId) async {
  try {
    final db = await database;
    final result = await db.query(
      'afinamientos',
      where: 'idusuario = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha_tamizaje DESC',
    );
    
    return result.map((json) => Afinamiento.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener afinamientos no sincronizados
Future<List<Afinamiento>> getAfinamientosNoSincronizados() async {
  try {
    final db = await database;
    final result = await db.query(
      'afinamientos',
      where: 'sync_status = ?',
      whereArgs: [0],
      orderBy: 'fecha_tamizaje DESC',
    );
    return result.map((json) => Afinamiento.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Eliminar afinamiento
Future<bool> deleteAfinamiento(String id) async {
  try {
    final db = await database;
    final result = await db.delete(
      'afinamientos',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Marcar afinamiento como sincronizado
Future<bool> marcarAfinamientoComoSincronizado(String id) async {
  try {
    final db = await database;
    final result = await db.update(
      'afinamientos',
      {
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}
// Obtener afinamientos con información del paciente
Future<List<Map<String, dynamic>>> getAfinamientosConPaciente() async {
  try {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        a.*,
        p.nombre || ' ' || p.apellido as nombre_paciente,
        p.identificacion as identificacion_paciente,
        p.fecnacimiento,
        u.nombre as promotor_vida
      FROM afinamientos a
      LEFT JOIN pacientes p ON a.idpaciente = p.id
      LEFT JOIN usuarios u ON a.idusuario = u.id
      ORDER BY a.fecha_tamizaje DESC
    ''');
    // Continuación del método getAfinamientosConPaciente
    return result.map((row) {
      // Calcular edad del paciente
      int? edadPaciente;
      if (row['fecnacimiento'] != null) {
        final fechaNacimiento = DateTime.parse(row['fecnacimiento'].toString());
        edadPaciente = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;
      }
      
      final afinamientoData = Map<String, dynamic>.from(row);
      afinamientoData['edad_paciente'] = edadPaciente;
      
      return afinamientoData;
    }).toList();
  } catch (e) {
    return [];
  }
}

// Contar afinamientos por usuario
Future<int> countAfinamientosByUsuario(String usuarioId) async {
  try {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM afinamientos WHERE idusuario = ?',
      [usuarioId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  } catch (e) {
    return 0;
  }
}

// Obtener estadísticas de afinamientos
Future<Map<String, dynamic>> getAfinamientosEstadisticas() async {
  try {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM afinamientos');
    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final sincronizadosResult = await db.rawQuery('SELECT COUNT(*) as count FROM afinamientos WHERE sync_status = 1');
    final sincronizados = Sqflite.firstIntValue(sincronizadosResult) ?? 0;
    
    final pendientesResult = await db.rawQuery('SELECT COUNT(*) as count FROM afinamientos WHERE sync_status = 0');
    final pendientes = Sqflite.firstIntValue(pendientesResult) ?? 0;
    
    return {
      'total': total,
      'sincronizados': sincronizados,
      'pendientes': pendientes,
    };
  } catch (e) {
    return {
      'total': 0,
      'sincronizados': 0,
      'pendientes': 0,
    };
  }
}

// ==================== MÉTODOS PARA TAMIZAJES ====================

// Generador de ID único para tamizajes
String generarIdUnicoTamizaje() {
  final uuid = Uuid();
  final idUnico = uuid.v4();
  return 'tamiz_$idUnico';
}

// Crear tamizaje
Future<bool> createTamizaje(Tamizaje tamizaje) async {
  try {
    final db = await database;
    
    // Si no tiene ID, generar uno único
    if (tamizaje.id.isEmpty) {
      final nuevoId = generarIdUnicoTamizaje();
      tamizaje = tamizaje.copyWith(
        id: nuevoId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    final result = await db.insert(
      'tamizajes',
      tamizaje.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Actualizar tamizaje
Future<bool> updateTamizaje(Tamizaje tamizaje) async {
  try {
    final db = await database;
    
    final tamizajeData = tamizaje.toJson();
    tamizajeData['updated_at'] = DateTime.now().toIso8601String();
    
    final result = await db.update(
      'tamizajes',
      tamizajeData,
      where: 'id = ?',
      whereArgs: [tamizaje.id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Obtener todos los tamizajes
Future<List<Tamizaje>> getAllTamizajes() async {
  try {
    final db = await database;
    final result = await db.query(
      'tamizajes',
      orderBy: 'fecha_primera_toma DESC',
    );
    
    return result.map((json) => Tamizaje.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener tamizaje por ID
Future<Tamizaje?> getTamizajeById(String id) async {
  try {
    final db = await database;
    final result = await db.query(
      'tamizajes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Tamizaje.fromJson(result.first);
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Obtener tamizajes por paciente
Future<List<Tamizaje>> getTamizajesByPaciente(String pacienteId) async {
  try {
    final db = await database;
    final result = await db.query(
      'tamizajes',
      where: 'idpaciente = ?',
      whereArgs: [pacienteId],
      orderBy: 'fecha_primera_toma DESC',
    );
    
    return result.map((json) => Tamizaje.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener tamizajes por usuario
Future<List<Tamizaje>> getTamizajesByUsuario(String usuarioId) async {
  try {
    final db = await database;
    final result = await db.query(
      'tamizajes',
      where: 'idusuario = ?',
      whereArgs: [usuarioId],
      orderBy: 'fecha_primera_toma DESC',
    );
    
    return result.map((json) => Tamizaje.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener tamizajes no sincronizados
Future<List<Tamizaje>> getTamizajesNoSincronizados() async {
  try {
    final db = await database;
    final result = await db.query(
      'tamizajes',
      where: 'sync_status = ?',
      whereArgs: [0],
      orderBy: 'fecha_primera_toma DESC',
    );
    return result.map((json) => Tamizaje.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}

// Obtener tamizajes con información del paciente
Future<List<Map<String, dynamic>>> getTamizajesConPaciente() async {
  try {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        t.*,
        p.nombre || ' ' || p.apellido as nombre_paciente,
        p.identificacion as identificacion_paciente,
        p.fecnacimiento,
        p.genero as sexo_paciente,
        s.nombresede as sede_paciente,
        u.nombre as promotor_vida
      FROM tamizajes t
      LEFT JOIN pacientes p ON t.idpaciente = p.id
      LEFT JOIN sedes s ON p.idsede = s.id
      LEFT JOIN usuarios u ON t.idusuario = u.id
      ORDER BY t.fecha_primera_toma DESC
    ''');
    
    return result.map((row) {
      // Calcular edad del paciente
      int? edadPaciente;
      if (row['fecnacimiento'] != null) {
        final fechaNacimiento = DateTime.parse(row['fecnacimiento'].toString());
        edadPaciente = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;
      }
      
      final tamizajeData = Map<String, dynamic>.from(row);
      tamizajeData['edad_paciente'] = edadPaciente;
      
      return tamizajeData;
    }).toList();
  } catch (e) {
    return [];
  }
}

// Eliminar tamizaje
Future<bool> deleteTamizaje(String id) async {
  try {
    final db = await database;
    final result = await db.delete(
      'tamizajes',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Marcar tamizaje como sincronizado
Future<bool> marcarTamizajeComoSincronizado(String id) async {
  try {
    final db = await database;
    final result = await db.update(
      'tamizajes',
      {
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  } catch (e) {
    return false;
  }
}

// Contar tamizajes por usuario
Future<int> countTamizajesByUsuario(String usuarioId) async {
  try {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM tamizajes WHERE idusuario = ?',
      [usuarioId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  } catch (e) {
    return 0;
  }
}

// Obtener estadísticas de tamizajes
Future<Map<String, dynamic>> getTamizajesEstadisticas() async {
  try {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM tamizajes');
    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final sincronizadosResult = await db.rawQuery('SELECT COUNT(*) as count FROM tamizajes WHERE sync_status = 1');
    final sincronizados = Sqflite.firstIntValue(sincronizadosResult) ?? 0;
    
    final pendientesResult = await db.rawQuery('SELECT COUNT(*) as count FROM tamizajes WHERE sync_status = 0');
    final pendientes = Sqflite.firstIntValue(pendientesResult) ?? 0;
    
    // Estadísticas de presión arterial
    final normalResult = await db.rawQuery('SELECT COUNT(*) as count FROM tamizajes WHERE pa_sistolica < 120 AND pa_diastolica < 80');
    final normal = Sqflite.firstIntValue(normalResult) ?? 0;
    
    final elevadaResult = await db.rawQuery('SELECT COUNT(*) as count FROM tamizajes WHERE pa_sistolica >= 120 AND pa_sistolica < 130 AND pa_diastolica < 80');
    final elevada = Sqflite.firstIntValue(elevadaResult) ?? 0;
    
    final hipertension1Result = await db.rawQuery('SELECT COUNT(*) as count FROM tamizajes WHERE (pa_sistolica >= 130 AND pa_sistolica <= 139) OR (pa_diastolica >= 80 AND pa_diastolica <= 89)');
    final hipertension1 = Sqflite.firstIntValue(hipertension1Result) ?? 0;
    
    final hipertension2Result = await db.rawQuery('SELECT COUNT(*) as count FROM tamizajes WHERE pa_sistolica >= 140 OR pa_diastolica >= 90');
    final hipertension2 = Sqflite.firstIntValue(hipertension2Result) ?? 0;
    
    return {
      'total': total,
      'sincronizados': sincronizados,
      'pendientes': pendientes,
      'clasificacion_presion': {
        'normal': normal,
        'elevada': elevada,
        'hipertension_etapa_1': hipertension1,
        'hipertension_etapa_2': hipertension2,
      }
    };
  } catch (e) {
    return {
      'total': 0,
      'sincronizados': 0,
      'pendientes': 0,
      'clasificacion_presion': {
        'normal': 0,
        'elevada': 0,
        'hipertension_etapa_1': 0,
        'hipertension_etapa_2': 0,
      }
    };
  }
}
// Agregar al DatabaseHelper.dart

// Contar tamizajes
Future<int> countTamizajes() async {
  try {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM tamizajes');
    return Sqflite.firstIntValue(result) ?? 0;
  } catch (e) {
    return 0;
  }
}

// Contar medicamentos pendientes
Future<int> countMedicamentosPendientes() async {
  try {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM medicamentos WHERE sync_status = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  } catch (e) {
    return 0;
  }
}

// Contar visitas
Future<int> countVisitas() async {
  try {
    final db = await database;
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Asumiendo que la columna 'fecha' está en formato ISO 8601 (yyyy-MM-dd o similar)
    // Usamos LIKE para filtrar por año y mes
    final monthStr = month.toString().padLeft(2, '0'); // Ej: '04' para abril
    final datePattern = '$year-$monthStr%';

    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM visitas WHERE fecha LIKE ?',
      [datePattern],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  } catch (e) {
    return 0;
  }
}


// Contar pacientes
Future<int> countPacientes() async {
  try {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM pacientes');
    return Sqflite.firstIntValue(result) ?? 0;
  } catch (e) {
    return 0;
  }
}
Future<void> limpiarDatosUsuarioObsoletos(String usuario) async {
  final db = await database;
  try {
    // Limpiar token y sesión del usuario específico
    await db.update(
      'usuarios',
      {
        'token': null,
        'is_logged_in': 0,
        'last_sync': null,
      },
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  } catch (e) {
  }
}

// Método para verificar si el token es válido (por fecha)
Future<bool> isTokenExpired(String usuario) async {
  final db = await database;
  try {
    final result = await db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario],
      limit: 1,
    );
    
    if (result.isEmpty) return true;
    
    final user = result.first;
    final lastLogin = user['last_login'] as String?;
    
    if (lastLogin == null) return true;
    
    // ✅ REDUCIR TIEMPO DE EXPIRACIÓN A 7 DÍAS (más seguro)
    final lastLoginDate = DateTime.parse(lastLogin);
    final hoursSinceLogin = DateTime.now().difference(lastLoginDate).inHours;
    
    // Token expira después de 7 días (168 horas)
    final isExpired = hoursSinceLogin > 168;
    
    if (isExpired) {
    }
    
    return isExpired;
  } catch (e) {
    return true; // Asumir expirado en caso de error
  }
}

// ✅ MÉTODO PARA ACTUALIZAR TIMESTAMP DEL TOKEN
Future<void> updateTokenTimestamp(String usuario) async {
  final db = await database;
  try {
    await db.update(
      'usuarios',
      {'last_login': DateTime.now().toIso8601String()},
      where: 'usuario = ?',
      whereArgs: [usuario],
    );
  } catch (e) {
  }
}

// Método para limpiar todos los tokens expirados
Future<void> limpiarTokensExpirados() async {
  final db = await database;
  try {
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    
    await db.update(
      'usuarios',
      {
        'token': null,
        'is_logged_in': 0,
      },
      where: 'last_login < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );
    
  } catch (e) {
  }
}
// database/database_helper.dart

// Agregar parámetros de fecha a los métodos existentes

Future<int> countPacientesPorUsuario(
  String usuarioId, {
  String? fechaInicio,
  String? fechaFin,
}) async {
  final db = await database;
  
  String whereClause = 'idusuario = ?';
  List<dynamic> whereArgs = [usuarioId];
  
  if (fechaInicio != null && fechaFin != null) {
    whereClause += ' AND created_at BETWEEN ? AND ?';
    whereArgs.addAll([fechaInicio, fechaFin]);
  }
  
  final result = await db.query(
    'pacientes',
    where: whereClause,
    whereArgs: whereArgs,
  );
  
  return result.length;
}

Future<int> countVisitasPorUsuario(
  String usuarioId, {
  String? fechaInicio,
  String? fechaFin,
}) async {
  final db = await database;
  
  String whereClause = 'idusuario = ?';
  List<dynamic> whereArgs = [usuarioId];
  
  if (fechaInicio != null && fechaFin != null) {
    whereClause += ' AND fecha BETWEEN ? AND ?';
    whereArgs.addAll([fechaInicio, fechaFin]);
  }
  
  final result = await db.query(
    'visitas',
    where: whereClause,
    whereArgs: whereArgs,
  );
  
  return result.length;
}

Future<int> countTamizajesPorUsuario(
  String usuarioId, {
  String? fechaInicio,
  String? fechaFin,
}) async {
  final db = await database;
  
  String whereClause = 'idusuario = ?';
  List<dynamic> whereArgs = [usuarioId];
  
  if (fechaInicio != null && fechaFin != null) {
    whereClause += ' AND fecha BETWEEN ? AND ?';
    whereArgs.addAll([fechaInicio, fechaFin]);
  }
  
  final result = await db.query(
    'tamizajes',
    where: whereClause,
    whereArgs: whereArgs,
  );
  
  return result.length;
}

Future<int> countBrigadasPorUsuario(
  String usuarioId, {
  String? fechaInicio,
  String? fechaFin,
}) async {
  final db = await database;
  
  String whereClause = 'idusuario = ?';
  List<dynamic> whereArgs = [usuarioId];
  
  if (fechaInicio != null && fechaFin != null) {
    whereClause += ' AND fecha BETWEEN ? AND ?';
    whereArgs.addAll([fechaInicio, fechaFin]);
  }
  
  final result = await db.query(
    'brigadas',
    where: whereClause,
    whereArgs: whereArgs,
  );
  
  return result.length;
}

Future<int> countLaboratoriosPorUsuario(
  String usuarioId, {
  String? fechaInicio,
  String? fechaFin,
}) async {
  final db = await database;
  
  String whereClause = 'idusuario = ?';
  List<dynamic> whereArgs = [usuarioId];
  
  if (fechaInicio != null && fechaFin != null) {
    whereClause += ' AND fecha BETWEEN ? AND ?';
    whereArgs.addAll([fechaInicio, fechaFin]);
  }
  
  final result = await db.query(
    'laboratorios',
    where: whereClause,
    whereArgs: whereArgs,
  );
  
  return result.length;
}

Future<int> countEncuestasPorUsuario(
  String usuarioId, {
  String? fechaInicio,
  String? fechaFin,
}) async {
  final db = await database;
  
  String whereClause = 'idusuario = ?';
  List<dynamic> whereArgs = [usuarioId];
  
  if (fechaInicio != null && fechaFin != null) {
    whereClause += ' AND fecha BETWEEN ? AND ?';
    whereArgs.addAll([fechaInicio, fechaFin]);
  }
  
  final result = await db.query(
    'encuestas',
    where: whereClause,
    whereArgs: whereArgs,
  );
  
  return result.length;
}


// 🆕 MÉTODO PARA CASCADA DE IDs DE PACIENTE OFFLINE A ONLINE
  Future<void> actualizarIdPacienteEnCascada(String oldOfflineId, String newServerId) async {
    final db = await database;
    await db.transaction((txn) async {
      try {
        // 1. Visitas
        await txn.update('visitas', {'idpaciente': newServerId},
            where: 'idpaciente = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}

      try {
        // 2. Encuestas
        await txn.update('encuestas', {'idpaciente': newServerId},
            where: 'idpaciente = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}

      try {
        // 3. Findrisk Tests
        await txn.update('findrisk_tests', {'idpaciente': newServerId},
            where: 'idpaciente = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}

      try {
        // 4. Afinamientos
        await txn.update('afinamientos', {'idpaciente': newServerId},
            where: 'idpaciente = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}

      try {
        // 5. Tamizajes
        await txn.update('tamizajes', {'idpaciente': newServerId},
            where: 'idpaciente = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}

      try {
        // 6. Brigadas Paciente
        await txn.update('brigada_paciente', {'paciente_id': newServerId},
            where: 'paciente_id = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}

      try {
        // 7. Brigadas Medicamentos
        await txn.update('brigada_paciente_medicamento', {'paciente_id': newServerId},
            where: 'paciente_id = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}

      try {
        // 8. Envíos de Muestras (Detalle Laboratorio)
        await txn.update('detalle_envio_muestras', {'paciente_id': newServerId},
            where: 'paciente_id = ?', whereArgs: [oldOfflineId]);
      } catch (e) {}
    });
  }
} 