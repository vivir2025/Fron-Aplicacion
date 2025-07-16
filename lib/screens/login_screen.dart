import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    Key? key,
    required this.authProvider,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Colores del tema
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.authProvider.login(
        _usuarioController.text.trim(),
        _contrasenaController.text.trim(),
      );

      if (widget.authProvider.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onLoginSuccess();
        });
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(dynamic e) {
    String message = 'Error de autenticación';
    
    if (e.toString().contains('No hay credenciales guardadas')) {
      message = 'Primero debes iniciar sesión con internet';
    } else if (e.toString().contains('SocketException')) {
      message = 'Sin conexión a internet. Intentando con credenciales locales...';
    } else if (e.toString().contains('Credenciales inválidas')) {
      message = 'Usuario o contraseña incorrectos';
    } else if (e.toString().contains('No hay conexión a internet') || 
        e.toString().contains('No se pudo conectar al servidor')) {
      message = 'No hay conexión a internet. Verificando credenciales locales...';
    } else if (e.toString().contains('No hay credenciales válidas')) {
      message = 'Primero debes iniciar sesión con conexión a internet';
    } else if (e.toString().contains('Token no disponible')) {
      message = 'Sesión offline no disponible. Necesitas conexión a internet';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _getSnackbarColor(e),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Color _getSnackbarColor(dynamic e) {
    if (e.toString().contains('SocketException') || 
        e.toString().contains('No hay conexión')) {
      return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header con gradiente verde que cubre toda la parte superior incluyendo status bar
          Container(
            width: double.infinity,
            height: 290, // Tamaño original más pequeño
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryGreen,
                  lightGreen,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Formulario de login
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Card del formulario
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            // Campo Usuario
                            TextFormField(
                              controller: _usuarioController,
                              decoration: InputDecoration(
                                labelText: 'Usuario',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.person_outline, color: primaryGreen),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: primaryGreen, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su usuario';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Contraseña
                            TextFormField(
                              controller: _contrasenaController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.lock_outline, color: primaryGreen),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: primaryGreen,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: primaryGreen, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su contraseña';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            
                            // Botón de Login
                            SizedBox(
                              height: 56,
                              child: _isLoading
                                  ? Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [primaryGreen, lightGreen],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [primaryGreen, lightGreen],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'INICIAR SESIÓN',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Enlace de recuperación
                            TextButton(
                              onPressed: () {
                                // Navegar a pantalla de recuperación de contraseña
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}