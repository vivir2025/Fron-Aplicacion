import 'package:flutter/material.dart';
import '../models/paciente_model.dart';
import '../api/api_service.dart';
import 'auth_provider.dart';
import '../database/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PacienteProvider with ChangeNotifier {
  List<Paciente> _pacientes = [];
  bool _isLoading = false;
  final AuthProvider _authProvider;

  PacienteProvider(this._authProvider);

  List<Paciente> get pacientes => _pacientes;
  bool get isLoading => _isLoading;

  Future<void> loadPacientes() async {
  _isLoading = true;
  notifyListeners();

  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none && _authProvider.isAuthenticated) {
      // Online: traer desde API
      final response = await ApiService.getPacientes(_authProvider.token!);
      _pacientes = response.map<Paciente>((json) => Paciente.fromJson(json)).toList();

      // Guardar localmente
      final db = DatabaseHelper.instance;
      for (final paciente in _pacientes) {
        await db.createPaciente(paciente); // Inserta (puedes optimizar con upsert si es necesario)
      }
    } else {
      // Offline: cargar desde SQLite
      _pacientes = await DatabaseHelper.instance.readAllPacientes();
      debugPrint('Pacientes cargados localmente: ${_pacientes.length}');
    }
  } catch (e) {
    print('Error loading pacientes: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> addPaciente(Paciente paciente) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_authProvider.isAuthenticated) {
        await ApiService.createPaciente(_authProvider.token!, paciente.toJson());
        await loadPacientes(); // Recargar la lista después de agregar
      }
    } catch (e) {
      print('Error adding paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePaciente(Paciente paciente) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_authProvider.isAuthenticated) {
        await ApiService.updatePaciente(_authProvider.token!, paciente.id, paciente.toJson());
        await loadPacientes(); // Recargar la lista después de actualizar
      }
    } catch (e) {
      print('Error updating paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePaciente(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_authProvider.isAuthenticated) {
        await ApiService.deletePaciente(_authProvider.token!, id);
        _pacientes.removeWhere((p) => p.id == id);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting paciente: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> syncData() async {
    if (_authProvider.isAuthenticated) {
      await loadPacientes();
    }
  }
  void clearData() {
  _pacientes = [];
  _isLoading = false;
  notifyListeners();
}
}