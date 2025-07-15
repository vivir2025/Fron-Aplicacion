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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

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

  Future<int> deletePaciente(String id) async {
    final db = await instance.database;
    return await db.delete(
      'pacientes',
      where: 'id = ?',
      whereArgs: [id],
    );
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
      'contrasena': user['contrasena'], // En producción usar hash
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

  // MÉTODO CORREGIDO: No requiere is_logged_in = 1 para buscar
  Future<Map<String, dynamic>?> getUserByCredentials(String usuario, String contrasena) async {
    final db = await database;
    try {
      final result = await db.query(
        'usuarios',
        where: 'usuario = ?', // CORREGIDO: Solo busca por usuario
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
      
      // Comparación directa (en producción usar hash)
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

  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'usuarios',
        where: 'is_logged_in = 1',
        orderBy: 'last_login DESC', // Obtener el más reciente
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

  // MÉTODO NUEVO: Para limpiar sesiones al iniciar la app
  Future<void> clearOldSessions() async {
    final db = await database;
    await db.update(
      'usuarios',
      {'is_logged_in': 0},
      where: 'is_logged_in = 1',
    );
    debugPrint('Sesiones anteriores limpiadas');
  }

  // MÉTODO NUEVO: Para debug - listar todos los usuarios
  Future<void> debugListUsers() async {
    final db = await database;
    final users = await db.query('usuarios');
    debugPrint('=== USUARIOS EN BASE DE DATOS ===');
    for (final user in users) {
      debugPrint('ID: ${user['id']}, Usuario: ${user['usuario']}, Logged: ${user['is_logged_in']}, Token: ${user['token'] != null ? '[EXISTE]' : '[FALTA]'}');
    }
    debugPrint('=== FIN USUARIOS ===');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}