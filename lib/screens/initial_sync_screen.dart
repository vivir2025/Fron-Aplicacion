import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/paciente_provider.dart';
import '../services/sincronizacion_service.dart';
import 'dart:ui';

class InitialSyncScreen extends StatefulWidget {
  const InitialSyncScreen({Key? key}) : super(key: key);

  @override
  State<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends State<InitialSyncScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusMessage = 'Iniciando sincronización...';
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSync() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pacienteProvider = Provider.of<PacienteProvider>(context, listen: false);

    try {
      // ✅ PASO 1: Cargar sedes
      setState(() {
        _statusMessage = 'Cargando sedes...';
        _progress = 0.20;
      });
      await pacienteProvider.loadSedes();

      // ✅ PASO 2: Sincronizar pacientes desde servidor
      setState(() {
        _statusMessage = 'Sincronizando pacientes desde servidor...';
        _progress = 0.40;
      });
      
      if (authProvider.isAuthenticated && authProvider.token != null) {
        // 🆕 USAR EL MÉTODO DE SINCRONIZACIÓN COMPLETA DE PACIENTES
        await pacienteProvider.syncPacientesFromServer();
        
        setState(() {
          _statusMessage = 'Pacientes sincronizados correctamente';
          _progress = 0.60;
        });
      } else {
        // Si no hay token, solo cargar desde DB local
        debugPrint('⚠️ Sin token, cargando pacientes desde DB local');
        await pacienteProvider.loadPacientesFromDB();
        
        setState(() {
          _statusMessage = 'Pacientes cargados desde almacenamiento local';
          _progress = 0.60;
        });
      }

      // ✅ PASO 3: Cargar medicamentos
      setState(() {
        _statusMessage = 'Cargando medicamentos...';
        _progress = 0.80;
      });
      await authProvider.loadInitialMedicamentos();

      // ✅ PASO 4: Finalización
      setState(() {
        _statusMessage = '¡Sincronización completa!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }

    } catch (e) {
      debugPrint("❌ Error durante la sincronización inicial: $e");
      
      // ✅ EN CASO DE ERROR, INTENTAR CARGAR SOLO DESDE DB LOCAL
      try {
        setState(() {
          _statusMessage = 'Error de conexión, cargando datos locales...';
          _progress = 0.70;
        });
        
        await pacienteProvider.loadPacientesFromDB();
        
        setState(() {
          _statusMessage = 'Datos locales cargados correctamente';
          _progress = 1.0;
        });
        
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Modo offline: usando datos locales'),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
        
      } catch (localError) {
        debugPrint("❌ Error crítico cargando datos locales: $localError");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error crítico: $localError'),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 5),
            ),
          );
          await authProvider.logout();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Fondo con patrones
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
              ),
            ),
            // Contenido principal
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo o ícono
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            size: 50,
                            color: Color(0xFF1E8449),
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Título
                        const Text(
                          'Fundación Nacer para Vivir',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E8449),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Indicadores de progreso
                        _buildStatusIndicator(),
                        const SizedBox(height: 30),
                        // Mensaje de estado actual
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2E86C1),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Mensaje de espera
                        Text(
                          'Esto solo tomará un momento',
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Versión
            Positioned(
              bottom: 20,
              right: 20,
              child: Text(
                '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator('Cargando sedes', Icons.business_outlined, 0.20),
        const SizedBox(height: 12),
        _buildStepIndicator('Sincronizando pacientes', Icons.people_outline, 0.40),
        const SizedBox(height: 12),
        _buildStepIndicator('Cargando medicamentos', Icons.medication_outlined, 0.80),
        const SizedBox(height: 12),
        _buildStepIndicator('Sincronización completa', Icons.check_circle_outline, 1.0),
        const SizedBox(height: 25),
        // Barra de progreso personalizada
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 10,
                width: MediaQuery.of(context).size.width * 0.85 * 0.8 * _progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E86C1),
                      Color(0xFF1E8449),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(String message, IconData icon, double progress) {
    final isCompleted = _progress >= progress;
    final isInProgress = _progress < progress && _progress > progress - 0.20;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted 
                ? const Color(0xFF1E8449).withOpacity(0.1)
                : isInProgress 
                    ? const Color(0xFF2E86C1).withOpacity(0.1)
                    : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Icon(
                icon,
                color: isCompleted 
                    ? const Color(0xFF1E8449)
                    : isInProgress 
                        ? const Color(0xFF2E86C1)
                        : Colors.grey[400],
                size: isInProgress ? 20 + _controller.value * 2 : 20,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCompleted || isInProgress ? FontWeight.w500 : FontWeight.normal,
              color: isCompleted 
                  ? const Color(0xFF1E8449)
                  : isInProgress 
                      ? const Color(0xFF2E86C1)
                      : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}

// Pintor personalizado para el fondo con patrones (sin cambios)
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E86C1).withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    for (int i = 0; i < 5; i++) {
      final radius = (i + 1) * 50.0;
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.15),
        radius,
        paint,
      );
      
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.85),
        radius,
        paint,
      );
    }
    
    final linePaint = Paint()
      ..color = const Color(0xFF1E8449).withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    for (int i = 0; i < 10; i++) {
      final offset = i * 30.0;
      canvas.drawLine(
        Offset(0, offset),
        Offset(offset * 2, 0),
        linePaint,
      );
      
      canvas.drawLine(
        Offset(size.width, size.height - offset),
        Offset(size.width - offset * 2, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
