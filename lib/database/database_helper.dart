import 'package:fnpv_app/models/visita_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Incrementado a 4 por la nueva tabla visitas
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

    // Nueva tabla para visitas
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
        idusuario TEXT NOT NULL,
        idpaciente TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    debugPrint('Base de datos creada con todas las tablas incluyendo visitas');
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
    // ← NUEVA MIGRACIÓN PARA AGREGAR COLUMNA FIRMA
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE visitas ADD COLUMN firma TEXT');
        debugPrint('Columna firma agregada a tabla visitas');
      } catch (e) {
        debugPrint('Error al agregar columna firma (puede que ya exista): $e');
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
      where: 'sync_status = 0',
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
    Future<int> updatePacienteGeolocalizacion(String pacienteId, double latitud, double longitud) async {
    final db = await database;
    return await db.update(
      'pacientes',
      {
        'latitud': latitud,
        'longitud': longitud,
        'sync_status': 0, // Marcar como no sincronizado
      },
      where: 'id = ?',
      whereArgs: [pacienteId],
    );
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

  // MÉTODOS PARA VISITAS
   Future<bool> createVisita(Visita visita) async {
    try {
      final db = await database;
      final result = await db.insert(
        'visitas', 
        visita.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Visita guardada localmente con ID: ${visita.id}');
      return result > 0;
    } catch (e) {
      debugPrint('Error al guardar visita localmente: $e');
      return false;
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
      return result.map((json) => Visita.fromJson(json)).toList();
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
        return Visita.fromJson(result.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener visita por ID: $e');
      return null;
    }
  }

  Future<bool> updateVisita(Visita visita) async {
    try {
      final db = await database;
      final result = await db.update(
        'visitas',
        {
          ...visita.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [visita.id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Error al actualizar visita: $e');
      return false;
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
  // Método para contar visitas por usuario
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

  // Método para obtener las últimas N visitas
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
      return result.map((json) => Visita.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al obtener últimas visitas: $e');
      return [];
    }
  }
  // Método adicional para buscar visitas por paciente
   Future<List<Visita>> getVisitasByPaciente(String pacienteId) async {
    try {
      final db = await database;
      final result = await db.query(
        'visitas',
        where: 'idpaciente = ?',
        whereArgs: [pacienteId],
        orderBy: 'fecha DESC',
      );
      return result.map((json) => Visita.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al obtener visitas por paciente: $e');
      return [];
    }
  }
  // Método para obtener visitas no sincronizadas
  Future<List<Visita>> getVisitasNoSincronizadas() async {
    try {
      final db = await database;
      final result = await db.query(
        'visitas',
        where: 'sync_status = ?',
        whereArgs: [0], // 0 = no sincronizado
        orderBy: 'fecha DESC',
      );
      return result.map((json) => Visita.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al obtener visitas no sincronizadas: $e');
      return [];
    }
  }
  // Método para marcar visitas como sincronizadas
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
      return result > 0;
    } catch (e) {
      debugPrint('Error al marcar visita como sincronizada: $e');
      return false;
    }
  }

  Future close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }

  Future<List<Visita>> getAllVisitas() async {
  try {
    final db = await database;
    final result = await db.query(
      'visitas',
      orderBy: 'fecha DESC',
    );
    return result.map((json) => Visita.fromJson(json)).toList();
  } catch (e) {
    debugPrint('Error al obtener todas las visitas: $e');
    return [];
  }
}



}
