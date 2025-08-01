import 'dart:convert';

import 'package:fnpv_app/models/envio_muestra_model.dart';
import 'package:fnpv_app/models/medicamento.dart';
import 'package:fnpv_app/models/medicamento_con_indicaciones.dart';
import 'package:fnpv_app/models/visita_model.dart';
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
  // Utilizar UUID v4 para generar ID único
  final uuid = Uuid();
  final idUnico = uuid.v4();
  
  // Opcionalmente agregar un prefijo para identificar tipo de entidad
  return 'vis_$idUnico';
}



get totalArchivosAdjuntos => null;

Future<Database> _initDB(String filePath) async {
final dbPath = await getDatabasesPath();
final path = join(dbPath, filePath);

return await openDatabase(
  path,
  version: 11, // 🚀 Incrementado a 10 
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
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (envio_muestra_id) REFERENCES envio_muestras (id) ON DELETE CASCADE,
    FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
  )
''');

debugPrint('Base de datos creada con todas las tablas incluyendo visitas mejorada');
}

Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
debugPrint('Actualizando base de datos de versión $oldVersion a $newVersion');

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
  debugPrint('Tabla visitas creada durante upgrade');
}

if (oldVersion < 5) {
  try {
    await db.execute('ALTER TABLE visitas ADD COLUMN firma TEXT');
    debugPrint('Columna firma agregada a tabla visitas');
  } catch (e) {
    debugPrint('Error al agregar columna firma (puede que ya exista): $e');
  }
}

if (oldVersion < 6) {
  try {
    await db.execute('ALTER TABLE visitas ADD COLUMN latitud REAL');
    await db.execute('ALTER TABLE visitas ADD COLUMN longitud REAL');
    debugPrint('✅ Columnas latitud y longitud agregadas a tabla visitas');
  } catch (e) {
    debugPrint('⚠️ Error al agregar columnas de geolocalización (puede que ya existan): $e');
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
    
    debugPrint('✅ Nuevas columnas agregadas a tabla visitas para manejo mejorado');
  } catch (e) {
    debugPrint('⚠️ Error al agregar nuevas columnas a visitas: $e');
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
      debugPrint('✅ Columna firma agregada en migración v9');
    } else {
      debugPrint('✅ Columna firma ya existe en migración v9');
    }
    
    debugPrint('✅ Migración v9 completada - Columna firma verificada');
  } catch (e) {
    debugPrint('⚠️ Error en migración v9: $e');
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
    

    

    debugPrint('✅ Tablas de medicamentos creadas en migración v10');
  } catch (e) {
    debugPrint('⚠️ Error en migración v10 (medicamentos): $e');
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (envio_muestra_id) REFERENCES envio_muestras (id) ON DELETE CASCADE,
        FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
      )
    ''');

    

    debugPrint('✅ Tabla envio_muestras creada en migración v11');
  } catch (e) {
    debugPrint('⚠️ Error en migración v11 (envio_muestras): $e');
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
  debugPrint('Error al obtener columnas de $tableName: $e');
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
    debugPrint('Tabla sedes creada manualmente');
  }
} catch (e) {
  debugPrint('Error al crear tabla sedes: $e');
}
}

// Método para verificar y reparar la tabla visitas si es necesario
Future<void> ensureVisitasTableIntegrity() async {
final db = await database;
try {
  final columns = await getTableColumns('visitas');
  debugPrint('Columnas actuales en tabla visitas: $columns');
  
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
        debugPrint('✅ Columna $column agregada a tabla visitas');
      } catch (e) {
        debugPrint('⚠️ Error al agregar columna $column: $e');
      }
    }
  }
} catch (e) {
  debugPrint('Error al verificar integridad de tabla visitas: $e');
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

Future<List<Paciente>> getUnsyncedPacientes() async {
final db = await database;
final result = await db.query(
  'pacientes', 
  where: 'sync_status = 0 AND (latitud IS NOT NULL OR longitud IS NOT NULL)',
);
return result.map((json) => Paciente.fromJson(json)).toList();
}

Future<void> markPacientesAsSynced(List<String> pacienteIds) async {
final db = await database;
await db.update(
  'pacientes',
  {'sync_status': 1},
  where: 'id IN (${List.filled(pacienteIds.length, '?').join(',')})',
  whereArgs: pacienteIds,
);
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
  debugPrint('Error al buscar paciente por identificación: $e');
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
  debugPrint('Error al buscar paciente por ID: $e');
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
  debugPrint('Sedes anteriores eliminadas');

  // Insertar nuevas sedes
  for (final sede in sedes) {
    final sedeData = {
      'id': sede['id'].toString(),
      'nombresede': sede['nombresede'].toString(),
      'direccion': sede['direccion']?.toString() ?? '',
    };
    
    await db.insert('sedes', sedeData);
    debugPrint('Sede insertada: ${sedeData['nombresede']}');
  }
  
  debugPrint('Sedes guardadas correctamente: ${sedes.length}');
} catch (e) {
  debugPrint('Error al guardar sedes: $e');
  rethrow;
}
}

