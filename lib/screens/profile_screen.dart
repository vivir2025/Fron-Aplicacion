import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fnpv_app/api/api_service.dart';
import 'package:fnpv_app/database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final VoidCallback onLogout;

  const ProfileScreen({
    Key? key,
    required this.authProvider,
    required this.onLogout,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _contrasenaActualController;
  late TextEditingController _contrasenaNuevaController;
  bool _isLoading = false;
  String? _selectedSedeId;
  List<Map<String, dynamic>> _sedes = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.authProvider.user?['nombre']);
    _correoController = TextEditingController(text: widget.authProvider.user?['correo']);
    _contrasenaActualController = TextEditingController();
    _contrasenaNuevaController = TextEditingController();
    _loadSedes();
    _loadCurrentSede();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaActualController.dispose();
    _contrasenaNuevaController.dispose();
    super.dispose();
  }

  Future<void> _loadSedes() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;
      
      if (isOnline && widget.authProvider.isAuthenticated) {
        // Online: obtener de API
        final apiSedes = await ApiService.getSedes(widget.authProvider.token!);
        await DatabaseHelper.instance.saveSedes(apiSedes);
        setState(() {
          _sedes = apiSedes.map((s) => {
            'id': s['id'].toString(),
            'nombresede': s['nombresede'].toString(),
          }).toList();
        });
      } else {
        // Offline: obtener de SQLite
        final localSedes = await DatabaseHelper.instance.getSedes();
        setState(() {
          _sedes = localSedes;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar sedes: $e');
    }
  }

  Future<void> _loadCurrentSede() async {
    final currentSede = await widget.authProvider.getCurrentSede();
    if (currentSede != null && mounted) {
      setState(() {
        _selectedSedeId = currentSede['id']?.toString();
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authProvider.updateProfile(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        contrasenaActual: _contrasenaActualController.text.isNotEmpty
            ? _contrasenaActualController.text.trim()
            : null,
        contrasenaNueva: _contrasenaNuevaController.text.isNotEmpty
            ? _contrasenaNuevaController.text.trim()
            : null,
        sedeId: _selectedSedeId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Perfil actualizado correctamente'),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: _selectedSedeId,
        decoration: InputDecoration(
          labelText: 'Sede',
          prefixIcon: const Icon(Icons.business, color: Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: _sedes.map((sede) {
          return DropdownMenuItem<String>(
            value: sede['id'],
            child: Text(sede['nombresede']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSedeId = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await widget.authProvider.logout();
              widget.onLogout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header verde con avatar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.authProvider.user?['nombre'] ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.authProvider.user?['correo'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Formulario
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su nombre';
                        }
                        return null;
                      },
                    ),
                    
                    _buildTextField(
                      controller: _correoController,
                      label: 'Correo electrónico',
                      icon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su correo';
                        }
                        if (!value.contains('@')) {
                          return 'Ingrese un correo válido';
                        }
                        return null;
                      },
                    ),
                    
                    const Text(
                      'Seguridad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _contrasenaActualController,
                      label: 'Contraseña actual (opcional)',
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                    
                    _buildTextField(
                      controller: _contrasenaNuevaController,
                      label: 'Nueva contraseña (opcional)',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (_contrasenaActualController.text.isNotEmpty && 
                            (value == null || value.isEmpty)) {
                          return 'Debe ingresar una nueva contraseña';
                        }
                        return null;
                      },
                    ),
                    
                    if (_sedes.isNotEmpty) ...[
                      const Text(
                        'Ubicación',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Actualizar Perfil',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}