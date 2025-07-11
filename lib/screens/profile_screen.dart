import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.authProvider.user?['nombre']);
    _correoController = TextEditingController(text: widget.authProvider.user?['correo']);
    _contrasenaActualController = TextEditingController();
    _contrasenaNuevaController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaActualController.dispose();
    _contrasenaNuevaController.dispose();
    super.dispose();
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
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.authProvider.logout();
              widget.onLogout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ... (same form fields as before)
              // Keep the same form fields from the previous implementation
            ],
          ),
        ),
      ),
    );
  }
}