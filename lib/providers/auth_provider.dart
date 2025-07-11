import '../api/api_service.dart';

class AuthProvider {
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sede;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get sede => _sede;
  bool get isAuthenticated => _token != null;

  Future<void> login(String usuario, String contrasena) async {
    final response = await ApiService.login(usuario, contrasena);
    _token = response['token'];
    _user = response['usuario'];
    _sede = response['sede'];
  }

  Future<void> logout() async {
    if (_token != null) {
      await ApiService.logout(_token!);
    }
    _token = null;
    _user = null;
    _sede = null;
  }

  Future<void> loadProfile() async {
    if (_token != null) {
      final response = await ApiService.getProfile(_token!);
      _user = response['usuario'];
      _sede = response['sede'];
    }
  }

  Future<void> updateProfile({
    String? nombre,
    String? correo,
    String? contrasenaActual,
    String? contrasenaNueva,
  }) async {
    if (_token != null) {
      final response = await ApiService.updateProfile(
        _token!,
        nombre: nombre,
        correo: correo,
        contrasenaActual: contrasenaActual,
        contrasenaNueva: contrasenaNueva,
      );
      _user = response['usuario'];
    }
  }
}