Future<List<Map<String, dynamic>>> getSedes() async {
final db = await database;
try {
  // Asegurar que la tabla existe
  await ensureSedesTableExists();
  
  final result = await db.query('sedes');
  debugPrint('Sedes obtenidas desde DB: ${result.length}');
  return result;
} catch (e) {
  debugPrint('Error al obtener sedes: $e');
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
    debugPrint('Ya existen sedes, no se insertarán por defecto');
    return;
  }
  
  // Insertar sedes por defecto
  final defaultSedes = [
    {'id': 'sede-1', 'nombresede': 'Sede Principal', 'direccion': 'Dirección principal'},
    {'id': 'sede-2', 'nombresede': 'Sede Secundaria', 'direccion': 'Dirección secundaria'},
  ];
  
  for (final sede in defaultSedes) {
    await db.insert('sedes', sede);
    debugPrint('Sede por defecto insertada: ${sede['nombresede']}');
  }
  
  debugPrint('Sedes por defecto insertadas: ${defaultSedes.length}');
} catch (e) {
  debugPrint('Error al insertar sedes por defecto: $e');
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
  if (user['usuario'] == null || user['contrasena'] == null || user['token'] == null) {
    debugPrint('Usuario encontrado pero faltan datos: usuario=${user['usuario']}, contrasena=${user['contrasena'] != null ? '[EXISTE]' : '[FALTA]'}, token=${user['token'] != null ? '[EXISTE]' : '[FALTA]'}');
    return null;
  }
  
  // Comparación directa
  if (user['contrasena'] == contrasena) {
    debugPrint('Credenciales válidas encontradas para usuario: $usuario');
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
    debugPrint('Contraseña incorrecta para usuario: $usuario');
  }
  
  return null;
} catch (e) {
  debugPrint('Error al obtener usuario: $e');
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

debugPrint('Usuario $userId actualizado (is_logged_in: $isLoggedIn), filas afectadas: $rowsUpdated');
}

