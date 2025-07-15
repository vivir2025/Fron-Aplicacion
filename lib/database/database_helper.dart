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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
     // Nueva tabla para usuarios
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
        is_logged_in INTEGER DEFAULT 0
      )
    ''');
  }

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

  Future close() async {
    final db = await instance.database;
    db.close();
  }

    // Métodos para usuarios
  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('usuarios', user);
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
    
    // Comparación segura (en producción usa hash)
    if (user['contrasena'] == contrasena) {
      return user;
    }
    
    return null;
  } catch (e) {
    debugPrint('Error al obtener usuario: $e');
    return null;
  }
}

  Future<void> updateUserLoginStatus(String userId, bool isLoggedIn, {String? token}) async {
    final db = await instance.database;
    await db.update(
      'usuarios',
      {
        'is_logged_in': isLoggedIn ? 1 : 0,
        if (token != null) 'token': token,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final db = await instance.database;
    final result = await db.query(
      'usuarios',
      where: 'is_logged_in = 1',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
