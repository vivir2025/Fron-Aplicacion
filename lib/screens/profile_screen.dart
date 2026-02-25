import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:Bornive/api/api_service.dart';
import 'package:Bornive/database/database_helper.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/sincronizacion_service.dart';

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
  bool _isSyncing = false;
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
            backgroundColor: const Color(0xFF1B5E20),
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
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        readOnly: readOnly,
        cursorColor: const Color(0xFF1B5E20),
        style: GoogleFonts.roboto(
          color: readOnly ? Colors.grey.shade700 : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
          floatingLabelStyle: GoogleFonts.roboto(color: const Color(0xFF1B5E20), fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: const Color(0xFF1B5E20), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSedeInfo() {
    if (_selectedSedeId == null || _sedes.isEmpty) return const SizedBox.shrink();
    final selectedSede = _sedes.where((s) => s['id'] == _selectedSedeId).toList();
    final sedeText = selectedSede.isNotEmpty 
        ? selectedSede.first['nombresede']?.toString() ?? 'Sede sin nombre'
        : 'Sede desconocida';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.building, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sede Vinculada',
                  style: GoogleFonts.roboto(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sedeText,
                  style: GoogleFonts.roboto(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sincronizar() async {
    setState(() { _isSyncing = true; });
    try {
      final usuario = await DatabaseHelper.instance.getLoggedInUser();
      if (usuario == null || usuario['token'] == null) {
        _mostrarSnackbar('No hay usuario autenticado', isError: true);
        return;
      }
      final resultado = await SincronizacionService.sincronizacionCompleta(usuario['token']);
      if (resultado['exito_general']) {
        _mostrarSnackbar('Sincronización completada exitosamente');
      } else {
        _mostrarSnackbar('Error en la sincronización', isError: true);
      }
    } catch (e) {
      _mostrarSnackbar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  void _mostrarSnackbar(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1B5E20),
        title: Text('Mi Perfil', style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: _isSyncing ? null : _sincronizar,
            tooltip: 'Sincronizar datos',
          ),
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.white),
            onPressed: () async {
              await widget.authProvider.logout();
              widget.onLogout();
            },
            tooltip: 'Cerrar sesión',
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
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Iconsax.user,
                          size: 50,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.authProvider.user?['nombre'] ?? 'Usuario',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.authProvider.user?['correo'] ?? '',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Personal',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre completo',
                      icon: Iconsax.user,
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
                      icon: Iconsax.sms,
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
                    
                    Text(
                      'Seguridad',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _contrasenaActualController,
                      label: 'Contraseña actual (opcional)',
                      icon: Iconsax.lock,
                      obscureText: true,
                    ),
                    
                    _buildTextField(
                      controller: _contrasenaNuevaController,
                      label: 'Nueva contraseña (opcional)',
                      icon: Iconsax.key,
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
                      Text(
                        'Centro de Salud / Sede',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSedeInfo(),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF1B5E20).withOpacity(0.4),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.save_2, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Guardar Cambios',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
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