// ✅ MÉTODO CORREGIDO EN database_helper.dart
// ✅ MÉTODO CORREGIDO SIN COLUMNAS PROBLEMÁTICAS
Future<int> updatePacienteGeolocalizacion(String pacienteId, double latitud, double longitud) async {
  final db = await database;
  
  try {
    debugPrint('🔄 Iniciando actualización de geolocalización...');
    debugPrint('📍 Paciente ID: $pacienteId');
    debugPrint('📍 Latitud: $latitud');
    debugPrint('📍 Longitud: $longitud');
    
    // ✅ VERIFICAR QUE EL PACIENTE EXISTE PRIMERO
    final existingPaciente = await db.query(
      'pacientes',
      where: 'id = ?',
      whereArgs: [pacienteId],
    );
    
    if (existingPaciente.isEmpty) {
      debugPrint('❌ Paciente no encontrado con ID: $pacienteId');
      return 0;
    }
    
    debugPrint('✅ Paciente encontrado, procediendo con actualización...');
    
    // ✅ VERIFICAR QUE COLUMNAS EXISTEN ANTES DE ACTUALIZAR
    final tableInfo = await db.rawQuery("PRAGMA table_info(pacientes)");
    final columnNames = tableInfo.map((col) => col['name'].toString()).toList();
    
    debugPrint('📋 Columnas disponibles en tabla pacientes: $columnNames');
    
    // ✅ CONSTRUIR UPDATE DINÁMICAMENTE SOLO CON COLUMNAS EXISTENTES
    Map<String, dynamic> updateData = {
      'latitud': latitud,
      'longitud': longitud,
    };
    
    // Solo agregar columnas si existen
    if (columnNames.contains('sync_status')) {
      updateData['sync_status'] = 0;
      debugPrint('✅ Agregando sync_status al update');
    } else {
      debugPrint('⚠️ Columna sync_status no existe, omitiendo...');
    }
    
    if (columnNames.contains('updated_at')) {
      updateData['updated_at'] = DateTime.now().toIso8601String();
      debugPrint('✅ Agregando updated_at al update');
    } else {
      debugPrint('⚠️ Columna updated_at no existe, omitiendo...');
    }
    
    debugPrint('📝 Datos a actualizar: $updateData');
    
    // ✅ ACTUALIZAR CON TRANSACCIÓN EXPLÍCITA
    final result = await db.transaction((txn) async {
      final updateResult = await txn.update(
        'pacientes',
        updateData,
        where: 'id = ?',
        whereArgs: [pacienteId],
      );
      
      debugPrint('🔄 Filas afectadas en actualización: $updateResult');
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
        debugPrint('✅ Verificación post-actualización:');
        debugPrint('   - ID: ${paciente['id']}');
        debugPrint('   - Identificación: ${paciente['identificacion']}');
        debugPrint('   - Latitud guardada: ${paciente['latitud']}');
        debugPrint('   - Longitud guardada: ${paciente['longitud']}');
        
        if (columnNames.contains('sync_status')) {
          debugPrint('   - Sync status: ${paciente['sync_status']}');
        }
        
        // ✅ VERIFICAR QUE LOS VALORES COINCIDEN
        if (paciente['latitud'] == latitud && paciente['longitud'] == longitud) {
          debugPrint('🎉 Coordenadas guardadas correctamente en la base de datos');
        } else {
          debugPrint('⚠️ Las coordenadas no coinciden después de guardar');
          debugPrint('   - Esperado: $latitud, $longitud');
          debugPrint('   - Guardado: ${paciente['latitud']}, ${paciente['longitud']}');
        }
      }
    } else {
      debugPrint('❌ No se actualizó ninguna fila. Posibles causas:');
      debugPrint('   - ID de paciente incorrecto');
      debugPrint('   - Problema con la consulta SQL');
      debugPrint('   - Restricciones de la base de datos');
    }
    
    return result;
    
  } catch (e) {
    debugPrint('💥 Error en updatePacienteGeolocalizacion: $e');
    debugPrint('💥 Stack trace: ${StackTrace.current}');
    rethrow;
  }
}
// ✅ MÉTODO PARA VERIFICAR Y AGREGAR COLUMNAS NECESARIAS
Future<void> verificarYAgregarColumnasGeolocalizacion() async {
  final db = await database;
  
  try {
    debugPrint('🔍 Verificando estructura de tabla pacientes...');
    
    // Obtener información de la tabla
    final tableInfo = await db.rawQuery("PRAGMA table_info(pacientes)");
    final columnNames = tableInfo.map((col) => col['name'].toString()).toList();
    
    debugPrint('📋 Columnas actuales: $columnNames');
    
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
          debugPrint('✅ Columna $nombreColumna agregada exitosamente');
        } catch (e) {
          if (e.toString().contains('duplicate column name')) {
            debugPrint('ℹ️ Columna $nombreColumna ya existe');
          } else {
            debugPrint('❌ Error agregando columna $nombreColumna: $e');
          }
        }
      } else {
        debugPrint('✅ Columna $nombreColumna ya existe');
      }
    }
    
    // Verificar estructura final
    final finalTableInfo = await db.rawQuery("PRAGMA table_info(pacientes)");
    final finalColumnNames = finalTableInfo.map((col) => col['name'].toString()).toList();
    debugPrint('📋 Estructura final de tabla pacientes: $finalColumnNames');
    
  } catch (e) {
    debugPrint('💥 Error verificando/agregando columnas: $e');
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
    debugPrint('Usuario logueado encontrado: ${result.first['usuario']}');
    return result.first;
  }
  
  debugPrint('No hay usuario logueado');
  return null;
} catch (e) {
  debugPrint('Error al obtener usuario logueado: $e');
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
debugPrint('Sesiones anteriores limpiadas');
}

Future<void> debugListUsers() async {
final db = await database;
final users = await db.query('usuarios');
debugPrint('=== USUARIOS EN BASE DE DATOS ===');
for (final user in users) {
  debugPrint('ID: ${user['id']}, Usuario: ${user['usuario']}, Logged: ${user['is_logged_in']}, Token: ${user['token'] != null ? '[EXISTE]' : '[FALTA]'}');
}
debugPrint('=== FIN USUARIOS ===');
}

Future<void> debugListSedes() async {
final sedes = await getSedes();
debugPrint('=== SEDES EN BASE DE DATOS ===');
for (final sede in sedes) {
  debugPrint('ID: ${sede['id']}, Nombre: ${sede['nombresede']}, Dirección: ${sede['direccion']}');
}
debugPrint('=== FIN SEDES ===');
}

Future<List<Map<String, dynamic>>> getAllUsers() async {
final db = await database;
try {
  return await db.query('usuarios');
} catch (e) {
  debugPrint('Error al obtener todos los usuarios: $e');
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
      debugPrint('✅ ID único generado para nueva visita: $nuevoId');
    }
    
    // Preparar datos con manejo especial para archivos y opciones múltiples
    final visitaData = _prepareVisitaDataForDB(visita);
    
    final result = await db.insert(
      'visitas', 
      visitaData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    debugPrint('✅ Visita guardada localmente con ID: ${visita.id}');
    return result > 0;
  } catch (e) {
    debugPrint('❌ Error al guardar visita localmente: $e');
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
  
  debugPrint('✅ Visita actualizada: ${visita.id}');
  return result > 0;
} catch (e) {
  debugPrint('❌ Error al actualizar visita: $e');
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
  debugPrint('Error al obtener visitas por usuario: $e');
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
  debugPrint('Error al obtener visita por ID: $e');
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
  debugPrint('Error al obtener todas las visitas: $e');
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
  debugPrint('Error al obtener visitas por paciente: $e');
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
  debugPrint('Error al obtener visitas no sincronizadas: $e');
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
  debugPrint('Error al eliminar visita: $e');
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
  debugPrint('Error al contar visitas: $e');
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
  debugPrint('Error al obtener últimas visitas: $e');
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
  debugPrint('Error al marcar visitas como sincronizadas: $e');
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
  
  debugPrint('✅ Visita $id marcada como sincronizada');
  return result > 0;
} catch (e) {
  debugPrint('❌ Error al marcar visita como sincronizada: $e');
  return false;
}
}

// 🆕 MÉTODOS AUXILIARES PARA MANEJO DE DATOS JSON

String _listToJsonString(List<dynamic>? list) {
if (list == null || list.isEmpty) return '[]';
try {
  return jsonEncode(list);
} catch (e) {
  debugPrint('Error al convertir lista a JSON: $e');
  return '[]';
}
}

String _mapToJsonString(Map<String, dynamic>? map) {
if (map == null || map.isEmpty) return '{}';
try {
  return jsonEncode(map);
} catch (e) {
  debugPrint('Error al convertir mapa a JSON: $e');
  return '{}';
}
}

List<dynamic> _jsonStringToList(String? jsonString) {
if (jsonString == null || jsonString.isEmpty || jsonString == '[]') return [];
try {
  final decoded = jsonDecode(jsonString);
  return decoded is List ? decoded : [];
} catch (e) {
  debugPrint('Error al convertir JSON a lista: $e');
  return [];
}
}

Map<String, dynamic> _jsonStringToMap(String? jsonString) {
if (jsonString == null || jsonString.isEmpty || jsonString == '{}') return {};
try {
  final decoded = jsonDecode(jsonString);
  return decoded is Map<String, dynamic> ? decoded : {};
} catch (e) {
  debugPrint('Error al convertir JSON a mapa: $e');
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
  debugPrint('Error al agregar foto a visita: $e');
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
  debugPrint('Error al eliminar foto de visita: $e');
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
  debugPrint('Error al actualizar firma de visita: $e');
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
  debugPrint('Error al actualizar opciones múltiples: $e');
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
  debugPrint('❌ Error al obtener estadísticas de archivos: $e');
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
  debugPrint('❌ Error al limpiar archivos huérfanos: $e');
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
  
  debugPrint('✅ Base de datos optimizada exitosamente');
  return true;
} catch (e) {
  debugPrint('❌ Error al optimizar base de datos: $e');
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
  debugPrint('❌ Error al obtener información de la base de datos: $e');
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
    
    debugPrint('✅ ${medicamentosServer.length} medicamentos sincronizados desde servidor');
  } catch (e) {
    debugPrint('❌ Error sincronizando medicamentos: $e');
  }
}

// Obtener todos los medicamentos (para mostrar en la UI)
Future<List<Medicamento>> getAllMedicamentos() async {
  final db = await database;
  try {
    final result = await db.query('medicamentos', orderBy: 'nombmedicamento ASC');
    return result.map((json) => Medicamento.fromJson(json)).toList();
  } catch (e) {
    debugPrint('❌ Error obteniendo medicamentos: $e');
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
    
    debugPrint('✅ Medicamentos guardados para visita $visitaId');
  } catch (e) {
    debugPrint('❌ Error guardando medicamentos de visita: $e');
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
    debugPrint('❌ Error obteniendo medicamentos de visita: $e');
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
    debugPrint('❌ Error verificando medicamentos: $e');
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
    debugPrint('❌ Error contando medicamentos: $e');
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
    
    debugPrint('✅ Medicamento $medicamentoId asociado a visita $visitaId');
  } catch (e) {
    debugPrint('❌ Error insertando medicamento-visita: $e');
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
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await txn.insert(
          'detalle_envio_muestras',
          detalleCompleto,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      debugPrint('✅ Envío de muestra guardado localmente: ${envio.id} con ${envio.detalles.length} detalles');
      return true;
    });
  } catch (e) {
    debugPrint('❌ Error guardando envío de muestra: $e');
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
    debugPrint('❌ Error obteniendo envíos de muestras: $e');
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
    debugPrint('❌ Error obteniendo envíos no sincronizados: $e');
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
    
    debugPrint('✅ Envío de muestra $id marcado como sincronizado');
    return result > 0;
  } catch (e) {
    debugPrint('❌ Error marcando envío como sincronizado: $e');
    return false;
  }
}

} // Fin de la clase DatabaseHelper
